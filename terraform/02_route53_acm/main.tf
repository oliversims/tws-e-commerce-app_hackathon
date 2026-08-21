# 02_route53_acm — main.tf
# Creates the Route 53 hosted zone + ACM wildcard cert for simsoliver.com.
# Apply from your PC after 00_state. DNS validation records are created here.
# Outputs feed 08_external-dns; certificate_arn is also used in Ingress YAML.

resource "aws_route53_zone" "main" {
  name          = var.domain_name
  force_destroy = true

  tags = {
    Name = var.domain_name
  }
}

# Wildcard ACM cert (apex + *.) — must stay in the same region as the ALB (us-east-1).
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Apex + wildcard share one ACM validation CNAME. The ... groups those
# duplicates so for_each creates a single Route 53 record, not two.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.resource_record_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }...
  }

  allow_overwrite = true
  zone_id         = aws_route53_zone.main.zone_id
  name            = each.value[0].name
  type            = each.value[0].type
  ttl             = 60
  records         = [each.value[0].record]
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Domain is registered in Route 53 — keep registrar NS aligned with this hosted zone.
import {
  to = aws_route53domains_registered_domain.main
  id = var.domain_name
}

resource "aws_route53domains_registered_domain" "main" {
  domain_name = var.domain_name

  dynamic "name_server" {
    for_each = aws_route53_zone.main.name_servers
    content {
      name = name_server.value
    }
  }

  lifecycle {
    ignore_changes = [
      admin_contact,
      registrant_contact,
      tech_contact,
      billing_contact,
      auto_renew,
      transfer_lock,
    ]
  }
}
