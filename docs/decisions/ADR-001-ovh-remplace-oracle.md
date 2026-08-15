# ADR-001 : OVH Cloud remplace Oracle Cloud comme hôte IA

## Statut
Accepté

## Date
2026-08-15

## Contexte
Blueseatra extrait des données personnelles (noms, emails, téléphones, adresses de chantier) depuis des PDF, photos et emails. L'hébergement Oracle Cloud (région US Ashburn pour la VM Hermes) sortait les traitements du territoire UE. Le produit OracleMind (serveur MCP OCI) reste un logiciel commercial distinct : on abandonne Oracle comme *hébergeur*, pas le dépôt OracleMind.

Exigences :
- Souveraineté des données (Roubaix, France)
- Isolation réseau : Ollama jamais exposé en clair
- Trois services : Ollama (modèles), Hermes Agent (orchestration), n8n (flux déterministes)
- Le backend FastAPI / Supabase reste le cœur métier (prix, devis, isolation tenant)

## Décision
Créer un dépôt privé dédié `ovh-ai-stack` (pas un dossier dans Blueseatra) :
- cycle de vie infra ≠ cycle de vie produit SaaS
- secrets et volumes hors du repo applicatif
- clone direct sur le VPS

Stack :
| Service | Rôle | Exposition |
|---|---|---|
| Caddy | TLS + clé API | 80 / 443 publics |
| Ollama | LLM local (`qwen3.6:27b`, `hermes3`, `qwen2.5:14b`) | réseau Docker uniquement |
| Hermes Agent | orchestration, pas de pricing | réseau Docker + Caddy + clé |
| n8n | webhooks / email | Caddy HTTPS |

## Alternatives rejetées

### Tout mettre dans `zehair-louzza/Blueseatra`
Mélange secrets d'infra et code produit. Accès GitHub trop large pour un VPS.

### Continuer Oracle Free Tier (Ampere)
Région US, clauses transfert, dépendance à un compte cloud distinct. Rejeté pour le RGPD.

### Exposer Ollama `:11434` sur Internet
Surface d'attaque directe sur des documents clients. Rejeté.

### Un seul conteneur « tout-en-un »
Couplage fort, redémarrages inutiles, plus difficile à limiter en RAM (18 Go pour Ollama seuls).

## Conséquences
- Render (Francfort) appelle `https://$PUBLIC_DOMAIN/api/chat` avec `X-Api-Key`
- DNS A requis avant Let's Encrypt
- OracleMind / OracleMind-Pro restent des produits MCP ; prévoir un audit de décommission des VM OCI
- Supabase `eu-west-1` et Render Frankfurt inchangés
