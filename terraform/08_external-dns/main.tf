# 08_external-dns — main.tf
# IRSA policy/role + ExternalDNS Helm chart for Route 53 record automation.
# Watches Ingresses and creates DNS for subdomains; run on the bastion after 06_bastion.
# Depends on 02_route53_acm and 04_eks; pairs with 07_alb-controller for public hostnames.

# IAM policy document: ChangeResourceRecordSets on the hosted zone + list actions.
data "aws_iam_policy_document" "external_dns" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${data.terraform_remote_state.route53_acm.outputs.hosted_zone_id}",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns" {
  name   = "ExternalDNSPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.external_dns.json
}

# IAM role that lets the ExternalDNS pod update Route 53 (IRSA).
module "iam_role" {
  source = "../modules/eks-oidc-iam-role"

  role_name         = "AmazonEKSExternalDNSRole"
  oidc_provider_url = data.terraform_remote_state.eks.outputs.oidc_provider_url
  policy_arns       = [aws_iam_policy.external_dns.arn]

  tags = {
    Role = "role-external-dns"
  }
}

# Helm release that installs ExternalDNS in kube-system.
module "external_dns" {
  source = "../modules/helm-release"

  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns/"

  app = {
    name          = "external-dns"
    version       = "1.15.0"
    chart         = "external-dns"
    force_update  = true
    wait          = false
    recreate_pods = false
  }

  values = [templatefile("${path.module}/values.yaml", {
    role_arn       = module.iam_role.iam_role_arn
    domain_name    = var.domain_name
    region         = local.region
    txt_owner_id   = data.terraform_remote_state.eks.outputs.eks_cluster_name
    hosted_zone_id = data.terraform_remote_state.route53_acm.outputs.hosted_zone_id
  })]
}
