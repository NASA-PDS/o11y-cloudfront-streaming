# CloudFront Real-Time Logging - IAM

Standalone root module (own state) for the three IAM roles used by the pipeline in
[`../`](../README.md). It is separate so IAM changes have their own review and apply path.

| Role | Trusted by | Allows |
|---|---|---|
| `pds-o11y-cloudfront-streaming-cf-kinesis-role` | CloudFront (same account) | Write records to the Kinesis stream |
| `pds-o11y-cloudfront-streaming-firehose-role` | Firehose | Read the Kinesis stream; invoke the transform Lambda; `es:*` on the OpenSearch domain; write the S3 backup under `pds_logs_firehose_prefix`; write CloudWatch Logs; manage VPC network interfaces |
| `pds-o11y-cloudfront-streaming-transform-role` | Lambda | `AWSLambdaBasicExecutionRole` (CloudWatch Logs) |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.58.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role.cloudfront_realtime_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cloudfront_realtime_log_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cloudfront_realtime_log_transform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cloudfront_realtime_log_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.firehose_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.firehose_kinesis_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.firehose_lambda_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.firehose_opensearch_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.firehose_s3_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.firehose_vpc_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_basic_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_ssm_parameter.cloudfront_role_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.firehose_role_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.kinesis_stream_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.lambda_execution_role_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudfront_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudfront_realtime_log_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.firehose_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.firehose_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.firehose_kinesis_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.firehose_lambda_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.firehose_opensearch_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.firehose_s3_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.firehose_vpc_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_ssm_parameter.pds_logs_bucket_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_managedby"></a> [managedby](#input\_managedby) | Managing organization or team tag (e.g. team email distribution list). | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region used by the provider and for computing service ARNs. | `string` | `"us-west-2"` | no |
| <a name="input_cicd"></a> [cicd](#input\_cicd) | CI/CD tag. | `string` | `"iac"` | no |
| <a name="input_component"></a> [component](#input\_component) | Component tag. Matches the GitHub repository name. | `string` | `"o11y-cloudfront-streaming"` | no |
| <a name="input_env"></a> [env](#input\_env) | Deployment env. Used to derive the existing OpenSearch domain name. | `string` | `"dev"` | no |
| <a name="input_pds_logs_firehose_prefix"></a> [pds\_logs\_firehose\_prefix](#input\_pds\_logs\_firehose\_prefix) | S3 prefix within the pds-logs-<env> bucket where Firehose backup records are written. | `string` | `"pdc-cds-infra/cloudfront/realtime/firehose"` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Tenant tag. | `string` | `"en"` | no |
| <a name="input_venue"></a> [venue](#input\_venue) | Venue tag. | `string` | `"pds-cds-dev"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloudfront_realtime_log_role_arn"></a> [cloudfront\_realtime\_log\_role\_arn](#output\_cloudfront\_realtime\_log\_role\_arn) | ARN of the CloudFront real-time logging role. |
| <a name="output_cloudfront_role_arn_ssm_parameter_name"></a> [cloudfront\_role\_arn\_ssm\_parameter\_name](#output\_cloudfront\_role\_arn\_ssm\_parameter\_name) | SSM parameter name containing the CloudFront real-time logging IAM role ARN. |
| <a name="output_firehose_role_arn"></a> [firehose\_role\_arn](#output\_firehose\_role\_arn) | ARN of the Firehose execution role. |
| <a name="output_firehose_role_arn_ssm_parameter_name"></a> [firehose\_role\_arn\_ssm\_parameter\_name](#output\_firehose\_role\_arn\_ssm\_parameter\_name) | SSM parameter name containing the Firehose execution IAM role ARN. |
| <a name="output_lambda_execution_role_arn"></a> [lambda\_execution\_role\_arn](#output\_lambda\_execution\_role\_arn) | ARN of the Lambda execution role. |
| <a name="output_lambda_execution_role_arn_ssm_parameter_name"></a> [lambda\_execution\_role\_arn\_ssm\_parameter\_name](#output\_lambda\_execution\_role\_arn\_ssm\_parameter\_name) | SSM parameter name containing the Lambda execution IAM role ARN. |
<!-- END_TF_DOCS -->

## SSM parameters

This module publishes the three role ARNs and the Kinesis stream ARN. The runbook
[SSM contract](https://github.com/NASA-PDS/o11y-platform/blob/main/terraform/README.md#ssm-contract)
lists the paths and which repos read each, except the Lambda role ARN
(`lambda/lambda-transform-role-arn` under the component prefix), which only the main module reads.

## Deploy

Deploy before the main module (Admin tier). Phase, permissions, and verification:
runbook [Phase 2b](https://github.com/NASA-PDS/o11y-platform/blob/main/terraform/README.md#phase-2---iam).
Why it can apply first and where venue inputs live: [`../README.md`](../README.md#deployment).
Local runs: [Local iteration](../README.md#local-iteration).
