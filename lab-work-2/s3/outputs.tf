output "website_endpoint" {
    # value = aws_s3_bucket.mx-bucket.bucket_regional_domain_name
    value = aws_s3_bucket.mx-bucket.website_domain
  
}

# modules call type
# output "website_endpoint" {
#   value = module.s3.website_endpoint
# }
