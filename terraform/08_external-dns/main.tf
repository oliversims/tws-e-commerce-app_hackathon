# 08_external-dns — main.tf
# Watches Ingress resources and creates Route 53 records for *.simsoliver.com subdomains.

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

module "iam_role" {
  source = "../modules/eks-oidc-iam-role"

  role_name         = "AmazonEKSExternalDNSRole"
  oidc_provider_url = data.terraform_remote_state.eks.outputs.oidc_provider_url
  policy_arns       = [aws_iam_policy.external_dns.arn]

  tags = {
    Role = "role-external-dns"
  }
}

module "external_dns" {
  source = "../modules/helm-release"

  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns/"

  app = {
    name             = "external-dns"
    description      = "external-dns"
    version          = "1.15.0"
    chart            = "external-dns"
    force_update     = true
    wait             = false
    recreate_pods    = false
    create_namespace = false
    deploy           = 1
  }

  values = [templatefile("${path.module}/values.yaml", {
    role_arn       = module.iam_role.iam_role_arn
    domain_name    = var.domain_name
    region         = local.region
    txt_owner_id   = data.terraform_remote_state.eks.outputs.eks_cluster_name
    hosted_zone_id = data.terraform_remote_state.route53_acm.outputs.hosted_zone_id
  })]
}
