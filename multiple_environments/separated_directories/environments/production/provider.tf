terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # Using local state for simplicity
  # backend "s3" {
  #   bucket                  = "tf-awesome-backend"
  #   key                     = "multi-environments/prod/terraform.tfstate"
  #   region                  = "ap-southeast-1"
  #   profile                 = "tf-awesome"
  #   use_lockfile = true
  # }
}
provider "aws" {
  profile = "reachapp"
  region  = var.default_region
}



