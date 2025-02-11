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


# S3 Static Website Hosting Configurations

resource "aws_s3_bucket_website_configuration" "bucket1" {
  bucket = aws_s3_bucket.mx-bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}
resource "aws_s3_bucket_policy" "public_read_access" {
  bucket = aws_s3_bucket.mx-bucket.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
   "Principal": "*",
      "Action": [ "s3:GetObject" ],
      "Resource": [
        "${aws_s3_bucket.mx-bucket.arn}",
        "${aws_s3_bucket.mx-bucket.arn}/*"
      ]
    }
  ]
}
EOF
}



