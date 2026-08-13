# 13_kube-prometheus-stack — main.tf
# Deploys kube-prometheus-stack (Prometheus, Grafana, Alertmanager) via Helm.
# Run on the bastion after 06_bastion; Ingress/DNS optional via stacks 07–08.
# Slack webhook: put the URL in slack_webhook.url (gitignored; see .example).

locals {
  # First non-empty, non-comment line from slack_webhook.url
  slack_webhook_url = try([
    for line in split("\n", file("${path.module}/slack_webhook.url")) :
    trimspace(line)
    if trimspace(line) != "" && !startswith(trimspace(line), "#")
  ][0], "")
}

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
    replace(
      file("${path.module}/values.yaml"),
      "api_url: ''",
      "api_url: ${jsonencode(local.slack_webhook_url)}"
    )
  ]
}
