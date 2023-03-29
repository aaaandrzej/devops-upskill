#!/bin/sh

set -ex

terraform --chdir=terraform init --reconfigure --input=false
terraform --chdir=terraform plan --destroy --input=false
terraform --chdir=terraform destroy --auto-approve --input=false