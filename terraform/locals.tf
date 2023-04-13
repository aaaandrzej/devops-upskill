locals {
  az_count = length(data.aws_availability_zones.main.names)
}