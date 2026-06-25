# 13_metrics-server — providers.tf

terraform {
  required_version = ">= 1.5"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17"
    }
  }

  backend "s3" {
    bucket       = "tfstate-tws-us-east-1-681j1a"
    key          = "13_metrics-server/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}
