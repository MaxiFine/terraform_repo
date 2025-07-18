# ECS Creation with Auto Scaling Group and Capacity Provider
resource "aws_ecs_cluster" "mx-ecs-aws_ecs_cluster" {
  name = "mx-ecs-aws_ecs_cluster"
  tags = {
    Name = "mx-ecs-aws_ecs_cluster"
    Environment = "test-env"
    Project = "ECS Project 1"
  }
  
}

resource "aws_ecs_capacity_provider" "mx-ecs-capacity-provider" {
  name = "mx-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.mx-ecs-asg.arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      status = "ENABLED"
      target_capacity = 3
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 10
    }  
    
    }
  tags = {
    Name = "mx-ecs-capacity-provider"
    Environment = "test-env"
    Project = "ECS Project 1"
  }
}


resource "aws_ecs_cluster_capacity_providers" "mx-ecs-capacity-providers" {
  cluster_name = aws_ecs_cluster.mx-ecs-aws_ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.mx-ecs-capacity-providers.name]

  default_capacity_provider_strategy {
    base = 1
    weight = 10
    capacity_provider = aws_ecs_capacity_provider.mx-ecs-capacity-provider.name
  }
}

# Definition of ECS task service
resource "aws_ecs_task_definition" "mx-ecs-task-definition" {
  family                   = "mx-ecs-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
#   execution_role_arn = aws_iam_role.mx-ecs-task-execution-role.arn
#   task_role_arn      = aws_iam_role.mx-ecs-task-role.arn
  cpu                      = "256"
  memory                   = "512"

  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = "mx-ecs-container"
    #   image     = "nginx:latest"
      image     = "public.ecr.aws/f9n5f1l7/dgs:latest"
    #   command   = ["nginx", "-g", "daemon off;"]
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = {
    Name        = "mx-ecs-task-definition"
    Environment = "test-env"
    Project     = "ECS Project 1"
  }
  
}

# ECS to run the service
resource "aws_ecs_service" "mx-ecs-service" {
  name            = "mx-ecs-service"
  cluster         = aws_ecs_cluster.mx-ecs-aws_ecs_cluster.id
  task_definition = aws_ecs_task_definition.mx-ecs-task-definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-12345678", "subnet-87654321"] # Replace with your subnet IDs
    security_groups  = ["sg-12345678"] # Replace with your security group ID
    assign_public_ip = true
  }

  force_new_deployment = true
  placement_constraints {
    type = "distinctInstance"
    # type = "typeOfPlacementConstraint"
  }

  triggers = {
    redeployment = timestamp()
  }



  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.mx-ecs-capacity-provider.name
    weight            = 1
    base              = 1
  }


  load_balancer {
    target_group_arn = "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-target-group/1234567890abcdef" # Replace with your target group ARN
    container_name   = "mx-ecs-container"
    container_port   = 80
  }

  depends_on = [ aws_autoscaling_group.ecs-asg ]

  tags = {
    Name        = "mx-ecs-service"
    Environment = "test-env"
    Project     = "ECS Project 1"
  }
  
}