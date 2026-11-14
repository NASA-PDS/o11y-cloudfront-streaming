# CloudFront Real-Time Logging - IAM

Standalone root module (own state) for the three IAM roles used by the pipeline in
[`../`](../README.md). It is separate so IAM changes have their own review and apply path.

| Role | Trusted by | Allows |
|---|---|---|
| `pds-o11y-cloudfront-streaming-cf-kinesis-role` | CloudFront (same account) | Write records to the Kinesis stream; `kms:GenerateDataKey` for the stream's server-side encryption |
| `pds-o11y-cloudfront-streaming-firehose-role` | Firehose | Read the Kinesis stream; `kms:Decrypt` for the stream's server-side encryption; invoke the transform Lambda; `es:*` on the OpenSearch domain; write the S3 backup under `pds_logs_firehose_prefix`; write CloudWatch Logs; manage VPC network interfaces |
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
| [aws_kms_key.kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
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
| <a name="input_kinesis_kms_key_arn"></a> [kinesis\_kms\_key\_arn](#input\_kinesis\_kms\_key\_arn) | ARN of the AWS managed key alias/aws/kinesis (the key that encrypts the Kinesis stream). When null, the key is looked up by alias in the account and region. | `string` | `null` | no |
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

## Kinesis KMS key

The stream is encrypted with the AWS managed key `alias/aws/kinesis`. The `kms:GenerateDataKey`
(CloudFront role) and `kms:Decrypt` (Firehose role) statements are scoped to that key's ARN, which
the `aws_kms_key` data source reads at plan time. Both statements are also limited by
`kms:ViaService` (`kinesis.<region>.<dns-suffix>`) and `kms:EncryptionContext:aws:kinesis:arn`
(this stream's ARN). The key ARN is stable, so the policies do not change between plans.

- **Permission:** the principal that plans and applies this module needs `kms:DescribeKey` on the key.
- **Key not found:** AWS creates the AWS managed key when the service first uses it, and this
  module applies before the stream exists, so on a venue that has never used Kinesis encryption in
  the region the lookup can fail at plan time with a not-found error for `alias/aws/kinesis`. The
  KMS `DescribeKey` API documents that a predefined AWS alias (`alias/aws/...`) is associated with
  an AWS managed key when it is described, so the check below may create the key; that behavior
  is documented for AWS services and has not been confirmed for a call made with user credentials.
  If the check still reports not found, enable server-side encryption with `alias/aws/kinesis`
  on any Kinesis stream in the region once (for example a temporary stream), confirm the check
  below returns a key, then re-plan.
- **Override:** `kinesis_kms_key_arn` skips the lookup and scopes the two statements to the ARN you
  give. Use it when the applying principal cannot call `kms:DescribeKey`. The stream's `kms_key_id`
  is the alias `alias/aws/kinesis` (set in [`../`](../README.md)), so the ARN must be the key that
  the alias resolves to; a different ARN would leave the roles without access to the stream's key.

Check the key from the CLI:

```bash
REGION="us-west-2"
aws kms describe-key --region "${REGION}" --key-id alias/aws/kinesis \
  --query 'KeyMetadata.[Arn,KeyManager,KeyState]' --output text
```

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
