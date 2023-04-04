variable "region" {
  type    = string
  default = "us-west-2"
}

variable "owner" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type = string
}

variable "instance_size" {
  type    = string
  default = "t2.micro"
}
