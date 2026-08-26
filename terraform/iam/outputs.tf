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

output "cloudfront_realtime_log_role_arn" {
  description = "ARN of the CloudFront real-time logging role."
  value       = aws_iam_role.cloudfront_realtime_log_kinesis.arn
}

output "firehose_role_arn" {
  description = "ARN of the Firehose execution role."
  value       = aws_iam_role.cloudfront_realtime_firehose.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.cloudfront_realtime_log_transform.arn
}

output "cloudfront_role_arn_ssm_parameter_name" {
  description = "SSM parameter name containing the CloudFront real-time logging IAM role ARN."
  value       = aws_ssm_parameter.cloudfront_role_arn.name
}

output "firehose_role_arn_ssm_parameter_name" {
  description = "SSM parameter name containing the Firehose execution IAM role ARN."
  value       = aws_ssm_parameter.firehose_role_arn.name
}

output "lambda_execution_role_arn_ssm_parameter_name" {
  description = "SSM parameter name containing the Lambda execution IAM role ARN."
  value       = aws_ssm_parameter.lambda_execution_role_arn.name
}
