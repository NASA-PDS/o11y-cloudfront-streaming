data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_ssm_parameter" "pds_logs_bucket_arn" {
  name = "/pds/pdc-cds-infra/s3/pds-logs-bucket-arn"
}

# AWS managed key that encrypts the Kinesis stream. The KMS policy statements
# are scoped to its ARN. Skipped when kinesis_kms_key_arn is set.
data "aws_kms_key" "kinesis" {
  count = var.kinesis_kms_key_arn == null ? 1 : 0

  key_id = local.kinesis_kms_key_alias
}
