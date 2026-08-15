variable "namespace" {
  description = "Kubernetes namespace for the release"
  type        = string
}

variable "repository" {
  description = "Helm chart repository URL"
  type        = string
}

variable "app" {
  description = "Chart name, version, and optional Helm flags (force_update, wait, recreate_pods, create_namespace)"
  type        = map(any)
}

variable "values" {
  description = "Helm values YAML documents"
  type        = list(string)
  default     = []
}

variable "set" {
  description = "Helm --set overrides"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
