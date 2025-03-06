# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name    = "mxdrproject.click"
  comment = "Primary domain zone"
}

# Health Check for Primary Region (e.g., eu-west-1)
resource "aws_route53_health_check" "primary_health_check_https" {
  fqdn              = "primary.mxdrproject.click"  # Replace with your primary endpoint
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"  # Your health check endpoint
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "Primary-Region-Health-Check"
  }
}
resource "aws_route53_health_check" "primary_health_check_http" {
  fqdn              = "primary.mxdrproject.click"  # Replace with your primary endpoint
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"  # Your health check endpoint
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "Primary-Region-Health-Check"
  }
}

# Failover Record for PRIMARY (Active)
resource "aws_route53_record" "primary_failover" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "myapp.mxdrproject.click"  # Your domain/subdomain
  type    = "A"
  ttl     = 60

  set_identifier = "primary-region"

  # Alias to your PRIMARY resource (e.g., ALB in eu-west-1)
  alias {
    name                   = "dualstack.primary-alb-123456.eu-west-1.elb.amazonaws.com"  # Replace with your ALB DNS
    zone_id                = "${aws_route53_zone.main.zone_id}"  # Replace with ALB's hosted zone ID (eu-west-1 ALB)
    evaluate_target_health = true
  }

  # Failover Routing Policy
  failover_routing_policy {
    type = "PRIMARY"  # Active
  }

  # Link to Health Check
  # health_check_id = aws_route53_health_check.primary_health_check.id
  health_check_id = ["${aws_route53_health_check.primary_health_check_http.id}", 
                    "${aws_route53_health_check.primary_health_check_http.id}"
  ]
}

# Failover Record for SECONDARY (Passive)
resource "aws_route53_record" "secondary_failover" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "myapp.mxdrproject.click"
  type    = "A"
  # ttl     = 60

  set_identifier = "secondary-region"

  # Alias to your SECONDARY resource (e.g., ALB in eu-central-1)
  alias {
    # name                   = "dualstack.secondary-alb-789012.eu-central-1.elb.amazonaws.com"  # Replace with your ALB DNS
    name                   = "${var.external_alb_dns}"  # Replace with your ALB DNS
    zone_id                = "Z2DEF3456WXY7"  # Replace with ALB's hosted zone ID (eu-central-1 ALB)
    evaluate_target_health = true
  }

  # Failover Routing Policy
  failover_routing_policy {
    type = "SECONDARY"  # Passive
  }

  # No direct health check needed; Route 53 auto-fails over if PRIMARY is unhealthy.
}


####################
# CW TO detect failure
resource "aws_cloudwatch_event_rule" "failover_trigger" {
  name        = "failover-trigger"
  description = "Triggers Lambda on failure detection"

  event_pattern = <<EOF
{
  "source": ["aws.health"],
  "detail-type": ["AWS Health Event"],
  "detail": {
    "service": ["RDS", "EC2"]
  }
}
EOF
}
