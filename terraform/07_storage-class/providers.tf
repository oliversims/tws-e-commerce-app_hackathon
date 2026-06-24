# 07_storage-class — providers.tf

terraform {
  required_version = ">= 1.5"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
  }

  backend "s3" {
    bucket       = "tfstate-tws-us-east-1-681j1a"
    key          = "07_storage-class/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
