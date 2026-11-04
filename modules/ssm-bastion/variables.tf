variable "name" {
  description = "Name for the bastion and its IAM/SG resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC the bastion runs in."
  type        = string
}

variable "subnet_id" {
  description = "Private subnet for the bastion (it never gets a public IP)."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster the bastion is allowed to describe and configure kubectl for."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key used to encrypt the root volume."
  type        = string
}

variable "instance_type" {
  description = "Bastion instance type."
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
