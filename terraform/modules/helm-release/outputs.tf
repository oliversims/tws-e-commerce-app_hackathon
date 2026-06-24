# modules/helm-release — outputs.tf
# Returns Helm release metadata and name to the calling stack.

# Full Helm release metadata (empty list when deploy is disabled).
output "deployment" {
  description = "Helm release metadata when deploy is enabled"
  value       = var.app["deploy"] ? [helm_release.this[0].metadata] : []
}

# Chart release name as shown by `helm list`.
output "release_name" {
  description = "Name of the Helm release"
  value       = var.app["deploy"] ? helm_release.this[0].name : null
}
