#!/usr/bin/env bash
# Régénère OLLAMA_API_KEY et recrée Caddy. N'affiche pas la clé.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "pas de .env"
  exit 1
fi

NEW="$(openssl rand -hex 32)"
sed -i "s/^OLLAMA_API_KEY=.*/OLLAMA_API_KEY=${NEW}/" .env
chmod 600 .env
docker compose up -d --force-recreate caddy
echo "cle_regenerée longueur=${#NEW}"
echo "prochaine_etape=copier .env vers Render HERMES_API_KEY (ne pas coller dans le chat)"
