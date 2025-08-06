# output "s3_bucket_name" {
#     description = "Name of the S3 bucket"
#     value       = aws_s3_bucket.mx-bucket.name
  
# }
output "s3_bucket_name" {
    description = "Name of the S3 bucket"
    value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
    description = "ARN of the S3 bucket"
    value       = module.s3.bucket_arn
}

output "s3_bucket_id" {
    description = "ID of the S3 bucket"
    value       = module.s3.bucket_id
}