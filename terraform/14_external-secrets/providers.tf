# 14_external-secrets — providers.tf
# AWS + Helm; Helm uses bastion ~/.kube/config.
# S3 backend key: 14_external-secrets/terraform.tfstate

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0, < 6.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17"
    }
  }

  backend "s3" {
    bucket       = "tfstate-tws-us-east-1-m67t3m"
    key          = "14_external-secrets/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = local.region
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}
