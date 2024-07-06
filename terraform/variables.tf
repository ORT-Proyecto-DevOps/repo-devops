variable "aws_region" {
  type        = string
  default     = "us-east-1"
}

variable "enable_s3_buckets" {
  type    = bool
  default = false
}

variable "enable_ecr" {
  type    = bool
  default = false
}