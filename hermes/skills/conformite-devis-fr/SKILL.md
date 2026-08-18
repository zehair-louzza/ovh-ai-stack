---
name: conformite-devis-fr
description: "Utiliser avant validation ou export d'un devis en France pour contrôler les mentions obligatoires, la qualification de TVA ligne par ligne, les conditions d'exécution et l'acceptation client. Produit des décisions et alertes sans calculer les montants, FastAPI restant le seul moteur de prix."
compatibility: "Contexte juridique et fiscal français. Requiert les données du devis et du profil entreprise. Une validation humaine demeure obligatoire pour les cas ambigus."
metadata:
  author: "Blueseatra"
  version: "1.0.0"
---

# Conformité d'un devis en France

## Quand l'activer

Activer après chiffrage FastAPI et avant toute validation ou génération de PDF client. Réactiver à chaque nouvelle version modifiant le périmètre, la TVA, les parties ou les conditions.

Ce skill ne fournit pas de conseil juridique définitif et ne calcule pas l'impôt ni les montants.

## Sources de référence

- Devis et information précontractuelle : https://entreprendre.service-public.fr/vosdroits/F31144
- TVA des travaux dans les logements : https://www.impots.gouv.fr/professionnel/questions/quel-taux-de-tva-appliquer-pour-les-travaux-realises-dans-les-logements

Si la règle applicable n'est pas certaine, demander une validation comptable ou juridique ; ne jamais inventer.

## Hiérarchie des données

1. données confirmées du dossier ;
2. profil légal du tenant ;
3. décisions fiscales validées par l'utilisateur ;
4. règles officielles à jour ;
5. aucune déduction silencieuse.

## Contrôle des parties et de l'objet

Vérifier la présence et la séparation de :

- identité complète du prestataire ;
- destinataire légal ou donneur d'ordre ;
- client/enseigne si distinct ;
- site d'intervention ;
- objet, périmètre, quantités, unités, délais ou date d'exécution ;
- référence, date, version, statut et durée de validité ;
- modalités de paiement, acceptation et signature si requises.

L'adresse du site ne remplace pas l'adresse du destinataire.

## Qualification de TVA

### Principes

- Demander à FastAPI d'appliquer la TVA ligne par ligne à partir d'un code fiscal validé.
- Ne jamais déduire un taux réduit du seul mot « rénovation ».
- Les taux réduits de 10 % ou 5,5 % concernent, sous conditions, certains travaux dans des logements d'habitation achevés depuis plus de deux ans ; la page impots.gouv.fr détaille les travaux et conditions.
- Une boutique, un bureau ou un autre local exclusivement professionnel ne doit pas être traité automatiquement comme un logement éligible.
- Les équipements achetés directement par le client peuvent suivre un traitement différent de la pose facturée par l'entreprise.
- Un taux nul exige un motif légal explicite et la mention correspondante ; ne jamais utiliser `0` comme valeur de secours.

### Données à recueillir

- usage du local : habitation, professionnel ou mixte ;
- ancienneté du logement si pertinent ;
- nature exacte des travaux ;
- fourniture par l'entreprise ou achat direct client ;
- éligibilité énergétique documentée si 5,5 % envisagé ;
- régime de TVA du prestataire ;
- justificatif ou attestation requis selon la réglementation à jour.

Retourner `vat_code_candidate` et `status`, jamais un montant de TVA recalculé par le modèle.

## Mentions et conditions

Contrôler notamment :

- nom ou raison sociale, adresse, identifiants légaux et contacts du prestataire ;
- nom et adresse du client destinataire ;
- date du devis et référence unique ;
- description détaillée, quantités, unités et prix issus de FastAPI ;
- total HT, ventilation de TVA et total TTC issus de FastAPI ;
- durée de validité ;
- date ou délai d'exécution ;
- frais ou modalités de déplacement lorsqu'ils sont facturés ;
- conditions de paiement, acompte éventuel et pénalités si applicables ;
- assurances professionnelles lorsque la réglementation et l'activité l'exigent ;
- cadre d'acceptation daté et signé ;
- CGV ou renvoi accessible, si applicable.

Ne pas déclarer « conforme » si un champ obligatoire est vide ou contradictoire.

## Sortie attendue

```json
{
  "status": "blocked",
  "party_checks": [],
  "vat_decisions": [
    {"line_id": "", "vat_code_candidate": null, "status": "a_confirmer", "basis": [], "missing_evidence": []}
  ],
  "mandatory_mentions": [
    {"field": "", "status": "present", "value_source": "tenant_profile", "issue": null}
  ],
  "conditions_checks": [],
  "blocking_issues": [],
  "warnings": [],
  "amounts_recalculated_by_ai": false
}
```

## Blocage

Bloquer le PDF final si :

- partie, site ou périmètre critique non identifié ;
- TVA non justifiée ;
- ligne nécessaire sans prix FastAPI ;
- totaux absents ou incohérents selon le recalcul backend ;
- identifiant légal ou mention essentielle manquante ;
- statut du devis non validé.

Un export brouillon reste possible uniquement avec un marquage visible « BROUILLON » et sans présentation trompeuse.
