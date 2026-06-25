# 03_keys — outputs.tf

output "deployer_key_name" {
  description = "Used by 04_eks, 05_jenkins, and 06_bastion"
  value       = aws_key_pair.deployer.key_name
}
