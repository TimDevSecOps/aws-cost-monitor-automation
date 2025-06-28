#!/bin/bash
set -euo pipefail

[ ! -d log ] && mkdir -p log

TF_LOG=DEBUG TF_LOG_PATH=log/init.log  terraform init
TF_LOG=DEBUG TF_LOG_PATH=log/plan.log  terraform plan -out=tfplay.binary
TF_LOG=DEBUG TF_LOG_PATH=log/apply.log terraform apply tfplay.binary

#TF_LOG=DEBUG TF_LOG_PATH=log/destroy.log terraform destroy
