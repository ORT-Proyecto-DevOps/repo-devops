# Crear un repositorio de ECR
resource "aws_ecr_repository" "ecr-services" {
  name                 = "aws-ecr-be-services"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}