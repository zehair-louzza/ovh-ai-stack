# ADR-003 : Raisonnement Hermes sur Gemma 4 26B-A4B

## Statut
Accepté

## Date
2026-08-17

## Contexte
ADR-002 mappait génération et raisonnement sur `qwen3.6:27b` parce que Gemma 4 n'était pas sur le disque. `gemma4:26b` (digest `5571076f3d70`, 17 Go, 26B A4B MoE) est maintenant installé sur le VPS et a répondu à un `ollama run` de contrôle.

Hermes Agent n'expose toujours pas de slot nommé `raisonnement`. La documentation officielle dit que le modèle principal est « what the agent thinks with. Every user message, every tool-call loop, every streamed response goes through this model. » Il n'existe pas de clé `reasoning_model` ni `auxiliary.reasoning`. `agent.reasoning_overrides` ne change que l'effort (high / none), pas le modèle appelé.

## Décision
Pointer le slot principal Hermes (`model`) vers `gemma4:26b`, avec `agent.reasoning_effort: high`.

| Rôle Blueseatra | Clé Hermes documentée | Modèle |
|---|---|---|
| Raisonnement (pense / contrôle lots) | `model` + `agent.reasoning_effort` | `gemma4:26b` (`high`) |
| Extraction | `delegation` + `auxiliary.web_extract` | `qwen2.5:14b` |
| Tâches légères | `compression`, `title_generation`, `mcp`, `skills_hub`, `approval`, `triage_specifier` | `qwen2.5:14b` |
| Vision | `auxiliary.vision` | `gemma4:26b` (texte + image) |
| Secours local | `fallback_providers` | `qwen3.6:27b` puis `qwen2.5:14b` puis `hermes3` |
| Génération devis SaaS | hors Hermes | FastAPI → Ollama `qwen3.6:27b` |

Cette ADR remplace le mapping raisonnement / principal d'ADR-002. Extraction, interdiction de `provider: auto`, et `max_concurrent_children: 1` restent inchangés.

## Alternatives considérées

### Inventer `auxiliary.reasoning`
Rejeté : clé absente. Hermes l'ignorerait.

### Garder `qwen3.6:27b` en principal et n'ajouter que `reasoning_overrides.gemma4:26b`
Rejeté : l'override ne s'applique que si Gemma est déjà le modèle actif. Gemma ne serait jamais appelé.

### MoA (références + agrégateur)
Rejeté : hors besoin, charge plusieurs modèles, incompatible avec `OLLAMA_MAX_LOADED_MODELS=1`.

## Conséquences
- `hermes/config.yaml` et `HERMES_MODEL` doivent tous les deux valoir `gemma4:26b`. Sans mise à jour du `.env` VPS, l'env compose peut recouvrir le YAML.
- Un tour Hermes charge Gemma (~17 Go). Ollama décharge Qwen. Les tâches 14B restent un swap.
- FastAPI continue d'appeler `https://ia.blueseatra.com/api/chat`. Cette ADR ne change pas `ai_service.py`.
- Appliquer sur le VPS : `git pull`, `HERMES_MODEL=gemma4:26b` dans `.env`, `docker compose up -d hermes`.

## Sources
- [Configuring Models](https://hermes-agent.nousresearch.com/docs/user-guide/configuring-models)
- [Configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration)
- [gemma4:26b](https://ollama.com/library/gemma4:26b)
- [Gemma + Ollama](https://ai.google.dev/gemma/docs/integrations/ollama)
