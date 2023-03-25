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