# ===========================
# Define AWS Providers
# ===========================
provider "aws" {
  region = "eu-west-1" # Origin region (Ireland)
}

provider "aws" {
  alias  = "replica"
  region = "eu-central-1" # Replica region (Frankfurt)
}

# Fetch AWS Account ID
data "aws_caller_identity" "current" {}

# Generate random names for S3 buckets
resource "random_pet" "this" {
  length = 2
}

locals {
  origin_bucket_name  = "origin-bucket-${random_pet.this.id}"
  replica_bucket_name = "replica-bucket-${random_pet.this.id}"
}

# ===========================
# Replica Bucket (Frankfurt)
# ===========================
resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = local.replica_bucket_name
}

resource "aws_s3_bucket_versioning" "replica_versioning" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ===========================
# Origin Bucket (Ireland)
# ===========================
resource "aws_s3_bucket" "origin" {
  bucket = local.origin_bucket_name
}

resource "aws_s3_bucket_versioning" "origin_versioning" {
  bucket = aws_s3_bucket.origin.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ===========================
# IAM Role & Policy for Replication
# ===========================
resource "aws_iam_role" "replication" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "replication" {
  name = "s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetReplicationConfiguration"
        ],
        Resource = aws_s3_bucket.origin.arn
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ],
        Resource = "${aws_s3_bucket.origin.arn}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        Resource = "${aws_s3_bucket.replica.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# ===========================
# KMS Key (Replica Region)
# ===========================
resource "aws_kms_key" "replica" {
  provider                = aws.replica
  description             = "S3 Replica Bucket KMS Key"
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "s3-replication-key",
    Statement = [
      {
        Sid    = "AllowS3Replication",
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ],
        Resource = "*"
      },
      {
        Sid    = "EnableReplicationRole",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.replication.arn
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ],
        Resource = "*"
      },
      # allow full accesss
      {
        Sid    = "AllowRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      }
    ]
  })
}

# Attach KMS Policy to Replication IAM Role
resource "aws_iam_policy" "kms_replication" {
  name = "kms-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ],
        Effect   = "Allow",
        Resource = aws_kms_key.replica.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kms_replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.kms_replication.arn
}

# ===========================
# Replication Configuration
# ===========================
resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.origin.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replication-rule"
    status = "Enabled"

    delete_marker_replication {
      status = "Disabled"
    }

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.replica.arn
      }
    }

    filter {
      prefix = "" # Replicate all objects
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        # Enabled = true
        status = "Enabled"
      }
    }
  }
}
