# 01_vpc — outputs.tf
# Networking IDs and cluster name for downstream stacks.
# Apply from your PC; consumers read these via terraform_remote_state.

output "region" {
  description = "Used by 07_alb-controller"
  value       = local.region
}

output "vpc_id" {
  description = "Used by 04_eks, 05_jenkins, 06_bastion, and 07_alb-controller"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "Used by 04_eks (API and node SSH from inside the VPC)"
  value       = local.vpc_cidr
}

output "cluster_name" {
  description = "Used by 04_eks and 06_bastion"
  value       = local.name
}

output "public_subnets" {
  description = "Used by 05_jenkins and 06_bastion"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Used by 04_eks"
  value       = module.vpc.private_subnets
}
