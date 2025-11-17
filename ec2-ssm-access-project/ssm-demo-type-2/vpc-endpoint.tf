locals {
  services = {
    "ec2messages" : {
      "name" : "com.amazonaws.${var.region}.ec2messages"
    },
    "ssm" : {
      "name" : "com.amazonaws.${var.region}.ssm"
    },
    "ssmmessages" : {
      "name" : "com.amazonaws.${var.region}.ssmmessages"
    }
  }
}


resource "aws_vpc_endpoint" "ssm_endpoint" {
    for_each = local.services
    vpc_id = aws_vpc.main.id
    service_name = each.value.name
    vpc_endpoint_type = "Interface"
    subnet_ids = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
    private_dns_enabled = true
    ip_address_type = "ipv4"
    tags = {
        Name = "MX-SSM-Endpoint"
    }
}

# Security Group for VPC Endpoint
resource "aws_security_group" "ssm_https" {
  name        = "allow_ssm"
  description = "Allow SSM traffic"
#   vpc_id      = module.vpc.vpc_id
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # cidr_blocks = module.vpc.private_subnets_cidr_blocks
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_security_group" "ssm_endpoint_sg" {
  name        = "ssm-endpoint-sg"
  description = "Security group for SSM VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
        Name = "ssm-endpoint-sg"
    }
}

