variable "instance_size" {
  type = string
  validation {
    condition     = length(var.instance_size) > 4 && startswith(var.instance_size, "t")
    error_message = "The instance_size value must be at least 4 characters long and start with t."
  }
}
variable "key_name" {}
variable "app_sg" {}
variable "app_name" {}
variable "iam_instance_profile" {}
variable "user_data" {}
variable "desired_capacity" { type = number }
variable "max_size" { type = number }
variable "min_size" { type = number }
variable "app_dependency" {}
variable "subnets" {}
variable "tg_arn" {}
variable "owner" {}
