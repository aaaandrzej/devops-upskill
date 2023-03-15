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

locals {
  az_count = length(var.availability_zones)
}