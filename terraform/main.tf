// es necesario estar en el workspace "ecr_workspace" <- terraform workspace select s3_buckets_workspace
module "s3_buckets" {
  source = "./modules/s3_buckets"
  count  = local.is_s3_buckets_workspace ? 1 : 0
}

// es necesario estar en el workspace "ecr_workspace" <- terraform workspace select ecr_workspace
module "ecr" {
  source = "./modules/ecr"
  count  = local.is_ecr_workspace ? 1 : 0
}

// es necesario estar en el workspace "ecs_workspace" <- terraform workspace select ecs_workspace
module "ecs" {
  source = "./modules/ecs"
  count  = local.is_ecs_workspace ? 1 : 0
}

locals {
  is_s3_buckets_workspace = terraform.workspace == "s3_buckets_workspace"
  is_ecr_workspace        = terraform.workspace == "ecr_workspace"
  is_ecs_workspace        = terraform.workspace == "ecs_workspace"
}