data "archive_file" "cloudfront_realtime_transform" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_cloudwatch_log_group" "cloudfront_realtime_transform" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 30
  tags              = local.common_tags
}

resource "aws_lambda_function" "cloudfront_realtime_transform" {
  function_name = local.lambda_function_name
  description   = "Transforms CloudFront real-time log records from Firehose into newline-delimited JSON."
  role          = aws_iam_role.cloudfront_realtime_log_transform.arn

  filename         = data.archive_file.cloudfront_realtime_transform.output_path
  source_code_hash = data.archive_file.cloudfront_realtime_transform.output_base64sha256

  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  architectures = ["x86_64"]

  memory_size = 512
  timeout     = 300
  publish     = false

  ephemeral_storage {
    size = 512
  }

  tags = merge(
    local.common_tags,
    {
      Name    = local.lambda_function_name
      Purpose = "CloudFront real-time log transformation"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.cloudfront_realtime_transform
  ]
}
