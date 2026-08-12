# 12_metrics-server — main.tf
# Deploys metrics-server for kubectl top and HPA CPU/memory metrics.
# Run on the bastion after 06_bastion; useful before 13_kube-prometheus-stack.

# Helm release that installs metrics-server in kube-system.
module "metrics_server" {
  source = "../modules/helm-release"

  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"

  app = {
    name             = "metrics-server"
    description      = "metrics-server"
    version          = "3.12.2"
    chart            = "metrics-server"
    force_update     = true
    wait             = false
    recreate_pods    = false
    create_namespace = false
    deploy           = 1
  }

  values = [file("${path.module}/values.yaml")]
}
