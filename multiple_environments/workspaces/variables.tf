 
variable default_region {
    type = string
    description = "the region this infrastructure is in"
    # default = "ap-southeast-1"
    default = "eu-west-1"
}
 
variable instance_size {
    type = string
    description = "ec2 web server size"
    default = "t2.micro"
}

variable infra_env {
    type = map(string)
    default =  {
        staging = "infra-staging"
        production   = "infra-production"
        Purpose = "Define environment names for infrastructure"
        Task = "Manage multiple environments using workspaces"
    }
}


#############
### VPC Variables
variable "env" {
    # default = terraform.workspace
    default = "dev"
    description = "Environment For this resources"
}
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "az_count" { default = 2 }
variable "enable_nat" { 
    description = "Enable NAT Gateways"
    default = true # for prod environment
    # default = false  # for dev environment
    }

variable "project_name" {
    description = "Name of Project"
    type = string
    default = "ReachApp"
  
}