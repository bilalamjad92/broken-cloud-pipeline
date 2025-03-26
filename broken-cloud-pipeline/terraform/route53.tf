resource "aws_route53_health_check" "app" {
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3
  tags              = { Component = "Route53" }
}

resource "aws_route53_health_check" "jenkins" {
  port              = 80
  type              = "HTTP"
  resource_path     = "/login"
  request_interval  = 30
  failure_threshold = 3
  tags              = { Component = "Route53" }
}
#commented
