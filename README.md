# cf-realtime-monitor

AWS infrastructure that captures CloudFront real-time access logs for PDS data-node
distributions, transforms them, and delivers them to OpenSearch for monitoring/analytics.

The real content of this repo is the Terraform package under [`terraform/`](./terraform/README.md)
— see its README for architecture, deploy, and destroy instructions. IAM roles live in their own
standalone [`terraform/iam/`](./terraform/iam/README.md) root module.

This repo was created from NASA-PDS's `template-repo-python` template; the `src/pds/` and
`tests/pds/` directories are unmodified template scaffolding, not part of the actual deliverable.

```
CloudFront (existing distribution, /data* and /data/store/img* cache behaviors)
  -> aws_cloudfront_realtime_log_config
  -> Kinesis Data Stream
  -> Firehose delivery stream
       -> Lambda transform
       -> OpenSearch domain (existing)
       -> S3 backup (existing pds-logs-<env> bucket)
```
