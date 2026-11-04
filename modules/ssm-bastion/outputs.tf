output "instance_id" {
  description = "Instance ID, used with aws ssm start-session."
  value       = aws_instance.this.id
}

output "iam_role_arn" {
  description = "IAM role ARN of the bastion (granted cluster access via an EKS access entry)."
  value       = aws_iam_role.this.arn
}

output "security_group_id" {
  description = "Security group ID of the bastion."
  value       = aws_security_group.this.id
}
