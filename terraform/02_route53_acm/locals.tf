# 02_route53_acm — locals.tf
# Region local: from 00_state — must be us-east-1 for ACM certs used by ALB.
# Apply from your PC after 00_state.

locals {
  # us-east-1 — required for ACM certs used by ALB in this project.
  region = data.terraform_remote_state.state.outputs.state_bucket_region
}
