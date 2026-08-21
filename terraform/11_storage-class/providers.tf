# 11_storage-class — providers.tf
# Declares the Kubernetes provider; pins version and S3 backend.
# Uses ~/.kube/config — apply on the bastion after 06_bastion.
# S3 state key matches this folder name.

terraform {
  required_version = ">= 1.5"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
  }

  backend "s3" {
    bucket       = "tfstate-tws-us-east-1-pmugrd"
    key          = "11_storage-class/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
