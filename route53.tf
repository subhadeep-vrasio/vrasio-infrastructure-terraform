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
