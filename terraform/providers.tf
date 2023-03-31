terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
  backend "s3" {
    bucket = "aszulc-tfstate"
    key    = "dev.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.region
}
