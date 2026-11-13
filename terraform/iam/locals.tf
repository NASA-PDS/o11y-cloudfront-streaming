locals {
  common_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }

  kinesis_stream_name    = "pds-o11y-cloudfront-streaming-kinesis"
  lambda_function_name   = "pds-o11y-cloudfront-streaming-transform"
  opensearch_domain_name = "pds-${var.env}-o11y"

  # Every name above is a static literal (no random suffixes), so the ARNs the
  # policies below need can be computed without a live resource reference to
  # the main module. This is what lets iam/ apply independently, in either
  # order relative to the main module.
  kinesis_stream_arn    = "arn:${data.aws_partition.current.partition}:kinesis:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stream/${local.kinesis_stream_name}"
  lambda_function_arn   = "arn:${data.aws_partition.current.partition}:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${local.lambda_function_name}"
  opensearch_domain_arn = "arn:${data.aws_partition.current.partition}:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_domain_name}"

  # The stream is encrypted with the AWS managed Kinesis key (alias/aws/kinesis).
  # That key may not exist in an account/region until Kinesis first uses it, so
  # the policies match any key ARN in this account/region and rely on the
  # kms:ViaService and stream encryption-context conditions to confine use to
  # this stream. Keeping this a computed pattern preserves independent apply
  # order for iam/.
  kinesis_kms_key_arn_pattern = "arn:${data.aws_partition.current.partition}:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
  kinesis_kms_via_service     = "kinesis.${var.aws_region}.${data.aws_partition.current.dns_suffix}"

  cloudfront_role_arn_ssm_parameter_name       = "/pds/o11y-cloudfront-streaming/cloudfront/cloudfront-role-arn"
  firehose_role_arn_ssm_parameter_name         = "/pds/o11y-cloudfront-streaming/firehose/firehose-role-arn"
  lambda_execution_role_arn_ssm_parameter_name = "/pds/o11y-cloudfront-streaming/lambda/lambda-transform-role-arn"
  kinesis_stream_arn_ssm_parameter_name        = "/pds/o11y-cloudfront-streaming/kinesis/kinesis-stream-arn"
}
