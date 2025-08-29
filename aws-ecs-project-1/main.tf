# Updated Terraform configuration for ECS
# - Uses Amazon Linux 2 ECS-optimized AMI via SSM parameter
# - Injects user-data template (ecs.sh.tpl) into launch template
# - Adds CloudWatch Logs group + awslogs configuration in task definition
# - Enables ALB access logs to an S3 bucket
# - Enables ECS Container Insights for the cluster

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Use the ECS-optimized Amazon Linux 2 AMI (recommended for EC2-backed ECS)
# This SSM parameter returns the latest recommended AMI image id for the region
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "aws_caller_identity" "current" {}

# (Optional) keep ubuntu AMI data if you want it elsewhere, but it's unused below
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

# VPC, subnets, IGW, route table (unchanged)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = { Name = "ECS|main" }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = { Name = "ECS|subnet1" }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = { Name = "ECS|subnet2" }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "ECS|Internet_gateway" }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = { Name = "ECS|Route_table_main" }
}

resource "aws_route_table_association" "subnet_route" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet2_route" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "security_group" {
  name   = "ecs-security-group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ECS|Security_group" }
}

############
# Instance Profile & IAM (unchanged)
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "MxECSInstanceRole"
  role = aws_iam_role.ecs_instance_role.name
  tags = { Name = "MxECSInstanceRole" }
}

# Launch template: use ECS-optimized AMI and templatefile user-data
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-template"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3.micro"

  key_name               = "aws-365-keypair"
  vpc_security_group_ids = [aws_security_group.security_group.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "ECS|Instance|Template" }
  }

  # Inject cluster-aware user-data (must save ecs.sh.tpl in this module)
  user_data = base64encode(
    templatefile("${path.module}/ecs.sh.tpl", { cluster_name = aws_ecs_cluster.ecs_cluster.name })
  )
}

resource "aws_autoscaling_group" "ecs_asg" {
  vpc_zone_identifier = [aws_subnet.subnet.id, aws_subnet.subnet2.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

# ALB S3 bucket for access logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = "mx-ecs-alb-logs-${data.aws_caller_identity.current.account_id}"
  acl    = "private"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "delivery.logs.amazonaws.com" },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.alb_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    }
  ]
}
POLICY
}

resource "aws_lb" "ecs_alb" {
  name               = "MxECSLoadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security_group.id]
  subnets            = [aws_subnet.subnet.id, aws_subnet.subnet2.id]

  access_logs {
    enabled = true
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-logs"
  }

  tags = { Name = "MxECSLoadBalancer" }
}

resource "aws_lb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "MxECSTargetGroup"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path = "/"
  }

  tags = { Name = "ECSTargetGroup" }
}

#########
## ECS Cluster (enable Container Insights)
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "MxECSCluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = { Name = "MxECSCluster" }
}

# ECS Capacity Provider & attachment (unchanged)
resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "mx-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn
    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 3
    }
  }
  tags = { Name = "ECSCapacityProvider" }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
  }
}

# CloudWatch Log Group for ECS tasks
resource "aws_cloudwatch_log_group" "ecs_tasks" {
  name              = "/ecs/mxECSFamily"
  retention_in_days = 14
}

# ECS Task Definition with awslogs logConfiguration
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family             = "mxECSFamily"
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  cpu                = 256
  memory             = "512"

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "dockergs",
      image     = "docker.io/maxfine22/getting-started:latest",
      cpu       = 256,
      memory    = 512,
      essential = true,
      portMappings = [
        {
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_tasks.name,
          "awslogs-region"        = "us-east-1",
          "awslogs-stream-prefix" = "dockergs"
        }
      }
    }
  ])

  tags = { Name = "ECSTaskDefinition" }
}

# ECS service (unchanged aside from references)
resource "aws_ecs_service" "ecs_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 2

  network_configuration {
    subnets         = [aws_subnet.subnet.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.security_group.id]
  }

  force_new_deployment = true
  placement_constraints { type = "distinctInstance" }

  triggers = { redeployment = timestamp() }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "dockergs"
    container_port   = 80
  }

  tags = { Name = "ECSService" }
  depends_on = [aws_autoscaling_group.ecs_asg]
}

# Task Execution Role (unchanged)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
