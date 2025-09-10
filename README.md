# Terraform + Ansible NGINX HTTPS Deployment Guide

## Overview

This project automates the deployment of a **highly available, secure NGINX web server infrastructure** on AWS using Infrastructure as Code (Terraform) and Configuration Management (Ansible). The architecture includes HTTPS support, automated scaling, and secure access patterns.

## What This Deploys

- **Networking**: VPC with public and private subnets across three Availability Zones
- **Load Balancing**: Internet-facing Application Load Balancer (ALB) with HTTP→HTTPS redirect
- **Security**: HTTPS termination at ALB with AWS ACM certificate
- **Compute**: Auto Scaling Group running NGINX in Docker containers on EC2 instances
- **Access**: Bastion host in public subnet for secure SSH access
- **DNS**: Optional Route 53 configuration for custom domains
- **Monitoring**: Health checks at `/phrase` endpoint

## Architecture Approach

1. **Terraform** provisions all AWS infrastructure components
2. **Terraform** generates dynamic Ansible inventory and configuration
3. **Ansible** configures NGINX containers through the bastion host
4. **ALB** distributes traffic to healthy instances across AZs

## Repository Structure

```
├── ansible/
│   ├── ansible.cfg.tpl          # Template for Ansible configuration
│   ├── inventory.ini            # Generated inventory (private IPs)
│   ├── inventory.tpl            # Inventory template
│   └── playbook.yml             # NGINX Docker configuration
├── phrase-assignment/
│   └── backend.tf               # Remote state configuration (optional)
└── terraform/
    ├── acm.tf                   # SSL certificate configuration
    ├── alb.tf                   # Load balancer setup
    ├── asg.tf                   # Auto Scaling Group configuration
    ├── bastion.tf               # Bastion host + Ansible automation
    ├── outputs.tf               # Output values (ALB DNS, Bastion IP)
    ├── route53.tf               # DNS management
    ├── security.tf              # Security group definitions
    ├── userdata.tpl             # EC2 bootstrap script
    ├── main.tf                  # Provider configuration
    ├── variables.tf             # Variable definitions
    ├── versions.tf              # Version constraints
    └── terraform.tfvars         # Variable values
```

## Prerequisites

### AWS Account Setup
- AWS account with appropriate IAM permissions ([IAM Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html))
- Domain hosted in Route 53 (if using custom DNS)
- ACM certificate in the same region as your deployment

### Local Environment Setup
- **Terraform** 1.3+ ([Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))
- **Ansible** 2.15+ ([Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html))
- **AWS CLI v2** ([Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **SSH key** configured in AWS and locally

### SSH Key Setup (WSL/Ubuntu)
```bash
# Copy your key to the Linux environment
cp /mnt/c/Users/MAYOR/Downloads/my-key.pem ~/.ssh/my-key.pem

# Set appropriate permissions
chmod 600 ~/.ssh/my-key.pem
```

## Configuration

### Required Variables (terraform/terraform.tfvars)

Create or update `terraform.tfvars` with your specific values:

```hcl
region = "us-east-1"
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.0.0/24","10.0.1.0/24","10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24","10.0.11.0/24","10.0.12.0/24"]
key_name = "my-key"
allowed_ssh_cidr = "203.0.113.10/32"  # Your public IP
domain_name = "yourdomain.com"         # Optional
zone_id = "Z123EXAMPLE"                # Optional
instance_type = "t3.micro"
desired_capacity = 3
min_size = 3
max_size = 5

# Use either the ARN below, or configure acm.tf for DNS validation
# acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxx"
```

## Deployment Instructions

### Step 1: Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_REGION="us-east-1"
```

### Step 2: Initialize Terraform

```bash
cd terraform
terraform init
```

### Step 3: Review Deployment Plan

```bash
terraform plan
```

### Step 4: Deploy Infrastructure

```bash
terraform apply -auto-approve
```

**This will:**
- Create VPC, subnets, and networking components
- Deploy security groups with least-privilege access
- Launch bastion host and NGINX instances
- Configure load balancer and auto scaling
- Generate Ansible inventory and configuration
- Automatically provision NGINX via Ansible

### Step 5: Verify Deployment

```bash
# Get ALB endpoint
terraform output alb_dns_name

# Test the application
curl https://$(terraform output -raw alb_dns_name)/phrase
# Expected response: "Service alive"

# Check health status
curl -I https://$(terraform output -raw alb_dns_name)/
# Expected: HTTP 200 OK
```

### Step 6: Manual Ansible Run (If Needed)

```bash
cd ../ansible

# Test connectivity
ansible -i inventory.ini nginx -m ping

# Run provisioning
ansible-playbook -i inventory.ini playbook.yml
```

## Troubleshooting

### Common Issues and Solutions

**Targets Unhealthy**
- Verify health check path is `/phrase`
- Check security groups allow port 80 from ALB to instances
- Confirm NGINX container is running on instances

**HTTPS Not Working**
- Ensure ACM certificate is in the same region as ALB
- Verify listener 443 references the correct ACM certificate

**SSH Connection Issues**
- Use appropriate username (ec2-user for Amazon Linux, ubuntu for Ubuntu)
- Verify inventory uses ProxyCommand through bastion for private instances

**Ansible Warnings**
- Run Ansible from Linux home directory, not `/mnt/c/`
- Ensure inventory file permissions are correct (chmod 644)

**DNS Resolution Problems**
- Allow 24-48 hours for DNS propagation
- Verify nameservers are correctly set at your domain registrar

## Maintenance

### Scaling the Deployment

```bash
# Increase instance count
terraform apply -var='desired_capacity=5' -auto-approve

# Update instance type
terraform apply -var='instance_type=t3.small' -auto-approve
```

### Infrastructure Updates

```bash
# Modify Terraform configurations
terraform plan
terraform apply

# Update Ansible playbook
cd ../ansible
ansible-playbook -i inventory.ini playbook.yml
```

## Cleanup

To avoid ongoing AWS charges, destroy all resources when finished:

```bash
cd terraform
terraform destroy -auto-approve
```

## Production Recommendations

### Security Enhancements
- Implement end-to-end TLS with AWS Private CA
- Replace SSH with AWS Systems Manager Session Manager
- Enable AWS WAF for application protection
- Configure CloudWatch alarms and monitoring

### Performance Optimization
- Use Packer to create pre-configured AMIs with Docker preinstalled
- Implement ALB access logs to S3 for analysis
- Configure CloudWatch dashboards for visibility

### Deployment Improvements
- Set up CI/CD pipeline for automated testing and deployment
- Implement blue-green deployment strategy
- Add automated testing with Terratest
- Use remote state storage with S3 and DynamoDB locking

## Documentation References

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible AWS Guide](https://docs.ansible.com/ansible/latest/scenario_guides/guide_aws.html)
- [AWS ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
- [Route 53 DNS Management](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html)

## Support

For issues related to:
- **Terraform**: Check plan output and validate configurations
- **Ansible**: Run with `-vvv` flag for verbose output
- **AWS**: Verify IAM permissions and service limits
- **Network**: Check security groups and NACL configurations

This deployment provides a production-ready foundation for web applications with built-in security, scalability, and automation capabilities.
