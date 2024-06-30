#!/bin/bash

# Lista de buckets a vaciar
buckets=("dev-vue-app2" "stg-vue-app2" "prd-vue-app2")

for bucket in "${buckets[@]}"; do
  echo "Vaciando el bucket: $bucket"
  aws s3 rm s3://$bucket --recursive
done
