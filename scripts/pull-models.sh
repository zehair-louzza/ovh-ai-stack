#!/usr/bin/env bash
# Télécharge les modèles Ollama réellement utilisés sur ce VPS.
# Mise à jour 2026-08-25 : gemma4:26b, qwen3.6:27b, qwen3:14b, deepseek-r1:14b,
# qwen2.5:14b et Phi-4-reasoning-vision-15B ont été retirés du VPS le 23/08/2026
# (63 Go libérés, aucun ne raisonnait ET n'avait la vision à la fois). Ne plus
# les télécharger — voir ADR-006 et ADR-008 pour l'historique complet.
# Noms officiels : https://ollama.com/library/gpt-oss  https://ollama.com/library/qwen2.5vl
#                  https://ollama.com/library/qwen2.5  https://ollama.com/library/hermes3
# Rôles Hermes : voir docs/decisions/ADR-006-gpt-oss-reasoning-model-graduated-effort.md
#                et docs/decisions/ADR-007-reactivation-toolsets-et-reasoning-high.md
set -euo pipefail

echo "=== Raisonnement Hermes (modèle principal, agent.reasoning_effort: high) ==="
docker compose exec ollama ollama pull gpt-oss:20b

echo "=== Vision (seul modèle multimodal du slot auxiliary.vision) ==="
docker compose exec ollama ollama pull qwen2.5vl:7b

echo "=== Secours (fallback_providers, si gpt-oss:20b échoue) ==="
docker compose exec ollama ollama pull hermes3
# Alias pour l'ancien nom utilisé par le backend Blueseatra (HERMES_DEFAULT_MODEL)
docker compose exec ollama ollama cp hermes3 hermes-3 || true

echo "=== Extraction légère / texte collé manuellement (HERMES_EXTRACT_MODEL côté Blueseatra) ==="
docker compose exec ollama ollama pull qwen2.5:7b

echo "=== Rédaction Description + Étapes uniquement (HERMES_DESCRIPTION_MODEL côté Blueseatra, PAS un rôle Hermes agent) ==="
docker compose exec ollama ollama pull hf.co/mradermacher/GLM-4.7-Flash-GGUF:Q3_K_M
docker compose exec ollama ollama cp hf.co/mradermacher/GLM-4.7-Flash-GGUF:Q3_K_M glm-4.7-flash:Q3_K_M || true

echo "=== Modèles installés ==="
docker compose exec ollama ollama list
