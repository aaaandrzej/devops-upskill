variable "region" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "cidr_blocks" {
  type = map(list(string))
  default = {
    public  = ["10.0.0.0/24", "10.0.1.0/24"]
    private = ["10.0.16.0/20", "10.0.32.0/20"]
  }
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
