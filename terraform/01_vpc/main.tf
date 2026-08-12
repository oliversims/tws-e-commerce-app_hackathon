# 01_vpc — main.tf
# Creates the VPC and core networking (subnets, IGW, NAT, route tables).
# Apply from your PC after 00_state. Outputs feed 04_eks, 05_jenkins, 06_bastion.
# Public subnets: Jenkins + Bastion. Private subnets: EKS nodes.

# Builds VPC, subnets, internet gateway, NAT gateway, and route tables.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.18.1"

  name            = local.name
  cidr            = local.vpc_cidr
  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # AWS still creates these with the VPC; do not manage them in Terraform.
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  # Tag public subnets so Kubernetes can create internet-facing load balancers.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  # Tag private subnets so Kubernetes can create internal load balancers.
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  map_public_ip_on_launch = true
}
