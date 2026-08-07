# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo provisions AWS infrastructure that captures CloudFront real-time access logs for PDS data-node
distributions, transforms them, and delivers them to OpenSearch for monitoring/analytics. It was created from
NASA-PDS's `template-repo-python` template, but **the real content of this repo is the Terraform package under
`terraform/`, not a Python library** — the `src/pds/your_package_name/` and `tests/pds/your_package_name/`
directories are unmodified template scaffolding and are not part of the actual deliverable. Don't extend them
unless the project is deliberately being repurposed as a Python package.

## Commands

### Terraform

All commands run from the `terraform/` directory.

```bash
cd terraform
cp -p tfvars/dev.tfvars.example tfvars/dev.tfvars   # fill in vpc_id, private_subnet_ids, pds_logs_bucket_arn

terraform init -backend-config=backend-dev.hcl
terraform fmt -check
terraform validate

PLAN="tfplan.$(date +%Y%m%d.%H%M)"
terraform plan -var-file=tfvars/dev.tfvars -out="$PLAN"
terraform show "$PLAN"
terraform apply "$PLAN"
```

Destroy (does not touch the OpenSearch domain, VPC, subnets, or pre-existing OpenSearch security group — only
the resources this package created):

```bash
terraform plan -destroy -out="tfplan.destroy.$(date +%Y%m%d.%H%M)"
terraform apply tfplan.destroy.<timestamp>
```

CI (`.github/workflows/terraform_cicd.yaml`) runs `terraform fmt` and `terraform validate` on every push; the
`plan`/`apply` steps are commented out pending AWS OIDC credential setup in this repo.

### Python template scaffolding (vestigial)

The following applies only to the unused `src/pds/your_package_name` scaffolding inherited from the template,
kept here for completeness:

```bash
python -m venv venv && source venv/bin/activate && pip install --editable '.[dev]'
pytest                         # run tests
tox -e lint                    # flake8 + mypy + pre-commit
tox                            # tests + lint + docs
```

## Architecture

### Log pipeline (`terraform/`)

```
CloudFront (existing distribution, /data* and /data/store/img* cache behaviors)
  -> aws_cloudfront_realtime_log_config (100% sampling, 17 fields, see locals.tf)
  -> Kinesis Data Stream (on-demand, 90-day retention)
  -> Firehose delivery stream (destination: opensearch)
       -> Lambda transform (terraform/lambda/lambda_function.py), invoked inline via Firehose
            processing_configuration before OpenSearch delivery
       -> OpenSearch domain (existing, data-sourced by name pds-<env>-observability;
            index pds-cloudfront-realtime-index-YYYY-MM-DD, daily rotation)
       -> S3 backup (existing pds-logs-<env> bucket, GZIP, AllDocuments mode)
```

Key point: this package **creates** the Kinesis stream, Lambda, Firehose stream, IAM roles, the Firehose
security group, an OpenSearch ingress rule, and the CloudFront real-time log config — but it does **not** own
the CloudFront distribution, the OpenSearch domain, the VPC/subnets, or the S3 backup bucket. Those are looked
up via `data` sources or passed in as variables (`vpc_id`, `private_subnet_ids`, `opensearch_security_group_id`,
`pds_logs_bucket_arn`) and referenced by convention-based names in `locals.tf`. To wire a CloudFront distribution
to this config, add `realtime_log_config_arn` (the `cloudfront_realtime_log_config_arn` output) to its ordered
cache behaviors in the Terraform stack that owns that distribution — see README.md for the exact snippet and a
note on cache-behavior precedence ordering.

Resource/IAM role names, the OpenSearch domain name, and SSM parameter paths are all derived in `locals.tf` from
`var.env` (dev/test/prod) — per-venue variable values live in `terraform/tfvars/<venue>.tfvars` and
`terraform/iam/tfvars/<venue>.tfvars` (checked in only as `.example`, gitignored once copied).

### Lambda transform (`terraform/lambda/lambda_function.py`)

Single-file, dependency-free (stdlib only) Firehose transformation Lambda — packaged by Terraform via
`archive_file` (no build step, no `requirements.txt`). Responsibilities:

- Decode/parse tab-delimited CloudFront real-time log records. `FIELDS` in this file **must stay in sync** with
  `cloudfront_realtime_log_fields` in `terraform/locals.tf` (same fields, same order) — CloudFront's real-time
  log config sends fields positionally, not by name.
- Convert `sc-status`/`sc-bytes` to int and `timestamp`/`time-to-first-byte` to float; `-` becomes `null`.
- Derive an `@timestamp` ISO-8601 field from the epoch `timestamp`.
- Classify each request (`request_type`: `directory_listing`, `data_download`, `metadata_download`,
  `static_asset`, `other_file`, `other`) based on `cs-uri-stem` file extension and `/data/store/` query
  parameters (`prefix`/`delimiter` signal a directory listing).
- Extract PDS-specific dimensions (`data_area`, `mission`, `collection`, `path_prefix`) by walking path segments
  after `/data/store/<data_area>/` and/or the `prefix` query parameter; `collection` is matched against
  `COLLECTION_IDENTIFIER_PATTERN` (upper-case, underscore- and digit-containing tokens, e.g. `LROLRC_1066B`).
- Compute `is_download` (file request + GET + 2xx + non-zero response bytes) and a generic `request_outcome`
  (`success`/`redirect`/`client_error`/`server_error`) for dashboarding.
- Per-record failures are caught and returned to Firehose as `ProcessingFailed` (with the original data intact)
  rather than failing the whole batch; structured JSON is printed to stdout/CloudWatch Logs for both successes
  and failures.

There is currently no automated test coverage for this file (no `terraform/lambda/test_*.py` or equivalent) —
changes to field parsing or classification logic should be manually verified against sample CloudFront
real-time log lines before deploying, since a field-order mismatch with `locals.tf` silently corrupts every
downstream document.

### Extension list maintenance

`DATA_EXTENSIONS`, `METADATA_EXTENSIONS`, and `STATIC_EXTENSIONS` in the Lambda drive `request_type` and
`is_download` classification and are PDS-domain-specific (e.g. `img`, `fits`, `lbl`, `tab`). When adding a new
file type to the distribution, extend the appropriate set (and `COMPOUND_EXTENSIONS` if it has a multi-part
suffix like `.tar.gz`) rather than special-casing it elsewhere.
