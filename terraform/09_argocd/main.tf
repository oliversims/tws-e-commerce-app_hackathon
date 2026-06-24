# 09_argocd — main.tf
# Deploys Argo CD via Helm for GitOps-based application delivery to the cluster.

# Helm release that installs Argo CD in the argocd namespace.
module "argocd" {
  source = "../modules/helm-release"

  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"

  app = {
    name             = "my-argo-cd"
    description      = "argo-cd"
    version          = "8.1.3"
    chart            = "argo-cd"
    force_update     = true
    wait             = false
    recreate_pods    = false
    create_namespace = true
    deploy           = 1
  }

  values = [templatefile("${path.module}/values.yaml", {
    serverReplicas = 1
  })]

  depends_on = [data.terraform_remote_state.storage_class]
}
