resource "aws_s3_object" "lottery_csv" {
  bucket = aws_s3_bucket.example_s3_bucket.id
  key    = "example_file.csv"
  source = "../../data/Lottery_Mega_Millions_Winning_Numbers__Beginning_2002.csv"

  etag   = filemd5("../../data/Lottery_Mega_Millions_Winning_Numbers__Beginning_2002.csv")
}