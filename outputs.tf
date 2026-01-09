output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "ec2_public_ip" {
  value = aws_instance.ec2.public_ip
}

output "ec2_public_dns" {
  value = aws_instance.ec2.public_dns
}

output "sandbox_domain" {
  value = var.domain_name
}

output "sandbox_cloudfront_domain" {
  value = aws_cloudfront_distribution.sandbox.domain_name
}

output "sandbox_https_url" {
  value = "https://${var.domain_name}"
}

output "ec2_elastic_ip" {
  value = data.aws_eip.existing.public_ip
}