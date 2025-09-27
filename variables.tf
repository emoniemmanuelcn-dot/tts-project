variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "audio_bucket_name" {
  type = string
}

variable "audio_retention_days" {
  type = number
  default = 30
}

variable "audio_prefix" {
  type = string
  default = "tts/"
}
