data "aws_opensearch_domain" "observability" {
  domain_name = local.opensearch_domain_name
}
