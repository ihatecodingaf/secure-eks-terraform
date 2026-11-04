variable "alias" {
  description = "Key alias, without the alias/ prefix."
  type        = string
}

variable "description" {
  description = "Human-readable description of what the key protects."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Waiting period before a scheduled key deletion completes."
  type        = number
  default     = 30
}

variable "policy_statements" {
  description = "Additional Allow statements appended to the key policy."
  type = list(object({
    sid                   = string
    principal_type        = string
    principal_identifiers = list(string)
    actions               = list(string)
    conditions = list(object({
      test     = string
      variable = string
      values   = list(string)
    }))
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the key."
  type        = map(string)
  default     = {}
}
