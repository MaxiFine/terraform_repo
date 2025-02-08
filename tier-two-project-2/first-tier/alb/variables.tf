variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

# Optionally, if you need to reference a public security group:
variable "public_sg_id" {
  description = "ID of the public security group"
  type        = string
}
