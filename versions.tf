terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.83, < 6.0"
    }
  }

  # Partial configuration: values are supplied at init time so no
  # account-specific details live in the repo.
  #   terraform init -backend-config=backend.hcl
  backend "s3" {}
}
