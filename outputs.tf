output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint (private unless endpoint_public_access = true)."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the control plane."
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN, for creating more IRSA roles."
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnets used by worker nodes."
  value       = module.vpc.private_subnets
}

output "kms_key_arns" {
  description = "Customer-managed KMS keys by purpose."
  value       = { for k, m in module.kms : k => m.key_arn }
}

output "bastion_instance_id" {
  description = "SSM bastion instance ID."
  value       = one(module.bastion[*].instance_id)
}

output "connect" {
  description = "How to reach the cluster."
  value = var.enable_bastion ? join("\n", [
    "aws ssm start-session --region ${local.region} --target ${one(module.bastion[*].instance_id)}",
    "# then, on the bastion:",
    "aws eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name} && kubectl get nodes",
  ]) : "aws eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name}"
}
