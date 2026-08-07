# PDS CloudFront Real-Time Logging — Terraform

Creates and configures the CloudFront real-time logging pipeline for PDS data-node
distributions: a Kinesis Data Stream, a Lambda transform function, a Firehose delivery stream to
OpenSearch (with S3 backup), the supporting IAM roles, a Firehose security group, and the
CloudFront real-time log configuration itself.

This package does **not** own the CloudFront distribution, the OpenSearch domain, the
VPC/subnets, or the S3 backup bucket — those are looked up via `data` sources or passed in as
variables and referenced by convention-based names (see `locals.tf`).

IAM roles live in the standalone [`iam/`](./iam/README.md) root module (its own state) — deploy
it first; see [Deploy](#deploy) below.

## Deployment architecture

`iam/` and this module would naturally depend on each other: the IAM policies need ARNs for
resources this module creates (the Kinesis stream, the Lambda function), while this module needs
the role ARNs back for the CloudFront log config, Firehose, and Lambda. Every resource name here
is a static literal (no random suffixes), so `iam/` **computes** the ARNs it needs from
`data.aws_caller_identity` + `data.aws_partition` + the same name locals, instead of reading a
live resource attribute. That breaks the cycle: `iam/` can apply with zero knowledge of whether
this module's resources exist yet.

```mermaid
flowchart LR
    subgraph iam["terraform/iam — deploy 1st"]
        NAMES["static name locals\n(kinesis_stream_name, lambda_function_name, ...)"]
        COMPUTE["computed ARNs\naccount_id + partition + name"]
        ROLES["3 IAM roles + policies"]
        NAMES --> COMPUTE --> ROLES
        ROLES --> PUB["SSM: /pds/monitor/{cloudfront,firehose,lambda}/*-role-arn"]
    end

    subgraph main["terraform/ — deploy 2nd"]
        SUB["data aws_ssm_parameter"]
        RES["Kinesis stream, Lambda function,\nFirehose stream, CloudFront log config"]
        SUB --> RES
    end

    PUB -->|"read at plan time"| SUB
```

Deploy `iam/` first (see [`iam/README.md`](./iam/README.md)); this module reads its role ARNs
back via `data "aws_ssm_parameter"` rather than an in-module `depends_on`. This module also needs
the existing VPC/subnets, the OpenSearch security group, and the S3 backup bucket — supplied via
`terraform.tfvars` (see [Inputs](#inputs) below) — and does a live `data "aws_opensearch_domain"`
lookup against the existing `pds-<env>-observability` domain, so it cannot plan until that domain
exists.

Once applied, this module outputs `cloudfront_realtime_log_config_arn`, which must be wired into
the existing CloudFront distribution manually — this package does not own that distribution. See
[CloudFront real-time log configuration](#cloudfront-real-time-log-configuration) below for the
exact snippet.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.8.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.57.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudfront_realtime_log_config.cloudfront_realtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_realtime_log_config) | resource |
| [aws_cloudwatch_log_group.cloudfront_realtime_transform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_kinesis_firehose_delivery_stream.cloudfront_realtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream) | resource |
| [aws_kinesis_stream.cloudfront_realtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_stream) | resource |
| [aws_lambda_function.cloudfront_realtime_transform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_security_group.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ssm_parameter.kinesis_stream_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_vpc_security_group_egress_rule.firehose_all_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.opensearch_https_from_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [archive_file.cloudfront_realtime_transform](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_opensearch_domain.observability](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/opensearch_domain) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_ssm_parameter.cloudfront_role_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.firehose_role_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.lambda_execution_role_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_opensearch_security_group_id"></a> [opensearch\_security\_group\_id](#input\_opensearch\_security\_group\_id) | ID of the existing security group attached to the OpenSearch domain. | `string` | n/a | yes |
| <a name="input_pds_logs_bucket_arn"></a> [pds\_logs\_bucket\_arn](#input\_pds\_logs\_bucket\_arn) | ARN of the pds-logs-<env> S3 bucket where Firehose backup records are written. Output from pdc-cds-infra cloudfront/pds-main. | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | IDs of the existing private subnets Firehose will use for its VPC ENIs. | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the existing VPC containing the private subnets and OpenSearch domain. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region used by the provider and regional resources. | `string` | `"us-west-2"` | no |
| <a name="input_cicd"></a> [cicd](#input\_cicd) | CI/CD tag. | `string` | `"terraform"` | no |
| <a name="input_component"></a> [component](#input\_component) | Component tag. Matches the GitHub repository name. | `string` | `"cf-realtime-monitor"` | no |
| <a name="input_env"></a> [env](#input\_env) | Deployment env. | `string` | `"dev"` | no |
| <a name="input_managedby"></a> [managedby](#input\_managedby) | Managing organization or team tag. | `string` | `"viviant@jpl.caltech.edu"` | no |
| <a name="input_node"></a> [node](#input\_node) | PDS node abbreviation, using lowercase letters only, such as en, img, or sbn. | `string` | `"en"` | no |
| <a name="input_pds_logs_firehose_prefix"></a> [pds\_logs\_firehose\_prefix](#input\_pds\_logs\_firehose\_prefix) | S3 prefix within pds\_logs\_bucket\_arn where Firehose backup records are written. | `string` | `"pdc-cds-infra/cloudfront/realtime/firehose"` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Tenant tag. | `string` | `"en"` | no |
| <a name="input_venue"></a> [venue](#input\_venue) | Venue tag. | `string` | `"pds-cds-dev"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloudfront_realtime_log_config_arn"></a> [cloudfront\_realtime\_log\_config\_arn](#output\_cloudfront\_realtime\_log\_config\_arn) | ARN to associate with the existing CloudFront cache behaviors. |
| <a name="output_cloudfront_realtime_log_config_name"></a> [cloudfront\_realtime\_log\_config\_name](#output\_cloudfront\_realtime\_log\_config\_name) | Name of the CloudFront real-time log configuration. |
| <a name="output_cloudfront_realtime_log_role_arn"></a> [cloudfront\_realtime\_log\_role\_arn](#output\_cloudfront\_realtime\_log\_role\_arn) | ARN of the CloudFront real-time logging role (published by the ./iam root module, read here via SSM). |
| <a name="output_cloudfront_role_arn_ssm_parameter_name"></a> [cloudfront\_role\_arn\_ssm\_parameter\_name](#output\_cloudfront\_role\_arn\_ssm\_parameter\_name) | SSM parameter name containing the CloudFront real-time logging IAM role ARN (published by ./iam). |
| <a name="output_firehose_delivery_stream_arn"></a> [firehose\_delivery\_stream\_arn](#output\_firehose\_delivery\_stream\_arn) | ARN of the Firehose delivery stream sending transformed CloudFront logs to OpenSearch. |
| <a name="output_firehose_delivery_stream_name"></a> [firehose\_delivery\_stream\_name](#output\_firehose\_delivery\_stream\_name) | Name of the Firehose delivery stream sending transformed CloudFront logs to OpenSearch. |
| <a name="output_firehose_role_arn"></a> [firehose\_role\_arn](#output\_firehose\_role\_arn) | ARN of the Firehose execution role (published by the ./iam root module, read here via SSM). |
| <a name="output_firehose_role_arn_ssm_parameter_name"></a> [firehose\_role\_arn\_ssm\_parameter\_name](#output\_firehose\_role\_arn\_ssm\_parameter\_name) | SSM parameter name containing the Firehose execution IAM role ARN (published by ./iam). |
| <a name="output_firehose_security_group_id"></a> [firehose\_security\_group\_id](#output\_firehose\_security\_group\_id) | ID of the security group created for the Firehose delivery stream. |
| <a name="output_kinesis_stream_arn"></a> [kinesis\_stream\_arn](#output\_kinesis\_stream\_arn) | ARN of the Kinesis Data Stream receiving CloudFront real-time logs. |
| <a name="output_kinesis_stream_arn_ssm_parameter_name"></a> [kinesis\_stream\_arn\_ssm\_parameter\_name](#output\_kinesis\_stream\_arn\_ssm\_parameter\_name) | SSM parameter name containing the Kinesis Data Stream ARN. |
| <a name="output_kinesis_stream_name"></a> [kinesis\_stream\_name](#output\_kinesis\_stream\_name) | Name of the Kinesis Data Stream receiving CloudFront real-time logs. |
| <a name="output_lambda_execution_role_arn"></a> [lambda\_execution\_role\_arn](#output\_lambda\_execution\_role\_arn) | ARN of the Lambda execution role (published by the ./iam root module, read here via SSM). |
| <a name="output_lambda_execution_role_arn_ssm_parameter_name"></a> [lambda\_execution\_role\_arn\_ssm\_parameter\_name](#output\_lambda\_execution\_role\_arn\_ssm\_parameter\_name) | SSM parameter name containing the Lambda execution IAM role ARN (published by ./iam). |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the CloudFront real-time log transformation Lambda function. |
| <a name="output_lambda_function_invoke_arn"></a> [lambda\_function\_invoke\_arn](#output\_lambda\_function\_invoke\_arn) | Invoke ARN of the CloudFront real-time log transformation Lambda function. |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the CloudFront real-time log transformation Lambda function. |
| <a name="output_lambda_log_group_name"></a> [lambda\_log\_group\_name](#output\_lambda\_log\_group\_name) | CloudWatch Logs log group for the transformation Lambda function. |
| <a name="output_opensearch_domain_arn"></a> [opensearch\_domain\_arn](#output\_opensearch\_domain\_arn) | ARN of the existing OpenSearch domain used by Firehose. |
| <a name="output_opensearch_domain_endpoint"></a> [opensearch\_domain\_endpoint](#output\_opensearch\_domain\_endpoint) | Endpoint of the existing OpenSearch domain used by Firehose. |
| <a name="output_opensearch_domain_name"></a> [opensearch\_domain\_name](#output\_opensearch\_domain\_name) | Derived OpenSearch domain name. |
| <a name="output_opensearch_index_name"></a> [opensearch\_index\_name](#output\_opensearch\_index\_name) | Base OpenSearch index name reserved for the Firehose delivery stream. |
| <a name="output_opensearch_index_rotation"></a> [opensearch\_index\_rotation](#output\_opensearch\_index\_rotation) | OpenSearch index rotation period reserved for the Firehose delivery stream. |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | Existing private subnet IDs reserved for the Firehose VPC configuration. |
| <a name="output_s3_backup_bucket_arn"></a> [s3\_backup\_bucket\_arn](#output\_s3\_backup\_bucket\_arn) | ARN of the existing PDS logs bucket used for Firehose backup records. |
<!-- END_TF_DOCS -->

## Firehose delivery stream

Terraform creates:

```text
pds-cloudfront-realtime-firehose
```

The stream:

- Reads from `pds-cloudfront-realtime-kinesis-stream`
- Invokes `pds-cloudfront-realtime-log-transform` using `$LATEST`
- Delivers transformed records to the existing `pds-<env>-observability` domain
- Writes to the daily-rotated `pds-cloudfront-realtime-index` index
- Uses the existing private subnets and `pds-cloudfront-realtime-firehose-sg`
- Backs up all documents to the existing S3 backup bucket in GZIP format
- Uses a 1 MiB OpenSearch buffer and the provider-supported 60-second interval
- Retries OpenSearch delivery for 300 seconds

S3 object prefixes:

```text
backup/YYYY/MM/DD/HH/
errors/<error-type>/YYYY/MM/DD/HH/
```

The Lambda processor receives up to 1 MiB per invocation or records accumulated for 60 seconds,
whichever threshold is reached first.

## CloudFront real-time log configuration

Terraform creates:

```text
pds-cloudfront-realtime-log-config
```

Settings:

- Sampling rate: `100` percent
- Destination: the Kinesis stream created by this package
- IAM role: `pds-cloudfront-realtime-log-kinesis-role` (created by [`iam/`](./iam/README.md))
- Fields: the 17 fields required by the Lambda transform, in the exact parsing order

This package creates the real-time log configuration but does not manage the existing CloudFront
distribution. In the Terraform stack that owns the distribution, add the configuration ARN to
both existing ordered cache behaviors:

```hcl
ordered_cache_behavior {
  path_pattern            = "/data*"
  realtime_log_config_arn = <this-package-cloudfront_realtime_log_config_arn>

  # Keep the existing behavior settings unchanged.
}

ordered_cache_behavior {
  path_pattern            = "/data/store/img*"
  realtime_log_config_arn = <this-package-cloudfront_realtime_log_config_arn>

  # Keep the existing behavior settings unchanged.
}
```

CloudFront evaluates ordered cache behaviors by precedence. Preserve the existing ordering,
especially because `/data/store/img*` is more specific than `/data*`.

## Existing OpenSearch domain

The package does not create or manage the domain. It reads:

```text
pds-<env>-observability
```

through `data.aws_opensearch_domain.observability`.

The package also does not replace the domain access policy. The Terraform stack that owns the
existing domain must add the Firehose role principal with `es:*` access to the domain ARN and
`domain-arn/*`. This avoids overwriting existing Logstash or administrator access.

Fine-grained access control is unchanged and remains disabled.

## Existing network resources

Supply these existing resource IDs in `terraform.tfvars`:

```hcl
vpc_id                        = "vpc-..."
private_subnet_ids            = ["subnet-...", "subnet-..."]
opensearch_security_group_id  = "sg-..."
```

`private_subnet_ids` is used by the Firehose VPC configuration.

## Firehose security group

Terraform creates:

```text
pds-cloudfront-realtime-firehose-sg
```

Rules:

- No inbound rules on the Firehose security group
- Outbound: all IPv4 protocols and ports to `0.0.0.0/0`
- Existing OpenSearch SG inbound: TCP 443 from the Firehose SG

## OpenSearch ingest path

Firehose OpenSearch destination settings:

```text
Base index: pds-cloudfront-realtime-index
Rotation:   OneDay
Pattern:    pds-cloudfront-realtime-index-YYYY-MM-DD
```

After Firehose is created and records are delivered, use OpenSearch Dashboards Dev Tools to
locate the indexes:

```http
GET _cat/indices/pds-cloudfront-realtime-index-*?v&s=index
```

Use this data-view pattern in OpenSearch Dashboards:

```text
pds-cloudfront-realtime-index-*
```

Select `@timestamp` as the time field.

## Other resource settings

### S3 backup bucket

```text
pds-<node>-<env>-cloudfront-firehose-backup
```

Includes AES256 encryption, versioning, BucketOwnerEnforced ownership, and all S3 public-access
blocks.

### Kinesis stream

```text
pds-cloudfront-realtime-kinesis-stream
```

- On-demand mode
- 90-day retention (`2160` hours)
- Server-side encryption disabled

### Lambda transform

```text
pds-cloudfront-realtime-log-transform
```

- Python 3.12
- `x86_64`
- 512 MB memory
- 300-second timeout
- 512 MB ephemeral storage
- `$LATEST` (`publish = false`)
- 30-day CloudWatch Logs retention

## Deploy

State lives in S3 (see `backend.tf` / `backend-<venue>.hcl`) — pick a venue and initialize with
its backend config. IAM must be deployed first since this module reads role ARNs from SSM.

```bash
# 1. IAM (own state, deploy first)
cd terraform/iam
terraform init -backend-config=backend-dev.hcl
terraform plan  -out=tfplan.iam
terraform apply tfplan.iam

# 2. Everything else
cd ../
cp -p terraform.tfvars.example terraform.tfvars
# Replace the example VPC, subnet, and OpenSearch SG IDs.

terraform init -backend-config=backend-dev.hcl
terraform fmt -check
terraform validate

PLAN="tfplan.$(date +%Y%m%d.%H%M)"
terraform plan -out="$PLAN"
terraform show "$PLAN"
terraform apply "$PLAN"
```

Swap `backend-dev.hcl` for `backend-test.hcl` / `backend-prod.hcl` for other venues.

### First-time migration from local state

Existing deployments predate the S3 backend. Whoever holds the current local
`terraform/terraform.tfstate` needs to migrate it once:

```bash
cd terraform
terraform init -backend-config=backend-dev.hcl -migrate-state   # answer "yes"
terraform plan                                                   # must show no changes
```

## Destroy

The OpenSearch domain, VPC, subnets, and existing OpenSearch security group are not destroyed by
this package. Terraform removes only the new ingress rule and the Firehose security group created
here.

```bash
DESTROY_PLAN="tfplan.destroy.$(date +%Y%m%d.%H%M)"
terraform plan -destroy -out="$DESTROY_PLAN"
terraform apply "$DESTROY_PLAN"
```

Destroy the main module before `iam/` (roles must outlive the resources that reference them).
