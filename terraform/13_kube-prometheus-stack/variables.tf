# 13_kube-prometheus-stack — variables.tf

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for Alertmanager (leave empty to disable Slack)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "slack_channel" {
  description = "Slack channel for Alertmanager notifications"
  type        = string
  default     = "#alerts"
}
