resource "aws_ssm_parameter" "kinesis_stream_arn" {
  name        = local.kinesis_stream_arn_ssm_parameter_name
  description = "ARN of the Kinesis Data Stream receiving CloudFront real-time logs."
  type        = "String"
  value       = aws_kinesis_stream.cloudfront_realtime.arn

  tags = local.common_tags
}

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