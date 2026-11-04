variable "name" {
  description = "Name prefix for endpoint resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the endpoints in."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR allowed to reach the interface endpoints."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets that get an endpoint network interface."
  type        = list(string)
}

variable "route_table_ids" {
  description = "Route tables associated with the S3 gateway endpoint."
  type        = list(string)
}

variable "enable_interface_endpoints" {
  description = "Create the interface endpoints. The S3 gateway endpoint is always created (it is free)."
  type        = bool
  default     = true
}

variable "interface_services" {
  description = "AWS services to expose through interface endpoints."
  type        = list(string)
  default = [
    "ecr.api",     # image manifests
    "ecr.dkr",     # image pulls
    "sts",         # IRSA token exchange
    "eks-auth",    # EKS Pod Identity
    "ec2",         # VPC CNI ENI management
    "logs",        # CloudWatch Logs
    "kms",         # envelope encryption calls
    "ssm",         # Session Manager
    "ssmmessages", # Session Manager
    "ec2messages", # Session Manager
  ]
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
