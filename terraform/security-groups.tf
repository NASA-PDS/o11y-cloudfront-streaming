resource "aws_security_group" "firehose" {
  name        = local.firehose_security_group_name
  description = "Security group for the CloudFront real-time logging Firehose delivery stream."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = local.firehose_security_group_name
  })
}

resource "aws_vpc_security_group_egress_rule" "firehose_all_ipv4" {
  security_group_id = aws_security_group.firehose.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow all outbound IPv4 traffic from Firehose ENIs."
}
