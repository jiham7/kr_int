resource "aws_iam_user" "example_user" {
  name = "example-user"
}

resource "aws_iam_policy" "assume_role_policy" {
  name        = "assume_athena_role_policy"
  description = "A test policy that allows a user to assume a role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Resource = aws_iam_role.athena_role.arn
      },
    ],
  })
}

resource "aws_iam_user_policy_attachment" "test_attach" {
  user       = aws_iam_user.example_user.name
  policy_arn = aws_iam_policy.assume_role_policy.arn
}

resource "aws_iam_access_key" "user_key" {
  user = aws_iam_user.example_user.name
}