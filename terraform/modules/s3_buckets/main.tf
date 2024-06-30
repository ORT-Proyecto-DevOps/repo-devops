resource "aws_s3_bucket" "frontend_bucket" {
  count  = 3
  bucket = ["dev-vue-app1", "stg-vue-app1", "prd-vue-app1"][count.index]

  tags = {
    Name = ["dev-vue-app1", "stg-vue-app1", "prd-vue-app1"][count.index]
  }

  lifecycle_rule {
    enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "frontend_bucket" {
  count  = 3
  bucket = aws_s3_bucket.frontend_bucket[count.index].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_bucket" {
  count  = 3
  bucket = aws_s3_bucket.frontend_bucket[count.index].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "frontend_bucket" {
  count = 3
  depends_on = [
    aws_s3_bucket_ownership_controls.frontend_bucket,
    aws_s3_bucket_public_access_block.frontend_bucket,
  ]

  bucket = aws_s3_bucket.frontend_bucket[count.index].id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "frontend_bucket_website" {
  count = 3
  bucket = aws_s3_bucket.frontend_bucket[count.index].bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  count = 3
  bucket = aws_s3_bucket.frontend_bucket[count.index].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "PublicReadGetObject",
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = format("arn:aws:s3:::%s/*", aws_s3_bucket.frontend_bucket[count.index].id)
      }
    ]
  })
}