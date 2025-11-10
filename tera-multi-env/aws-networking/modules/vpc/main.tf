data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_subnet" "public" {
  count = var.az_count
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.env}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count = var.az_count
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index + var.az_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.env}-private-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.env}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  count = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Optional NAT Gateway
resource "aws_eip" "nat" {
  count = var.enable_nat ? 1 : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]
  tags = { Name = "${var.env}-nat" }
}

output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_subnets" {
  value = aws_subnet.public[*].id
}
output "private_subnets" {
  value = aws_subnet.private[*].id
}
