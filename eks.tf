################################################################################
# EKS cluster
################################################################################

locals {
  cluster_admin_policy = "arn:${local.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  admin_access_entries = {
    for i, arn in var.cluster_admin_role_arns : "admin-${i}" => {
      principal_arn = arn
      policy_associations = {
        admin = {
          policy_arn   = local.cluster_admin_policy
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  bastion_access_entries = {
    for k, v in { bastion = true } : k => {
      principal_arn       = one(module.bastion[*].iam_role_arn)
      policy_associations = {
        admin = {
          policy_arn   = local.cluster_admin_policy
          access_scope = { type = "cluster" }
        }
      }
    } if var.enable_bastion
  }

  bastion_api_rules = {
    for k, v in { ingress_bastion_https = true } : k => {
      description                       = "kubectl from the SSM bastion"
      type                              = "ingress"
      protocol                          = "tcp"
      from_port                         = 443
      to_port                           = 443
      source_security_group_id          = one(module.bastion[*].security_group_id)
    } if var.enable_bastion
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = local.name
  cluster_version = var.kubernetes_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # API endpoint is private by default. Public access, if enabled, is limited
  # to an explicit CIDR allowlist (0.0.0.0/0 is rejected by validation).
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = var.endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  cluster_security_group_additional_rules = local.bastion_api_rules

  # IAM-native access entries instead of the legacy aws-auth ConfigMap.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true
  access_entries                           = merge(local.admin_access_entries, local.bastion_access_entries)

  # Envelope-encrypt Kubernetes Secrets with our own KMS key.
  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = module.kms["eks"].key_arn
  }

  # Full control plane audit trail, encrypted at rest.
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_kms_key_id        = module.kms["logs"].key_arn
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  cluster_addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
      # Enforce Kubernetes NetworkPolicy natively in the VPC CNI.
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
      })
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    general = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Encrypted gp3 root volume with our own key.
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.node_disk_size_gb
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = module.kms["ebs"].key_arn
            delete_on_termination = true
          }
        }
      }

      # IMDSv2 only, hop limit 1: pods cannot reach the node's instance
      # credentials and must use IRSA / Pod Identity instead.
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      # Shell access through SSM Session Manager instead of SSH keys.
      iam_role_additional_policies = {
        ssm = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        workload = "general"
      }
    }
  }

  tags = local.tags
}

################################################################################
# IAM role for the EBS CSI driver (IRSA), scoped to our EBS KMS key
################################################################################

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.48"

  role_name             = "${local.name}-ebs-csi"
  attach_ebs_csi_policy = true
  ebs_csi_kms_cmk_ids   = [module.kms["ebs"].key_arn]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}
