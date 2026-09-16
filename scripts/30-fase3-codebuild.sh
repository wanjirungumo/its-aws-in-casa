#!/usr/bin/env bash
# SBLOCCO FASE 3 — build isolata con CodeBuild (serve il piano studente).
set -euo pipefail

AWS="aws --endpoint-url=http://localhost:4566"
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""

echo "[1/5] bucket di sorgente e artefatti"
$AWS s3 mb s3://bacheca-sorgente  || true
$AWS s3 mb s3://bacheca-artefatti || true
$AWS s3api put-bucket-versioning --bucket bacheca-sorgente \
  --versioning-configuration Status=Enabled

echo "[2/5] ruolo di servizio"
$AWS iam create-role --role-name ruolo-pipeline \
  --assume-role-policy-document file://infra/ruolo-fiducia.json >/dev/null 2>&1 || true
$AWS iam put-role-policy --role-name ruolo-pipeline \
  --policy-name permessi-pipeline \
  --policy-document file://infra/ruolo-permessi.json >/dev/null

echo "[3/5] preparo lo zip del sorgente"
rm -f sorgente.zip
zip -q -r sorgente.zip sito build.sh test.sh buildspec.yml
$AWS s3 cp sorgente.zip s3://bacheca-sorgente/sorgente.zip

echo "[4/5] creo il progetto CodeBuild"
$AWS codebuild create-project --cli-input-json file://infra/codebuild-progetto.json >/dev/null 2>&1 \
  || $AWS codebuild update-project --cli-input-json file://infra/codebuild-progetto.json >/dev/null

echo "[5/5] lancio la build"
ID=$($AWS codebuild start-build --project-name bacheca-build --query 'build.id' --output text)
echo "    build id: $ID"
echo "    (la prima volta scarica l'immagine di build: puo' metterci qualche minuto)"

for _ in $(seq 1 60); do
  STATO=$($AWS codebuild batch-get-builds --ids "$ID" --query 'builds[0].buildStatus' --output text)
  echo "    stato: $STATO"
  [ "$STATO" != "IN_PROGRESS" ] && break
  sleep 10
done

echo ""
echo "Artefatti prodotti:"
$AWS s3 ls s3://bacheca-artefatti --recursive
