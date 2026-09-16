#!/usr/bin/env bash
# SBLOCCO FASE 2 — lo stesso bucket, ma dichiarato in CloudFormation.
set -euo pipefail

AWS="aws --endpoint-url=http://localhost:4566"
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""

echo "[1/3] deploy dello stack 'bacheca'"
$AWS cloudformation deploy \
  --stack-name bacheca \
  --template-file infra/01-sito.yaml \
  --parameter-overrides NomeBucket=bacheca-cfn

echo "[2/3] output dello stack"
$AWS cloudformation describe-stacks --stack-name bacheca \
  --query 'Stacks[0].Outputs' --output table

echo "[3/3] pubblico dist/ nel bucket creato dallo stack"
bash build.sh
$AWS s3 sync dist/ s3://bacheca-cfn --delete

echo ""
echo "Fatto.  ./scripts/90-anteprima.sh bacheca-cfn"
