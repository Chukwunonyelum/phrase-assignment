variable "aws_region" {
  default = "us-east-1"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "acm_cert_arn" {
  description = "ACM certificate ARN"
  type        = string
}


variable "ami" {
  description = "AMI ID for the EC2 instances"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file used by Ansible"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the site"
  type        = string
}


variable "record_name" {
  description = "subdomain name for the site"
  type        = string
}

# Provide your issued ACM cert ARN (same region as the ALB)
variable "acm_certificate_arn" {
  type        = string
  description = "ARN of an ISSUED ACM certificate"
}






