resource "aws_lb" "ecs_alb" {
 name               = "ecs-alb"
 internal           = false
 load_balancer_type = "application"
#  security_groups    = [aws_security_group.security_group.id]
 security_groups    = [module.security_groups.public_security_group_id]
 subnets            = [module.networking.public_subnet_ids]

 tags = {
   Name = "ecs|alb"
   Environment = "dev"
   owner      = "mx-devops"
 }
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
 name        = "ecs-target-group"
 port        = 80
 protocol    = "HTTP"
 target_type = "ip"
#  vpc_id      = aws_vpc.main.id
 vpc_id      = module.networking.vpc_id

 health_check {
   path = "/"
 }
}