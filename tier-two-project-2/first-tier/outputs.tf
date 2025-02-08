terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configs for provider
provider "aws" {
  region = "eu-west-1"

}

# Create the VPC
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    name = "vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    name = "public_subnet-1"
  }
}

resource "aws_subnet" "public_subnet-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    name = "public_subnet-2"
  }
}

# Create the private Subnets
resource "aws_subnet" "private_subnet-1" {
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = "10.0.3.0/24"
  availability_zone               = "eu-west-1a"
  map_customer_owned_ip_on_launch = false

  tags = {
    name = "private_subnet"
  }
}

resource "aws_subnet" "private_subnet-2" {

  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = "10.0.4.0/24"
  availability_zone               = "eu-west-1b"
  map_customer_owned_ip_on_launch = false

  tags = {
    name = "private_subnet-2"
  }
}


