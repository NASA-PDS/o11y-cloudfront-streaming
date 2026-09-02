data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_ssm_parameter" "pds_logs_bucket_arn" {
  name = "/pds/pdc-cds-infra/s3/pds-logs-bucket-arn"
}
