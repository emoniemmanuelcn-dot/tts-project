resource "aws_cloudfront_origin_access_control" "oac" {
  name             = "tts-oac"
  description      = "OAC for CloudFront -> S3"
  signing_protocol = "sigv4"
  signing_behavior = "always"
  origin_type      = "s3"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  origin {
    domain_name = aws_s3_bucket.audio_bucket.bucket_regional_domain_name
    origin_id   = "s3-audio-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET","HEAD"]
    cached_methods   = ["GET","HEAD"]
    target_origin_id = "s3-audio-origin"
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
