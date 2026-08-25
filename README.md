# ovh-ai-stack

Stack IA auto-hébergée pour [Blueseatra](https://github.com/zehair-louzza/Blueseatra) sur VPS OVH (Roubaix).

Ollama, Hermes Agent et n8n tournent dans des conteneurs séparés. Seul Caddy écoute sur Internet. Les documents clients ne quittent pas l'UE par défaut.

## Pourquoi un dépôt à part

- Blueseatra = produit SaaS (FastAPI / React / Supabase)
- OracleMind = produit MCP Oracle (inchangé)
- Ce dépôt = infra VPS (secrets, volumes, durcissement)

Voir [ADR-001](docs/decisions/ADR-001-ovh-remplace-oracle.md).

## Architecture

```
Internet
   │  80 / 443
   ▼
 Caddy (TLS + X-Api-Key)
   ├── PUBLIC_DOMAIN  → ollama:11434   (FastAPI /api/chat — pas Hermes Agent)
   ├── N8N_HOST       → n8n:5678
   └── HERMES_HOST    → hermes:8642    (API chat /v1 + health, slots ci-dessous)
```

FastAPI (Render, Francfort) appelle `https://$PUBLIC_DOMAIN/api/chat` avec `X-Api-Key`.
n8n déclenche les flux déterministes. Hermes Agent n'a pas le droit de calculer un prix.

Slots Hermes (état réel au 25/08/2026 — voir [ADR-006](docs/decisions/ADR-006-gpt-oss-reasoning-model-graduated-effort.md) et [ADR-007](docs/decisions/ADR-007-reactivation-toolsets-et-reasoning-high.md) ; ADR-002/ADR-003 sont l'historique de la config initiale, remplacée depuis) :

| Rôle Blueseatra | Clé Hermes | Modèle |
|---|---|---|
| Raisonnement (agent Hermes) | `model` + `agent.reasoning_effort: high` | `gpt-oss:20b` |
| Vision (slot auxiliaire, seul modèle multimodal) | `auxiliary.vision` | `qwen2.5vl:7b` |
| Extraction légère / tâches rapides | `auxiliary.web_extract` | `gpt-oss:20b` |
| Secours si `gpt-oss:20b` échoue | `fallback_providers` | `hermes3` |
| Génération devis SaaS — raisonnement/extraction | hors Hermes (FastAPI → Ollama, `HERMES_REASONING_MODEL`) | `gpt-oss:20b` |
| Génération devis SaaS — Description + Étapes uniquement | hors Hermes (FastAPI → Ollama, `HERMES_DESCRIPTION_MODEL`) | `glm-4.7-flash:Q3_K_M` |

`gemma4:26b`, `qwen3.6:27b`, `qwen3:14b`, `deepseek-r1:14b`, `qwen2.5:14b` et `Phi-4-reasoning-vision-15B` ont été retirés du VPS le 23/08/2026 (63 Go libérés, aucun ne raisonnait ET n'avait la vision à la fois) — ne plus les réinstaller.

### Mémoire persistante / apprentissage autonome

Hermes Agent a une boucle d'apprentissage intégrée (mémoire persistante `MEMORY.md`/`USER.md`, création/amélioration autonome de skills) activée par défaut. Elle a été vérifiée en réel le 25/08/2026 : un bug d'usage de l'outil `memory` (action invalide) la rendait totalement inopérante, corrigé et renforcé dans `hermes/SOUL.md` (section « Mémoire persistante — apprentissage autonome ») — voir [ADR-008](docs/decisions/ADR-008-hermes-apprentissage-autonome-fiabilite.md).

## Prérequis déjà faits sur le VPS

- Ubuntu 24.04.4 — `ubuntu@vps-b377201e.vps.ovh.net`
- Docker 29.7.2 + Compose v5.4.0
- UFW 22 / 80 / 443
- Swap 4 Go

Reste : reboot noyau, clés SSH, secrets, DNS (`ia` / `n8n` / `hermes`.blueseatra.com), `compose up`, modèles.

## Suite de l'installation

Guide unique, commandes **une par une** (PowerShell casse les pipes multi-lignes) :

→ **[docs/GUIDE-POWERSHELL.md](docs/GUIDE-POWERSHELL.md)**

## RGPD / sécurité

- [docs/RGPD.md](docs/RGPD.md)
- [docs/SECURITE.md](docs/SECURITE.md)
- [docs/DECOMMISSION-ORACLE.md](docs/DECOMMISSION-ORACLE.md)

## Sources officielles

- [Ollama Docker](https://docs.ollama.com/docker)
- [Ollama bind / OLLAMA_HOST](https://docs.ollama.com/faq)
- [Hermes Agent Docker](https://hermes-agent.nousresearch.com/docs/user-guide/docker)
- [Hermes configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration)
- [Hermes API server](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server)
- [n8n Docker Compose](https://docs.n8n.io/deploy/host-n8n/install-options/use-a-cloud-provider/use-docker-compose)
- [Caddy matchers](https://caddyserver.com/docs/caddyfile/matchers)
- [gpt-oss](https://ollama.com/library/gpt-oss) · [qwen2.5vl](https://ollama.com/library/qwen2.5vl) · [hermes3](https://ollama.com/library/hermes3)
- [Hermes Agent — Mémoire persistante](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory)
