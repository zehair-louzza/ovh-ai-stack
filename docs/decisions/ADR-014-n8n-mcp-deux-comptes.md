# ADR-014 — n8n relié à l'agent Hermès par MCP, avec deux comptes n8n

- Statut : accepté
- Date : 11 octobre 2026

## Contexte

L'agent Hermès du tableau de bord doit pouvoir consulter, lancer et construire des automatisations n8n. n8n fournit un serveur MCP intégré (`/mcp-server/http`), protégé par un jeton personnel lié au compte qui le génère. Ses outils vont de la lecture à la création, à la publication et à la suppression de données.

Hermès n'offre pas de confirmation par outil MCP : ses demandes d'accord ne portent que sur les commandes système. Le modèle local (gpt-oss:20b) peut mal comprendre une demande, et un contenu lu (page web, e-mail) peut contenir des instructions malveillantes.

L'édition gratuite auto-hébergée de n8n ne permet pas de partager workflows et accès entre utilisateurs.

## Décision

1. Deux connexions MCP dans la configuration de l'agent (`/opt/data/config.yaml`), toutes deux sur l'adresse interne `http://n8n:5678/mcp-server/http` :
   - `n8n`, jeton du compte Owner (`N8N_MCP_TOKEN`) : lecture et exécution seulement ;
   - `n8n-hermes`, jeton d'un compte Member « Hermès » (`N8N_MCP_TOKEN_HERMES`) : construction, sans `publish_workflow`, `unpublish_workflow` ni `delete_data_table_column`.
2. Jetons dans `.env` du VPS, référencés par `${…}` dans `config.yaml`.
3. Publication réservée au propriétaire, après relecture dans n8n.
4. La passerelle du SaaS (`hermes-passerelle`) ne reçoit aucune connexion MCP.
5. Pas d'entrée OAuth `n8n-official` : la connexion par navigateur est impossible depuis le conteneur.

## Conséquences

- Les workflows créés par Hermès restent dans l'espace du compte Hermès et n'utilisent que les accès créés pour lui.
- Le compte Owner reste joignable pour consulter et lancer les workflows existants, sans droit de modification.
- La configuration de l'agent vit dans son volume (ADR-013) : `hermes/config.yaml` du dépôt n'est pas modifié. La procédure est dans `docs/EXPLOITATION-HERMES.md`.

## Rejeté

- **Un seul jeton Owner avec tous les outils** : Hermès pourrait créer un workflow qui utilise tous les accès enregistrés et le publier.
- **Remplacer le jeton Owner par le compte Member** : refusé par le propriétaire, qui veut garder l'accès à ses workflows existants.
