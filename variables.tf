################################################################################
# General
################################################################################

variable "project_name" {
  description = "Short name used as a prefix for every resource."
  type        = string
  default     = "secure-eks"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project_name))
    error_message = "project_name must be 2-21 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Extra tags applied to every resource."
  type        = map(string)
  default     = {}
}

################################################################################
# Network
################################################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC. A /16 is recommended so pods get plenty of IPs."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 16
    error_message = "vpc_cidr must be a valid CIDR of size /16 or larger."
  }
}

variable "az_count" {
  description = "Number of Availability Zones to spread the cluster across."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3 (EKS requires at least two AZs)."
  }
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway (cheaper, not AZ-resilient). Set false for one NAT per AZ in production."
  type        = bool
  default     = false
}

variable "enable_interface_endpoints" {
  description = "Create private VPC interface endpoints (ECR, STS, SSM, Logs, ...) so AWS API traffic never leaves the VPC."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention for EKS control plane logs and VPC flow logs."
  type        = number
  default     = 90
}

################################################################################
# EKS
################################################################################

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Keep this on a version in EKS standard support."
  type        = string
  default     = "1.35"
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API publicly. Off by default: the API is reachable only from inside the VPC (via the SSM bastion)."
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint when endpoint_public_access = true."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.endpoint_public_access_cidrs, "0.0.0.0/0")
    error_message = "Refusing to expose the Kubernetes API to 0.0.0.0/0. List specific office/VPN CIDRs instead."
  }
}

variable "cluster_admin_role_arns" {
  description = "IAM role ARNs (e.g. an SSO admin role) granted cluster-admin through EKS access entries."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Desired number of worker nodes at creation."
  type        = number
  default     = 2
}

variable "node_disk_size_gb" {
  description = "Root volume size for worker nodes."
  type        = number
  default     = 50
}

################################################################################
# Access
################################################################################

variable "enable_bastion" {
  description = "Create an SSM-only admin host (no SSH, no public IP) in a private subnet for kubectl access to the private API."
  type        = bool
  default     = true
}
