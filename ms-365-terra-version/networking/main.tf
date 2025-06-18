


resource "aws_vpc" "mx-vpc" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = {
    Name               = "MxProject-VPC-1"
  }

}

resource "aws_subnet" "public_subnet" {
  vpc_id               = aws_vpc.mx-vpc.id
  cidr_block           = var.public_subnet_cidr
  # more dynamic availability zones can be added if needed
  availability_zone    = "${var.aws_region_short}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet | 1"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region_short}a"

  tags = {
    Name        = "Private Subnet | 1"
    Environment = "Development"
  }
}


resource "aws_internet_gateway" "mx-internet-gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "mx-project-internet-gateway"
    Environment = "Development"
  }
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.mx-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mx-internet-gateway.id
  }

  tags = {
    Name        = "Public Route Table"
    Environment = "Development"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.mx-vpc.id

  tags = {
    Name        = "Private Route Table"
    Environment = "Development"
  }

}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}


resource "aws_eip" "mx_eip_nat" {
  #   vpc = true
  domain = "vpc"

  tags = {
    Name        = "MxProject-NAT-EIP"
    Environment = "Development"
  }

}

resource "aws_nat_gateway" "mx_nat_gateway" {
  allocation_id = aws_eip.mx_eip_nat.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name        = "MxProject-NAT-Gateway"
    Environment = "Development"
  }
}