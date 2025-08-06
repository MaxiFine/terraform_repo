output "website_endpoint" {
    description = "value of the website endpoint"
    value = aws_s3_bucket.mx-bucket.bucket_regional_domain_name
    # value = aws_s3_bucket.mx-bucket.website_domain
    # value = aws_s3_bucket.mx-bucket.s3_bucket_bucket_re_domain_name
}

# modules call type
# output "website_endpoint_module_call_type" {
#   value = module.s3.website_endpoint
# }

output "name_of_s3_bucket" {
    description = "Name of the S3 bucket"
    value       = aws_s3_bucket.mx-bucket.website_domain
  
}

output "s3_bucket_id" {
    description = "ID of the S3 bucket"
    value       = aws_s3_bucket.mx-bucket.id
}