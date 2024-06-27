// Comandos a llamar en orden:
// terraform init
// terraform plan
// terraform apply
// yes
// Siempre al iniciar una sesion nueva de AWS Academy actualizar las crendenciales en ~/.aws/credentials

module "s3_buckets" {
  source = "F:/VSC/terraform/modules/s3_buckets"
}
