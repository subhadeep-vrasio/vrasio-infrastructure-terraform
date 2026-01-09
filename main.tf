terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "ec2_sg" {
  name   = "${var.env}-ec2-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.http_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.env}-ec2-sg", Env = var.env }
}

resource "aws_instance" "ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  user_data = var.install_web_stack ? local.web_user_data : null

  tags = { Name = "${var.env}-ec2", Env = var.env }
}

# Reference the existing Elastic IP
data "aws_eip" "existing" {
  public_ip = var.elastic_ip  # Provide your existing Elastic IP (e.g., 54.177.103.217)
}

# Associate the existing Elastic IP with the EC2 instance
resource "aws_eip_association" "this" {
  instance_id   = aws_instance.ec2.id
  public_ip     = data.aws_eip.existing.public_ip
}
