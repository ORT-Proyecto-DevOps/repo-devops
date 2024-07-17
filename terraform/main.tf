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

// es necesario estar en uno de los workspaces que estan en la variable "environments"
module "ecs" {
  for_each           = local.current_env
  source             = "./modules/ecs/"
  prefix             = local.prefix
  environment        = each.value.env
  service_names      = local.service_names
  task_names         = local.task_names
  api_paths          = local.api_paths
}

locals {
  is_s3_buckets_workspace       = terraform.workspace == "s3_buckets_workspace"
  is_ecr_workspace              = terraform.workspace == "ecr_workspace"

  prefix        = "aws-ecs"
  service_names = ["shipping-service", "payments-service", "products-service", "orders-service"]
  task_names    = ["shipping-task", "payments-task", "products-task", "orders-task"]
  api_paths = ["shipping", "payments", "products", "orders"]

  environments = {
    dev  = { workspace = "ecs_dev_workspace", env = "dev" }
    stg  = { workspace = "ecs_stg_workspace", env = "stg" }
    prod = { workspace = "ecs_prod_workspace", env = "prod" }
    }

   # Determinar qué ambiente está activo basado en el workspace actual
    current_env = {
    for key, value in local.environments :
    key => value
    if terraform.workspace == value.workspace
  }
}