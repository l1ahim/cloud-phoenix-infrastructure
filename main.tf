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

  iam_tags = {
    Maintainers = "Claranet DevOps Team"
    Environment = "Production"
    Application = "Phoenix"
    Name        = "Phoenix Prod Policies"
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

#############################################
#               VPC SECURITY GROUP
#############################################
module "sg_vpc_endpoint" {
  source  = "cloudposse/security-group/aws"
  version = "1.0.1"

  attributes = ["cl-ph-vpc-endpoint-sg"]

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

module "sg_alb" {
  source  = "cloudposse/security-group/aws"
  version = "1.0.1"

  attributes = ["cl-ph-alb-sg"]

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
    },
    {
      key         = "https"
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = null
      description = "Allow HTTPS from everywhere"
    }
  ]
  vpc_id = module.vpc.vpc_id
}

#############################################
#               VPC ENDPOINTS
#############################################

module "vpc_endpoints" {
  source  = "cloudposse/vpc/aws//modules/vpc-endpoints"
  version = "2.0.0"

  vpc_id = module.vpc.vpc_id

  gateway_vpc_endpoints = {
    "s3" = {
      name = "s3"
      route_table_ids = values(module.private_subnets.az_route_table_ids)
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = [
              "s3:*",
            ]
            Effect    = "Allow"
            Principal = "*"
            Resource  = "*"
          },
        ]
      })
    }
  }

  interface_vpc_endpoints = {
    "ecs" = {
      name                = "ecs"
      security_group_ids  = [module.sg_vpc_endpoint.id]
      subnet_ids          = values(module.private_subnets.az_subnet_ids)
      policy              = null
      private_dns_enabled = true
    },
     "ssm" = {
      name                = "ssm"
      security_group_ids  = [module.sg_vpc_endpoint.id]
      subnet_ids          = values(module.private_subnets.az_subnet_ids)
      policy              = null
      private_dns_enabled = true
    },
    "ecs-agent" = {
      name                = "ecs-agent"
      security_group_ids  = [module.sg_vpc_endpoint.id]
      subnet_ids          = values(module.private_subnets.az_subnet_ids)
      policy              = null
      private_dns_enabled = false
    },
    "ecr" = {
      name                = "ecr.api"
      security_group_ids  = [module.sg_vpc_endpoint.id]
      subnet_ids          = values(module.private_subnets.az_subnet_ids)
      policy              = null
      private_dns_enabled = true
    },
    "dkr" = {
      name                = "ecr.dkr"
      security_group_ids  = [module.sg_vpc_endpoint.id]
      subnet_ids          = values(module.private_subnets.az_subnet_ids)
      policy              = null
      private_dns_enabled = true
    },
    "codepipeline" = {
      name                = "codepipeline"
      security_group_ids  = [module.sg_vpc_endpoint.id]
      subnet_ids          = values(module.private_subnets.az_subnet_ids)
      policy              = null
      private_dns_enabled = true
    }
  }
}

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
#               Parameter Store
#############################################

module "store_write" {
  source  = "cloudposse/ssm-parameter-store/aws"
  version = "0.10.0"

  parameter_write = [
    {
      name        = "/cl/prod/app/github/oauth"
      value       = var.github_oauth_token
      type        = "String"
      overwrite   = "true"
      description = "GitHub OAuth to clone the repo"
    }
  ]

  tags = local.ssm_tags
}


#############################################
#               DATABASE
#############################################

module "documentdb_cluster" {
  source = "cloudposse/documentdb-cluster/aws"
  version = "0.15.0"

  namespace               = "eg"
  stage                   = "testing"
  name                    = "docdb"
  cluster_size            = 3
  master_username         = "admin1"
  master_password         = "Test123456789"
  instance_class          = "db.t3.medium"
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = values(module.private_subnets.az_subnet_ids)
  allowed_security_groups = [module.vpc.vpc_default_security_group_id]
}

#############################################
#               ALB
#############################################


#############################################
#               ECS
#############################################

resource "aws_ecs_cluster" "phoenix" {
  name = "phoenix-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "cl_ph_capacity" {
  cluster_name = aws_ecs_cluster.phoenix.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

#############################################
#               CODEPIPELINE - CI/CD
#############################################

module "cicd_pipeline" {
  source = "./modules/pipeline"

  github_repo          = var.github_repo
  vpc_id               = module.vpc.vpc_id
  private_subnets      = values(module.private_subnets.az_subnet_ids)
  security_group_ids   = [module.sg_alb.id]
  github_oauth_token   = var.github_oauth_token
  github_owner         = var.github_owner
  github_repo_name     = var.github_repo_name
  db_connection_string = var.db_connection_string
  tags                 = local.iam_tags
  repo_source_version  = var.repo_branch
}
