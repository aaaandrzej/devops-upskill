#!/bin/sh

set -ex

terraform -chdir=terraform init --reconfigure --input=false  \
 -backend-config="bucket=${TFSTATE_BUCKET}" \
 -backend-config="key=${TFSTATE_KEY}" \
 -backend-config="region=${TFSTATE_REGION}"
terraform -chdir=terraform plan --input=false
terraform -chdir=terraform apply --auto-approve --input=false