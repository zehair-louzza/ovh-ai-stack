#!/usr/bin/env bash
# Met à jour les skills Hermes sur le VPS (git pull + recreate hermes).
set -euo pipefail
cd "$(dirname "$0")/.."
git pull --ff-only https://github.com/zehair-louzza/ovh-ai-stack.git main
docker compose up -d --force-recreate hermes
docker compose exec hermes ls -la /opt/blueseatra-skills || true
echo "skills_hermes=ok"
