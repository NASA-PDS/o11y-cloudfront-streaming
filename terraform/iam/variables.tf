variable "aws_region" {
  description = "AWS region used by the provider and for computing service ARNs."
  type        = string
  default     = "us-west-2"
}

variable "env" {
  description = "Deployment env. Used to derive the existing OpenSearch domain name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.env)
    error_message = "env must be one of: dev, test, prod."
  }
}

variable "tenant" {
  description = "Tenant tag."
  type        = string
  default     = "en"
}

variable "venue" {
  description = "Venue tag."
  type        = string
  default     = "pds-cds-dev"
}

variable "component" {
  description = "Component tag. Matches the GitHub repository name."
  type        = string
  default     = "o11y-cloudfront-streaming"
}

variable "cicd" {
  description = "CI/CD tag."
  type        = string
  default     = "iac"
}

variable "managedby" {
  description = "Managing organization or team tag (e.g. team email distribution list)."
  type        = string
}

variable "kinesis_kms_key_arn" {
  description = "ARN of the AWS managed key alias/aws/kinesis (the key that encrypts the Kinesis stream). When null, the key is looked up by alias in the account and region."
  type        = string
  default     = null

  validation {
    condition     = var.kinesis_kms_key_arn == null || can(regex("^arn:[a-z-]+:kms:[a-z0-9-]+:[0-9]{12}:key/[0-9a-zA-Z-]+$", var.kinesis_kms_key_arn))
    error_message = "kinesis_kms_key_arn must be null or a KMS key ARN (arn:<partition>:kms:<region>:<account-id>:key/<key-id>)."
  }
}

variable "pds_logs_firehose_prefix" {
  description = "S3 prefix within the pds-logs-<env> bucket where Firehose backup records are written."
  type        = string
  default     = "pdc-cds-infra/cloudfront/realtime/firehose"
}
