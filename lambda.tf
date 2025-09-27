data "archive_file" "cleanup_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/cleanup"
  output_path = "${path.module}/../lambda/cleanup.zip"
}

resource "aws_iam_role" "cleanup_lambda_role" {
  name = "tts-cleanup-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cleanup_policy" {
  role = aws_iam_role.cleanup_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Action = ["s3:ListBucket","s3:DeleteObject","s3:GetObject"], Effect = "Allow", Resource = [aws_s3_bucket.audio_bucket.arn, "${aws_s3_bucket.audio_bucket.arn}/*"] },
      { Action = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"], Effect = "Allow", Resource = "*" }
    ]
  })
}

resource "aws_lambda_function" "cleanup" {
  filename         = "${path.module}/../lambda/cleanup.zip"
  function_name    = "tts_cleanup"
  role             = aws_iam_role.cleanup_lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("${path.module}/../lambda/cleanup.zip")
  environment {
    variables = {
      AUDIO_S3_BUCKET = aws_s3_bucket.audio_bucket.bucket
      AUDIO_S3_PREFIX = var.audio_prefix
      RETENTION_DAYS  = var.audio_retention_days
    }
  }
}

resource "aws_cloudwatch_event_rule" "daily" {
  name                = "tts-cleanup-daily"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "run_lambda" {
  rule = aws_cloudwatch_event_rule.daily.name
  arn  = aws_lambda_function.cleanup.arn
}

resource "aws_lambda_permission" "allow_event" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily.arn
}
