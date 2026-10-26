output "bucket_name" {
  value = aws_s3_bucket.tfstate.bucket
}

output "region" {
  value = "eu-north-1"
}