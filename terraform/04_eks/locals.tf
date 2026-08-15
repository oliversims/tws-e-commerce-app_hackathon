# 04_eks — locals.tf
# Backend locals: bucket/region from 00_state (via state.tf) for remote_state reads.
# Cluster name local: from 01_vpc so EKS matches the VPC naming convention.
# Apply from your PC after 00_state and 01_vpc.

locals {
  backend_bucket = data.terraform_remote_state.state.outputs.state_bucket_name
  backend_region = data.terraform_remote_state.state.outputs.state_bucket_region
  region         = local.backend_region

  name = data.terraform_remote_state.vpc.outputs.cluster_name

  tags = {
    Name = local.name
  }
}
