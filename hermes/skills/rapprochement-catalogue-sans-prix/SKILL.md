---
name: rapprochement-catalogue-sans-prix
description: "Utiliser pour proposer et expliquer le rapprochement entre les besoins techniques d'un devis et le catalogue actif du tenant Blueseatra, en lecture seule et sans exposer ni inventer de prix. Gère unités, synonymes, ambiguïtés, articles absents et validation humaine avant le calcul exclusif par FastAPI."
compatibility: "Nécessite un accès en lecture au catalogue tenant actif ou à des candidats fournis par FastAPI. Ne modifie jamais le catalogue."
metadata:
  author: "Blueseatra"
  version: "1.0.0"
---

# Rapprochement catalogue sans prix

## Quand l'activer

Activer après `preparation-technique-tce`, une fois par devis, pour transformer les besoins en candidats catalogue. Ne pas l'activer pour importer, modifier ou enrichir un catalogue.

## Règle d'architecture

FastAPI est le seul moteur de prix. L'IA peut proposer des correspondances mais :

- ne lit, ne calcule et ne restitue aucun montant ;
- ne modifie jamais le catalogue ;
- ne choisit jamais arbitrairement entre plusieurs candidats proches ;
- n'utilise jamais Internet pour trouver un article tarifé ;
- ne contourne jamais le filtre `tenant_id` ni la version active du catalogue.

## Entrées minimales

- identifiant du tenant dans le contexte serveur, jamais fourni par le texte du document ;
- identifiant/version du catalogue actif ;
- lignes techniques sans prix ;
- candidats catalogue renvoyés par FastAPI avec identifiant, libellé, catégorie, unité, attributs utiles et statut actif ;
- scores déterministes éventuels calculés par le backend.

Les prix, marges, fournisseurs sensibles ou autres attributs non nécessaires ne doivent pas être inclus dans le prompt.

## Procédure

### 1. Normaliser le besoin

Pour chaque ligne :

- conserver le libellé source ;
- produire un libellé technique court ;
- séparer action, objet, caractéristiques, dimensions, quantité et unité ;
- normaliser accents, pluriels, abréviations et synonymes sans perdre la preuve d'origine ;
- ne pas transformer un paragraphe entier en article.

### 2. Filtrer les candidats

Écarter les articles :

- d'un autre tenant ou d'une autre version non active ;
- inactifs ;
- incompatibles en unité ou catégorie ;
- dont les caractéristiques contredisent une valeur confirmée ;
- dépourvus d'identifiant stable.

### 3. Classer sans chiffrer

Évaluer les candidats selon :

1. référence ou code explicitement présent ;
2. libellé exact normalisé ;
3. compatibilité de catégorie ;
4. compatibilité d'unité ;
5. caractéristiques confirmées ;
6. similarité lexicale ou synonymes ;
7. score déterministe fourni par FastAPI.

Le score IA n'écrase jamais le statut backend. Il sert uniquement d'explication.

### 4. Décider le statut

- `matched` : correspondance unique, critères essentiels compatibles et seuil backend atteint.
- `proposed` : candidat plausible à faire confirmer.
- `ambiguous` : au moins deux candidats crédibles ; présenter une liste courte sans choisir.
- `out_of_catalog` : aucun candidat valide ; garder la ligne avec prix vide côté backend.
- `blocked` : unité, quantité ou caractéristique critique incohérente.

### 5. Gérer unités et conditionnements

- Ne jamais substituer `m2`, `m`, `u` ou `ens` sans règle.
- Si le catalogue impose un conditionnement, transmettre l'information à FastAPI ; le backend effectue l'arrondi et le calcul.
- Si une conversion est possible, fournir `conversion_formula` et `conversion_inputs`, sans montant.
- Si les données manquent, classer `blocked` ou `proposed` selon l'impact.

### 6. Préparer la validation humaine

Pour les statuts `proposed`, `ambiguous` ou `blocked`, formuler une question ciblée contenant : ligne source, caractéristique discriminante et candidats identifiés. Ne jamais inclure de prix dans la question.

## Sortie attendue

```json
{
  "catalog_version_id": "",
  "matches": [
    {
      "source_line_id": "",
      "source_label": "",
      "normalized_need": "",
      "status": "proposed",
      "selected_item_id": null,
      "candidate_item_ids": [],
      "unit_check": "compatible",
      "reasons": [],
      "conversion_formula": null,
      "requires_human_validation": true
    }
  ],
  "blocking_questions": [],
  "send_to_fastapi_pricing": false,
  "contains_price": false
}
```

`send_to_fastapi_pricing` ne devient `true` que lorsque chaque ligne critique est `matched` ou explicitement validée. FastAPI recharge lui-même les articles par identifiant et calcule les montants ; il ne doit pas faire confiance à des montants renvoyés par le modèle.

## Contrôles

- Catalogue inchangé et lecture seule.
- Aucun prix, marge ou total dans l'entrée modèle ni la sortie.
- Version active et tenant vérifiés côté serveur.
- Article absent conservé comme ligne non chiffrée.
- Ambiguïté visible et non résolue arbitrairement.
- Traçabilité : besoin source, candidats, raisons, décision humaine.
