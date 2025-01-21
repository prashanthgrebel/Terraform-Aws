
#AWS S3 bucket Terraform module

Terraform module which creates S3 bucket on AWS with all (or almost all) features provided by Terraform AWS provider.

These features of S3 bucket configurations are supported:

- access logging
- versioning
- CORS
- lifecycle rules
- server-side encryption
- Cross-Region Replication (CRR)
- static web-site hosting

## Usage

### Private bucket with versioning enabled

```hcl
module "s3_bucket" {
  source = "

  bucket = "my-s3-bucket"

  control_object_ownership = true

  versioning = {
    enabled = true
  }
}
```

### Complete example
```hcl
resource "aws_iam_role" "this" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
    ]
  }
}

module "log_bucket" {
  source =""

  bucket        = "logs-${random_pet.this.id}"
  force_destroy = true

  control_object_ownership = true

  attach_access_log_delivery_policy     = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  access_log_delivery_policy_source_accounts = [data.aws_caller_identity.current.account_id]
  access_log_delivery_policy_source_buckets  = ["arn:aws:s3:::${local.bucket_name}"]
}

module "s3_bucket" {
  source = ""

  bucket = local.bucket_name

  force_destroy       = true
  acceleration_status = "Suspended"
  request_payer       = "BucketOwner"

  tags = {
    Owner = "Anton"
  }

  # Note: Object Lock configuration can be enabled only on new buckets
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration
  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode = "GOVERNANCE"
        days = 1
      }
    }
  }

  # Bucket policies
  attach_policy                            = true
  policy                                   = data.aws_iam_policy_document.bucket_policy.json
  attach_deny_insecure_transport_policy    = true
  attach_require_latest_tls_policy         = true
  attach_deny_incorrect_encryption_headers = true
  attach_deny_incorrect_kms_key_sse        = true
  allowed_kms_key_arn                      = aws_kms_key.objects.arn
  attach_deny_unencrypted_object_uploads   = true

  # S3 bucket-level Public Access Block configuration (by default now AWS has made this default as true for S3 bucket-level block public access)
  # block_public_acls       = true
  # block_public_policy     = true
  # ignore_public_acls      = true
  # restrict_public_buckets = true

  # S3 Bucket Ownership Controls
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  expected_bucket_owner = data.aws_caller_identity.current.account_id

  acl = "private" # "acl" conflicts with "grant" and "owner"

  logging = {
    target_bucket = module.log_bucket.s3_bucket_id
    target_prefix = "log/"
  }

  website = {
    # conflicts with "error_document"
    #        redirect_all_requests_to = {
    #          host_name = "https://modules.tf"
    #        }

    index_document = "index.html"
    error_document = "error.html"
    routing_rules = [{
      condition = {
        key_prefix_equals = "docs/"
      },
      redirect = {
        replace_key_prefix_with = "documents/"
      }
      }, {
      condition = {
        http_error_code_returned_equals = 404
        key_prefix_equals               = "archive/"
      },
      redirect = {
        host_name          = "archive.myhost.com"
        http_redirect_code = 301
        protocol           = "https"
        replace_key_with   = "not_found.html"
      }
    }]
  }

  versioning = {
    status     = true
    mfa_delete = false
  }



  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.objects.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  cors_rule = [
    {
      allowed_methods = ["PUT", "POST"]
      allowed_origins = ["https://modules.tf", "https://terraform-aws-modules.modules.tf"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
      }, {
      allowed_methods = ["PUT"]
      allowed_origins = ["https://example.com"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]

  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      filter = {
        tags = {
          some    = "value"
          another = "value2"
        }
      }

      transition = [
        {
          days          = 30
          storage_class = "ONEZONE_IA"
          }, {
          days          = 60
          storage_class = "GLACIER"
        }
      ]

      #        expiration = {
      #          days = 90
      #          expired_object_delete_marker = true
      #        }

      #        noncurrent_version_expiration = {
      #          newer_noncurrent_versions = 5
      #          days = 30
      #        }
    },
    {
      id                                     = "log1"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
      ]

      noncurrent_version_expiration = {
        days = 300
      }
    },
    {
      id      = "log2"
      enabled = true

      filter = {
        prefix                   = "log1/"
        object_size_greater_than = 200000
        object_size_less_than    = 500000
        tags = {
          some    = "value"
          another = "value2"
        }
      }

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
      ]

      noncurrent_version_expiration = {
        days = 300
      }
    },
  ]

  metric_configuration = [
    {
      name = "documents"
      filter = {
        prefix = "documents/"
        tags = {
          priority = "high"
        }
      }
    },
    {
      name = "other"
      filter = {
        tags = {
          production = "true"
        }
      }
    },
    {
      name = "all"
    }
  ]
}
```

## Inputs
| Name                                  | Description                                                                                                                    | Type             | Default       | Required |
|---------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|------------------|---------------|----------|
| create_bucket                         | Controls if S3 bucket should be created                                                                                        | bool             | true          | No       |
| attach_access_log_delivery_policy     | Controls if S3 bucket should have S3 access log delivery policy attached                                                     | bool             | false         | No       |
| attach_deny_insecure_transport_policy | Controls if S3 bucket should have deny non-SSL transport policy attached                                                    | bool             | false         | No       |
| attach_require_latest_tls_policy      | Controls if S3 bucket should require the latest version of TLS                                                               | bool             | false         | No       |
|                                       | Controls if S3 bucket should have bucket policy attached (set to `true` to use value of `policy` as bucket policy)            | bool             | false         | No       |
| attach_public_policy                 | Controls if a user-defined public bucket policy will be attached (set to `false` to allow upstream to apply defaults to the bucket) | bool             | false         | No       |
| attach_deny_incorrect_encryption_headers | Controls if S3 bucket should deny incorrect encryption headers policy attached                                           | bool             | false         | No       |
| attach_deny_incorrect_kms_key_sse     | Controls if S3 bucket policy should deny usage of incorrect KMS key SSE                                                     | bool             | false         | No       |
| allowed_kms_key_arn                  | The ARN of KMS key which should be allowed in PutObject                                                                        | string           | null          | No       |
| attach_deny_unencrypted_object_uploads | Controls if S3 bucket should deny unencrypted object uploads policy attached                                               | bool             | false         | No       |
| bucket                                | (Optional, Forces new resource) The name of the bucket. If omitted, Terraform will assign a random, unique name.               | string           | null          | No       |
| bucket_prefix                         | (Optional, Forces new resource) Creates a unique bucket name beginning with the specified prefix. Conflicts with bucket.        | string           | null          | No       |
| acl                                   | (Optional) The canned ACL to apply. Conflicts with `grant`                                                                     | string           | null       | No       |
| policy                                | (Optional) A valid bucket policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy. For more information about building AWS IAM policy documents with Terraform, see the AWS IAM Policy Document Guide. | string           | null          | No       |
| tags                                  | (Optional) A mapping of tags to assign to the bucket.                                                                          | map(string)      | {}            | No       |
| force_destroy                         | (Optional, Default:false ) A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | bool             | false         | No       |
| cors_rule                             | List of maps containing rules for Cross-Origin Resource Sharing.                                                             | any              | []            | No       |
| versioning                            | Map containing versioning configuration.                                                                                       | map(string)      | {}            | No       |
| logging                               | Map containing access bucket logging configuration.                                                                            | map(string)      | {}            | No       |
| access_log_delivery_policy_source_buckets | (Optional) List of S3 bucket ARNs which should be allowed to deliver access logs to this bucket.                              | list(string)     | []            | No       |
| access_log_delivery_policy_source_accounts | (Optional) List of AWS Account IDs should be allowed to deliver access logs to this bucket.                                  | list(string)     | []            | No       |
| grant                                 | An ACL policy grant. Conflicts with `acl`                                                                                       | any              | []            | No       |
| owner                                 | Bucket owner's display name and ID. Conflicts with `acl`                                                                        | map(string)      | {}            | No       |
| expected_bucket_owner                 | The account ID of the expected bucket owner                                                                                    | string           | null          | No       |
| lifecycle_rule                        | List of maps containing configuration of object lifecycle management.                                                         | any              | [{...}]       | No       |
| replication_configuration            | Map containing cross-region replication configuration.                                                                         | any              | {}            | No       |
| server_side_encryption_configuration | Map containing server-side encryption configuration.                                                                           | any              | {}            | No       |
| object_lock_configuration             | Map containing S3 object locking configuration.                                                                                 | any              | {}            | No       |
| metric_configuration                  | Map containing bucket metric configuration.                                                                                    | any              | []            | No       |
| object_lock_enabled                   | Whether S3 bucket should have an Object Lock configuration enabled.                                                            | bool             | false         | No       |
| block_public_acls                     | Whether Amazon S3 should block public ACLs for this bucket.                                                                    | bool             | true          | No       |
| block_public_policy                   | Whether Amazon S3 should block public bucket policies for this bucket.                                                        | bool             | true          | No       |
| ignore_public_acls                    | Whether Amazon S3 should ignore public ACLs for this bucket.                                                                   | bool             | true          | No       |
| restrict_public_buckets               | Whether Amazon S3 should restrict public bucket policies for this bucket.                                                     | bool             | true          | No       |
| control_object_ownership              | Whether to manage S3 Bucket Ownership Controls on this bucket.                                                                 | bool             | false         | No       |
| object_ownership                      | Object ownership. Valid values: BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter. 'BucketOwnerEnforced': ACLs are disabled, and the bucket owner automatically owns and has full control over every object in the bucket. 'BucketOwnerPreferred': Objects uploaded to the bucket change ownership to the bucket owner if the objects are uploaded with the bucket-owner-full-control canned ACL. 'ObjectWriter': The uploading account will own the object if the object is uploaded with the bucket-owner-full-control canned ACL. | string           | BucketOwnerEnforced | No       |
| website | Map containing static web-site hosting or redirect configuration. | `any` | `{}` | no |

## Outputs

| Name                                | Value                                                      | Description                                                       |
|-------------------------------------|------------------------------------------------------------|-------------------------------------------------------------------|
| s3_bucket_id                        | `aws_s3_bucket_policy.this[0].id`, `aws_s3_bucket.this[0].id`, or empty string | The name of the bucket.                                           |
| s3_bucket_arn                       | `aws_s3_bucket.this[0].arn`                               | The ARN of the bucket. Will be of format `arn:aws:s3:::bucketname`. |
| s3_bucket_bucket_domain_name        | `aws_s3_bucket.this[0].bucket_domain_name`                | The bucket domain name. Will be of format `bucketname.s3.amazonaws.com`. |
| s3_bucket_bucket_regional_domain_name | `aws_s3_bucket.this[0].bucket_regional_domain_name`        | The bucket region-specific domain name. The bucket domain name including the region name, please refer here for format. Note: The AWS CloudFront allows specifying S3 region-specific endpoint when creating S3 origin, it will prevent redirect issues from CloudFront to S3 Origin URL. |
| s3_bucket_hosted_zone_id            | `aws_s3_bucket.this[0].hosted_zone_id`                     | The Route 53 Hosted Zone ID for this bucket's region.              |
| s3_bucket_lifecycle_configuration_rules | `aws_s3_bucket_lifecycle_configuration.this[0].rule`   | The lifecycle rules of the bucket, if the bucket is configured with lifecycle rules. If not, this will be an empty string. |
| s3_bucket_policy                    | `aws_s3_bucket_policy.this[0].policy`                      | The policy of the bucket, if the bucket is configured with a policy. If not, this will be an empty string. |
| s3_bucket_region                    | `aws_s3_bucket.this[0].region`                            | The AWS region this bucket resides in.                            |
|s3_bucket_website_domain | `aws_s3_bucket_website_configuration.this[0].website_domain, ""` |The domain of the website endpoint, if the bucket is configured with a website. If not, this will be an empty string. This is used to create Route 53 alias records. |
| s3_bucket_website_endpoint | `aws_s3_bucket_website_configuration.this[0].website_endpoint, ""` | The website endpoint, if the bucket is configured with a website. If not, this will be an empty string. | 
