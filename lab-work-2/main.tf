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


#   S3 BUCKET CREATION
resource "aws_s3_bucket" "mx-bucket" {
    bucket = "mx-lab-bucket"

}

# S3 BUCKET ACCESS CONFIGURATION
resource "aws_s3_bucket_public_access_block" "mx-bucket" {
  bucket = aws_s3_bucket.mx-bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
