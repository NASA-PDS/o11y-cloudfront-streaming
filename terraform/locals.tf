locals {
  common_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }

  s3_backup_bucket_name         = "pds-logs-${var.env}"
  kinesis_stream_name           = "pds-o11y-cloudfront-streaming-kinesis"
  cloudfront_realtime_log_name  = "pds-o11y-cloudfront-streaming-log-config"
  lambda_function_name          = "pds-o11y-cloudfront-streaming-transform"
  opensearch_domain_name        = "pds-${var.env}-o11y"
  firehose_delivery_stream_name = "pds-o11y-cloudfront-streaming-firehose"
  firehose_security_group_name  = "pds-o11y-cloudfront-streaming-firehose-sg"
  opensearch_index_name         = "pds-o11y-cloudfront-streaming-index"
  opensearch_index_rotation     = "OneDay"

  kinesis_stream_arn_ssm_parameter_name        = "/pds/o11y-cloudfront-streaming/kinesis/kinesis-stream-arn"
  cloudfront_role_arn_ssm_parameter_name       = "/pds/o11y-cloudfront-streaming/cloudfront/cloudfront-role-arn"
  firehose_role_arn_ssm_parameter_name         = "/pds/o11y-cloudfront-streaming/firehose/firehose-role-arn"
  lambda_execution_role_arn_ssm_parameter_name = "/pds/o11y-cloudfront-streaming/lambda/lambda-transform-role-arn"

  opensearch_security_group_id_ssm_parameter_name = "/pds/o11y-platform/opensearch/opensearch_security_group_id"

  cloudfront_realtime_log_fields = [
    "timestamp",
    "c-ip",
    "time-to-first-byte",
    "sc-status",
    "sc-bytes",
    "cs-method",
    "cs-protocol",
    "cs-host",
    "cs-uri-stem",
    "x-edge-location",
    "x-edge-request-id",
    "cs-user-agent",
    "cs-referer",
    "cs-uri-query",
    "x-edge-response-result-type",
    "x-edge-result-type",
    "c-country",
  ]
}
