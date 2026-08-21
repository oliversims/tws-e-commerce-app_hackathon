# 02_route53_acm — outputs.tf
# DNS + TLS identifiers for later stacks and Kubernetes Ingress manifests.
# Apply from your PC; save these after apply (see RESTORATION.txt).

output "certificate_arn" {
  description = "Used by Ingress TLS (kubernetes/ingress.yaml)"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "hosted_zone_id" {
  description = "Used by 08_external-dns"
  value       = aws_route53_zone.main.zone_id
}

output "domain_name" {
  description = "Used by 08_external-dns domain filter"
  value       = var.domain_name
}
