# 08_external-dns — providers.tf
# Declares AWS and Helm providers; pins versions and S3 backend.
# Helm talks to the cluster via ~/.kube/config — run on the bastion.
# S3 backend key matches this folder (08_external-dns/...).

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
    key          = "08_external-dns/terraform.tfstate"
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
