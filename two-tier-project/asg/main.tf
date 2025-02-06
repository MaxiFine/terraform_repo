resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 2
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = var.public_subnets
}
