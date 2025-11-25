terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
 
  # backend "s3" {
  #   bucket                  = "tf-awesome-backend"
  #   key                     = "terraform.tfstate"
  #   workspace_key_prefix    = "workspaces"
  #   region                  = "ap-southeast-1"
  #   profile                 = "tf-awesome"
  # }
}


provider "aws" {
    region = "eu-west-1"
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


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_instance" "private" {
  ami                    = local.selected_ami  
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  associate_public_ip_address = false

  tags = {
    Name = "PrivateInstance"
  }
}

# create an rds instance in the private subnet
# use a bastian host to access it from that same subnet
# Add a cloud watch to do a stress testing too.