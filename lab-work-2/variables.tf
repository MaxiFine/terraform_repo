variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1" 
  
}

variable "bucket_name" {
    description = "AWS S3 Bucket"
    type = string
    default = "mx-lab-bucket"
  
}

