# WITH FREE domain

# resource "aws_cloudfront_distribution" "app" {
#   enabled = true
#   comment = "CloudFront HTTPS for ${var.env}"

#   origin {
#     domain_name = aws_instance.ec2.public_dns
#     origin_id   = "ec2-origin"

#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "http-only"
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }
#   }

#   default_cache_behavior {
#     target_origin_id       = "ec2-origin"
#     viewer_protocol_policy = "redirect-to-https"

#     allowed_methods = ["GET", "HEAD"]
#     cached_methods  = ["GET", "HEAD"]

#     forwarded_values {
#       query_string = false
#       cookies { forward = "none" }
#     }
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }

#   tags = { Env = var.env }
# }

# WITH Domian
# resource "aws_cloudfront_distribution" "sandbox" {
#   enabled = true
#   comment = "Sandbox CloudFront for ${var.domain_name}"

#   aliases = [var.domain_name]

#   origin {
#     domain_name = aws_instance.ec2.public_dns
#     origin_id   = "sandbox-ec2"

#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "http-only"
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }
#   }

#   default_cache_behavior {
#     target_origin_id       = "sandbox-ec2"
#     viewer_protocol_policy = "redirect-to-https"

#     allowed_methods = ["GET", "HEAD"]
#     cached_methods  = ["GET", "HEAD"]

#     forwarded_values {
#       query_string = false
#       cookies { forward = "none" }
#     }
#   }

#   viewer_certificate {
#     acm_certificate_arn      = aws_acm_certificate_validation.sandbox_cert_validation.certificate_arn
#     ssl_support_method       = "sni-only"
#     minimum_protocol_version = "TLSv1.2_2021"
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   tags = {
#     Env = var.env
#   }
# }




resource "aws_cloudfront_distribution" "sandbox" {
  enabled = true
  comment = "Sandbox CloudFront for ${var.domain_name}"

  aliases = [var.domain_name]

  origin {
    domain_name = aws_instance.ec2.public_dns
    origin_id   = "sandbox-ec2"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "sandbox-ec2"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  # If you have an ACM certificate, keep this:
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.sandbox_cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # If you don't have ACM, use CloudFront's default SSL certificate by commenting the above lines and uncommenting this:
  # viewer_certificate {
  #   cloudfront_default_certificate = true
  # }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Env = var.env
  }
}
