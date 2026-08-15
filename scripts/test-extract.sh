#!/usr/bin/env bash
# Mini extraction JSON via Ollama, clé lue sur le VPS uniquement.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a
# shellcheck disable=SC1091
source ./.env
set +a

payload='{"model":"hermes-3","stream":false,"think":false,"messages":[{"role":"system","content":"Return ONLY valid JSON."},{"role":"user","content":"Demande de devis: remplacement de 3 spots LED 230V au 12 rue Victor Hugo, Paris 11e, client Marie Dupont, tel 0601020304, urgent."}],"options":{"temperature":0.1,"num_predict":400}}'

code="$(curl -sS -o /tmp/ollama-extract.json -w '%{http_code}' \
  -H "X-Api-Key: ${OLLAMA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${payload}" \
  https://ia.blueseatra.com/api/chat)"

echo "http=${code}"
python3 - <<'PY'
import json
from pathlib import Path
raw = Path("/tmp/ollama-extract.json").read_text(encoding="utf-8")
try:
    data = json.loads(raw)
    content = data.get("message", {}).get("content", raw)
    print("reponse=", content[:800])
except json.JSONDecodeError:
    print("brut=", raw[:400])
PY
