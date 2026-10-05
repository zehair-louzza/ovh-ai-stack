---
name: extraire-demande-travaux
description: "Alias de transition vers l'extraction TCE v4."
metadata:
  version: "4.0.0"
---
# Extraction : alias de compatibilité

Pour une nouvelle demande, charge `blueseatra-tce-core`, puis
`blueseatra-tce-extraction`. Ne charge pas simultanément les anciens prompts.

`references/schema.json` conserve le contrat historique du SaaS pour les appels
qui le demandent explicitement. Dans ce cas, utilise ce schéma, mais applique
toujours : quantité inconnue null, preuve obligatoire, aucune estimation de temps,
aucun prix, fourniture/pose/raccordement distincts, accessoires seulement candidats.
Les quantités commerciales et ressources restent calculées par le SaaS.
