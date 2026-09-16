#!/usr/bin/env bash
# SBLOCCO FASE 1 — fa in automatico quello che nella Fase 1 digiti a mano.
# Usalo solo se sei rimasto indietro: la fase serve proprio a digitarla.
set -euo pipefail

AWS="aws --endpoint-url=http://localhost:4566"
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""

echo "[1/4] creo il bucket"
$AWS s3 mb s3://bacheca-its || true

echo "[2/4] lo accendo come sito web"
$AWS s3 website s3://bacheca-its --index-document index.html

echo "[3/4] build"
bash build.sh

echo "[4/4] carico dist/ nel bucket"
$AWS s3 sync dist/ s3://bacheca-its --delete

echo ""
echo "Fatto. Controlla con:"
echo "  aws --endpoint-url=http://localhost:4566 s3 ls s3://bacheca-its"
echo "  aws --endpoint-url=http://localhost:4566 s3 cp s3://bacheca-its/index.html -"
echo "  ./scripts/90-anteprima.sh bacheca-its      <- per vederlo nel browser"
