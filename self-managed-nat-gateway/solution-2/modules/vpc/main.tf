module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "~> 6.0"

    name = "self-managed-nat-gateway-vpc"
    cidr = "10.11.0.0/16"  # 65,536 IP addresses

    # Define AZs and subnet ranges
    azs             = [local.az[0], local.az[1]] # 2 Availability Zones
    private_subnets = ["10.11.1.0/24", "10.11.2.0/24"]    # 256 IPs each
    public_subnets  = ["10.11.101.0/24", "10.11.102.0/24"] # 256 IPs each

    enable_nat_gateway = false # Using custom NAT instance instead of managed NAT gateway

    tags = {
        Terraform   = "true"
        Environment = "Development"
        Purpose     = "learn-self-managed-nat-gateway-instance"
        Module     = "aws-vpc-module"

    }
}
