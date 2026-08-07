resource "aws_cloudfront_realtime_log_config" "cloudfront_realtime" {
  name          = local.cloudfront_realtime_log_name
  sampling_rate = 100
  fields        = local.cloudfront_realtime_log_fields

  endpoint {
    stream_type = "Kinesis"

    kinesis_stream_config {
      role_arn   = data.aws_ssm_parameter.cloudfront_role_arn.value
      stream_arn = aws_kinesis_stream.cloudfront_realtime.arn
    }
  }
}
