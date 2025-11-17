variable "region" {
  default = "eu-west-1"
  description = "AWS REGION"
}


variable "ami_id" {
  description = "AMI ID to use for the instance. If not provided, the latest Ubuntu 22.04 LTS AMI will be used."
  default     = ""
}
