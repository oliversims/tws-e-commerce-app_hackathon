# 02_keys — outputs.tf

output "deployer_key_name" {
  description = "Used by 03_eks, 04_jenkins, and 05_bastion"
  value       = aws_key_pair.deployer.key_name
}
