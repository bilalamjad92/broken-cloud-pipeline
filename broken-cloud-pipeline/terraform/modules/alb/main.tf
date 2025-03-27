resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb.id]
  tags               = var.tags
  access_logs {
    bucket  = var.log_bucket_id
    prefix  = "alb"
    enabled = true
  }
  depends_on = [var.log_bucket_policy_id] # Ensure policy is applied first.manadatory to create
}
resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-sg-"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]#var.name == "jenkins" ? ["0.0.0.0/0"] : var.allowed_cidr
  }
  ingress {
    from_port   = 443
    to_port     = 443
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
  tags = var.tags
}
resource "aws_lb_target_group" "this" {
  name_prefix = "tg-"
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = 8080 # Changed to 8080 for both
  target_type = "instance"
  health_check {
    path                = var.name == "jenkins" ? "/login" : "/"
    port                = var.name == "jenkins" ? "8080" : "80"
    # path                = var.name == "jenkins" ? "/login" : "/health"
    # port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 90
    interval            = 150
    matcher             = "200"
  }
  tags = merge(var.tags, { Name = "${var.name}-tg" })
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
  depends_on = [aws_lb_target_group.this] # Ensure TG exists before listener
  lifecycle {
    replace_triggered_by = [aws_lb_target_group.this.id] # Force listener update when TG changes
  }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
  depends_on = [aws_lb_target_group.this]
}
resource "aws_wafv2_web_acl" "jenkins_geo_restriction" {
  count = var.name == "jenkins" ? 1 : 0 
  name        = "jenkins-geo-restriction"
  description = "Restrict Jenkins ALB to Portugal"
  scope       = "REGIONAL" # Use REGIONAL for ALBs
  default_action {
    allow {} # Allow traffic by default unless blocked by rules
  }
  rule {
    name     = "allow-portugal-only"
    priority = 1
    action {
      block {} # Block requests not matching the condition
    }
    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["PT"] # Allow only Portugal
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "JenkinsGeoRestriction"
      sampled_requests_enabled   = true
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "JenkinsWebACL"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}
resource "aws_wafv2_web_acl_association" "jenkins_waf" {
  count = var.name == "jenkins" ? 1 : 0

  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.jenkins_geo_restriction[0].arn
}
