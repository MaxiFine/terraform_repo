terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
#   region = "eu-west-1"
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_import" {
  # bucket = "mx-test-import-bucket"
  bucket = "mx-terraform-import-bucket"
  force_destroy = true
  tags = {
    Name        = "mx-terraform-import-bucket" 
    Type        = "Import"
    LiveBucket = "mx-terraform-import-bucket"
    test        = "import"
  }
  }
