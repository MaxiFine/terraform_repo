resource "aws_route53_record" "primary" {
  zone_id = var.zone_id
  name    = "mxwebsite.com"
  type    = "A"
  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
