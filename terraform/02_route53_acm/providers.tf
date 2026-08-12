# 02_route53_acm — providers.tf
# AWS provider region comes from local.region (00_state via state.tf).
# Remote Terraform state for this stack lives in the S3 bucket from 00_state.
# ACM for ALB must live in the same region as the load balancer (us-east-1).
# Apply from your PC.

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
    key          = "02_route53_acm/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = local.region
}
