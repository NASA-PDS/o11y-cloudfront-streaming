data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# IAM roles are owned by the standalone ./iam root module (its own state) and
# consumed here via SSM rather than direct resource references.
data "aws_ssm_parameter" "cloudfront_role_arn" {
  name = local.cloudfront_role_arn_ssm_parameter_name
}

data "aws_ssm_parameter" "firehose_role_arn" {
  name = local.firehose_role_arn_ssm_parameter_name
}

data "aws_ssm_parameter" "lambda_execution_role_arn" {
  name = local.lambda_execution_role_arn_ssm_parameter_name
}
