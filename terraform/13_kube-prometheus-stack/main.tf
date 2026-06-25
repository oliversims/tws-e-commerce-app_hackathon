# 13_kube-prometheus-stack — main.tf
# Deploys kube-prometheus-stack (Prometheus, Grafana, Alertmanager) via Helm.

locals {
  alertmanager_slack_values = var.slack_webhook_url != "" ? yamlencode({
    alertmanager = {
      config = {
        route = {
          receiver = "slack-notification"
          routes = [
            {
              receiver = "slack-notification"
              matchers = ["severity = \"critical\""]
            }
          ]
        }
        receivers = [
          {
            name = "slack-notification"
            slack_configs = [
              {
                api_url       = var.slack_webhook_url
                channel       = var.slack_channel
                send_resolved = true
              }
            ]
          }
        ]
      }
    }
  }) : null
}

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

  values = concat(
    [file("${path.module}/values.yaml")],
    local.alertmanager_slack_values != null ? [local.alertmanager_slack_values] : []
  )
}
