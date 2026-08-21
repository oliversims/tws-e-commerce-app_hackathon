# 03_keys — outputs.tf
# Exposes the EC2 key pair name for SSH-capable stacks.
# Apply from your PC; consumers read this via terraform_remote_state.

output "deployer_key_name" {
  description = "Used by 05_jenkins and 06_bastion"
  value       = aws_key_pair.deployer.key_name
}
