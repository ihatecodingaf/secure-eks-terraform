################################################################################
# VPC
#
# Three subnet tiers per AZ:
#   public  /24  - NAT gateways and internet-facing load balancers only
#   private /20  - worker nodes and pods (large, VPC CNI gives each pod an IP)
#   intra   /24  - EKS control plane ENIs, no route to the internet at all
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.16"

  name = local.name
  cidr = var.vpc_cidr
  azs  = local.azs

  private_subnets = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 48)]
  intra_subnets   = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 52)]

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = false

  # Lock down the default security group so nothing can accidentally use it.
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  # VPC flow logs (all traffic) to a KMS-encrypted CloudWatch log group.
  enable_flow_log                                 = true
  flow_log_traffic_type                           = "ALL"
  flow_log_max_aggregation_interval               = 60
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_kms_key_id        = module.kms["logs"].key_arn
  flow_log_cloudwatch_log_group_retention_in_days = var.log_retention_days

  # Tags the AWS Load Balancer Controller and Karpenter use for discovery.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
  }

  tags = local.tags
}

module "vpc_endpoints" {
  source = "./modules/vpc-endpoints"

  name                       = local.name
  vpc_id                     = module.vpc.vpc_id
  vpc_cidr                   = module.vpc.vpc_cidr_block
  subnet_ids                 = module.vpc.private_subnets
  route_table_ids            = module.vpc.private_route_table_ids
  enable_interface_endpoints = var.enable_interface_endpoints
  tags                       = local.tags
}
