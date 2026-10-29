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

Two root modules, each with its own state: `terraform/iam/` (execution roles, deploy first) and
`terraform/` (Kinesis, Firehose, Lambda). The CloudFront realtime log config is created by
`pdc-cds-infra/cloudfront/pds-main`, not here. Operational deploys use Terragrunt from
`cds-infra-deploy` (see the o11y-platform deployment runbook). For local iteration,
[Task](https://taskfile.dev) via `terraform/Taskfile.yaml` provides namespaced `iam:*` / `streaming:*`
tasks wrapping `terraform init/plan/apply` with the right `-backend-config` / `-var-file` per
venue. All commands run from the `terraform/` directory.

The tasks read this repo's own gitignored tfvars (`iam/tfvars/<venue>.tfvars` and
`tfvars/<venue>.tfvars`), copied from the `.tfvars.example` files, and gitignored S3 backend files
(`iam/backend-<venue>.hcl` and `backend-<venue>.hcl`); `terraform/README.md` shows how to write them.

```bash
cd terraform

task iam:deploy       VENUE=dev   # deploy first — main module reads role ARNs from SSM
task streaming:deploy VENUE=dev
```

Destroy (does not touch the OpenSearch domain, VPC, subnets, or pre-existing OpenSearch security group — only
the resources this package created):

```bash
task streaming:destroy VENUE=dev   # destroy the pipeline before the roles it uses
task iam:destroy       VENUE=dev
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
  -> aws_cloudfront_realtime_log_config (created by pdc-cds-infra pds-main; 100% sampling, 17 fields)
  -> Kinesis Data Stream (on-demand, 90-day retention)
  -> Firehose delivery stream (destination: opensearch)
       -> Lambda transform (terraform/lambda/lambda_function.py), invoked inline via Firehose
            processing_configuration before OpenSearch delivery
       -> OpenSearch domain (existing, data-sourced by name pds-<env>-o11y;
            index pds-o11y-cloudfront-streaming-index-YYYY-MM-DD, daily rotation)
       -> S3 backup (existing pds-logs-<env> bucket, GZIP, AllDocuments mode)
```

What this repo creates and what it does not own: see [README.md](README.md) and
[terraform/README.md](terraform/README.md). The OpenSearch domain is looked up by name, the bucket ARN is read
from SSM, and `vpc_id` / `private_subnet_ids` are variables. `pdc-cds-infra/cloudfront/pds-main` (flag
`enable_o11y_streaming`) creates the real-time log config and attaches it to the cache behaviors.

Resource and role names and SSM parameter paths are static literals in `terraform/locals.tf` and
`terraform/iam/locals.tf` (that is what lets `iam/` compute ARNs); only the OpenSearch domain name is derived
from `var.env` (dev/test/prod). Per-venue variable values are tracked in `cds-infra-deploy` at
`venues/<venue>/o11y-cloudfront-streaming/{iam,streaming}/terragrunt.hcl` (this repo keeps only `.example`
templates plus gitignored local copies for Task iteration; see Commands above).

### Lambda transform (`terraform/lambda/lambda_function.py`)

Single-file, dependency-free (stdlib only) Firehose transformation Lambda — packaged by Terraform via
`archive_file` (no build step, no `requirements.txt`). Responsibilities:

- Decode/parse tab-delimited CloudFront real-time log records. `FIELDS` in this file **must stay in sync** (same
  fields, same order) with `o11y_streaming_log_fields` in pdc-cds-infra `cloudfront/pds-main/locals.tf`, which
  creates the log config — CloudFront's real-time log config sends fields positionally, not by name.
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
real-time log lines before deploying, since a field-order mismatch with `pds-main` silently corrupts every
downstream document.

### Extension list maintenance

`DATA_EXTENSIONS`, `METADATA_EXTENSIONS`, and `STATIC_EXTENSIONS` in the Lambda drive `request_type` and
`is_download` classification and are PDS-domain-specific (e.g. `img`, `fits`, `lbl`, `tab`). When adding a new
file type to the distribution, extend the appropriate set (and `COMPOUND_EXTENSIONS` if it has a multi-part
suffix like `.tar.gz`) rather than special-casing it elsewhere.
