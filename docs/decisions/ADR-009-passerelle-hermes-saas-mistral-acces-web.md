# ADR-009 : Passerelle Hermès dédiée au SaaS, Mistral et accès web

## Statut
Accepté (29/09/2026)

## Contexte
- L'utilisateur veut que **toute** l'IA du SaaS Blueseatra passe par Hermès, sans appel direct de l'API Render vers Ollama, avec l'OCR sur le VPS (PaddleOCR-VL par défaut) et Mistral en remplacement de Cerebras.
- Il veut aussi un accès web à Hermès sur `hermes.blueseatra.com`, protégé par identifiant et mot de passe.
- L'agent principal garde volontairement tous ses outils (ADR-007). Or le SaaS lui transmettrait des documents clients, un contenu non fiable, avec un terminal à portée.
- L'agent principal envoie aussi des schémas d'outils à chaque appel : les modèles OCR ne les acceptent pas (HTTP 400, historique de `hermes/config.yaml`).

## Décision
1. Ajouter un **second conteneur `hermes-passerelle`** (même image) avec `hermes/passerelle/config.yaml` :
   - aucun outil (`disabled_toolsets`) ;
   - fournisseurs nommés `ollama` et `mistral` ;
   - `direct_model_requests: true`.
   Le SaaS y envoie `provider` + `model` à chaque requête.
2. L'agent principal reste inchangé (ADR-007/008). Il reçoit seulement le fournisseur `mistral`, et son tableau de bord est activé.
3. `hermes.blueseatra.com` sert deux accès :
   - **machines** : en-tête `X-Api-Key` → passerelle, avec Bearer injecté par Caddy ;
   - **navigateur** : `basic_auth` Caddy (bcrypt en base64 dans `.env`) → tableau de bord 9119, qui a lui aussi sa propre connexion.
4. `scripts/activer-hermes.sh` génère les identifiants et démarre les services, puis fait trois essais réels par la passerelle : Mistral, Qwen2.5 et PaddleOCR avec une image d'essai.

## Conséquences
- La passerelle ajoute encore le prompt système de base d'Hermès à chaque appel, sans schémas d'outils. La latence réelle des petits modèles OCR doit être mesurée par le script avant toute bascule du SaaS.
- Si PaddleOCR est refusé par la passerelle (contrôle de contexte minimal d'Hermès, par exemple), le script le montre. Le SaaS ne doit alors pas être basculé tant que ce point n'est pas résolu.
- Retour arrière côté SaaS : `BLUESEATRA_IA_VIA_HERMES=0` sur Render.
