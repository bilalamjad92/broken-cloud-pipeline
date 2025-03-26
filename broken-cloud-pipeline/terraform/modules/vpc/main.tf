module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name}-vpc"
  cidr = var.cidr

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = [cidrsubnet(var.cidr, 8, 1), cidrsubnet(var.cidr, 8, 2)] # e.g., 10.40.1.0/24, 10.40.2.0/24
  public_subnets  = [cidrsubnet(var.cidr, 8, 3), cidrsubnet(var.cidr, 8, 4)] # e.g., 10.40.3.0/24, 10.40.4.0/24

  enable_nat_gateway = true
  single_nat_gateway = true # Cost minimization
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.tags
}