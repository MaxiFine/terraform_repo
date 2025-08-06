output "s3_bucket_endpoint" {
    description = "Name of the S3 bucket"
    # value       = aws_s3_bucket.modules.s3.website_endpoint
    value = module.s3.website_endpoint
  
}

# output "s3_bucket_name" {
#     description = "Name of the S3 bucket"
#     value       = module.s3.name_of_s3_bucket
# }

output "s3_bucket_id" {
    description = "ARN of the S3 bucket"
    value       = module.s3.s3_bucket_id
}

# output "s3_bucket_id" {
#     description = "ID of the S3 bucket"
#     value       = module.s3.bucket_id
# }