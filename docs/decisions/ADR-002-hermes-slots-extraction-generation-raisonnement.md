# ADR-002 : Slots Hermes pour extraction, génération et raisonnement

## Statut
Remplacé par [ADR-003](ADR-003-hermes-raisonnement-gemma4.md) pour le modèle principal / raisonnement. Extraction et interdiction de `provider: auto` restent valides.

## Date
2026-08-16

## Remplacé le
2026-08-17 — `gemma4:26b` installé sur le VPS.

## Contexte
Blueseatra v2 sépare trois rôles IA : extraction (routeur / parse), génération (texte devis), raisonnement (contrôle matériaux / lots). Hermes Agent n'expose pas de slots nommés `extraction`, `génération` ou `raisonnement`.

Les seuls slots documentés sont le modèle principal, les tâches auxiliaires (`vision`, `web_extract`, `compression`, `title_generation`, `mcp`, `skills_hub`, `approval`, `triage_specifier`, …), `delegation`, et `fallback_providers`.

Le raisonnement se configure via `agent.reasoning_effort`, pas via un modèle dédié.

Contraintes VPS :

- Modèles installés : `qwen3.6:27b`, `qwen2.5:14b`, `hermes3` / `hermes-3`
- Non installés : Gemma 4 26B-A4B, DeepSeek-R1 32B
- `OLLAMA_MAX_LOADED_MODELS=1` (24 Go RAM)
- Données clients : rester sur Ollama local. `provider: auto` est interdit (découverte OpenRouter / Nous Portal)

## Décision
Mapper les trois rôles Blueseatra sur les clés officielles, uniquement avec des modèles déjà présents :

| Rôle Blueseatra | Clé Hermes documentée | Modèle |
|---|---|---|
| Génération | `model` (principal) | `qwen3.6:27b` |
| Raisonnement | `agent.reasoning_effort` (+ overrides) | `high` sur le 27B |
| Extraction | `delegation` + `auxiliary.web_extract` | `qwen2.5:14b` |
| Tâches légères | `compression`, `title_generation`, `mcp`, `skills_hub`, `approval`, `triage_specifier` | `qwen2.5:14b` |
| Vision | `auxiliary.vision` | `qwen3.6:27b` (aucun VL dédié) |
| Secours local | `fallback_providers` | `qwen2.5:14b` puis `hermes3` |

Sous-agents : `max_concurrent_children: 1`, `orchestrator_enabled: false`.

## Alternatives considérées

### Inventer `auxiliary.extraction` / `auxiliary.reasoning`
Rejeté : clés absentes de la documentation. Hermes les ignorerait.

### Pointer le raisonnement vers Gemma 4 ou DeepSeek-R1
Rejeté tant que le modèle n'est pas sur le disque. Un slot requis vers un modèle manquant casse le gateway.

### `provider: auto` sur les tâches auxiliaires
Rejeté : la chaîne de découverte tente OpenRouter puis Nous Portal. Sortie UE et fuite de documents clients.

### Laisser tous les slots sur `qwen3.6:27b`
Rejeté : chaque titre, compression ou extract déchargerait le 27B pour rien. Le 14B est déjà le fallback RAM prévu.

## Conséquences
- `hermes/config.yaml` est la source de vérité du routage Hermes Agent (`hermes.blueseatra.com`).
- FastAPI (Render) appelle encore Ollama (`https://ia.blueseatra.com/api/chat`). Cette ADR ne change pas `ai_service.py`. Extraire / raisonner côté SaaS reste `HERMES_DEFAULT_MODEL` / `HERMES_REASONING_MODEL`.
- Appliquer sur le VPS : `git pull` puis `docker compose up -d hermes`.
- Quand un reasoner sera testé (Gemma 4 26B-A4B ou DeepSeek-R1 32B) : nouvelle ADR, `ollama pull`, puis seulement ensuite `agent.reasoning_overrides` ou bascule du `model` principal.

## Sources
- [Configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration)
- [Configuring Models](https://hermes-agent.nousresearch.com/docs/user-guide/configuring-models)
- [Subagent Delegation](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation)
- [Fallback Providers](https://hermes-agent.nousresearch.com/docs/user-guide/features/fallback-providers)
