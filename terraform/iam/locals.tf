locals {
  common_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }

  kinesis_stream_name    = "pds-cloudfront-realtime-kinesis-stream"
  lambda_function_name   = "pds-cloudfront-realtime-log-transform"
  opensearch_domain_name = "pds-${var.env}-observability"

  # Every name above is a static literal (no random suffixes), so the ARNs the
  # policies below need can be computed without a live resource reference to
  # the main module. This is what lets iam/ apply independently, in either
  # order relative to the main module.
  kinesis_stream_arn    = "arn:${data.aws_partition.current.partition}:kinesis:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stream/${local.kinesis_stream_name}"
  lambda_function_arn   = "arn:${data.aws_partition.current.partition}:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${local.lambda_function_name}"
  opensearch_domain_arn = "arn:${data.aws_partition.current.partition}:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_domain_name}"

  # SSM paths kept identical to the ones this repo has always published so
  # existing consumers (e.g. pdc-observability) are unaffected by this split.
  cloudfront_role_arn_ssm_parameter_name       = "/pds/monitor/cloudfront/cloudfront-role-arn"
  firehose_role_arn_ssm_parameter_name         = "/pds/monitor/firehose/firehose-role-arn"
  lambda_execution_role_arn_ssm_parameter_name = "/pds/monitor/lambda/lambda-transform-role-arn"
}
