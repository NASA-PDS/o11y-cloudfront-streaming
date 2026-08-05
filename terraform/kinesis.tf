resource "aws_kinesis_stream" "cloudfront_realtime" {
  name             = local.kinesis_stream_name
  retention_period = 2160

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
