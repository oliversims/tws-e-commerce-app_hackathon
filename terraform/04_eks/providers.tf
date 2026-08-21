# 04_eks — providers.tf
# AWS provider region comes from local.region (00_state via state.tf → locals).
# Remote Terraform state for this stack lives in the S3 bucket from 00_state.
# Apply from your PC after 01_vpc.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0, < 6.0.0"
    }
    # 0.14.0 time_sleep can busy-loop forever on WSL (no 20m context deadline).
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0, < 0.14.0"
    }
  }

  backend "s3" {
    bucket       = "tfstate-tws-us-east-1-m67t3m"
    key          = "04_eks/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = local.region
}
