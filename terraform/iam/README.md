# CloudFront Real-Time Logging — IAM

Standalone root module (own state) for the three IAM roles used by the CloudFront real-time
logging pipeline in [`../`](../README.md):

- `pds-cloudfront-realtime-log-kinesis-role` — lets CloudFront write real-time logs to Kinesis
- `pds-cloudfront-realtime-firehose-role` — Firehose's execution role (reads Kinesis, invokes the
  transform Lambda, writes to OpenSearch, backs up to S3)
- `pds-cloudfront-realtime-log-transform-lambda-role` — the transform Lambda's execution role

Split out from the main module so IAM changes go through their own review/apply path (per the
org's Terraform guidelines), separate from the pipeline resources those roles have permission to
touch.

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

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_pds_logs_bucket_arn"></a> [pds\_logs\_bucket\_arn](#input\_pds\_logs\_bucket\_arn) | ARN of the pds-logs-<env> S3 bucket where Firehose backup records are written. Output from pdc-cds-infra cloudfront/pds-main. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region used by the provider and for computing service ARNs. | `string` | `"us-west-2"` | no |
| <a name="input_cicd"></a> [cicd](#input\_cicd) | CI/CD tag. | `string` | `"terraform"` | no |
| <a name="input_component"></a> [component](#input\_component) | Component tag. Matches the GitHub repository name. | `string` | `"cf-realtime-monitor"` | no |
| <a name="input_env"></a> [env](#input\_env) | Deployment env. Used to derive the existing OpenSearch domain name. | `string` | `"dev"` | no |
| <a name="input_managedby"></a> [managedby](#input\_managedby) | Managing organization or team tag. | `string` | `"viviant@jpl.caltech.edu"` | no |
| <a name="input_pds_logs_firehose_prefix"></a> [pds\_logs\_firehose\_prefix](#input\_pds\_logs\_firehose\_prefix) | S3 prefix within pds\_logs\_bucket\_arn where Firehose backup records are written. | `string` | `"pdc-cds-infra/cloudfront/realtime/firehose"` | no |
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

## Why this can deploy independently

The three roles' policies need ARNs for resources the *main* module owns (the Kinesis stream, the
Lambda function, the OpenSearch domain), while the main module needs these roles' ARNs back. Every
name in this repo is a static literal (no random suffixes), so those ARNs are computed here from
`data.aws_caller_identity` + `data.aws_partition` + the same name locals, rather than read via a
live resource reference — see `locals.tf`. That breaks the two-way dependency: this module can
apply with zero knowledge of whether the main module's resources exist yet.

## Publishes to SSM

Role ARNs are published under the same paths this repo has always used (unchanged by this split,
so `pdc-observability` and any other consumer are unaffected):

```text
/pds/monitor/cloudfront/cloudfront-role-arn
/pds/monitor/firehose/firehose-role-arn
/pds/monitor/lambda/lambda-transform-role-arn      (new — previously only used in-module)
```

The main module reads all three back via `data "aws_ssm_parameter"`.

## Deploy

Deploy this **before** the main module — its resources (CloudFront log config, Firehose delivery
stream, Lambda function) need these role ARNs from SSM to plan successfully. Deployment is driven
by [Task](https://taskfile.dev) via the [`Taskfile.yaml`](../Taskfile.yaml) one level up — run
`task --list` there to see everything available.

tfvars are tracked in [`cds-infra-deploy`](https://github.com/NASA-PDS/cds-infra-deploy) at
`venues/<venue>/cf-realtime-monitor/iam.tfvars` — set `CDS_INFRA_DEPLOY_DIR` to a local
checkout (see `../README.md#deploy` for the full env var / `LOCAL=1` explanation).

```bash
cd terraform
export CDS_INFRA_DEPLOY_DIR=/path/to/cds-infra-deploy

task iam:validate
task iam:plan   VENUE=dev
task iam:deploy VENUE=dev
```

Swap `VENUE=dev` for `VENUE=test` / `VENUE=prod` for other venues.

## Migrating an existing (pre-split) deployment

If this repo was previously deployed as a single module with local state, the IAM resources are
sitting in that old state file, not here. Someone with the current AWS credentials and that local
`terraform.tfstate` needs to move them once, **after** the main module has already been migrated
to its own S3 backend (see `../README.md`):

```bash
cd terraform

# 1. Pull the IAM-related resources out of the main module's state into a local file.
#    Repeat for every address in this list:
#      aws_iam_role.cloudfront_realtime_log_kinesis
#      aws_iam_role_policy.cloudfront_realtime_log_kinesis
#      aws_iam_role.cloudfront_realtime_firehose
#      aws_iam_role_policy.firehose_s3_backup
#      aws_iam_role_policy.firehose_cloudwatch_logs
#      aws_iam_role_policy.firehose_lambda_invoke
#      aws_iam_role_policy.firehose_kinesis_read
#      aws_iam_role_policy.firehose_vpc_access
#      aws_iam_role_policy.firehose_opensearch_write
#      aws_iam_role.cloudfront_realtime_log_transform
#      aws_iam_role_policy_attachment.lambda_basic_execution
#      aws_ssm_parameter.cloudfront_role_arn
#      aws_ssm_parameter.firehose_role_arn
terraform state mv -state-out=/tmp/iam.tfstate <address> <address>

# 2. Push the extracted state into this module's own backend.
cd iam
terraform init -backend-config=backend-dev.hcl
terraform state push /tmp/iam.tfstate

# 3. There is no pre-existing aws_ssm_parameter for the Lambda execution role
#    (it was previously only used in-module) — import it after the first
#    `terraform apply` here creates it normally, or apply straight away and
#    let Terraform create it fresh.

# 4. Verify both sides are clean.
cd ..
task iam:plan     VENUE=dev   # expect no changes
task monitor:plan VENUE=dev   # expect no changes
```
