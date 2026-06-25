# 02_route53_acm — outputs.tf

output "certificate_arn" {
  value = aws_acm_certificate.main.arn
}

output "hosted_zone_id" {
  value = aws_route53_zone.main.zone_id
}
