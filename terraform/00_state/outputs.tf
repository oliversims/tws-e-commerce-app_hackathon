# 00_state — outputs.tf
# Exposes the state bucket name + region for every later stack.
# Stacks 01+ read these via local remote_state in their state.tf files.
# Keep terraform/00_state/terraform.tfstate until the bastion is up (also uploaded by 06).

output "state_bucket_name" {
  description = "Used by stacks 01–16 via state.tf"
  value       = aws_s3_bucket.tfstate_bucket.id
}

output "state_bucket_region" {
  description = "Used by stacks 01–16 via state.tf"
  value       = var.aws_region
}
