variable "region" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "cidr_blocks" {
  type = map(list(string))
}

variable "scope" {
  type = map(string)
  default = {
    public  = "public",
    private = "private"
  }
}

variable "owner" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_port" {
  type = number
}

variable "db_name" {
  type = string
}

locals {
  az_count = length(var.availability_zones)
}