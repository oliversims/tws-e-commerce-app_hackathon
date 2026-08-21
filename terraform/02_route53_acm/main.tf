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

# Apex + wildcard share one ACM validation CNAME, so one Route 53 record is enough.
# Do not for_each over domain_validation_options: those names are unknown until
# the cert is created, and Terraform cannot plan for_each keys that appear at apply.
resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  zone_id         = aws_route53_zone.main.zone_id
  name            = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_name
  type            = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_type
  ttl             = 60
  records         = [tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_value]
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
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
