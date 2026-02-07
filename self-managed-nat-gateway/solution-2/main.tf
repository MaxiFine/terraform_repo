##############################################
# Provider Configuration
##############################################

provider "aws" {
    region = "us-east-2" # US East (Ohio) region
}

# Specify required providers and their versions
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "6.0.0-beta1"
        }
    }
}

############################################
# VPC and Subnet Configuration
############################################

# Create VPC using the official AWS VPC module
module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "5.21.0"

    name = "my-vpc"
    cidr = "10.11.0.0/16"  # 65,536 IP addresses

    # Define AZs and subnet ranges
    azs             = ["us-east-2a", "us-east-2b"] # 2 Availability Zones
    private_subnets = ["10.11.1.0/26", "10.11.2.0/26"]    # 62 IPs each
    public_subnets  = ["10.11.101.0/24", "10.11.102.0/24"] # 254 IPs each

    enable_nat_gateway = false # Using custom NAT instance instead of managed NAT gateway

    tags = {
        Terraform   = "true"
        Environment = "dev"
    }
}

##########################################
# AMI Configuration
##########################################

# Fetch the latest ARM64 Amazon Linux 2023 AMI
data "aws_ami" "latest_amazon_linux" {
    most_recent = true

    filter {
        name   = "name"
        values = ["al2023-ami-2023.*-arm64"] # Using ARM for cost optimization
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["amazon"]
}

##########################################
# NAT Instance Configuration
##########################################

# Create the NAT instance in the public subnet
resource "aws_instance" "nat_ec2_instance" {
    instance_type = "t4g.nano"  # ARM-based instance for cost optimization
    ami           = data.aws_ami.latest_amazon_linux.id
    subnet_id     = module.vpc.public_subnets[0]
    
    # Bootstrap script to configure NAT functionality
    user_data = <<-EOF
#!/bin/bash
sudo yum install iptables-services -y
sudo systemctl enable iptables
sudo systemctl start iptables
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/custom-ip-forwarding.conf
sudo sysctl -p /etc/sysctl.d/custom-ip-forwarding.conf
sudo /sbin/iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
sudo /sbin/iptables -F FORWARD
sudo service iptables save
EOF

    source_dest_check      = false  # Required for NAT functionality
    vpc_security_group_ids = [aws_security_group.nat_ec2_sg.id]

    tags = {
        Name        = "self-managed-nat-ec2-instance"
        Terraform   = "true"
        Environment = "dev"
    }
}

# Security group for the NAT instance
resource "aws_security_group" "nat_ec2_sg" {
    name        = "self-managed-nat-ec2-sg"
    description = "Security group of Self-Managed NAT EC2 Instance"
    vpc_id      = module.vpc.vpc_id

    # Allow all TCP traffic from within the VPC
    ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = [module.vpc.vpc_cidr_block]
        description = "Allow all TCP traffic from VPC CIDR"
    }

    # Allow all outbound traffic
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }

    tags = {
        Name        = "self-managed-nat-ec2-instance-sg"
        Terraform   = "true"
        Environment = "dev"
    }
}

# Elastic IP for the NAT instance
resource "aws_eip" "nat_ec2_eip" {
    tags = {
        Name        = "self-managed-nat-ec2-instance-eip"
        Terraform   = "true"
        Environment = "dev"
    }
}

# Associate the Elastic IP with the NAT instance
resource "aws_eip_association" "nat_ec2_eip_assoc" {
    instance_id   = aws_instance.nat_ec2_instance.id
    allocation_id = aws_eip.nat_ec2_eip.id
}

##########################################
# Route Table Configuration
##########################################

# Add route for private subnet traffic through NAT instance
resource "aws_route" "nat_ec2_route" {
    route_table_id         = module.vpc.private_route_table_ids[0]
    destination_cidr_block = "0.0.0.0/0"
    network_interface_id   = aws_instance.nat_ec2_instance.primary_network_interface_id
}