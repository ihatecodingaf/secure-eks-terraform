data "aws_region" "current" {}

locals {
  service_prefix = "com.amazonaws.${data.aws_region.current.name}"

  interface_services = var.enable_interface_endpoints ? toset(var.interface_services) : toset([])
}

################################################################################
# S3 gateway endpoint (free). ECR stores image layers in S3, so this alone
# keeps most image-pull traffic off the NAT gateway.
################################################################################

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "${local.service_prefix}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = merge(var.tags, { Name = "${var.name}-s3" })
}

################################################################################
# Interface endpoints: AWS API calls from nodes and pods stay inside the VPC.
################################################################################

resource "aws_security_group" "endpoints" {
  count = var.enable_interface_endpoints ? 1 : 0

  name_prefix = "${var.name}-vpce-"
  description = "HTTPS from inside the VPC to AWS interface endpoints"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-vpce" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_https" {
  count = var.enable_interface_endpoints ? 1 : 0

  security_group_id = aws_security_group.endpoints[0].id
  description       = "HTTPS from the VPC"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_services

  vpc_id              = var.vpc_id
  service_name        = "${local.service_prefix}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.name}-${each.value}" })
}
