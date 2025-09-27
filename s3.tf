resource "aws_s3_bucket" "audio_bucket" {
  bucket = var.audio_bucket_name
  acl    = "private"
  lifecycle_rule {
    id      = "expire-old"
    enabled = true
    expiration { days = var.audio_retention_days }
  }
  force_destroy = false
}
