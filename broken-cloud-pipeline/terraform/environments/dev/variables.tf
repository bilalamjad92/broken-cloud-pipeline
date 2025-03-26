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
