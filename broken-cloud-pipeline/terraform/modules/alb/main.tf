resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb.id]
  tags               = var.tags
  access_logs {
    bucket  = var.log_bucket_id
    prefix  = "${var.name}-alb"
    enabled = true
  }
  depends_on = [var.log_bucket_policy_id] # Ensure policy is applied first.manadatory to create
}
resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-sg-"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr
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
    path                = var.name == "jenkins" ? "/login" : "/health"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }
  tags = merge(var.tags, { Name = "${var.name}-tg" })
  lifecycle {
    create_before_destroy = true
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
  depends_on = [aws_lb_target_group.this] # Ensure TG exists before listener
  lifecycle {
    replace_triggered_by = [aws_lb_target_group.this.id] # Force listener update when TG changes
  }
}
