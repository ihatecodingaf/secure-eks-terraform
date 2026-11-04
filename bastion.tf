################################################################################
# SSM-only admin host
#
# The Kubernetes API is private, so engineers reach it from inside the VPC.
# This host has no SSH, no key pair and no public IP: access is through AWS
# Systems Manager Session Manager, which is IAM-authenticated and logged.
################################################################################

module "bastion" {
  source = "./modules/ssm-bastion"
  count  = var.enable_bastion ? 1 : 0

  name         = "${local.name}-bastion"
  vpc_id       = module.vpc.vpc_id
  subnet_id    = module.vpc.private_subnets[0]
  cluster_name = local.name
  kms_key_arn  = module.kms["ebs"].key_arn
  tags         = local.tags
}
