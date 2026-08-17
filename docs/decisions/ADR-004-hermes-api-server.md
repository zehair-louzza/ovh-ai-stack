# ADR-004 : Activer l'API chat Hermes

## Statut
Accepté

## Date
2026-08-17

## Contexte
Le gateway Hermes tournait sans API OpenAI-compatible. FastAPI et les tests `curl` ne pouvaient pas appeler `hermes.blueseatra.com/v1/chat/completions`. La documentation officielle gate cette API derrière `API_SERVER_ENABLED=true`. En Docker, l'écoute par défaut `127.0.0.1` est invisible pour Caddy : il faut `API_SERVER_HOST=0.0.0.0`.

L'API donne accès aux outils Hermes, y compris le terminal. Elle ne doit pas être publiée en clair sur l'hôte.

## Décision
Activer l'API server uniquement sur le réseau Docker interne :

- `API_SERVER_ENABLED=true`
- `API_SERVER_HOST=0.0.0.0`
- `API_SERVER_KEY` dans `.env` uniquement (`openssl rand -hex 32`)
- Pas de `ports: "8642:8642"` sur l'hôte
- Caddy reste le seul exposé : `X-Api-Key` puis reverse-proxy vers `hermes:8642`
- Hermes authentifie ensuite `Authorization: Bearer $API_SERVER_KEY`
- `max_concurrent_runs: 1` (un seul modèle Ollama chargé)
- Pas de CORS navigateur (`API_SERVER_CORS_ORIGINS` non défini)

## Alternatives considérées

### Publier 8642 sur 0.0.0.0 de l'hôte
Rejeté : surface internet directe, contraire au modèle Caddy-only.

### Réutiliser `OLLAMA_API_KEY` comme Bearer
Rejeté : deux portes, deux secrets. Un vol de la clé Ollama n'ouvre pas les outils terminal Hermes.

### Tout laisser sur `/api/chat` Ollama
Conservé pour FastAPI extraction/raisonnement (PR Blueseatra #22). Cette ADR ouvre seulement le tuyau Hermes pour n8n / agents / un futur client.

## Conséquences
- Appel public : `https://hermes.blueseatra.com/v1/chat/completions` avec `X-Api-Key` et `Authorization: Bearer`.
- Appliquer : ajouter `API_SERVER_KEY` au `.env` VPS, `git pull`, `docker compose up -d --force-recreate hermes`.
- FastAPI n'est pas rerouté par cette ADR.

## Sources
- [API Server](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server)
- [Docker](https://hermes-agent.nousresearch.com/docs/user-guide/docker)
