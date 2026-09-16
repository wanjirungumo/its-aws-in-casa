#!/usr/bin/env bash
# Gira UNA volta sola, quando il Codespace viene creato. Non devi lanciarlo tu.
set -euo pipefail

echo "==> Installo awscli-local (il comando 'awslocal') e jq"
pip install --quiet --user awscli-local || pip install --quiet --break-system-packages awscli-local
sudo apt-get update -qq && sudo apt-get install -y -qq jq zip unzip >/dev/null

echo "==> Preparo le credenziali finte (LocalStack accetta qualunque cosa)"
mkdir -p "$HOME/.aws"
cat > "$HOME/.aws/credentials" <<'EOF'
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF
cat > "$HOME/.aws/config" <<'EOF'
[default]
region = us-east-1
output = json
cli_pager =
EOF

chmod +x scripts/*.sh build.sh test.sh 2>/dev/null || true

echo ""
echo "======================================================"
echo " Ambiente pronto. Ora, nel terminale:"
echo "   1) docker compose up -d"
echo "   2) ./scripts/00-check.sh"
echo "======================================================"
