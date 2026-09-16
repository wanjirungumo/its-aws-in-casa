#!/usr/bin/env bash
# IL CICLO DI TUTTI I GIORNI — hai cambiato il sito? Rilancia la pipeline.
# 1) rifa' lo zip  2) lo carica  3) fa ripartire la pipeline  4) ti dice com'e' andata
set -euo pipefail

AWS="aws --endpoint-url=http://localhost:4566"
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""

echo "[1/3] rifaccio lo zip del sorgente"
rm -f sorgente.zip
zip -q -r sorgente.zip sito build.sh test.sh buildspec.yml
$AWS s3 cp sorgente.zip s3://bacheca-sorgente/sorgente.zip

echo "[2/3] faccio ripartire la pipeline"
ESEC=$($AWS codepipeline start-pipeline-execution --name bacheca-pipeline \
        --query 'pipelineExecutionId' --output text)
echo "    esecuzione: $ESEC"

echo "[3/3] aspetto..."
for _ in $(seq 1 60); do
  STATO=$($AWS codepipeline get-pipeline-execution \
            --pipeline-name bacheca-pipeline --pipeline-execution-id "$ESEC" \
            --query 'pipelineExecution.status' --output text 2>/dev/null || echo "?")
  echo "    stato: $STATO"
  case "$STATO" in
    Succeeded|Failed|Stopped|Superseded) break ;;
  esac
  sleep 10
done

echo ""
echo "Dettaglio per fase:"
$AWS codepipeline list-action-executions --pipeline-name bacheca-pipeline \
  --query 'actionExecutionDetails[].{Fase:stageName,Azione:actionName,Stato:status}' \
  --output table
