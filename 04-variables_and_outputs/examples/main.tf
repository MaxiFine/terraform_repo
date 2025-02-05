terraform {
  backend "s3" {
    bucket         = "mx-devops-bucket"
    key            = "04-variables-and-outputs/examples/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "mx-terraform-locking"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  extra_tag = "extra-tag"
}

resource "aws_instance" "instance" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = {
    Name     = var.instance_name
    ExtraTag = local.extra_tag
  }
}

resource "aws_db_instance" "db_instance" {
  allocated_storage   = 20
  storage_type        = "gp2"
  engine              = "postgres"
  engine_version      = "12"
  instance_class      = "db.t2.micro"
  name                = var.db_user
  username            = var.db_user
  password            = var.db_pass
  skip_final_snapshot = true
}

