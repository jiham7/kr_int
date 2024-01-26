resource "aws_iam_role" "athena_role" {
  name = "AthenaSuperSetRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "athena.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_policy" "athena_s3_policy" {
  name        = "AthenaS3AccessPolicy"
  description = "Policy for Athena to access S3 Bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ],
        Effect   = "Allow",
        Resource = [
          aws_s3_bucket.example_s3_bucket.arn,
          "${aws_s3_bucket.example_s3_bucket.arn}/*",
        ],
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "attach_athena_s3" {
  role       = aws_iam_role.athena_role.name
  policy_arn = aws_iam_policy.athena_s3_policy.arn
}
