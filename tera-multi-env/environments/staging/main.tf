module "vpc" {
  source      = "../../modules/vpc"
  env         = "staging"
  vpc_cidr    = "10.20.0.0/16"
  az_count    = 2
  enable_nat  = true
}

resource "aws_lb" "alb" {
  name               = "staging-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
}

resource "aws_instance" "app" {
  # count                  = length(module.vpc.private_subnets)
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  subnet_id              = element(module.vpc.private_subnets, 0)

  tags = {
    Name = "staging-app-server"
  }
}
