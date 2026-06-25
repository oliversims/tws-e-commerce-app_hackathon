# 08_external-dns — variables.tf

variable "domain_name" {
  description = "Only create DNS records under this domain"
  type        = string
  default     = "simsoliver.com"
}
