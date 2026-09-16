#!/usr/bin/env bash
# ANTEPRIMA — scarica quello che c'e' DAVVERO dentro il bucket e te lo serve
# su http://localhost:8080 . Funziona sempre, anche dentro un Codespace.
#
# Uso:  ./scripts/90-anteprima.sh [nome-bucket]
set -euo pipefail

BUCKET="${1:-bacheca-cfn}"
AWS="aws --endpoint-url=http://localhost:4566"
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-test}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-test}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}
export AWS_PAGER=""

echo "[anteprima] scarico il contenuto di s3://$BUCKET"
rm -rf .anteprima && mkdir -p .anteprima
$AWS s3 sync "s3://$BUCKET" .anteprima --quiet

if [ ! -f .anteprima/index.html ]; then
  echo "[anteprima] ATTENZIONE: nel bucket non c'e' nessun index.html."
  echo "            Il deploy non e' arrivato. Guarda i log della fase precedente."
fi

echo "[anteprima] servo su http://localhost:8080  (CTRL+C per fermare)"
echo "            Nel Codespace: scheda PORTS -> porta 8080 -> apri nel browser."
cd .anteprima && python3 -m http.server 8080
