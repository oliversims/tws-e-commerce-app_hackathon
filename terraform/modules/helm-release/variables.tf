# modules/helm-release — variables.tf
# Input variables accepted by the helm-release module (chart, repo, values, etc.).

# Kubernetes namespace where the chart will be installed.
variable "namespace" {
  description = "Namespace where to deploy the application"
  type        = string
}

# Chart metadata map: name, version, chart, deploy toggle, and optional Helm flags.
variable "app" {
  description = "Helm chart metadata and deploy toggle"
  type        = map(any)
}

# Optional TLS credentials and credentials for private Helm repositories.
variable "repository_config" {
  description = "Optional Helm repository authentication configuration"
  type        = map(any)
  default     = {}
}

# Raw Helm values YAML strings passed to the chart.
variable "values" {
  description = "Helm values YAML content"
  type        = list(string)
  default     = []
}

# Non-sensitive Helm --set key=value overrides.
variable "set" {
  description = "Helm --set values"
  type = list(object({
    name  = string
    value = string
  }))
  default = null
}

# Sensitive Helm --set overrides (hidden in Terraform plan output).
variable "set_sensitive" {
  description = "Sensitive Helm --set values"
  type = list(object({
    name  = string
    value = string
  }))
  default = null
}

# Public Helm chart repository URL.
variable "repository" {
  description = "Helm chart repository URL"
  type        = string
}
