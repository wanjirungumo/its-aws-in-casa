#!/usr/bin/env bash
# BINARIO A — la pipeline scritta a mano.
#
# Fa ESATTAMENTE le tre fasi che fara' CodePipeline nella Fase 4:
#   Sorgente -> Build -> Deploy
# Solo che l'orchestratore sei tu, con venti righe di bash.
# Serve a capire che CodePipeline non e' magia: e' questo, gestito da qualcun altro.
set -uo pipefail

AWS="aws --endpoint-url=http://localhost:4566"
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""

BUCKET="${1:-bacheca-cfn}"

fase() { echo ""; echo "######## FASE: $1 ########"; }

fase "Sorgente"
echo "prendo il codice da: $(pwd)/sito"
ls -1 sito/

fase "Build"
bash build.sh || { echo ">>> BUILD FALLITA: mi fermo, non pubblico niente."; exit 1; }
bash test.sh  || { echo ">>> TEST FALLITI: mi fermo, non pubblico niente."; exit 1; }

fase "Deploy"
$AWS s3 sync dist/ "s3://$BUCKET" --delete || { echo ">>> DEPLOY FALLITO"; exit 1; }
echo "pubblicato su s3://$BUCKET"

echo ""
echo "########################################"
echo " Pipeline completata. Tre fasi, una sola"
echo " regola: se una fase fallisce, si ferma."
echo "########################################"
