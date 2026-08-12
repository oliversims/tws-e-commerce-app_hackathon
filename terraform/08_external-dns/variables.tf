# 08_external-dns — variables.tf
# Domain filter for ExternalDNS — only records under this zone are managed.
# Override at apply time if the hosted domain differs from the default.

variable "domain_name" {
  description = "Only create DNS records under this domain"
  type        = string
  default     = "simsoliver.com"
}
