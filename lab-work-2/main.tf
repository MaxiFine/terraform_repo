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
    bucket = var.bucket_name

}

# S3 BUCKET ACCESS CONFIGURATION
resource "aws_s3_bucket_public_access_block" "mx-bucket" {
  bucket = aws_s3_bucket.mx-bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Puting Object into s3
resource "aws_s3_bucket_object" "index" {
  bucket = aws_s3_bucket.mx-bucket.id
  key    = "index.html"
#   source = "C:/Users/MaxwellAdomako/terraforms/lab-work-2/error.html"

  source =  "${path.module}/index.html" 
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "error" {
  bucket = aws_s3_bucket.mx-bucket.id
  key    = "error.html"
  source = "${path.module}/error.html" 
  content_type = "text/html"
}

# S3 Static Website Hosting Configurations
resource "aws_s3_bucket_website_configuration" "mx-bucket" {
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
      "Action": [ "s3:GetObject"],
      "Resource": [
        "${aws_s3_bucket.mx-bucket.arn}",
        "${aws_s3_bucket.mx-bucket.arn}/*"
      ]
    }
  ]
}
EOF
}



