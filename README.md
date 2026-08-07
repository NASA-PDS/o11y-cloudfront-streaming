# cf-realtime-monitor

AWS infrastructure that captures CloudFront real-time access logs for PDS data-node
distributions, transforms them, and delivers them to OpenSearch for monitoring/analytics.

The real content of this repo is the Terraform package under [`terraform/`](./terraform/README.md)
— see its README for the technical architecture, deploy, and destroy instructions. IAM roles live
in their own standalone [`terraform/iam/`](./terraform/iam/README.md) root module.

This repo was created from NASA-PDS's `template-repo-python` template; the `src/pds/` and
`tests/pds/` directories are unmodified template scaffolding, not part of the actual deliverable.

## Architecture

```mermaid
flowchart LR
    CF["CloudFront Distribution\n(existing, owned by pdc-cds-infra)"]

    subgraph repo["cf-realtime-monitor"]
        RLC["Realtime Log Config"]
        KIN["Kinesis Data Stream"]
        FH["Firehose Delivery Stream"]
        LAM["Lambda Transform"]
        FHSG["Firehose Security Group"]

        subgraph iam["iam/ (own state)"]
            IAMR["3 IAM roles"]
        end
    end

    VPC["VPC / Private Subnets\n(existing)"]
    OS["OpenSearch Domain\n(pdc-observability, existing)"]
    S3["pds-logs-&lt;env&gt; S3 Bucket\n(pdc-cds-infra, existing)"]

    CF -->|"real-time log stream"| RLC
    RLC --> KIN
    KIN --> FH
    FH -->|"invoke"| LAM
    LAM -->|"transformed record"| FH
    FH -->|"HTTPS 443, SG ingress rule"| OS
    FH -->|"GZIP backup, AllDocuments"| S3
    FH -.->|"VPC ENIs"| VPC
    IAMR -.->|"role ARNs via SSM"| RLC
    IAMR -.->|"role ARNs via SSM"| FH
    IAMR -.->|"role ARN via SSM"| LAM
```

This repo creates the log-capture pipeline; it does **not** own the CloudFront distribution, the
OpenSearch domain, the VPC/subnets, or the S3 backup bucket — those are existing resources looked
up via `data` sources or passed in as variables. See
[`terraform/README.md`](./terraform/README.md#deployment-architecture) for the cross-repo
deployment order and the full technical architecture.
