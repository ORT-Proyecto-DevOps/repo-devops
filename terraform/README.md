# Comandos a tener en cuenta

- Es necesario tener creados los siguientes workspaces antes de llamar a los modulos:
```
terraform workspace new ecr_workspace
terraform workspace new s3_buckets_workspace
```

- Comandos a llamar en orden: (te tienes que encontrar en ./terraform para poder llamar a los comandos)
```
terraform init
terraform plan
terraform apply
yes
```
Siempre al iniciar una sesion nueva de AWS Academy actualizar las crendenciales en ~/.aws/credentials

