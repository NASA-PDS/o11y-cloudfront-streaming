resource "aws_ssm_parameter" "kinesis_stream_arn" {
  name        = local.kinesis_stream_arn_ssm_parameter_name
  description = "ARN of the Kinesis Data Stream receiving CloudFront real-time logs."
  type        = "String"
  value       = aws_kinesis_stream.cloudfront_realtime.arn

  tags = local.common_tags
}
