resource "aws_vpc" "mx-ecs-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "mx-ecs-vpc"
    Environment = "test-env"
    Project     = "ECS Project 1"
  }
}

resource "aws_subnet" "mx-ecs-subnet-1" {
  vpc_id            = aws_vpc.mx-ecs-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name        = "mx-ecs-subnet-1"
    Environment = "test-env"
    Project     = "ECS Project 1"
  }
}

