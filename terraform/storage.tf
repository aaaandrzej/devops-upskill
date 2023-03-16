resource "aws_s3_bucket" "main" {
  bucket = "${var.owner}-s3-${random_pet.random_pet.id}"
  tags = {
    Name  = "${var.owner}-s3-${random_pet.random_pet.id}"
    Owner = var.owner
  }
}

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}