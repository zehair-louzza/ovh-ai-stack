---
name: suivi-relance-devis
description: "Utiliser après émission d'un devis pour préparer le suivi et les relances professionnelles : statut, échéance de validité, message contextualisé, journalisation, traitement des réponses et création d'une nouvelle version. N'envoie rien sans validation humaine et ne modifie aucun montant."
compatibility: "Contexte Blueseatra après émission d'un devis. L'envoi nécessite un canal autorisé et une validation humaine."
metadata:
  author: "Blueseatra"
  version: "1.0.0"
---

# Suivi et relance d'un devis

## Quand l'activer

Activer après émission d'un PDF client ou lorsqu'un devis reste sans réponse. Ne pas l'utiliser pour chiffrer, modifier le catalogue ou changer un devis validé en place.

## Principes

- Le destinataire de relance est le contact du donneur d'ordre ou le contact commercial validé, pas automatiquement le site.
- Ne jamais envoyer sans validation humaine explicite du destinataire, de l'objet, du corps et des pièces jointes.
- Ne jamais changer un montant, une TVA, une quantité ou une condition dans un message de relance.
- Toute demande de modification crée un brouillon de nouvelle version ; le devis validé d'origine reste immuable.
- Respecter les préférences de contact, oppositions et données personnelles.

## États recommandés

`brouillon`, `a_valider`, `envoye`, `consulte`, `relance_a_preparer`, `relance_validee`, `accepte`, `refuse`, `expire`, `revision_demandee`, `annule`.

Un changement d'état doit être journalisé avec auteur, horodatage, canal et preuve.

## Procédure

### 1. Vérifier le dossier

- référence, version, date d'envoi et durée de validité ;
- destinataire et adresse de contact validés ;
- statut courant ;
- dernière interaction ;
- éventuelle demande de ne plus relancer ;
- pièce jointe correspondant exactement à la version émise.

### 2. Déterminer l'action

- avant expiration : rappel courtois et proposition de réponse aux questions ;
- proche de l'expiration : mention factuelle de la date de validité ;
- après expiration : ne pas promettre le maintien des conditions ; proposer une révision ;
- refus : enregistrer le motif sans insister ;
- demande de modification : créer une tâche de révision et une nouvelle version ;
- acceptation : enregistrer la preuve et arrêter les relances.

Le calendrier de relance doit être paramétrable par tenant. Ne jamais inventer une cadence universelle.

### 3. Rédiger le message

Structure :

1. objet avec référence et site ;
2. salutation nominative si confirmée ;
3. rappel bref du devis et de sa date ;
4. question simple sur la décision ou les informations manquantes ;
5. date de validité uniquement si confirmée ;
6. disponibilité pour échanger ;
7. signature issue du profil tenant.

Ton professionnel, non pressant et sans jargon interne. Ne pas mentionner l'IA, le score de matching, les marges ou les coûts.

### 4. Valider avant envoi

Présenter un aperçu contenant : destinataire, canal, objet, corps, pièce jointe, référence/version et effet attendu. Attendre l'approbation. Après approbation, le canal externe peut envoyer et doit retourner une preuve ou une erreur.

### 5. Traiter les réponses

Classer la réponse sans surinterpréter :

- acceptation explicite ;
- refus explicite ;
- question ;
- demande de révision ;
- réponse ambiguë à confirmer.

Une acceptation ne peut être déduite d'un accusé de réception ou d'une consultation.

## Sortie attendue

```json
{
  "quote_version_id": "",
  "current_status": "envoye",
  "recommended_action": "prepare_followup",
  "recipient": {"name": "", "email": "", "role": "donneur_ordre", "confirmed": false},
  "draft": {"subject": "", "body": "", "attachment_version": ""},
  "requires_human_approval": true,
  "send_now": false,
  "audit_event": {"type": "followup_drafted", "timestamp": null},
  "blocking_issues": []
}
```

## Interdictions

- pas d'envoi automatique sans règle et consentement validés ;
- pas de pièce jointe interne ;
- pas de nouvelle version écrasant l'ancienne ;
- pas de promesse de prix ou délai non confirmée ;
- pas de relance après acceptation, refus définitif ou opposition.
