#!/usr/bin/env bash
# Teste Caddy + Ollama sans afficher la clé.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a
# shellcheck disable=SC1091
source ./.env
set +a

echo "longueur_cle=${#OLLAMA_API_KEY}"

code_no="$(curl -sS -o /dev/null -w '%{http_code}' https://ia.blueseatra.com/api/tags || true)"
echo "sans_cle=${code_no}"

code_yes="$(curl -sS -o /tmp/ollama-tags.json -w '%{http_code}' \
  -H "X-Api-Key: ${OLLAMA_API_KEY}" \
  https://ia.blueseatra.com/api/tags || true)"
echo "avec_cle=${code_yes}"

if [[ -s /tmp/ollama-tags.json ]]; then
  python3 - <<'PY'
import json
from pathlib import Path
raw = Path("/tmp/ollama-tags.json").read_text(encoding="utf-8")
try:
    data = json.loads(raw)
    print("modeles=", [m.get("name") for m in data.get("models", [])])
except json.JSONDecodeError:
    print("reponse_non_json=", raw[:200])
PY
fi
