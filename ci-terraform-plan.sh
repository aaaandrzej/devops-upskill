#!/bin/sh

set -ex

terraform -chdir=terraform init --reconfigure --input=false
terraform -chdir=terraform plan --input=false