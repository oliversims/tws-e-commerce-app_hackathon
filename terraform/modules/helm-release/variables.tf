# modules/helm-release — variables.tf
# Inputs for chart, repo, values, and Helm --set overrides.
# Used by bastion stacks 07–13 when wrapping helm_release.

variable "namespace" {
  description = "Namespace where to deploy the application"
  type        = string
}

variable "app" {
  description = "Helm chart metadata and deploy toggle"
  type        = map(any)
}

variable "values" {
  description = "Helm values YAML content"
  type        = list(string)
  default     = []
}

variable "set" {
  description = "Helm --set values"
  type = list(object({
    name  = string
    value = string
  }))
  default = null
}

variable "repository" {
  description = "Helm chart repository URL"
  type        = string
}
