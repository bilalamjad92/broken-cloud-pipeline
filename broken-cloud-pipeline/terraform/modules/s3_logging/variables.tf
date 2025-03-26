variable "name" {
  type        = string
  description = "Prefix for the S3 bucket name"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for S3 resources"
}