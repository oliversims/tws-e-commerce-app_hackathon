# 09_argocd — providers.tf
# Declares Helm and Kubernetes providers; pins versions and S3 backend.
# Both providers use ~/.kube/config — apply on the bastion after 06_bastion.
# S3 backend key matches this folder (09_argocd/...).

terraform {
  required_version = ">= 1.5"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
  }

  backend "s3" {
    bucket       = "tfstate-tws-us-east-1-m67t3m"
    key          = "09_argocd/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
