#!/usr/bin/env bash
# SBLOCCO FASE 4 — la pipeline intera: Sorgente -> Build -> Deploy.
set -euo pipefail

AWS="aws --endpoint-url=http://localhost:4566"
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""

echo "[1/4] mi assicuro che esista il bucket di destinazione (Fase 2)"
$AWS cloudformation deploy --stack-name bacheca \
  --template-file infra/01-sito.yaml \
  --parameter-overrides NomeBucket=bacheca-cfn >/dev/null

echo "[2/4] progetto CodeBuild in versione 'dentro la pipeline'"
$AWS codebuild create-project --cli-input-json file://infra/codebuild-progetto-pipeline.json >/dev/null 2>&1 \
  || $AWS codebuild update-project --cli-input-json file://infra/codebuild-progetto-pipeline.json >/dev/null

echo "[3/4] carico il sorgente"
rm -f sorgente.zip
zip -q -r sorgente.zip sito build.sh test.sh buildspec.yml
$AWS s3 cp sorgente.zip s3://bacheca-sorgente/sorgente.zip

echo "[4/4] creo la pipeline (parte da sola appena creata)"
$AWS codepipeline delete-pipeline --name bacheca-pipeline 2>/dev/null || true
$AWS codepipeline create-pipeline --pipeline file://infra/pipeline.json >/dev/null

echo ""
echo "Guarda cosa sta facendo:"
echo "  aws --endpoint-url=http://localhost:4566 codepipeline list-action-executions \\"
echo "      --pipeline-name bacheca-pipeline --output table"
