resource "aws_ssm_parameter" "firehose_security_group_id" {
  name        = local.firehose_security_group_id_ssm_parameter_name
  description = "ID of the Firehose security group — read by o11y-platform to create the Firehose→OpenSearch ingress rule."
  type        = "String"
  value       = aws_security_group.firehose.id

  tags = local.common_tags
}


output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role (published by the ./iam root module, read here via SSM)."
  value       = data.aws_ssm_parameter.lambda_execution_role_arn.value
  sensitive   = true
}

output "cloudfront_realtime_log_role_arn" {
  description = "ARN of the CloudFront real-time logging role (published by the ./iam root module, read here via SSM)."
  value       = data.aws_ssm_parameter.cloudfront_role_arn.value
  sensitive   = true
}

output "firehose_role_arn" {
  description = "ARN of the Firehose execution role (published by the ./iam root module, read here via SSM)."
  value       = data.aws_ssm_parameter.firehose_role_arn.value
  sensitive   = true
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
  value       = data.aws_opensearch_domain.o11y.arn
}

output "opensearch_domain_endpoint" {
  description = "Endpoint of the existing OpenSearch domain used by Firehose."
  value       = data.aws_opensearch_domain.o11y.endpoint
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

output "firehose_delivery_stream_name" {
  description = "Name of the Firehose delivery stream sending transformed CloudFront logs to OpenSearch."
  value       = aws_kinesis_firehose_delivery_stream.cloudfront_realtime.name
}

output "firehose_delivery_stream_arn" {
  description = "ARN of the Firehose delivery stream sending transformed CloudFront logs to OpenSearch."
  value       = aws_kinesis_firehose_delivery_stream.cloudfront_realtime.arn
}

output "firehose_security_group_id_ssm_parameter_name" {
  description = "SSM parameter name containing the Firehose security group ID (read by o11y-platform to create the Firehose→OpenSearch ingress rule)."
  value       = local.firehose_security_group_id_ssm_parameter_name
}

output "kinesis_stream_arn_ssm_parameter_name" {
  description = "SSM parameter name containing the Kinesis Data Stream ARN (published by ./iam)."
  value       = local.kinesis_stream_arn_ssm_parameter_name
}

output "cloudfront_role_arn_ssm_parameter_name" {
  description = "SSM parameter name containing the CloudFront real-time logging IAM role ARN (published by ./iam)."
  value       = local.cloudfront_role_arn_ssm_parameter_name
}

output "firehose_role_arn_ssm_parameter_name" {
  description = "SSM parameter name containing the Firehose execution IAM role ARN (published by ./iam)."
  value       = local.firehose_role_arn_ssm_parameter_name
}

output "lambda_execution_role_arn_ssm_parameter_name" {
  description = "SSM parameter name containing the Lambda execution IAM role ARN (published by ./iam)."
  value       = local.lambda_execution_role_arn_ssm_parameter_name
}
