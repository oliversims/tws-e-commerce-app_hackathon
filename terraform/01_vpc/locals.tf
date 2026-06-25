# 01_vpc — locals.tf

locals {
  backend_bucket = data.terraform_remote_state.state.outputs.state_bucket_name
  backend_region = data.terraform_remote_state.state.outputs.state_bucket_region
  region         = local.backend_region
  name            = "tws-eks-cluster"
  vpc_cidr        = "10.0.0.0/16"
  azs             = ["${local.region}a", "${local.region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  tags = {
    example = local.name
  }
}
