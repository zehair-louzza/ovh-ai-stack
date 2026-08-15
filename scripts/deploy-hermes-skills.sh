#!/usr/bin/env bash
# Met à jour les skills Hermes sur le VPS (git pull + recreate hermes).
set -euo pipefail
cd "$(dirname "$0")/.."
GIT_SSH_COMMAND='ssh -i ~/.ssh/github_ovh_ai_stack -o IdentitiesOnly=yes' git pull
docker compose up -d --force-recreate hermes
docker compose exec hermes ls -la /opt/data/skills/blueseatra-devis || true
echo "skills_hermes=ok"
