# 09_argocd — main.tf
# Deploys Argo CD via Helm for GitOps application delivery to the cluster.
# Run on the bastion after 06_bastion; typically after 07_alb-controller / 08_external-dns
# if you expose the Argo CD UI with an Ingress and DNS.

# Helm release that installs Argo CD in the argocd namespace.
# server.secretkey must be set; an empty argocd-secret makes the UI show
# "Failed to load data" after helm upgrade.
resource "random_password" "argocd_server_secretkey" {
  length  = 32
  special = false
}

module "argocd" {
  source = "../modules/helm-release"

  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"

  app = {
    name             = "my-argo-cd"
    version          = "8.1.3"
    chart            = "argo-cd"
    force_update     = true
    wait             = false
    recreate_pods    = false
    create_namespace = true
  }

  values = [file("${path.module}/values.yaml")]

  set = [
    {
      name  = "configs.secret.extra.server\\.secretkey"
      value = random_password.argocd_server_secretkey.result
    }
  ]
}
