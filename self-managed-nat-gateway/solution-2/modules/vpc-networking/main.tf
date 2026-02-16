module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "~> 6.0"

    name = var.vpc_name
    cidr = var.vpc_cidr  # 65,536 IP addresses

    # Define AZs and subnet ranges
    azs             = [local.az[0], local.az[1]] # 2 Availability Zones
    public_subnets  = local.public_subnets  
    private_subnets = local.private_subnets

    enable_nat_gateway = false # Using custom NAT instance instead of managed NAT gateway

    tags = {
        Terraform   = "true"
        Environment = "Development"
        Purpose     = "learn-self-managed-nat-gateway-instance"
        Module     = "aws-vpc-module"

    }
}
