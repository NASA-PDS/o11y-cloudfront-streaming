data "aws_iam_policy_document" "cloudfront_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "cloudfront_realtime_log_kinesis" {
  name               = "pds-o11y-cloudfront-streaming-cf-kinesis-role"
  path               = "/service-role/"
  description        = "Allows CloudFront real-time logging to write records to the configured Kinesis Data Stream."
  assume_role_policy = data.aws_iam_policy_document.cloudfront_assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "cloudfront_realtime_log_kinesis" {
  statement {
    sid    = "WriteCloudFrontRealtimeLogs"
    effect = "Allow"

    actions = [
      "kinesis:DescribeStreamSummary",
      "kinesis:DescribeStream",
      "kinesis:PutRecord",
      "kinesis:PutRecords"
    ]

    resources = [local.kinesis_stream_arn]
  }
}

resource "aws_iam_role_policy" "cloudfront_realtime_log_kinesis" {
  name   = "pds-o11y-cloudfront-streaming-cf-kinesis-policy"
  role   = aws_iam_role.cloudfront_realtime_log_kinesis.id
  policy = data.aws_iam_policy_document.cloudfront_realtime_log_kinesis.json
}
