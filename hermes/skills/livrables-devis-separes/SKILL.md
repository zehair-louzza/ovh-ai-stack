---
name: livrables-devis-separes
description: "Utiliser pour préparer les contrats de données et règles d'export distincts du PDF client et du XLSX interne d'un devis Blueseatra. Empêche la fuite des coûts, marges, fournisseurs, scores de matching et notes internes, tout en assurant un rendu professionnel, versionné et cohérent avec les totaux FastAPI."
compatibility: "S'applique aux exports Blueseatra. Nécessite un devis validé par FastAPI et le profil entreprise."
metadata:
  author: "Blueseatra"
  version: "1.0.0"
---

# Livrables séparés : PDF client et XLSX interne

## Quand l'activer

Activer après `conformite-devis-fr` et avant la génération de fichiers. Il ne génère aucun prix : les montants sont copiés depuis le snapshot validé par FastAPI.

## Règle de séparation

Le PDF client et le XLSX interne sont deux projections d'un même `quote_version_id`, mais deux contrats de données distincts. Ne jamais produire l'un en masquant seulement visuellement des colonnes de l'autre.

## Contrat du PDF client

### Champs autorisés

- profil public du prestataire et logo ;
- destinataire légal, client/enseigne et site selon le gabarit ;
- numéro, date, version, objet, validité et statut ;
- descriptif des travaux, lots, désignations, quantités et unités ;
- prix de vente, taux de TVA et totaux fournis par FastAPI ;
- conditions, hypothèses, exclusions et acceptation ;
- mentions légales validées.

### Champs interdits

- prix d'achat et coût de revient ;
- marge, coefficient, rentabilité ;
- fournisseurs, contacts et délais internes ;
- score et raisons de matching ;
- candidats catalogue rejetés ;
- notes internes, prompts, traces IA ou questions de contrôle ;
- identifiants techniques, secrets, chemins de fichier ou données d'autres tenants.

### Rendu

- format A4, hiérarchie typographique claire et pagination ;
- en-tête professionnel, destinataire identifiable et site visible ;
- lots et sous-totaux lisibles ;
- ventilation TVA et totaux alignés ;
- coupures de page sans ligne orpheline ;
- pied de page légal sur chaque page ;
- zone d'acceptation ;
- filigrane visible si statut `brouillon`.

## Contrat du XLSX interne

Le XLSX peut inclure, selon les droits :

- feuille `Devis` ;
- feuille `Préparation interne` ;
- feuille `Planning` ;
- feuille `Hypothèses et exclusions` ;
- feuille `Paramètres` ;
- feuille `Suivi de chantier` ;
- article catalogue, prix d'achat, marge, fournisseur, délai, statut de matching et rentabilité.

Règles :

- chaque colonne sensible est explicitement marquée `interne` ;
- formules protégées mais données contrôlables ;
- cellules d'entrée séparées des cellules calculées ;
- références au `quote_version_id`, `pricing_snapshot_id` et catalogue actif ;
- aucun export interne vers un destinataire client sans confirmation et contrôle de droit.

## Procédure

1. Charger la version validée et son snapshot depuis FastAPI.
2. Vérifier le statut et l'absence de blocage conformité.
3. Construire deux objets indépendants : `client_view` et `internal_view`.
4. Appliquer une liste blanche de champs au PDF, jamais une liste noire.
5. Recalculer ou vérifier les totaux uniquement côté FastAPI.
6. Générer les fichiers avec noms contenant référence et version.
7. Ouvrir les fichiers générés pour contrôle : pagination, accents, tableaux, formules, zones masquées.
8. Stocker l'empreinte, l'auteur, l'horodatage et la version du gabarit.

## Sortie attendue

```json
{
  "quote_version_id": "",
  "pricing_snapshot_id": "",
  "client_export": {
    "status": "ready",
    "allowed_fields": [],
    "forbidden_fields_detected": [],
    "watermark": null
  },
  "internal_export": {
    "status": "ready",
    "sensitive_fields": [],
    "access_role_required": "operator"
  },
  "visual_checks": [],
  "blocking_issues": [],
  "amount_source": "fastapi_snapshot"
}
```

## Tests anti-fuite

Avant livraison du PDF, rechercher dans le texte extrait du PDF : `prix achat`, `marge`, `coefficient`, `fournisseur`, `score`, `prompt`, `tenant_id`, `matched_item_code`. Toute occurrence inattendue bloque l'export.

Vérifier aussi les métadonnées du fichier, annotations, pièces jointes incorporées et calques. Le masquage par couleur blanche ou colonne cachée n'est pas une suppression.
