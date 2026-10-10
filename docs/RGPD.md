# Conformité RGPD — stack IA OVH

Ce document décrit le traitement réel, pas une politique marketing. Références : [CNIL — sous-traitant](https://www.cnil.fr/fr/sous-traitant), [art. 28 RGPD](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre4), [sécurité de la sous-traitance](https://www.cnil.fr/fr/securite-gerer-la-sous-traitance).

## Rôles

| Acteur | Rôle | Localisation |
|---|---|---|
| ANELEC / Blueseatra (vous) | Responsable de traitement vis-à-vis des clients BTP | France |
| OVHcloud | Sous-traitant hébergeur (VPS Roubaix) | UE (France) |
| Render | Sous-traitant backend FastAPI | UE (Francfort) |
| Supabase | Sous-traitant PostgreSQL | UE (`eu-west-1`) |
| Hostinger | Sous-traitant frontend statique | à vérifier au contrat |
| Nous Research / OpenAI / Anthropic / Google | **Non utilisés par défaut** | hors UE si activés |

Un contrat de sous-traitance (DPA) est obligatoire avec OVH, Render et Supabase. OVHcloud en fournit un dans l'espace client.

## Données concernées

Documents de devis : identité, email, téléphone, adresse de chantier, description de travaux, parfois IBAN / SIRET du client final. Catégorie : données d'identification + données professionnelles. Pas de données de santé → pas d'obligation HDS.

## Finalités

1. Extraire un JSON structuré pour préparer un devis
2. Orchestrer des flux (email → n8n → FastAPI)
3. Journaux techniques (erreurs, santé des conteneurs)

Pas de réentraînement de modèle, pas de cession, pas de profiling commercial.

## Localisation et transferts

- Inférence par défaut : VPS OVH Roubaix (`vps-b377201e.vps.ovh.net`)
- Base : Supabase `eu-west-1`
- API métier : Render Frankfurt
- **Interdit par défaut** : envoyer un document client vers OpenAI / Gemini / Anthropic / portail Nous. Un tenant peut activer un provider cloud dans Blueseatra : cela devient un transfert hors UE à documenter (CCT + information du client)
- **Mistral** (`custom:mistral`, UE) et **OpenCode Free** (`opencode-free`, modèles hébergés aux États-Unis) sont accessibles par la passerelle depuis le 09/10/2026.
  - Blueseatra masque le texte de **tous** les appels IA avant l'envoi : adresses, noms de sites, clients, donneurs d'ordre, personnes, identifiants.
  - Aucune image n'est envoyée hors du VPS.
  - Plusieurs modèles gratuits d'OpenCode peuvent réutiliser les données ([conditions OpenCode Zen](https://opencode.ai/docs/zen/)) : à réserver aux essais. OpenCode Free reste un transfert hors UE à documenter.

## Mesures techniques (art. 32)

- TLS partout (Caddy / Let's Encrypt)
- Ollama non publié sur Internet
- Authentification par en-tête `X-Api-Key` (secret 256 bits)
- SSH par clé uniquement après durcissement
- fail2ban + UFW (22 / 80 / 443)
- Chiffrement des identifiants n8n (`N8N_ENCRYPTION_KEY`)
- Purge des exécutions n8n à 7 jours
- Télémétrie n8n désactivée
- Logs Hermes : secrets auto-redacted (doc officielle)
- Sauvegardes OVH quotidiennes (rétention 24 h) — insuffisant seul : exporter n8n + volumes hors site

## Durées de conservation

| Donnée | Durée | Où |
|---|---|---|
| Exécutions n8n | 7 jours | volume `n8n_data` |
| Sessions Hermes | à revoir chaque trimestre | volume `hermes_data` |
| Devis / comptes | durée contractuelle + obligations comptables | Supabase |
| Journaux SSH / fail2ban | 30 jours | `/var/log` |

## Droits des personnes

Les demandes d'accès / effacement passent par Blueseatra (base Supabase). Sur le VPS :
- n8n : supprimer les exécutions contenant la pièce
- Hermes : vider `sessions/` et `memories/` si un document y a transité
- Ollama : pas de persistance des prompts (hors logs applicatifs)

## Registre (extrait à recopier)

- Traitement : extraction IA de demandes de devis
- Base légale : exécution du contrat / intérêt légitime (préparation de devis)
- Destinataires : équipe interne ANELEC, sous-traitants UE ci-dessus
- Transferts hors UE : aucun par défaut

## Ce que ce dépôt ne fait pas

- Pas de registre CNIL automatisé
- Pas de DPA généré
- Pas d'analyse d'impact (AIPD) : à faire si le volume ou la sensibilité augmente
