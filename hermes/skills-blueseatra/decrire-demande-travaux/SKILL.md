---
name: decrire-demande-travaux
description: "Rédige le descriptif de travaux destiné au client à partir d'éléments déjà arrêtés (intitulé, fournitures, lieu, exclusions) : périmètre, préliminaires, déroulement chronologique et contrôles de fin de travaux, en style de rédacteur technique du bâtiment. À utiliser après extraire-demande-travaux, une fois par devis ou par variante."
version: 1.0.0
metadata:
  hermes:
    tags: [devis, btp, tce, redaction, blueseatra]
    category: blueseatra
---

# Décrire les travaux d'un devis

## Quand l'utiliser
Après `extraire-demande-travaux`, une fois par devis. S'il y a des variantes exclusives, une fois par variante : chacune forme un devis distinct.

## Sortie obligatoire
Un seul objet JSON conforme à `references/schema.json`, avec quatre champs : `description`, `preliminaires`, `etapes` et `controles_fin_travaux`.

## Règles de rédaction
- Écrire comme dans un devis d'entreprise du bâtiment : clair pour le client, irréprochable pour un maître d'ouvrage ou un bureau de contrôle.
- Phrases courtes, verbe à l'infinitif et objet précis, 25 mots au plus par étape.
- Vocabulaire du métier (DTU, TCE, ERP, consignation, calfeutrement, autocontrôle), sans formule de remplissage.
- De 5 à 12 étapes chronologiques :
  - préliminaires ;
  - sécurisation ;
  - dépose, seulement en cas de remplacement ;
  - préparation des supports ;
  - pose, ouvrage par ouvrage ;
  - raccordements ;
  - finitions ;
  - essais et mise en service ;
  - autocontrôle ;
  - nettoyage et repli.
- Mentionner les moyens d'accès et engins retenus à l'extraction.
- Reprendre exactement les fournitures, engins et exclusions retenus : n'en ajouter aucun et n'en retirer aucun.

## Interdits
- Aucun prix, quantité, durée, nombre d'heures ni effectif : ils sont calculés par l'application.
- Aucune dépose pour une installation neuve.
- Aucune exclusion, contrainte, marque ou diagnostic qui n'a pas été fourni.

## Vérification
- JSON valide contre le schéma.
- Au moins 5 étapes.
- Aucun chiffre de prix ni de durée.
