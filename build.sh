#!/usr/bin/env bash
# BUILD: prende i sorgenti da sito/ e produce dist/ (l'artefatto da pubblicare).
# Non modifica mai i sorgenti. Puoi rilanciarlo quante volte vuoi.
set -euo pipefail

SORGENTE="sito"
USCITA="dist"

echo "[build] pulisco $USCITA/"
rm -rf "$USCITA"
mkdir -p "$USCITA"

echo "[build] copio i sorgenti"
cp -r "$SORGENTE"/. "$USCITA"/

# Numero di build: data + ora. Se siamo in un repo git, aggiungo il commit.
STAMPA="$(date -u '+%Y%m%d-%H%M%S')"
if git rev-parse --short HEAD >/dev/null 2>&1; then
  STAMPA="$STAMPA-$(git rev-parse --short HEAD)"
fi

echo "[build] marchio la build come $STAMPA"
# sed -i cambia il file al volo; su macOS servirebbe sed -i '' ma qui siamo su Linux
sed -i.bak "s/__VERSIONE__/$STAMPA/g" "$USCITA/index.html" && rm -f "$USCITA/index.html.bak"

cat > "$USCITA/versione.json" <<EOF
{
  "build": "$STAMPA",
  "generato": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
EOF

echo "[build] OK -> $USCITA/ ($(find "$USCITA" -type f | wc -l) file)"
