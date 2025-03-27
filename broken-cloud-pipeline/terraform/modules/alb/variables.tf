variable "name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "allowed_cidr" {
  type = list(string)
}

variable "log_bucket_id" {
  type = string
}

variable "log_bucket_policy_id" {
  description = "ID of the S3 bucket policy"
  type        = string
}
variable "certificate_arn" {
  default     = "arn:aws:acm:eu-central-1:216989105561:certificate/15556a87-717c-44e7-8d68-aaf146333c17"
  description = "ARN of the ACM certificate"
}
