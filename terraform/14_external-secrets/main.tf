# 14_external-secrets — main.tf
# IRSA + External Secrets Operator. Syncs AWS Secrets Manager into Kubernetes Secrets.
# Run on the bastion after 04_eks. Pair with kubernetes/ ClusterSecretStore + ExternalSecret.

# IAM policy: read only the easyshop/* secrets in this account/region.
data "aws_iam_policy_document" "external_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [
      "arn:aws:secretsmanager:${local.region}:${data.aws_caller_identity.current.account_id}:secret:easyshop/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_secrets" {
  name   = "ExternalSecretsSecretsManagerPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.external_secrets.json
}

# IAM role assumed by the external-secrets ServiceAccount (IRSA).
module "iam_role" {
  source = "../modules/eks-oidc-iam-role"

  role_name         = "AmazonEKSExternalSecretsRole"
  oidc_provider_url = data.terraform_remote_state.eks.outputs.oidc_provider_url
  policy_arns       = [aws_iam_policy.external_secrets.arn]

  tags = {
    Role = "role-external-secrets"
  }
}

# Helm: External Secrets Operator in its own namespace.
module "external_secrets" {
  source = "../modules/helm-release"

  namespace  = "external-secrets"
  repository = "https://charts.external-secrets.io"

  app = {
    name             = "external-secrets"
    version          = "0.16.2"
    chart            = "external-secrets"
    force_update     = true
    wait             = false
    recreate_pods    = false
    create_namespace = true
  }

  values = [templatefile("${path.module}/values.yaml", {
    role_arn = module.iam_role.iam_role_arn
  })]
}
