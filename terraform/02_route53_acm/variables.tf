# 02_route53_acm — variables.tf
# Domain input for the hosted zone and ACM certificate.
# Apply from your PC; default is the project apex domain.

variable "domain_name" {
  description = "Apex domain for the Route 53 hosted zone and ACM certificate"
  type        = string
  default     = "simsoliver.com"
}
