variable "aws_region" {
  description = "AWS region used by the provider and regional resources."
  type        = string
  default     = "us-west-2"
}

variable "node" {
  description = "PDS node abbreviation, using lowercase letters only, such as en, img, or sbn."
  type        = string
  default     = "en"

  validation {
    condition     = can(regex("^[a-z]+$", var.node))
    error_message = "node must contain lowercase letters only (a-z)."
  }
}

variable "env" {
  description = "Deployment env."
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
  description = "Managing organization or team tag."
  type        = string
  default     = "viviant@jpl.caltech.edu"
}

variable "vpc_id" {
  description = "ID of the existing VPC containing the private subnets and OpenSearch domain."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID beginning with vpc-."
  }
}

variable "private_subnet_ids" {
  description = "IDs of the existing private subnets Firehose will use for its VPC ENIs."
  type        = list(string)

  validation {
    condition = (
      length(var.private_subnet_ids) > 0 &&
      alltrue([for subnet_id in var.private_subnet_ids : can(regex("^subnet-[0-9a-f]+$", subnet_id))])
    )
    error_message = "private_subnet_ids must contain at least one valid subnet ID beginning with subnet-."
  }
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