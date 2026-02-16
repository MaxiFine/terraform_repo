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
