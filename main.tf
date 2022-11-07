provider "aws" {
  region = local.region
}

#############################################
#               LOCALS
#############################################

locals {
  region = var.region

  vpc_tags = {
    Maintainers = "Claranet DevOps Team"
    Environment = "Production"
    Application = "Phoenix"
    Name        = "Phoenix Production VPC"
  }

  ssm_tags = {
    Maintainers = "Claranet DevOps Team"
    Environment = "Production"
    Application = "Phoenix"
    Name        = "Phoenix Production SSM"
  }

  alb_tags = {
    Maintainers = "Claranet DevOps Team"
    Environment = "Production"
    Application = "Phoenix"
    Name        = "Phoenix Production ALB"
  }

  public_cidr_block  = cidrsubnet(var.vpc_cidr_block, 2, 0)
  private_cidr_block = cidrsubnet(var.vpc_cidr_block, 2, 1)

}

#############################################
#               VPC
#############################################

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "2.0.0"

  namespace = var.namespace
  stage     = var.stage
  name      = var.vpc_name

  ipv4_primary_cidr_block          = var.vpc_cidr_block
  assign_generated_ipv6_cidr_block = false

  tags = local.vpc_tags
}


module "public_subnets" {
  source  = "cloudposse/multi-az-subnets/aws"
  version = "0.15.0"

  namespace          = var.namespace
  stage              = var.stage
  name               = var.name
  availability_zones = var.availability_zones
  vpc_id             = module.vpc.vpc_id
  cidr_block         = local.public_cidr_block
  type               = var.subnet_type_public
  igw_id             = module.vpc.igw_id

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

##### VPC Endpoints & Security Group
module "sg_vpc_endpoint" {
  source = "cloudposse/security-group/aws"
  version = "1.0.1"

  attributes = ["vpc-endpoint-sg"]

  # Allow unlimited egress
  allow_all_egress = true

  rules = [
    {
      key         = "https"
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      self        = null
      description = "Allow HTTPS from private subnets"
    }
  ]
  vpc_id = module.vpc.vpc_id
}

module "sg_alb_ingress" {
  source = "cloudposse/security-group/aws"
  version = "1.0.1"

  attributes = ["cl-ph-alb-sg"]

  # Allow unlimited egress
  allow_all_egress = true

  rules = [
    {
      key         = "http"
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = null
      description = "Allow HTTP from everywhere"
    }
  ]
  vpc_id = module.vpc.vpc_id
}

#module "vpc_endpoints" {
#  source  = "cloudposse/vpc/aws//modules/vpc-endpoints"
#  version = "2.0.0"

#  vpc_id = module.vpc.vpc_id

#  interface_vpc_endpoints = {
#    "ecs" = {
#      name                = "ecs"
#      security_group_ids  = [module.sg_vpc_endpoint.id]
#      subnet_ids          = values(module.private_subnets.az_subnet_ids)
#      policy              = null
#      private_dns_enabled = true
#    },
#    "ecs-agent" = {
#      name                = "ecs-agent"
#      security_group_ids  = [module.sg_vpc_endpoint.id]
#      subnet_ids          = values(module.private_subnets.az_subnet_ids)
#      policy              = null
#      private_dns_enabled = false
#    },
#    "ecr" = {
#      name                = "ecr.api"
#      security_group_ids  = [module.sg_vpc_endpoint.id]
#      subnet_ids          = values(module.private_subnets.az_subnet_ids)
#      policy              = null
#      private_dns_enabled = true
#    },
#    "dkr" = {
#      name                = "ecr.dkr"
#      security_group_ids  = [module.sg_vpc_endpoint.id]
#      subnet_ids          = values(module.private_subnets.az_subnet_ids)
#      policy              = null
#      private_dns_enabled = true
#    },
#    "codepipeline" = {
#      name                = "codepipeline"
#      security_group_ids  = [module.sg_vpc_endpoint.id]
#      subnet_ids          = values(module.private_subnets.az_subnet_ids)
#      policy              = null
#      private_dns_enabled = true
#    }
#  }
#}

#############################################
#               CLOUDWATCH
#############################################
module "cloudwatch_logs" {
  source  = "cloudposse/cloudwatch-logs/aws"
  version = "0.6.6"

  namespace = var.namespace
  stage     = var.stage
  name      = var.name
}

module "flow_logs" {
  source  = "cloudposse/vpc-flow-logs-s3-bucket/aws"
  version = "0.18.0"

  flow_log_enabled = var.flow_log_enabled
  namespace        = var.namespace
  stage            = var.stage
  name             = "flowlogs"

  vpc_id = module.vpc.vpc_id

  /* This will empty the S3 bucket and delete it - be careful with it, logs may be needed for audit
      Use it ONLY when needed and you know what you are doing
    */
  force_destroy = true
}

#############################################
#               DATABASE
#############################################
#module "documentdb_cluster" {
#  source = "cloudposse/documentdb-cluster/aws"
#  version = "0.15.0"

#  namespace               = "eg"
#  stage                   = "testing"
#  name                    = "docdb"
#  cluster_size            = 3
#  master_username         = "admin1"
#  master_password         = "Test123456789"
#  instance_class          = "db.t3.medium"
#  vpc_id                  = module.vpc.vpc_id
#  subnet_ids              = values(module.private_subnets.az_subnet_ids)
#  allowed_security_groups = [module.vpc.vpc_default_security_group_id]
#}

#############################################
#               CODEPIPELINE - CI/CD
#############################################


## github token should be taken from parameter store
module "ecs_push_pipeline" {
  source  = "cloudposse/ecs-codepipeline/aws"
  version = "0.30.0"

  name                    = "phoenix"
  namespace               = "cl"
  stage                   = "production"
  github_oauth_token      = "/cl/prod/app/github/oauth"
  repo_owner              = "l1ahim"
  repo_name               = "cloud-phoenix-pipeline"
  branch                  = "main"
  service_name            = "phoenix"
  ecs_cluster_name        = "cl-phoenix-prod-cluster"
  privileged_mode         = true
  webhook_enabled         = false
  image_repo_name         = var.image_repo_name
  image_tag               = "latest"
  s3_bucket_force_destroy = true
  region                  = local.region
}


###### Parameter Store
module "store_write" {
  source  = "cloudposse/ssm-parameter-store/aws"
  version = "0.10.0"

  parameter_write = [
    {
      name        = "/cl/prod/app/github/oauth"
      value       = "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"
      type        = "String"
      overwrite   = "true"
      description = "GitHub OAuth to clone the repo"
    }
  ]

  tags = local.ssm_tags
}


#############################################
#               ALB
#############################################
module "alb" {
  source = "cloudposse/alb/aws"
  version     = "1.5.0"

  namespace                               = var.namespace
  stage                                   = var.stage
  name                                    = var.name

  vpc_id                                  = module.vpc.vpc_id
  security_group_ids                      = [module.sg_alb_ingress.id]
  subnet_ids                              = values(module.public_subnets.az_subnet_ids)
  internal                                = var.internal
  http_enabled                            = var.http_enabled
  access_logs_enabled                     = var.access_logs_enabled
  cross_zone_load_balancing_enabled       = var.cross_zone_load_balancing_enabled
  http2_enabled                           = var.http2_enabled
  idle_timeout                            = var.idle_timeout
  ip_address_type                         = var.ip_address_type
  deletion_protection_enabled             = var.deletion_protection_enabled
  deregistration_delay                    = var.deregistration_delay
  health_check_path                       = var.health_check_path
  health_check_timeout                    = var.health_check_timeout
  health_check_healthy_threshold          = var.health_check_healthy_threshold
  health_check_unhealthy_threshold        = var.health_check_unhealthy_threshold
  health_check_interval                   = var.health_check_interval
  health_check_matcher                    = var.health_check_matcher
  target_group_port                       = var.target_group_port
  target_group_target_type                = var.target_group_target_type

  tags = local.alb_tags
}

module "alb_ingress" {
  source = "cloudposse/alb-ingress/aws"
  version     = "0.25.1"

  namespace                           = var.namespace
  stage                               = var.stage
  name                                = "cl-ph-alb"

  vpc_id                              = module.vpc.vpc_id


  default_target_group_enabled        = false
  target_group_arn                    = module.alb.default_target_group_arn

  tags = local.alb_tags
}
