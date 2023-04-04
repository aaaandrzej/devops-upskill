resource "aws_key_pair" "kp" {
  key_name   = "${var.owner}-keypair"
  public_key = var.public_key
}