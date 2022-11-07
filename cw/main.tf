module "cloudwatch_logs" {
  source  = "cloudposse/cloudwatch-logs/aws"
  version = "0.6.6"

  namespace    = var.namespace
  stage        = var.stage
  name         = var.name
}
