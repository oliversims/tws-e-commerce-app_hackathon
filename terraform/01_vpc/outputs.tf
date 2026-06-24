# 01_vpc — outputs.tf

output "region" {
  description = "Used by 08_alb-controller"
  value       = local.region
}

output "vpc_id" {
  description = "Used by 03_eks, 04_jenkins, 05_bastion, and 08_alb-controller"
  value       = module.vpc.vpc_id
}

output "cluster_name" {
  description = "Used by 03_eks"
  value       = local.name
}

output "public_subnets" {
  description = "Used by 04_jenkins and 05_bastion"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Used by 03_eks"
  value       = module.vpc.private_subnets
}
