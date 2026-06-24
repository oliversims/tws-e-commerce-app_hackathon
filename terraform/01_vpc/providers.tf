# 01_vpc — providers.tf
# S3 backend is fully configured here — just run: terraform init && terraform apply

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0, < 6.0.0"
    }
  }

  backend "s3" {
    bucket       = "tfstate-tws-us-east-1-681j1a"
    key          = "01_vpc/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = local.region
}
