#!/usr/bin/env bash
# PULIZIA — cancella tutto quello che il laboratorio ha creato dentro LocalStack.
# Non tocca i tuoi file. Serve se vuoi ricominciare da zero.
set -uo pipefail

AWS="aws --endpoint-url=http://localhost:4566"
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-test}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-test}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}
export AWS_PAGER=""

echo "[pulizia] cancello la pipeline"
$AWS codepipeline delete-pipeline --name bacheca-pipeline 2>/dev/null

echo "[pulizia] cancello i progetti CodeBuild"
$AWS codebuild delete-project --name bacheca-build 2>/dev/null
$AWS codebuild delete-project --name bacheca-build-pipeline 2>/dev/null

echo "[pulizia] svuoto e cancello i bucket"
for B in bacheca-its bacheca-cfn bacheca-sorgente bacheca-artefatti; do
  $AWS s3 rb "s3://$B" --force 2>/dev/null && echo "   - $B cancellato"
done

echo "[pulizia] cancello lo stack CloudFormation"
$AWS cloudformation delete-stack --stack-name bacheca 2>/dev/null

echo "[pulizia] cancello il ruolo"
$AWS iam delete-role-policy --role-name ruolo-pipeline --policy-name permessi-pipeline 2>/dev/null
$AWS iam delete-role --role-name ruolo-pipeline 2>/dev/null

rm -rf dist .anteprima sorgente.zip
echo "[pulizia] fatto. Se vuoi azzerare proprio tutto: docker compose down -v"
