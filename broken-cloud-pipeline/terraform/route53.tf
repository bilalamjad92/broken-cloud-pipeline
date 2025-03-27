resource "aws_route53_health_check" "app" {
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  request_interval  = 30
  failure_threshold = 3
  tags              = { Component = "Route53" }
}

resource "aws_route53_health_check" "jenkins" {
  port              = 443
  type              = "HTTPS"
  resource_path     = "/login"
  request_interval  = 30
  failure_threshold = 3
  tags              = { Component = "Route53" }
}
# Route 53 Record for app
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.mptchallenge.zone_id
  name    = "app.mptchallenge.local"
  type    = "A"

  alias {
    name                   = module.app_alb.alb_dns_name
    zone_id                = module.app_alb.alb_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.app.id
}

# Route 53 Record for jenkins
resource "aws_route53_record" "jenkins" {
  zone_id = aws_route53_zone.mptchallenge.zone_id
  name    = "jenkins.mptchallenge.local"
  type    = "A"

  alias {
    name                   = module.jenkins_alb.alb_dns_name
    zone_id                = module.jenkins_alb.alb_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.jenkins.id
}

