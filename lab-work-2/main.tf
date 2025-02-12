terraform {
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
  # files_dir = path.cwd
  
}