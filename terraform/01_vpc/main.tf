# 01_vpc — main.tf
# VPC, subnets, IGW, NAT, route tables. Apply from your PC after 00_state.
# Public subnets: ALB, NAT, Jenkins, bastion. Private subnets: EKS nodes.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.18.1"

  name            = local.name
  cidr            = local.vpc_cidr
  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  # Default NACL/RT stay AWS-managed (allow-all NACL; dedicated public/private RTs).
  # This is NOT eks-api-client. It locks the VPC's AWS default SG (deny all) so
  # nothing accidentally uses the built-in "allow everything inside the VPC" default.
  manage_default_network_acl     = false
  manage_default_route_table     = false
  manage_default_security_group  = true
  default_security_group_name    = "${local.name}-default-deny"
  default_security_group_ingress = []
  default_security_group_egress  = []

  # Internet-facing ALBs land in public subnets; internal LBs in private.
  public_subnet_tags = {
    "kubernetes.io/role/elb"              = 1
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"     = 1
    "kubernetes.io/cluster/${local.name}" = "shared"
    "karpenter.sh/discovery"              = local.name
  }

  map_public_ip_on_launch = true
}
