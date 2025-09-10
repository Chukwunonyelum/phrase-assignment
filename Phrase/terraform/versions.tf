terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"   # matches the new-style attributes
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
  required_version = ">= 1.3.0"
}
