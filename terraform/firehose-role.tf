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
  name               = "pds-cloudfront-realtime-firehose-role"
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

    resources = [var.pds_logs_bucket_arn]
  }

  statement {
    sid    = "S3BackupBucketAccessObjectLevel"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:GetObject"
    ]

    resources = ["${var.pds_logs_bucket_arn}/${var.pds_logs_firehose_prefix}/*"]
  }
}

resource "aws_iam_role_policy" "firehose_s3_backup" {
  name   = "pds-cloudfront-realtime-firehose-s3-backup"
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
  name   = "pds-cloudfront-realtime-firehose-cloudwatch-logs"
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
      aws_lambda_function.cloudfront_realtime_transform.arn,
      "${aws_lambda_function.cloudfront_realtime_transform.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "firehose_lambda_invoke" {
  name   = "pds-cloudfront-realtime-firehose-lambda-invoke"
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

    resources = [aws_kinesis_stream.cloudfront_realtime.arn]
  }
}

resource "aws_iam_role_policy" "firehose_kinesis_read" {
  name   = "pds-cloudfront-realtime-firehose-kinesis-read"
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
  name   = "pds-cloudfront-realtime-firehose-vpc-access"
  role   = aws_iam_role.cloudfront_realtime_firehose.id
  policy = data.aws_iam_policy_document.firehose_vpc_access.json
}

data "aws_iam_policy_document" "firehose_opensearch_write" {
  statement {
    sid    = "AllowAccessToOpenSearchDomain"
    effect = "Allow"

    actions = ["es:*"]

    resources = [
      data.aws_opensearch_domain.observability.arn,
      "${data.aws_opensearch_domain.observability.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "firehose_opensearch_write" {
  name   = "pds-cloudfront-realtime-firehose-opensearch-write"
  role   = aws_iam_role.cloudfront_realtime_firehose.id
  policy = data.aws_iam_policy_document.firehose_opensearch_write.json
}
