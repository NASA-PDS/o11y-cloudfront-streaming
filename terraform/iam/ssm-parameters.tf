resource "aws_ssm_parameter" "cloudfront_role_arn" {
  name        = local.cloudfront_role_arn_ssm_parameter_name
  description = "ARN of the IAM role CloudFront uses to write real-time logs to Kinesis."
  type        = "String"
  value       = aws_iam_role.cloudfront_realtime_log_kinesis.arn

  tags = local.common_tags
}

resource "aws_ssm_parameter" "firehose_role_arn" {
  name        = local.firehose_role_arn_ssm_parameter_name
  description = "ARN of the IAM role Firehose uses to write logs to OpenSearch."
  type        = "String"
  value       = aws_iam_role.cloudfront_realtime_firehose.arn

  tags = local.common_tags
}

resource "aws_ssm_parameter" "lambda_execution_role_arn" {
  name        = local.lambda_execution_role_arn_ssm_parameter_name
  description = "ARN of the Lambda execution role for the CloudFront real-time log transform function."
  type        = "String"
  value       = aws_iam_role.cloudfront_realtime_log_transform.arn

  tags = local.common_tags
}
