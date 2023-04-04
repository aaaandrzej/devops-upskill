output "ec2_ami_id" {
  value = data.aws_ami.ubuntu.id
}