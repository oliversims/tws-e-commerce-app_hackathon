# 04_eks — locals.tf

locals {
  backend_bucket = data.terraform_remote_state.state.outputs.state_bucket_name
  backend_region = data.terraform_remote_state.state.outputs.state_bucket_region
  region         = local.backend_region
  name           = data.terraform_remote_state.vpc.outputs.cluster_name

  tags = {
    example = local.name
  }
}
