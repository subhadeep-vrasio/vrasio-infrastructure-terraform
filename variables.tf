variable "aws_region" { type = string }
variable "env"        { type = string }

variable "vpc_cidr"    { type = string }
variable "subnet_cidr" { type = string }

variable "ami_id"        { type = string }
variable "instance_type"{ type = string }
variable "key_name"     { type = string }

variable "root_volume_size" { type = number }
variable "root_volume_type" { type = string }

variable "ssh_cidr"  { type = string }
variable "http_cidr" { type = string }

variable "install_web_stack" { type = bool }

variable "domain_name" {
  description = "Full domain name for sandbox"
  type        = string
}

variable "origin_domain_name" {
  description = "Internal origin DNS that CloudFront connects to"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone id for vrasio.com"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for dev assets"
  type        = string
}

variable "elastic_ip" {
  description = "EC2 Static Elastic IP address"
  type        = string
}
