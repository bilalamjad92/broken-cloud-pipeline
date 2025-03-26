variable "name" {
  type        = string
  description = "Name prefix for monitoring resources"
}

variable "email" {
  type        = string
  description = "Email address for SNS notifications"
}

variable "alb_arn_suffix" {
  type        = string
  description = "ARN suffix of the ALB for monitoring"
}