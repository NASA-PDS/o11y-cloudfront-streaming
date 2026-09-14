data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    sid    = "AllowFirehoseAssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudfront_realtime_firehose" {
  name               = "pds-o11y-cloudfront-streaming-firehose-role"
  path               = "/service-role/"
  description        = "Execution role for the CloudFront real-time log Firehose delivery stream."
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "firehose_s3_backup" {
  statement {
    sid    = "S3BackupBucketAccessBucketLevel"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads"
    ]

    resources = [data.aws_ssm_parameter.pds_logs_bucket_arn.value]
  }

  statement {
    sid    = "S3BackupBucketAccessObjectLevel"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:GetObject"
    ]

    resources = ["${data.aws_ssm_parameter.pds_logs_bucket_arn.value}/${var.pds_logs_firehose_prefix}/*"]
  }
}

resource "aws_iam_role_policy" "firehose_s3_backup" {
  name   = "pds-o11y-cloudfront-streaming-firehose-s3-backup"
  role   = aws_iam_role.cloudfront_realtime_firehose.id
  policy = data.aws_iam_policy_document.firehose_s3_backup.json
}

data "aws_iam_policy_document" "firehose_cloudwatch_logs" {
  statement {
    sid    = "CloudWatchLogsWrite"
    effect = "Allow"

    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "firehose_cloudwatch_logs" {
  name   = "pds-o11y-cloudfront-streaming-firehose-cw-logs"
  role   = aws_iam_role.cloudfront_realtime_firehose.id
  policy = data.aws_iam_policy_document.firehose_cloudwatch_logs.json
}

data "aws_iam_policy_document" "firehose_lambda_invoke" {
  statement {
    sid    = "InvokeCloudFrontLogTransformLambda"
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration"
    ]

    resources = [
      local.lambda_function_arn,
      "${local.lambda_function_arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "firehose_lambda_invoke" {
  name   = "pds-o11y-cloudfront-streaming-firehose-lambda"
  role   = aws_iam_role.cloudfront_realtime_firehose.id
  policy = data.aws_iam_policy_document.firehose_lambda_invoke.json
}

data "aws_iam_policy_document" "firehose_kinesis_read" {
  statement {
    sid    = "ReadFromRealtimeLogStream"
    effect = "Allow"

    actions = [
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]

    resources = [local.kinesis_stream_arn]
  }
}

resource "aws_iam_role_policy" "firehose_kinesis_read" {
  name   = "pds-o11y-cloudfront-streaming-firehose-kinesis"
  role   = aws_iam_role.cloudfront_realtime_firehose.id
  policy = data.aws_iam_policy_document.firehose_kinesis_read.json
}

data "aws_iam_policy_document" "firehose_vpc_access" {
  statement {
    sid    = "AllowFirehoseVpcConfiguration"
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:Describe*",
      "ec2:DeleteNetworkInterface"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "firehose_vpc_access" {
  name   = "pds-o11y-cloudfront-streaming-firehose-vpc"
  role   = aws_iam_role.cloudfront_realtime_firehose.id
  policy = data.aws_iam_policy_document.firehose_vpc_access.json
}

data "aws_iam_policy_document" "firehose_opensearch_write" {
  statement {
    sid    = "AllowAccessToOpenSearchDomain"
    effect = "Allow"

    actions = ["es:*"]

    resources = [
      local.opensearch_domain_arn,
      "${local.opensearch_domain_arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "firehose_opensearch_write" {
  name   = "pds-o11y-cloudfront-streaming-firehose-os-write"
  role   = aws_iam_role.cloudfront_realtime_firehose.id
  policy = data.aws_iam_policy_document.firehose_opensearch_write.json
}
