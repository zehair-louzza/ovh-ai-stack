#!/usr/bin/env bash
# Génère les secrets locaux. À exécuter UNE fois sur le VPS.
set -euo pipefail

if [[ -f .env ]]; then
  echo ".env existe déjà — refus d'écraser. Éditez-le à la main."
  exit 1
fi

cp .env.example .env
OLLAMA_KEY="$(openssl rand -hex 32)"
N8N_KEY="$(openssl rand -hex 32)"
API_KEY="$(openssl rand -hex 32)"

sed -i "s/^OLLAMA_API_KEY=.*/OLLAMA_API_KEY=${OLLAMA_KEY}/" .env
sed -i "s/^N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=${N8N_KEY}/" .env
sed -i "s/^API_SERVER_KEY=.*/API_SERVER_KEY=${API_KEY}/" .env

chmod 600 .env
echo "Secrets écrits dans .env (chmod 600)."
echo "Éditez PUBLIC_DOMAIN, N8N_HOST, HERMES_HOST et ACME_EMAIL avant docker compose up."
