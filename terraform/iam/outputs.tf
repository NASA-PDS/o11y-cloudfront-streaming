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
