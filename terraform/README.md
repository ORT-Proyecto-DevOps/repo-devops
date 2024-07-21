# Comandos a tener en cuenta

- Es necesario tener creados los siguientes workspaces antes de llamar a los modulos:
```
terraform workspace new ecr_workspace
terraform workspace new s3_buckets_workspace
terraform workspace new ecs_dev_workspace
terraform workspace new ecs_prod_workspace
terraform workspace new ecs_stg_workspace

```

- Comandos a llamar en orden: (te tienes que encontrar en ./terraform para poder llamar a los comandos)
```
terraform init
terraform plan
terraform apply -auto-approve
```
Siempre al iniciar una sesion nueva de AWS Academy actualizar las crendenciales en ~/.aws/credentials

Si queremos eliminar los recursos usados en un Workspace hacemos:
```
terraform init
terraform destroy
```
Siempre al iniciar una sesion nueva de AWS Academy actualizar las crendenciales en ~/.aws/credentials