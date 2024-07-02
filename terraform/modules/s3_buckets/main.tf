locals {
  buckets = {
    dev = "dev-vue-app1",
    stg = "stg-vue-app1",
    prd = "prd-vue-app1"
  }
}

resource "aws_s3_bucket" "frontend_bucket" {
  for_each = local.buckets
  bucket   = each.value

  tags = {
    Name = each.value
  }

  lifecycle_rule {
    enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "frontend_bucket" {
  for_each = local.buckets
  bucket   = aws_s3_bucket.frontend_bucket[each.key].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_bucket" {
  for_each = local.buckets
  bucket   = aws_s3_bucket.frontend_bucket[each.key].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "frontend_bucket" {
  for_each = local.buckets
  depends_on = [
    aws_s3_bucket_ownership_controls.frontend_bucket,
    aws_s3_bucket_public_access_block.frontend_bucket,
  ]

  bucket = aws_s3_bucket.frontend_bucket[each.key].id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "frontend_bucket_website" {
  for_each = local.buckets
  bucket   = aws_s3_bucket.frontend_bucket[each.key].bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  for_each = local.buckets
  bucket   = aws_s3_bucket.frontend_bucket[each.key].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "PublicReadGetObject",
        Effect: "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = format("arn:aws:s3:::%s/*", aws_s3_bucket.frontend_bucket[each.key].id)
      }
    ]
  })
}
