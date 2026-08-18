---
name: preparation-technique-tce
description: "Utiliser après l'intake et le découpage des options pour transformer chaque scénario de devis en descriptif professionnel, phases d'intervention, lots TCE, fournitures sans prix, main-d'œuvre en heures-homme et jours de déplacement. Complète devis-travaux-tce sans chiffrer et sans remplacer FastAPI."
compatibility: "Hermes Agent local, contexte Blueseatra. Internet permis uniquement pour normes, DTU, phasage et spécifications sans prix."
metadata:
  author: "Blueseatra"
  version: "1.0.0"
---

# Préparation technique TCE

## Quand l'activer

Activer une fois par scénario produit par `devis-options-master`, avant le rapprochement catalogue. Ne jamais mélanger deux options exclusives.

Ce skill spécialise la préparation technique. Il ne remplace pas `devis-travaux-tce`, qui reste le skill métier maître.

## Principes

- Décrire uniquement le périmètre demandé ou nécessaire à son exécution normale.
- Ne pas inventer une cause de panne, un diagnostic, un état de support ou un résultat d'essai.
- Distinguer : fourniture, pose, dépose, protection, essais, nettoyage, évacuation et remise en service.
- Internet peut documenter un vocabulaire, une séquence, une spécification ou un NF DTU ; il est interdit pour les prix.
- Une référence au DTU n'est ajoutée que si le domaine et la version sont identifiés. Sinon écrire « selon règles de l'art et prescriptions fabricant », sans inventer de numéro.
- L'IA produit des quantités, unités, heures-homme et jours uniquement quand elles sont établies ou explicitement marquées `estime`. FastAPI est le seul moteur de prix.

## Procédure par scénario

### 1. Verrouiller le périmètre

Créer un identifiant de scénario et recopier : donneur d'ordre, client ou enseigne, site, objet, contraintes et exclusions issues de l'intake. Toute autre option est inscrite dans `exclusions_options`.

### 2. Classer en lots TCE

Affecter chaque prestation à un lot pertinent, sans créer de lot vide :

1. installation, protections et accès ;
2. dépose, curage et évacuation ;
3. gros œuvre ou maçonnerie ;
4. cloisons, doublages, plafonds ;
5. menuiserie, serrurerie, vitrerie ;
6. plomberie, sanitaires, ECS ;
7. CVC, ventilation, climatisation ;
8. électricité, éclairage, courants faibles ;
9. revêtements de sols et murs ;
10. peinture et finitions ;
11. essais, nettoyage, repli et remise en service.

L'ordre peut être adapté au chantier, mais les dépendances techniques doivent rester cohérentes.

### 3. Décomposer les ouvrages

Pour chaque lot, produire :

- résultat attendu ;
- support ou équipement concerné ;
- dépose et préparation ;
- fourniture et accessoires nécessaires ;
- pose, raccordement ou finition ;
- contrôles et essais ;
- réserves, hypothèses et exclusions.

Ne jamais utiliser comme unique ligne la reformulation du titre de la demande. Lister les composants concrets, sans marque ni référence si elles ne sont pas confirmées.

### 4. Quantités et unités

- Reprendre les mesures confirmées.
- Séparer `quantite_source` et `quantite_estimee`.
- Utiliser des unités explicites : `u`, `ens`, `m`, `m2`, `m3`, `h-h`, `jour`.
- Ne pas convertir une unité sans montrer la règle de conversion.
- Une quantité inconnue vaut `null`, jamais `1` par défaut, sauf si la source confirme un ensemble unique.

### 5. Main-d'œuvre et déplacement

- `labor_hours` représente les **heures-homme**, pas une durée calendaire ni un prix.
- Décomposer en installation, exécution, essais, nettoyage et repli.
- `travel_days` représente les jours réels de présence sur site.
- `crew_size` reste distinct de `labor_hours`.
- Toute estimation porte `status: estime`, une justification et ses hypothèses.
- Ne jamais convertir heures ou jours en euros.
- En cas d'incertitude critique sur accès, phasage, travail de nuit ou coactivité, laisser la valeur à confirmer.

### 6. Rédiger le descriptif client

Rédiger en français professionnel :

1. intitulé du scénario ;
2. périmètre et site ;
3. déroulement chronologique ;
4. essais et remise en service ;
5. hypothèses et exclusions visibles ;
6. contraintes client nécessaires à l'intervention.

Le descriptif doit être cohérent ligne par ligne avec la préparation technique.

## Sortie attendue

```json
{
  "scenario_id": "",
  "title": "",
  "works_description_client": "",
  "lots": [
    {
      "lot": "",
      "scope": "",
      "line_items_unpriced": [
        {"description": "", "quantity": null, "unit": "", "status": "confirme", "evidence": ""}
      ],
      "phases": [],
      "tests": [],
      "assumptions": [],
      "exclusions": []
    }
  ],
  "labor": {"hours_person": null, "crew_size": null, "status": "a_confirmer", "basis": []},
  "travel": {"on_site_days": null, "status": "a_confirmer", "basis": []},
  "blocking_questions": [],
  "contains_price": false
}
```

## Garde-fous finaux

- Un scénario = un devis.
- Aucun montant ou taux horaire dans la sortie.
- Aucun article catalogue choisi ici.
- Aucun DTU cité sans vérification.
- Toute prestation supplémentaire non demandée est une suggestion séparée à valider, jamais une ligne imposée.
