# Terraform Infrastructure Management for Vrasio

This repository contains the Terraform configuration files used to manage infrastructure for Vrasio's environment. This includes managing AWS resources like EC2, CloudFront, Redis setup, and other related services.

## Prerequisites

Before running Terraform, ensure that you have:

- Terraform installed on your system. You can download it from [Terraform official website](https://www.terraform.io/downloads).
- AWS credentials configured. If you haven't configured your AWS CLI credentials, you can follow the instructions [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

## Setup

### Initialize Terraform

Run the following command to initialize your Terraform environment. This will download the necessary provider plugins and modules.

```bash
terraform init
```

### Plan the Infrastructure

Use the following command to generate an execution plan for your infrastructure. Make sure to specify your variable file (`dev.tfvars`) to provide environment-specific configurations.

```bash
terraform plan -var-file="dev.tfvars" -out="dev.tfplan"
```

### Apply the Plan

Once the plan is generated, apply the changes to your infrastructure:

```bash
terraform apply "dev.tfplan"
```

### Destroy the Infrastructure

To destroy the infrastructure, run the following command with the specified variable file:

```bash
terraform destroy -var-file="dev.tfvars"
```

### Apply Changes to Specific Resources

To apply changes to specific resources, you can use the `-replace` flag. Here's an example for replacing an EC2 instance:

```bash
terraform plan -var-file="dev.tfvars" -replace="aws_instance.ec2" -out="dev.tfplan"
terraform apply -var-file="dev.tfvars" -replace="aws_instance.ec2"
```

## Output

- `ec2_public_dns` = "ec2-13-57-20-205.us-west-1.compute.amazonaws.com"
- `ec2_public_ip` = "54.177.103.217"
- `sandbox_cloudfront_domain` = "d38pavieo2eevg.cloudfront.net"
- `sandbox_domain` = "dev.vrasio.com"
- `sandbox_https_url` = "https://dev.vrasio.com"
- `subnet_id` = "subnet-0a1b01c8d8df0d63d"
- `vpc_id` = "vpc-0296b7c52d5cfb962"

These variables represent the public DNS/IP for the EC2 instance, CloudFront distribution, VPC, and other environment-specific configurations.

## Redis Setup

To set up Redis properly, follow these steps:

1. Add the Redis user and group:

   ```bash
   sudo useradd redis
   sudo groupadd redis
   ```

2. Add the `redis` user to the group:

   ```bash
   sudo useradd -g redis redis
   sudo usermod -aG redis redis
   ```

3. Set permissions for Redis data directory:

   ```bash
   sudo chown -R redis:redis /var/lib/redis
   sudo chmod -R 700 /var/lib/redis
   ```

4. Set permissions for the Redis service file:

   ```bash
   sudo chown redis:redis /etc/systemd/system/redis.service
   sudo chmod 755 /etc/systemd/system/redis.service
   ```

5. Reload systemd, restart Redis service, and check its status:

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart redis
   sudo systemctl status redis
   ```

6. Test the Redis connection:

   ```bash
   redis-cli ping
   ```

This will ensure that Redis is installed and running correctly.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
