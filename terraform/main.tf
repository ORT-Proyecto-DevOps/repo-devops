// Comandos a llamar en orden: (te tienes que encontrar dentro de esta carpeta para poder llamar a los comandos)
// terraform init
// terraform plan
// terraform apply
// yes
// Siempre al iniciar una sesion nueva de AWS Academy actualizar las crendenciales en ~/.aws/credentials

module "s3_buckets" {
  source = "./modules/s3_buckets"
}
