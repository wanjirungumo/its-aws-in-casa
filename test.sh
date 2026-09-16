#!/usr/bin/env bash
# TEST: controlla che dist/ sia pubblicabile. Se un test fallisce, lo script
# esce con codice != 0 e la pipeline si deve fermare PRIMA del deploy.
set -uo pipefail

FALLITI=0

controlla() {
  local descrizione="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  [ok]   $descrizione"
  else
    echo "  [FAIL] $descrizione"
    FALLITI=$((FALLITI + 1))
  fi
}

echo "[test] controllo l'artefatto in dist/"

controlla "dist/index.html esiste"        test -f dist/index.html
controlla "dist/style.css esiste"         test -f dist/style.css
controlla "dist/versione.json esiste"     test -f dist/versione.json
controlla "versione.json e' JSON valido"  python3 -c "import json;json.load(open('dist/versione.json'))"
controlla "il placeholder e' stato sostituito" bash -c '! grep -q "__VERSIONE__" dist/index.html'
controlla "nessun TODO rimasto nel sito"  bash -c '! grep -rq "TODO" dist/'

echo ""
if [ "$FALLITI" -gt 0 ]; then
  echo "[test] $FALLITI test FALLITI -> non si pubblica niente."
  exit 1
fi
echo "[test] tutti i test passati -> si puo' pubblicare."
