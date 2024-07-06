
output "bucket_names" {
  description = "Nombres de S3 Buckets"
  value       = local.is_s3_buckets_workspace ? module.s3_buckets[0].bucket_names : null
}

output "repository_name" {
  description = "Nombre de ECR"
 value       = local.is_ecr_workspace ? module.ecr[0].repository_name : null
}
