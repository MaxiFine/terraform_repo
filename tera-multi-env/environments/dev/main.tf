/*
Terraform Settings and AWS Provider Configuration

- terraform.required_providers: Ensures the AWS provider from HashiCorp 
  is installed, pinned to version ~> 6.0 for compatibility and stability.  

- terraform.backend "s3": Stores Terraform state remotely in an S3 bucket 
  for collaboration and persistence. The `use_lockfile = true` option 
  prevents simultaneous modifications of the state.  

- provider "aws": Configures the AWS provider to use the region specified 
  in the `var.region` variable.  

Purpose:
Establishes consistent Terraform behavior, remote state management, and 
the AWS provider connection details.  
*/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  
  # backend "s3" {
  #   bucket       = "account-vending-terraform-state"
  #   key          = "web-app-serverless/terraform.tfstate"
  #   region       = "eu-west-1"
  #   use_lockfile = true
  # }
}



provider "aws" {
  region = "eu-west-1"
  alias = "primary"
  profile = "default"
}

# provider "aws" {
#   region = "us-east-1"
#   alias  = "us_east_1"
# }

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}




module "vpc" {
  # source      = "../../modules/vpc"
  source      = "../../aws-networking/modules/vpc"
  env         = "dev"
  vpc_cidr    = "10.10.0.0/16"
  az_count    = 1
  enable_nat  = false
}


# Validate existence if provided
data "aws_ami" "validate" {
  count  = var.ami_id != "" ? 1 : 0
  owners = ["self", "amazon", "099720109477"]

  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}

# Default to latest Ubuntu
data "aws_ami" "ubuntu_latest" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  selected_ami = var.ami_id != "" ? data.aws_ami.validate[0].id : data.aws_ami.ubuntu_latest[0].id
}
resource "aws_instance" "dev_server" {
  ami                    = local.selected_ami
  instance_type          = "t2.micro"
  subnet_id              = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true

  tags = { Name = "dev-server" }
}
