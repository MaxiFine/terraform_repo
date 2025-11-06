variable "env" {}
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "az_count" { default = 2 }
variable "enable_nat" { default = true }
