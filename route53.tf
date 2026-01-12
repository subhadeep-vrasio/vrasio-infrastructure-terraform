resource "aws_route53_record" "sandbox_origin" {
  zone_id = var.hosted_zone_id
  name    = var.origin_domain_name
  type    = "A"
  ttl     = 60
  records = [var.elastic_ip]
}

resource "aws_route53_record" "sandbox_alias" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.sandbox.domain_name
    zone_id                = aws_cloudfront_distribution.sandbox.hosted_zone_id
    evaluate_target_health = false
  }
}
