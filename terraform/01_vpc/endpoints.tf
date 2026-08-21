# 01_vpc — endpoints.tf
#
# This does not replace NAT. NAT is still how private nodes reach the public
# internet (Docker Hub, GitHub, apt). This only shortcuts S3: add a free
# gateway endpoint so S3 traffic stays on the AWS network instead of NAT.

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.18.1"

  vpc_id                = module.vpc.vpc_id
  create_security_group = false

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
      tags            = { Name = "${local.name}-s3" }
    }
  }

  tags = {
    Name = local.name
  }
}
