variable "tags" {
  type = object({
    environment = optional(string, "develop")
    product     = optional(string, "cloud")
    service     = optional(string, "pipeline")
  })
  default = {
    environment = "develop"
    product     = "cloud"
    service     = "pipeline"
  }
  description = "Default tags applied to all resources"
}
variable "ecr_registry" { default = "216989105561.dkr.ecr.eu-central-1.amazonaws.com" }
variable "ecr_repo" { default = "hello-world" }
variable "image_tag" { default = "latest" }
