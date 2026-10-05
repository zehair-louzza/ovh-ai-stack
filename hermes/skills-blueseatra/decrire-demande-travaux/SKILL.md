---
name: decrire-demande-travaux
description: "Alias de transition vers la rédaction TCE v4."
metadata:
  version: "4.0.0"
---
# Rédaction : alias de compatibilité

Pour une nouvelle demande, charge `blueseatra-tce-redaction` après les validations
du backend. Ne lis ni prix, ni catalogue complet, ni pièces brutes à cette étape.

`references/schema.json` conserve le contrat narratif historique du SaaS uniquement
si ce contrat est explicitement demandé. Préserve les actions et les inclusions
reçues, sans ajouter de fourniture, de durée ou d'exclusion ; ne force jamais cinq
étapes lorsqu'il y en a moins. Aucun montant ni décision d'approbation.
