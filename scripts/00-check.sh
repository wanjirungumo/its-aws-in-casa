#!/usr/bin/env bash
# PREFLIGHT — lancialo PRIMA di tutto. Ti dice se l'ambiente e' a posto
# e su quale binario del laboratorio puoi andare.
set -uo pipefail

ENDPOINT="http://localhost:4566"
AWS="aws --endpoint-url=$ENDPOINT --output json"
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-test}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-test}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}
export AWS_PAGER=""

VERDE="\033[0;32m"; ROSSO="\033[0;31m"; GIALLO="\033[0;33m"; FINE="\033[0m"
ok()   { echo -e "  ${VERDE}[ok]${FINE}   $1"; }
no()   { echo -e "  ${ROSSO}[NO]${FINE}   $1"; }
warn() { echo -e "  ${GIALLO}[--]${FINE}   $1"; }

BLOCCANTI=0

echo ""
echo "=== 1. Strumenti installati ==========================="
command -v docker  >/dev/null 2>&1 && ok "docker c'e'"      || { no "docker NON c'e'";  BLOCCANTI=$((BLOCCANTI+1)); }
command -v aws     >/dev/null 2>&1 && ok "aws cli c'e'"     || { no "aws cli NON c'e'"; BLOCCANTI=$((BLOCCANTI+1)); }
command -v zip     >/dev/null 2>&1 && ok "zip c'e'"         || warn "zip manca -> sudo apt-get install -y zip"
command -v jq      >/dev/null 2>&1 && ok "jq c'e'"          || warn "jq manca (comodo, non obbligatorio)"

echo ""
echo "=== 2. LocalStack e' vivo? ============================"
if curl -s --max-time 5 "$ENDPOINT/_localstack/health" >/dev/null 2>&1; then
  ok "LocalStack risponde su $ENDPOINT"
else
  no "LocalStack non risponde. Lancia:  docker compose up -d   e riprova fra 20 secondi."
  BLOCCANTI=$((BLOCCANTI+1))
fi

echo ""
echo "=== 3. Servizi del piano gratuito ====================="
$AWS s3 ls >/dev/null 2>&1                    && ok "S3 risponde"             || { no "S3 non risponde";             BLOCCANTI=$((BLOCCANTI+1)); }
$AWS cloudformation list-stacks >/dev/null 2>&1 && ok "CloudFormation risponde" || { no "CloudFormation non risponde"; BLOCCANTI=$((BLOCCANTI+1)); }
$AWS iam list-roles >/dev/null 2>&1           && ok "IAM risponde"            || warn "IAM non risponde (non blocca le prime due fasi)"

echo ""
echo "=== 4. Servizi del piano studente ====================="
HA_CODEBUILD=0; HA_PIPELINE=0
$AWS codebuild list-projects   >/dev/null 2>&1 && { ok "CodeBuild disponibile";    HA_CODEBUILD=1; } || warn "CodeBuild NON disponibile (serve il piano studente)"
$AWS codepipeline list-pipelines >/dev/null 2>&1 && { ok "CodePipeline disponibile"; HA_PIPELINE=1; } || warn "CodePipeline NON disponibile (serve il piano studente)"

echo ""
echo "======================================================="
if [ "$BLOCCANTI" -gt 0 ]; then
  echo -e "${ROSSO} FERMO QUI: $BLOCCANTI problemi bloccanti.${FINE}"
  echo " Rileggi i [NO] qui sopra, sistema, rilancia questo script."
  exit 1
fi
if [ "$HA_CODEBUILD" -eq 1 ] && [ "$HA_PIPELINE" -eq 1 ]; then
  echo -e "${VERDE} TUTTO VERDE -> vai sul BINARIO B (pipeline vera).${FINE}"
  echo " Fasi 1, 2, 3, 4. Alza la mano solo se ti si rompe qualcosa."
else
  echo -e "${GIALLO} PIANO GRATUITO -> vai sul BINARIO A.${FINE}"
  echo " Fasi 1 e 2 uguali per tutti, poi la Fase 3-bis (pipeline a mano)."
  echo " Se hai il GitHub Student Pack, chiedi in aula: si sblocca in 5 minuti."
fi
echo "======================================================="
echo ""
