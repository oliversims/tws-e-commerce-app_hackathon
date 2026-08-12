# 05_jenkins — locals.tf
# Backend locals: bucket/region from 00_state (via state.tf) for remote_state reads.
# Region local drives the AWS provider for this stack.
# Apply from your PC after 00_state.

locals {
  backend_bucket = data.terraform_remote_state.state.outputs.state_bucket_name
  backend_region = data.terraform_remote_state.state.outputs.state_bucket_region
  region         = local.backend_region

  jenkins_host = aws_eip.jenkins_server_ip.public_ip
}
