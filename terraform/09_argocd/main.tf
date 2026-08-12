# 09_argocd — main.tf
# Deploys Argo CD via Helm for GitOps application delivery to the cluster.
# Run on the bastion after 06_bastion; typically after 07_alb-controller / 08_external-dns
# if you expose the Argo CD UI with an Ingress and DNS.

# Helm release that installs Argo CD in the argocd namespace.
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
    deploy           = 1
  }

  values = [templatefile("${path.module}/values.yaml", {
    serverReplicas = 1
  })]
}
