terraform {

#   backend "s3" {
#     bucket       = "account-vending-terraform-state"
#     key          = "web-app-ec2/terraform.tfstate"
#     region       = "eu-west-1"
#     use_lockfile = true
#   }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  profile = "mxcc"
}

# provider "aws" {
#   region = var.region
#     al
# }

# provider "aws" {
#   region = "us-east-1"
#   alias  = "us_east_1"
# }
