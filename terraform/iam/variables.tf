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
  default     = "terraform"
}

variable "managedby" {
  description = "Managing organization or team tag."
  type        = string
  default     = "viviant@jpl.caltech.edu"
}

variable "pds_logs_bucket_arn" {
  description = "ARN of the pre-existing pds-logs-<env> S3 bucket where Firehose backup records are written."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[^:]*:s3:::", var.pds_logs_bucket_arn))
    error_message = "pds_logs_bucket_arn must be a valid S3 bucket ARN."
  }
}

variable "pds_logs_firehose_prefix" {
  description = "S3 prefix within pds_logs_bucket_arn where Firehose backup records are written."
  type        = string
  default     = "pdc-cds-infra/cloudfront/realtime/firehose"
}
