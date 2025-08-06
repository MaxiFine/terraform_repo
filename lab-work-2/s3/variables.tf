variable "bucket_name" {
    description = "AWS S3 Bucket"
    type = string
    # default = "mx-lab-bucket"
    default = "mx-tf-state-bucket-dev"
  
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1" 
  
}