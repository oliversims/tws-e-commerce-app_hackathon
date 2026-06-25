# 02_route53_acm — Route 53 zone + ACM cert (simsoliver.com + *.simsoliver.com)

resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name = var.domain_name
  }
}

resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  zone_id         = aws_route53_zone.main.zone_id
  name            = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_name
  type            = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_type
  ttl             = 60
  records         = [tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_value]
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
