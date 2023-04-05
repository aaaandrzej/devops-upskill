#!/bin/sh

set -ex

terraform -chdir=terraform init --reconfigure --input=false  \
 -backend-config="bucket=${TFSTATE_BUCKET}" \
 -backend-config="key=${TFSTATE_KEY}" \
 -backend-config="region=${TFSTATE_REGION}"
terraform -chdir=terraform plan --destroy --input=false
terraform -chdir=terraform destroy --auto-approve --input=false