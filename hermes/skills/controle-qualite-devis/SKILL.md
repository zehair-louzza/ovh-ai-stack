---
name: controle-qualite-devis
description: "Utiliser comme porte de contrôle avant validation, envoi ou nouvelle version d'un devis Blueseatra. Vérifie parties, options exclusives, périmètre, lots, catalogue, main-d'œuvre, déplacement, TVA, totaux backend, cohérence PDF/XLSX, traçabilité et absence de prix inventé, puis retourne PASS, WARN ou BLOCK."
compatibility: "Nécessite le dossier de demande, la sortie des skills, la version du devis et les résultats FastAPI."
metadata:
  author: "Blueseatra"
  version: "1.0.0"
---

# Contrôle qualité du devis

## Quand l'activer

Activer :

- avant passage de brouillon à validé ;
- avant génération ou envoi du PDF client ;
- après toute modification de périmètre, prix, TVA ou destinataire ;
- lors d'une nouvelle version.

Le contrôleur ne corrige pas silencieusement. Il signale, bloque ou renvoie au skill responsable.

## Niveaux

- `PASS` : contrôle réussi avec preuve.
- `WARN` : écart non bloquant, visible et accepté.
- `BLOCK` : risque contractuel, fiscal, financier, de confidentialité ou de périmètre.

Un contrôle non exécutable n'est pas `PASS` : il devient `BLOCK` ou `WARN` selon la criticité.

## Checklist de contrôle

### A. Source et parties

- document source identifiable et lisible ;
- donneur d'ordre, client/enseigne et site séparés ;
- preuves et incertitudes conservées ;
- contradictions résolues ou visibles ;
- pièces jointes critiques présentes.

### B. Options exclusives

- `devis-options-master` a été exécuté ;
- nombre de scénarios cohérent avec les alternatives ;
- chaque devis exclut explicitement les autres options ;
- aucune alternative exclusive n'est incluse dans un total commun.

### C. Périmètre et technique

- descriptif client cohérent avec les lignes ;
- lots, dépose, préparation, pose, essais, nettoyage et repli traités si pertinents ;
- pas de diagnostic inventé ni prestation imposée hors demande ;
- quantités et unités présentes ou marquées à confirmer ;
- DTU ou norme cité uniquement avec référence vérifiée.

### D. Catalogue et prix

- catalogue tenant actif et version identifiée ;
- catalogue resté en lecture seule ;
- article choisi par identifiant stable ;
- ambiguïtés validées humainement ;
- ligne hors catalogue conservée sans prix ;
- tous les montants proviennent de FastAPI et du snapshot ;
- aucun montant calculé ou inventé par l'IA.

### E. Main-d'œuvre et déplacement

- heures exprimées en heures-homme ;
- effectif, heures et jours non confondus ;
- jours de déplacement égaux aux jours de présence sauf règle validée ;
- hypothèses visibles ;
- conversion en montant effectuée uniquement par FastAPI.

### F. TVA et légalité

- usage du local et conditions de taux documentés ;
- TVA qualifiée ligne par ligne ;
- absence de taux nul par défaut ;
- mentions obligatoires et conditions présentes ;
- durée de validité et date ou délai d'exécution présents.

### G. Calculs backend

Comparer les valeurs affichées au résultat FastAPI :

- total de chaque ligne ;
- sous-totaux par lot ;
- total HT ;
- TVA par taux ;
- total TTC ;
- remise éventuelle ;
- cohérence de l'arrondi.

L'IA ne refait pas le calcul de référence ; elle compare les champs et signale les divergences.

### H. Livrables et sécurité

- PDF client produit par liste blanche ;
- aucune donnée interne dans le PDF ;
- XLSX interne protégé et réservé au bon rôle ;
- référence et version identiques dans tous les livrables ;
- filigrane sur brouillon ;
- journal d'audit et snapshot présents ;
- pas de secret, prompt ou donnée inter-tenant.

## Sortie attendue

```json
{
  "overall": "BLOCK",
  "quote_version_id": "",
  "checks": [
    {
      "id": "A-01",
      "status": "PASS",
      "message": "",
      "evidence": [],
      "owner_skill": "intake-demande-devis",
      "blocking": false
    }
  ],
  "blockers": [],
  "warnings": [],
  "approved_exceptions": [],
  "next_action": "return_to_owner_skill"
}
```

## Règles de décision

Bloquer immédiatement pour : prix non issu de FastAPI, parties critiques incertaines, options fusionnées, article catalogue ambigu, TVA non justifiée, total divergent, donnée interne dans le PDF, donnée d'un autre tenant, statut non validé ou absence de snapshot.

Une exception doit contenir auteur, date, motif et portée. Elle ne peut jamais autoriser l'invention d'un prix ou une fuite inter-tenant.
