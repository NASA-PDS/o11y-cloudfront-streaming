resource "aws_kinesis_stream" "cloudfront_realtime" {
  name             = local.kinesis_stream_name
  retention_period = 2160

  # Server-side encryption at rest. The records contain client IP addresses,
  # request URIs and user agents.
  encryption_type = "KMS"
  kms_key_id      = local.kinesis_kms_key_id

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = merge(
    local.common_tags,
    {
      Name    = local.kinesis_stream_name
      Purpose = "CloudFront real-time log ingestion"
    }
  )
}
