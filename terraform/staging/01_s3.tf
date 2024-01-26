resource "aws_kms_key" "example_s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "example_s3_bucket" {
  bucket = "jiham-k-test"
}

resource "aws_s3_bucket_versioning" "example_s3_versioning" {
  bucket = aws_s3_bucket.example_s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "example_s3_ownership" {
  bucket = aws_s3_bucket.example_s3_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example_s3_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.example_s3_ownership]

  bucket = aws_s3_bucket.example_s3_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example_s3_sse" {
  bucket = aws_s3_bucket.example_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.example_s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "example_s3_lifecycle" {
  bucket = aws_s3_bucket.example_s3_bucket.id

  rule {
    id = "rule-1"
    expiration {
      days = 90
    }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    status = "Enabled"
  }
}