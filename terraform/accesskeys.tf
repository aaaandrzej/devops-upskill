resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "${var.owner}-keypair"
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" {
    command = "chmod 600 ${var.owner}-keypair.pem || true && echo '${tls_private_key.pk.private_key_pem}' > ./${var.owner}-keypair.pem && chmod 400 ${var.owner}-keypair.pem"
  }
}