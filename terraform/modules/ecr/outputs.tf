# Salidas para mostrar el nombre del repositorio y la URL
output "repository_url" {
  value = aws_ecr_repository.ecr-services.repository_url
}

output "repository_name" {
  value = aws_ecr_repository.ecr-services.name
}