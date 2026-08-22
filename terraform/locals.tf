locals {
  common_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }

  s3_backup_bucket_name         = "pds-logs-${var.env}"
  kinesis_stream_name           = "pds-cloudfront-realtime-kinesis-stream"
  cloudfront_realtime_log_name  = "pds-cloudfront-realtime-log-config"
  lambda_function_name          = "pds-cloudfront-realtime-log-transform"
  opensearch_domain_name        = "pds-${var.env}-observability"
  firehose_delivery_stream_name = "pds-cloudfront-realtime-firehose"
  firehose_security_group_name  = "pds-cloudfront-realtime-firehose-sg"
  opensearch_index_name         = "pds-cloudfront-realtime-index"
  opensearch_index_rotation     = "OneDay"

  kinesis_stream_arn_ssm_parameter_name        = "/pds/web-analytics-realtime/kinesis/kinesis-stream-arn"
  cloudfront_role_arn_ssm_parameter_name       = "/pds/web-analytics-realtime/cloudfront/cloudfront-role-arn"
  firehose_role_arn_ssm_parameter_name         = "/pds/web-analytics-realtime/firehose/firehose-role-arn"
  lambda_execution_role_arn_ssm_parameter_name = "/pds/web-analytics-realtime/lambda/lambda-transform-role-arn"

  opensearch_security_group_id_ssm_parameter_name = "/pds/observability/opensearch/opensearch_security_group_id"

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
