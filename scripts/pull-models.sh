#!/usr/bin/env bash
# Télécharge les modèles Ollama. gemma4:26b et qwen3.6:27b ≈ 17 Go chacun — prévoir 20-40 min / modèle.
# Noms officiels : https://ollama.com/library/gemma4:26b  https://ollama.com/library/qwen3.6:27b  https://ollama.com/library/hermes3
# Rôles Hermes : voir docs/decisions/ADR-003-hermes-raisonnement-gemma4.md
set -euo pipefail

echo "=== Raisonnement Hermes (modèle principal) ==="
docker compose exec ollama ollama pull gemma4:26b

echo "=== Génération SaaS / fallback Hermes ==="
docker compose exec ollama ollama pull qwen3.6:27b

echo "=== Modèle Blueseatra (compat HERMES_DEFAULT_MODEL) ==="
docker compose exec ollama ollama pull hermes3
# Alias pour l'ancien nom utilisé par le backend Blueseatra
docker compose exec ollama ollama cp hermes3 hermes-3 || true

echo "=== Extraction / délégation / fallback RAM ==="
docker compose exec ollama ollama pull qwen2.5:14b

echo "=== Modèles installés ==="
docker compose exec ollama ollama list
