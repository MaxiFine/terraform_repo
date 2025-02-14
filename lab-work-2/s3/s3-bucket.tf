
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

# Puting Object into s3 REDUNDANT CODES
# resource "aws_s3_bucket_object" "error" {
#   bucket = aws_s3_bucket.mx-bucket.id
#   key    = "error.html"
#   source = "${path.root}/error.html" 
#   content_type = "text/html"
# }

# USING OPTIMIZED CODES
# local vars to store the objects
locals {
  
  s3_objects = {
    index = {
      key = "index.html"
      source = "${path.root}/index.html"
      content_type = "text/html"
    }
    error = {
      key = "error.html"
      source = "${path.root}/error.html"
      content_type = "text/html"
    }
    about = {
      key = "about.html"
      source = "${path.root}/about.html"
      content_type = "text/html"
    }
  }
}


# s3 Objects created using for_each 
resource "aws_s3_bucket_object" "s3_objects" {
  for_each = local.s3_objects
  bucket = aws_s3_bucket.mx-bucket.id
  key    = each.value.key
  source = each.value.source
  content_type = each.value.content_type
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


