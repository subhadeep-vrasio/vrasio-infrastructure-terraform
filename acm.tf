provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "sandbox_cert" {
  provider          = aws.use1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Env = var.env
  }
}

resource "aws_route53_record" "sandbox_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.sandbox_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "sandbox_cert_validation" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.sandbox_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.sandbox_cert_validation : r.fqdn]
}
