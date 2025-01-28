
resource "random_id" "random_bucket_name" {
  keepers = {
    "key" = var.bucket_name
  }

  byte_length = 8
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.bucket_name}-${random_id.random_bucket_name.hex}"

  tags = {
    Name        = "DevOps"
    Environment = "DevOps"
    Project     = "Desafio-1"
    ManagedBy   = "Terraform"
  }
}


resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}