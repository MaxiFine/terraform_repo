module "vpc" {
  source      = "../../modules/vpc"
  env         = "dev"
  vpc_cidr    = "10.10.0.0/16"
  az_count    = 1
  enable_nat  = false
}

resource "aws_instance" "dev_server" {
  ami                    = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true

  tags = { Name = "dev-server" }
}
