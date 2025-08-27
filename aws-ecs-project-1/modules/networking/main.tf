data "aws_availability_zones" "available" {
    state = "available"
}


resource "aws_vpc" "ecs_vpc" {
#   name = 'ecs_vpc'
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"  

  tags = {
    Name = "ECS|VPC"
    Environment = "dev"
    owner = "mx-devops"
  }
}

resource "aws_subnet" "ecs_subnet_1" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "ECS|Subnet|1"
    Environment = "dev"
    owner      = "mx-devops"
  }
}


resource "aws_subnet" "ecs_subnet_2" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "ECS|Subnet|2"
    Environment = "dev"
    owner      = "mx-devops"
  }
}

resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name        = "ECS|IGW"
    Environment = "dev"
    owner      = "mx-devops"
  }
}

resource "aws_route_table" "ecs_route_table" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }

  tags = {
    Name        = "ECS|Route|Table"
    Environment = "dev"
    owner      = "mx-devops"
  }
}

resource "aws_route_table_association" "ecs_subnet_1" {
  subnet_id      = aws_subnet.ecs_subnet_1.id
  route_table_id = aws_route_table.ecs_route_table.id
}

resource "aws_route_table_association" "ecs_subnet_2" {
  subnet_id      = aws_subnet.ecs_subnet_2.id
  route_table_id = aws_route_table.ecs_route_table.id
}

resource "aws_security_group" "ecs_security_group" {
  name = "ecs_security_group"
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ECS|Security|Group"
    Environment = "dev"
    owner      = "mx-devops"
  }
}