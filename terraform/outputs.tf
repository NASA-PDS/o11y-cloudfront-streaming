output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.cloudfront_realtime_log_transform.arn
}

output "cloudfront_realtime_log_role_arn" {
  description = "ARN of the CloudFront real-time logging role."
  value       = aws_iam_role.cloudfront_realtime_log_kinesis.arn
}

output "firehose_role_arn" {
  description = "ARN of the Firehose execution role."
  value       = aws_iam_role.cloudfront_realtime_firehose.arn
}


output "s3_backup_bucket_arn" {
  description = "ARN of the existing PDS logs bucket used for Firehose backup records."
  value       = var.pds_logs_bucket_arn
}

output "opensearch_domain_name" {
  description = "Derived OpenSearch domain name."
  value       = local.opensearch_domain_name
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis Data Stream receiving CloudFront real-time logs."
  value       = aws_kinesis_stream.cloudfront_realtime.name
}

output "kinesis_stream_arn" {
  description = "ARN of the Kinesis Data Stream receiving CloudFront real-time logs."
  value       = aws_kinesis_stream.cloudfront_realtime.arn
}

output "lambda_function_name" {
  description = "Name of the CloudFront real-time log transformation Lambda function."
  value       = aws_lambda_function.cloudfront_realtime_transform.function_name
}

output "lambda_function_arn" {
  description = "ARN of the CloudFront real-time log transformation Lambda function."
  value       = aws_lambda_function.cloudfront_realtime_transform.arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the CloudFront real-time log transformation Lambda function."
  value       = aws_lambda_function.cloudfront_realtime_transform.invoke_arn
}

output "lambda_log_group_name" {
  description = "CloudWatch Logs log group for the transformation Lambda function."
  value       = aws_cloudwatch_log_group.cloudfront_realtime_transform.name
}

output "opensearch_domain_arn" {
  description = "ARN of the existing OpenSearch domain used by Firehose."
  value       = data.aws_opensearch_domain.observability.arn
}

output "opensearch_domain_endpoint" {
  description = "Endpoint of the existing OpenSearch domain used by Firehose."
  value       = data.aws_opensearch_domain.observability.endpoint
}

output "firehose_security_group_id" {
  description = "ID of the security group created for the Firehose delivery stream."
  value       = aws_security_group.firehose.id
}

output "private_subnet_ids" {
  description = "Existing private subnet IDs reserved for the Firehose VPC configuration."
  value       = var.private_subnet_ids
}

output "opensearch_index_name" {
  description = "Base OpenSearch index name reserved for the Firehose delivery stream."
  value       = local.opensearch_index_name
}

output "opensearch_index_rotation" {
  description = "OpenSearch index rotation period reserved for the Firehose delivery stream."
  value       = local.opensearch_index_rotation
}

output "cloudfront_realtime_log_config_name" {
  description = "Name of the CloudFront real-time log configuration."
  value       = aws_cloudfront_realtime_log_config.cloudfront_realtime.name
}

output "cloudfront_realtime_log_config_arn" {
  description = "ARN to associate with the existing CloudFront cache behaviors."
  value       = aws_cloudfront_realtime_log_config.cloudfront_realtime.arn
}

output "firehose_delivery_stream_name" {
  description = "Name of the Firehose delivery stream sending transformed CloudFront logs to OpenSearch."
  value       = aws_kinesis_firehose_delivery_stream.cloudfront_realtime.name
}

output "firehose_delivery_stream_arn" {
  description = "ARN of the Firehose delivery stream sending transformed CloudFront logs to OpenSearch."
  value       = aws_kinesis_firehose_delivery_stream.cloudfront_realtime.arn
}

output "kinesis_stream_arn_ssm_parameter_name" {
  description = "SSM parameter name containing the Kinesis Data Stream ARN."
  value       = aws_ssm_parameter.kinesis_stream_arn.name
}

output "cloudfront_role_arn_ssm_parameter_name" {
  description = "SSM parameter name containing the CloudFront real-time logging IAM role ARN."
  value       = aws_ssm_parameter.cloudfront_role_arn.name
}
