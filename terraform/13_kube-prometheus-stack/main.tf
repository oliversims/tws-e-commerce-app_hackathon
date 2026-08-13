# 13_kube-prometheus-stack — main.tf
# Deploys kube-prometheus-stack (Prometheus, Grafana, Alertmanager) via Helm.
# Run on the bastion after 06_bastion; Ingress/DNS optional via stacks 07–08.
# Slack webhook: var.slack_webhook_url → values.yaml.tftpl (TF_VAR_slack_webhook_url).

# Helm release that installs Prometheus, Grafana, and Alertmanager in monitoring.
module "kube_prometheus_stack" {
  source = "../modules/helm-release"

  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"

  app = {
    name             = "my-kube-prometheus-stack"
    version          = "72.9.1"
    chart            = "kube-prometheus-stack"
    force_update     = true
    wait             = false
    recreate_pods    = false
    create_namespace = true
    deploy           = 1
  }

  values = [
    templatefile("${path.module}/values.yaml.tftpl", {
      slack_api_url = var.slack_webhook_url
    })
  ]
}
