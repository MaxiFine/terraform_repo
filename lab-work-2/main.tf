terraform {

  # Backend configuration for storing Terraform state
  backend "s3" {
    bucket         = var.bucket_name
    key            = "terraform.tfstate"
    region        = var.aws_region
  }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

provider "aws" {
  region = var.aws_region
}

module "s3" {
  source = "./s3"
  bucket_name = var.bucket_name
  
}