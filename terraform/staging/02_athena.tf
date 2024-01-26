resource "aws_athena_database" "lottery_database" {
  name   = "lottery_database"
  bucket = aws_s3_bucket.example_s3_bucket.bucket
}

resource "aws_athena_named_query" "create_lottery_table" {
  name     = "create_lottery_table"
  database = aws_athena_database.lottery_database.name
  query    = <<-EOF
    CREATE EXTERNAL TABLE IF NOT EXISTS lottery_table (
      draw_date string,
      winning_numbers string,
      mega_ball string,
      multiplier string
    )
    ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY ',' 
    LINES TERMINATED BY '\n' 
    STORED AS TEXTFILE
    LOCATION 's3://${aws_s3_bucket.example_s3_bucket.bucket}/';
    EOF
}

resource "aws_iam_policy" "athena_s3_access" {
  name        = "athena_s3_access"
  description = "Policy for Athena to access S3 data"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:*"
        ],
        Resource = [
          aws_s3_bucket.example_s3_bucket.arn,
          "${aws_s3_bucket.example_s3_bucket.arn}/*"
        ],
      },
    ],
  })
}

