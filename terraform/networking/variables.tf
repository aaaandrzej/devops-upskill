variable "owner" {}
variable "region" {}
variable "availability_zones" {}
variable "vpc_cidr_block" {
  type = string
  default = "10.0.0.0/16"
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