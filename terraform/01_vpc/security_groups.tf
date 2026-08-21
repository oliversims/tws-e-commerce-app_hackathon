# 01_vpc — security_groups.tf
#
# This file CREATES eks-api-client. It does not open SSH or 443 here.
# The SG is an identity tag: "instances with this SG may call the private EKS API."
# Created in 01 (not 06) so 04_eks can allow 443 from it without a cycle on the bastion.
# 06_bastion attaches this SG to the instance; 04_eks trusts it on the cluster SG.

resource "aws_security_group" "eks_api_client" {
  name        = "${local.name}-eks-api-client"
  description = "Identity SG: attach to instances allowed to reach the private EKS API"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${local.name}-eks-api-client"
  }
}
