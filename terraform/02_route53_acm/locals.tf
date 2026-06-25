# 02_route53_acm — locals.tf

locals {
  # us-east-1 — required for ACM certs used by ALB in this project.
  region = data.terraform_remote_state.state.outputs.state_bucket_region
}
