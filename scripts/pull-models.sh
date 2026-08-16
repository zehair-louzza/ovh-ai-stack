#!/usr/bin/env bash
# Télécharge les modèles Ollama. qwen3.6:27b ≈ 17 Go — prévoir 20-40 min.
# Noms officiels : https://ollama.com/library/qwen3.6:27b  https://ollama.com/library/hermes3
# Rôles Hermes : voir docs/decisions/ADR-002-hermes-slots-extraction-generation-raisonnement.md
set -euo pipefail

echo "=== Modèle principal (génération + raisonnement Hermes) ==="
docker compose exec ollama ollama pull qwen3.6:27b

echo "=== Modèle Blueseatra (compat HERMES_DEFAULT_MODEL) ==="
docker compose exec ollama ollama pull hermes3
# Alias pour l'ancien nom utilisé par le backend Blueseatra
docker compose exec ollama ollama cp hermes3 hermes-3 || true

echo "=== Extraction / délégation / fallback RAM ==="
docker compose exec ollama ollama pull qwen2.5:14b

echo "=== Modèles installés ==="
docker compose exec ollama ollama list
