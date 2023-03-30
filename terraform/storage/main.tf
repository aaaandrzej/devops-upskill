resource "random_pet" "random_pet" {
  length = 2
}

resource "aws_s3_bucket" "main" {
  bucket        = "${var.owner}-s3-${random_pet.random_pet.id}"
  force_destroy = true
  tags = {
    Name  = "${var.owner}-s3-${random_pet.random_pet.id}"
    Owner = var.owner
  }
}

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}