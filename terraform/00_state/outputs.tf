# 00_state — outputs.tf

output "state_bucket_name" {
  description = "Used by stacks 01-10 via state.tf"
  value       = aws_s3_bucket.tfstate_bucket.id
}

output "state_bucket_region" {
  description = "Used by stacks 01-10 via state.tf"
  value       = var.aws_region
}
