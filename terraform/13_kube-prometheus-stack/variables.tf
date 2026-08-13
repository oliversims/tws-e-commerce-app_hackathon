# 13_kube-prometheus-stack — variables.tf
# Slack webhook for Alertmanager (set via TF_VAR_slack_webhook_url or -var).

variable "slack_webhook_url" {
  description = "Slack Incoming Webhook URL for Alertmanager (do not commit)"
  type        = string
  sensitive   = true
  default     = "" # empty is ok for destroy; apply script requires a real URL
}
