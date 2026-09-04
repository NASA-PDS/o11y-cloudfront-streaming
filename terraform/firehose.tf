resource "aws_kinesis_firehose_delivery_stream" "cloudfront_realtime" {
  name        = local.firehose_delivery_stream_name
  destination = "opensearch"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.cloudfront_realtime.arn
    role_arn           = data.aws_ssm_parameter.firehose_role_arn.value
  }

  opensearch_configuration {
    domain_arn = data.aws_opensearch_domain.o11y.arn
    role_arn   = data.aws_ssm_parameter.firehose_role_arn.value

    index_name            = local.opensearch_index_name
    index_rotation_period = local.opensearch_index_rotation

    buffering_interval = 60
    buffering_size     = 1
    retry_duration     = 300

    s3_backup_mode = "AllDocuments"

    s3_configuration {
      role_arn            = data.aws_ssm_parameter.firehose_role_arn.value
      bucket_arn          = data.aws_ssm_parameter.pds_logs_bucket_arn.value
      buffering_interval  = 300
      buffering_size      = 5
      compression_format  = "GZIP"
      prefix              = "${var.pds_logs_firehose_prefix}/!{timestamp:yyyy/MM/dd/HH}/"
      error_output_prefix = "${var.pds_logs_firehose_prefix}/errors/!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd/HH}/"
    }

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.cloudfront_realtime_transform.arn}:$LATEST"
        }
      }
    }

    vpc_config {
      role_arn           = data.aws_ssm_parameter.firehose_role_arn.value
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [aws_security_group.firehose.id]
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name    = local.firehose_delivery_stream_name
      Purpose = "CloudFront real-time log delivery to OpenSearch"
    }
  )

  # IAM roles/policies now live in the standalone ./iam root module — deploy
  # it first (see terraform/README.md) so the SSM lookups above resolve and
  # the roles already have their policies attached.
  depends_on = [
    aws_vpc_security_group_egress_rule.firehose_all_ipv4,
  ]
}
