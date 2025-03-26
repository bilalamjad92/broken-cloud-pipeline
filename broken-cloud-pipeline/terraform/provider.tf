terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Compatible with modern practices
    }
  }
}

provider "aws" {
  region = "eu-central-1" # Frankfurt region per your requirement
  default_tags {
    tags = var.tags
  }
}

variable "tags" {
  type = object({
    environment = optional(string, "develop")
    product     = optional(string, "cloud")
    service     = optional(string, "pipeline")
  })
  default = {}
}