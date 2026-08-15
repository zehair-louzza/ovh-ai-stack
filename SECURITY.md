# Sécurité

## Signaler une faille
N'ouvrez pas d'issue publique. Contactez le propriétaire du dépôt en privé.

## Surfaces de confiance

| Frontière | Contrôle |
|---|---|
| Internet → Caddy | TLS, `X-Api-Key` pour Ollama/Hermes |
| Caddy → Ollama | réseau Docker interne |
| Render → VPS | HTTPS + clé, jamais le port 11434 |
| Admin → VPS | SSH clé Ed25519, fail2ban |
| n8n webhooks | HTTPS uniquement, compte owner |

## Interdits
- Commit de `.env`, clés SSH, dumps n8n
- Publication de `11434`, `5678`, `8642` sur `0.0.0.0`
- Auth SSH par mot de passe une fois la clé installée
- Envoi de documents clients vers un LLM cloud sans décision écrite

## Rotation
Si `OLLAMA_API_KEY` fuit : régénérer, mettre à jour `.env` + secret Render `HERMES_API_KEY`, `docker compose up -d caddy`.
