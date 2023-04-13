#!/bin/sh

set -ex

mkdir $HOME/.terraform.d/plugin-cache || true
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

terraform -chdir=terraform init --reconfigure --input=false  \
 -backend-config="bucket=${TFSTATE_BUCKET}" \
 -backend-config="key=${TFSTATE_KEY}" \
 -backend-config="region=${TFSTATE_REGION}"
terraform -chdir=terraform plan --destroy --input=false
terraform -chdir=terraform destroy --auto-approve --input=false