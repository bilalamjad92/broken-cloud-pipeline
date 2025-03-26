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
# variable "name" { type = string }
# variable "vpc_id" { type = string }
# variable "public_subnets" { type = list(string) }
# variable "allowed_cidr" { type = list(string) }
# variable "tags" { type = object({}) }
# variable "log_bucket_id" {
#   description = "ID of the S3 bucket for ALB access logs"
#   type        = string
# }