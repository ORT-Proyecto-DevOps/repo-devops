output "bucket_names" {
  description = "Nombres de S3 Buckets"
  value       = module.s3_buckets.bucket_names
}

output "repository_name" {
  description = "Nombre de ECR"
  value       = module.ecr.repository_name
}
