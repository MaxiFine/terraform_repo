#---------------------------
# Outputs
#---------------------------
output "origin_bucket_arn" {
  value = aws_s3_bucket.origin.arn
}

output "replica_bucket_arn" {
  value = aws_s3_bucket.replica
}