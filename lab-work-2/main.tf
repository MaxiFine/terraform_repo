terraform {

  # Backend configuration for storing Terraform state
  backend "s3" {
    bucket         = "mx-tf-state-bucket-dev"
    key            = "lab-work-2/terraform.tfstate"
    region        = "us-east-1"
    encrypt = true
    dynamodb_table = "mx-tf-state-dynamo-table-dev"
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