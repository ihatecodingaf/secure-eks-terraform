################################################################################
# Customer-managed KMS keys
#
# One key per purpose keeps the blast radius small and lets each key policy
# grant only what that service needs. All keys rotate automatically.
################################################################################

locals {
  kms_keys = {
    eks = {
      description = "EKS envelope encryption of Kubernetes Secrets in etcd"
      statements  = []
    }

    ebs = {
      description = "EBS volumes for worker nodes, bastion and PersistentVolumes"
      statements = [
        {
          # Managed node groups launch instances through the Auto Scaling
          # service-linked role, which must be able to use the key.
          sid                   = "AllowAutoScalingUseOfKey"
          principal_type        = "AWS"
          principal_identifiers = ["arn:${local.partition}:iam::${local.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
          actions               = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
          conditions            = []
        },
        {
          sid                   = "AllowAutoScalingCreateGrant"
          principal_type        = "AWS"
          principal_identifiers = ["arn:${local.partition}:iam::${local.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
          actions               = ["kms:CreateGrant"]
          conditions = [{
            test     = "Bool"
            variable = "kms:GrantIsForAWSResource"
            values   = ["true"]
          }]
        },
      ]
    }

    logs = {
      description = "CloudWatch Logs: EKS control plane logs and VPC flow logs"
      statements = [{
        sid                   = "AllowCloudWatchLogs"
        principal_type        = "Service"
        principal_identifiers = ["logs.${local.region}.amazonaws.com"]
        actions               = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
        conditions = [{
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values   = ["arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:*"]
        }]
      }]
    }
  }
}

module "kms" {
  source   = "./modules/kms"
  for_each = local.kms_keys

  alias             = "${local.name}-${each.key}"
  description       = "${local.name}: ${each.value.description}"
  policy_statements = each.value.statements
  tags              = local.tags
}
