data "aws_opensearch_domain" "o11y" {
  domain_name = local.opensearch_domain_name
}

# Published by o11y-platform's opensearch module after every deploy — read here
# instead of a manual opensearch_security_group_id tfvar so this module doesn't need
# a value only the other repo can produce.
data "aws_ssm_parameter" "opensearch_security_group_id" {
  name = local.opensearch_security_group_id_ssm_parameter_name
}
