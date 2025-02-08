variable "aws_region" {
  description = "AWS Region to hold resources"
  type        = string
  default     = "eu-west-1"
}



variable "db_password" {
  type    = string
  default = "maxwell22"

}

variable "db_username" {
  type    = string
  default = "postgresrds"
}