locals {
  vpc_tags = {
    Maintainers = "Claranet DevOps Team"
    Environment = "Production"
    Application = "Phoenix"
    Name        = "Phoenix Production VPC"
  }

  public_cidr_block  = cidrsubnet(var.cidr_block, 2, 0)
  private_cidr_block = cidrsubnet(var.cidr_block, 2, 1)
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "2.0.0"

  namespace = var.namespace
  stage     = var.stage
  name      = var.vpc_name

  ipv4_primary_cidr_block = var.vpc_cidr_block
  assign_generated_ipv6_cidr_block = false

  tags = local.vpc_tags
}


module "public_subnets" {
  source  = "cloudposse/multi-az-subnets/aws"
  version = "0.15.0"

  namespace           = var.namespace
  stage               = var.stage
  name                = var.name
  availability_zones  = var.availability_zones
  vpc_id              = module.vpc.vpc_id
  cidr_block          = local.public_cidr_block
  type                = var.subnet_type_public
  igw_id              = module.vpc.igw_id
  nat_gateway_enabled = false
}

module "private_subnets" {
  source  = "cloudposse/multi-az-subnets/aws"
  version = "0.15.0"

  namespace          = var.namespace
  stage              = var.stage
  name               = var.name
  availability_zones = var.availability_zones
  vpc_id             = module.vpc.vpc_id
  cidr_block         = local.private_cidr_block
  type               = var.subnet_type_private
}
