# 10_kube-prometheus-stack — main.tf
# Deploys kube-prometheus-stack (Prometheus, Grafana, Alertmanager) via Helm.

# Helm release that installs Prometheus, Grafana, and Alertmanager in monitoring.
module "kube_prometheus_stack" {
  source = "../modules/helm-release"

  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"

  app = {
    name             = "my-kube-prometheus-stack"
    description      = "my-kube-prometheus-stack"
    version          = "72.9.1"
    chart            = "kube-prometheus-stack"
    force_update     = true
    wait             = false
    recreate_pods    = false
    create_namespace = true
    deploy           = 1
  }

  values = [file("${path.module}/values.yaml")]
}
