# -----------------------------
# Origin Request Policy
# (Forward everything to Laravel)
# -----------------------------
resource "aws_cloudfront_origin_request_policy" "sandbox_forward_all" {
  name = "${var.env}-sandbox-forward-all-policy"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "allViewer"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

# -----------------------------
# Cache Policy (Caching Disabled)
# IMPORTANT: When caching is disabled, CloudFront requires
# cookies/headers/query_string behavior to be NONE here.
# Forwarding is controlled by Origin Request Policy instead.
# -----------------------------
resource "aws_cloudfront_cache_policy" "sandbox_cache_disabled" {
  name = "${var.env}-sandbox-cache-disabled"

  default_ttl = 0
  min_ttl     = 0
  max_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = false
    enable_accept_encoding_brotli = false

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# -----------------------------
# CloudFront Distribution
# -----------------------------
resource "aws_cloudfront_distribution" "sandbox" {
  enabled = true
  comment = "Sandbox CloudFront for ${var.domain_name}"

  aliases = [var.domain_name]

  origin {
    domain_name = var.origin_domain_name
    origin_id   = "sandbox-ec2-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "sandbox-ec2-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.sandbox_cache_disabled.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.sandbox_forward_all.id
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.sandbox_cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Env = var.env
  }
}
