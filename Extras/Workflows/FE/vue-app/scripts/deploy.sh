#!/bin/bash

# Cambiar al directorio de salida de la construcción
cd dist

# Sincronizar favicons con caché fuerte
aws s3 sync ./common/favicons s3://$S3_ORIGIN_BUCKET/common/favicons --exclude "site.webmanifest" --metadata-directive 'REPLACE' --cache-control max-age=31536000,public,must-revalidate --delete

# Sincronizar assets con caché fuerte
aws s3 sync ./common/assets s3://$S3_ORIGIN_BUCKET/common/assets --metadata-directive 'REPLACE' --cache-control max-age=31536000,public,must-revalidate --delete

# Sincronizar bundles de Next.js con caché fuerte
aws s3 sync ./_next s3://$S3_ORIGIN_BUCKET/_next --exclude "data/*" --metadata-directive 'REPLACE' --cache-control max-age=31536000,public,immutable --delete

# Sincronizar datos de Next.js con caché temporal
aws s3 sync ./_next/data s3://$S3_ORIGIN_BUCKET/_next/data --metadata-directive 'REPLACE' --cache-control max-age=3600,must-revalidate --delete

# Sincronizar HTML y otros archivos con no caché
aws s3 sync ./ s3://$S3_ORIGIN_BUCKET --exclude "common/favicons/*" --exclude "_next/*" --exclude "common/assets/*" --include "common/favicons/site.webmanifest" --metadata-directive 'REPLACE' --cache-control no-cache,no-store,must-revalidate --delete
