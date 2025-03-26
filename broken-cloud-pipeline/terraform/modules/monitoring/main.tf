resource "aws_sns_topic" "this" {
  name = "${var.name}-notifications"
  tags = { Component = "SNS" }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.email
}

resource "aws_cloudwatch_metric_alarm" "cost_alarm" {
  alarm_name          = "${var.name}-cost-alarm"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  statistic           = "Maximum"
  period              = 86400
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.this.arn]
  tags                = { Purpose = "Cost Monitoring" }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name}-alb-5xx-alarm"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.this.arn]
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
  tags = { Purpose = "ALB Health" }
}