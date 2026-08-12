# 05_jenkins — providers.tf
# AWS provider region comes from local.region (00_state via state.tf → locals).
# Remote Terraform state for this stack lives in the S3 bucket from 00_state.
# Apply from your PC after 01_vpc and 03_keys.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0, < 6.0.0"
    }
  }

  backend "s3" {
    bucket       = "tfstate-tws-us-east-1-m67t3m"
    key          = "05_jenkins/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = local.region
}
