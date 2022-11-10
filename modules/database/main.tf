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
