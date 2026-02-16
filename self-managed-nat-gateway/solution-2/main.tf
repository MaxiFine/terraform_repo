##############################################
# Provider Configuration
##############################################
# Configure the AWS provider to use the desired region
provider "aws" {
    # region = "us-east-2" # US East (Ohio) region
    region = "eu-west-1" # EU (Ireland) region
}

# Specify required providers and their versions
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

############################################
# VPC and Subnet Configuration
############################################

# Create VPC using the official AWS VPC module
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

##########################################
# AMI Configuration
##########################################

# Fetch the latest ARM64 Amazon Linux 2023 AMI
# Error with t3.small because of my account reqs
# data "aws_ami" "latest_amazon_linux" {
#     most_recent = true

#     filter {
#         name   = "name"
#         values = ["al2023-ami-2023.*-arm64"] # Using ARM for cost optimization
#     }

#     filter {
#         name   = "virtualization-type"
#         values = ["hvm"]
#     }

#     owners = ["amazon"]
# }

## SOLUTION 2: Use x86_64 AMI instead of ARM64 to avoid compatibility issues with t3.small instance type
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


##########################################
# NAT Instance Configuration
##########################################

# IAM role for NAT instance (for SSM access)
resource "aws_iam_role" "nat_ssm_role" {
  name = "self-managed-nat-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Terraform   = "true"
    Environment = "Development"
    Purpose     = "nat-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "nat_ssm_core" {
  role       = aws_iam_role.nat_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nat_ssm_profile" {
  name = "self-managed-nat-ssm-profile"
  role = aws_iam_role.nat_ssm_role.name
}

# Create the NAT instance in the public subnet
resource "aws_instance" "nat_ec2_instance" {
    # instance_type = "t4g.nano"  # ARM-based instance for cost optimization
    instance_type = "t3.small"  # ARM-based instance for cost optimization
    ami           = data.aws_ami.latest_amazon_linux.id
    subnet_id     = module.vpc.public_subnets[0]
    iam_instance_profile = aws_iam_instance_profile.nat_ssm_profile.name
    
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
        Environment = "Development"
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
        Environment = "Development"
        Purpose     = "learn-self-managed-nat-gateway-instance"
    }
}

# Elastic IP for the NAT instance
resource "aws_eip" "nat_ec2_eip" {
    tags = {
        Name        = "self-managed-nat-ec2-instance-eip"
        Terraform   = "true"
        Environment = "Development"
        Purpose     = "learn-self-managed-nat-gateway-instance"
    }
}

# Associate the Elastic IP with the NAT instance
resource "aws_eip_association" "nat_ec2_eip_assoc" {
    instance_id   = aws_instance.nat_ec2_instance.id
    allocation_id = aws_eip.nat_ec2_eip.id

    # tags = {
    #     Name        = "self-managed-nat-ec2-instance-eip-association"
    #     Terraform   = "true"
    #     Environment = "Development"
    #     Purpose     = "learn-self-managed-nat-gateway-instance"
    # }
}

##########################################
# Route Table Configuration
##########################################

# Add route for private subnet traffic through NAT instance
resource "aws_route" "nat_ec2_route" {
    route_table_id         = module.vpc.private_route_table_ids[0]
    destination_cidr_block = "0.0.0.0/0"
    network_interface_id   = aws_instance.nat_ec2_instance.primary_network_interface_id

    # tags = {
    #     Name        = "nat-ec2-instance-route"
    #     Terraform   = "true"
    #     Environment = "Development"
    #     Purpose     = "learn-self-managed-nat-gateway-instance"
    # }
}

# Also add route for second private subnet if it exists
resource "aws_route" "nat_ec2_route_2" {
    count                  = length(module.vpc.private_route_table_ids) > 1 ? 1 : 0
    route_table_id         = module.vpc.private_route_table_ids[1]
    destination_cidr_block = "0.0.0.0/0"
    network_interface_id   = aws_instance.nat_ec2_instance.primary_network_interface_id
}

##########################################
# VPC Endpoints (for SSM access from private subnets)
##########################################

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "self-managed-nat-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Allow HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name        = "self-managed-nat-vpc-endpoints-sg"
    Terraform   = "true"
    Environment = "Development"
  }
}

# SSM VPC Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "self-managed-nat-ssm-endpoint"
    Terraform   = "true"
    Environment = "Development"
  }
}

# SSM Messages VPC Endpoint
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "self-managed-nat-ssmmessages-endpoint"
    Terraform   = "true"
    Environment = "Development"
  }
}

# EC2 Messages VPC Endpoint
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "self-managed-nat-ec2messages-endpoint"
    Terraform   = "true"
    Environment = "Development"
  }
}

# SPIN THE PROJECT UP

##########################################
# Private Test EC2 (for NAT validation)
##########################################

# IAM role for SSM
resource "aws_iam_role" "private_ssm_role" {
    name = "self-managed-nat-private-ssm-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action    = "sts:AssumeRole",
            Effect    = "Allow",
            Principal = { Service = "ec2.amazonaws.com" }
        }]
    })

    tags = {
        Terraform   = "true"
        Environment = "Development"
        Purpose     = "nat-validation-ssm-role"
    }
}

resource "aws_iam_role_policy_attachment" "private_ssm_core" {
    role       = aws_iam_role.private_ssm_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "private_ssm_profile" {
    name = "self-managed-nat-private-ssm-profile"
    role = aws_iam_role.private_ssm_role.name
}

# Security group for private test EC2
resource "aws_security_group" "private_test_ec2_sg" {
    name        = "self-managed-nat-private-test-ec2-sg"
    description = "Security group for private test EC2 to validate NAT egress"
    vpc_id      = module.vpc.vpc_id

    # Allow ICMP from within VPC for simple ping debugging
    ingress {
        from_port   = -1
        to_port     = -1
        protocol    = "icmp"
        cidr_blocks = [module.vpc.vpc_cidr_block]
        description = "Allow ICMP from VPC"
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
        Name        = "self-managed-nat-private-test-ec2-sg"
        Terraform   = "true"
        Environment = "Development"
        Purpose     = "nat-validation"
    }
}

# Private test EC2 instance (no public IP)
resource "aws_instance" "private_test_ec2" {
    ami                         = data.aws_ami.latest_amazon_linux.id
    instance_type               = "t3.micro"
    subnet_id                   = module.vpc.private_subnets[0]
    associate_public_ip_address = false
    vpc_security_group_ids      = [aws_security_group.private_test_ec2_sg.id]
    iam_instance_profile        = aws_iam_instance_profile.private_ssm_profile.name

    tags = {
        Name        = "self-managed-nat-private-test-ec2"
        Terraform   = "true"
        Environment = "Development"
        Purpose     = "nat-validation"
    }
}

##########################################
# Helpful Outputs
##########################################

output "nat_instance_id" {
    value       = aws_instance.nat_ec2_instance.id
    description = "ID of the NAT EC2 instance"
}

output "nat_instance_eip" {
    value       = aws_eip.nat_ec2_eip.public_ip
    description = "Elastic IP associated with NAT EC2"
}

output "private_test_instance_id" {
    value       = aws_instance.private_test_ec2.id
    description = "ID of the private test EC2"
}
