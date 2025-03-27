module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name}-vpc"
  cidr = var.cidr

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = [cidrsubnet(var.cidr, 8, 1), cidrsubnet(var.cidr, 8, 2)] 
  public_subnets  = [cidrsubnet(var.cidr, 8, 3), cidrsubnet(var.cidr, 8, 4)] 

  enable_nat_gateway   = true
  single_nat_gateway   = true # Cost minimization
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.tags
}

resource "aws_network_acl" "public" {
  vpc_id     = module.vpc.vpc_id     
  subnet_ids = module.vpc.public_subnets

  # Allow HTTPS inbound
  ingress {
    rule_no    = 100
    action     = "allow"
    from_port  = 443
    to_port    = 443
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
  }

  # Allow HTTP inbound
  ingress {
    rule_no    = 150
    action     = "allow"
    from_port  = 80
    to_port    = 80
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
  }

  # Allow ephemeral ports for return traffic
  ingress {
    rule_no    = 200
    action     = "allow"
    from_port  = 1024
    to_port    = 65535
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
  }

  # Deny all other inbound
  ingress {
    rule_no    = 300
    action     = "deny"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  # Allow all outbound
  egress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  tags = merge(var.tags, { Name = "${var.name}-public-nacl" })
}
