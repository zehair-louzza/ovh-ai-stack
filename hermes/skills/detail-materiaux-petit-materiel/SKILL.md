# Détail des matériaux et du petit matériel

## Quand utiliser ce skill

Appelé par `devis-travaux-tce` (au moment de décomposer une prestation en lignes) et par `preparation-technique-tce` (§ préparation des lignes techniques), chaque fois qu'une prestation est décomposée en lignes de devis — que ce soit à la création, à la révision ou à une nouvelle version.

Ce skill ne se déclenche jamais seul et ne fixe aucun prix : il décide **quelles lignes proposer** (désignations, quantités, unités) à envoyer au matching catalogue (FastAPI). Seul FastAPI + le catalogue tenant chiffrent — règle absolue inchangée, voir `securite-donnees-devis`.

**Pont Blueseatra (2026-08-25)** : le pipeline SaaS automatisé (FastAPI → Ollama direct) n'appelle jamais le gateway Hermes et ne voit donc jamais ce fichier. La checklist par corps d'état et la règle de regroupement du petit matériel ci-dessous ont été recopiées directement dans `EXPAND_SYSTEM` (`backend/ai_service.py`, role=reason, modèle `gpt-oss:20b`) pour qu'elles s'appliquent réellement aux devis générés par le SaaS. Toute modification de ce skill doit être répercutée manuellement dans `EXPAND_SYSTEM` — aucune synchronisation automatique n'existe entre les deux.

## Règle absolue

Ne jamais limiter une prestation à la seule main-d'œuvre ou au seul matériau principal. Pour chaque prestation, identifier systématiquement :

1. La main-d'œuvre nécessaire.
2. Les matériaux principaux visibles ou structurels.
3. Les matériaux secondaires et accessoires indispensables à la pose (fixations, raccords).
4. Le petit matériel et les consommables utilisés ou laissés dans l'ouvrage.
5. Les prestations annexes nécessaires : préparation, protection, évacuation, nettoyage, essais, réglages, finitions.

## Catégories à vérifier par corps d'état

Ne pas ajouter une catégorie non pertinente pour la prestation demandée — cette liste sert à ne rien oublier, pas à tout inclure systématiquement.

- **Fixations** : vis, chevilles, goujons, clous, rivets, écrous, rondelles, colliers, supports, équerres, rails, pattes de fixation.
- **Étanchéité et calfeutrement** : silicone, mastic, joints, mousse expansive, bandes d'étanchéité, membrane, primaire d'accrochage, bandes résilientes.
- **Collage et préparation** : colle, mortier-colle, enduit, ragréage, primaire, ciment, sable, mortier, résine, dégraissant.
- **Finitions** : joints, baguettes, profilés, plinthes, seuils, couvre-joints, enduit de finition, sous-couche, peinture de retouche.
- **Protection et logistique** : bâches, films de protection, adhésifs de masquage, protections de sol/angles, sacs à gravats, big bags, transport, déchetterie, nettoyage de fin de chantier.
- **Électricité** (si applicable) : gaines, câbles, boîtes d'encastrement/dérivation, connecteurs, bornes, goulottes, disjoncteurs, appareillages, essais et mise en service.
- **Plomberie** (si applicable) : tubes, raccords, coudes, tés, vannes, siphons, joints, flexibles, colliers, robinets d'arrêt, consommables de brasage/collage/sertissage, essais d'étanchéité.
- **Plâtrerie / isolation** (si applicable) : rails, montants, fourrures, suspentes, vis placo, bandes, enduits, isolant, pare-vapeur, trappes de visite.
- **Revêtements / sols / faïence** (si applicable) : primaire, ragréage, sous-couche, colle, mortier-colle, croisillons, profilés, plinthes, barres de seuil.
- **Menuiserie** (si applicable) : cales, pattes de fixation, visserie, mousse expansive, joints, habillages, bavettes, quincaillerie.

## Regroupement du petit matériel (ligne forfait)

Ne pas facturer arbitrairement chaque consommable insignifiant ligne par ligne — cela alourdit le devis sans le rendre plus clair. Regrouper les consommables mineurs dans **une ligne dédiée explicite**, par exemple :

> Fournitures de pose et consommables : visserie, chevilles, colles, mastics, bandes, protections, petites fixations et produits de finition — forfait.

Règles de ce regroupement :

- Proportionné à l'ampleur réelle des travaux — ne pas gonfler ni minimiser.
- Ne doit **jamais** masquer un matériau principal coûteux : tout matériau significatif apparaît sur sa propre ligne, distincte.
- Toujours nommer les catégories couvertes (visserie, colles, bandes...), jamais un intitulé vague comme « divers fournitures ».
- Cette ligne, comme toute ligne, passe par le matching catalogue — si aucun article catalogue ne correspond, son prix reste vide (« hors catalogue »), jamais estimé par ce skill.

## Sortie attendue par ligne proposée

Chaque ligne proposée à FastAPI (jamais de prix) porte :

- `description` : désignation précise de la prestation ou de l'article.
- `quantity`, `unit` : quantité et unité réalistes.
- `category` : corps d'état ou nature (ex. « plomberie sanitaire », « fournitures de pose »).
- `line_type_hint` (optionnel) : `main_work`, `installation_supplies`, `consumable`, `finish`, `protection`, `waste_removal` ou `testing` — indication pour le classement de la ligne, jamais utilisée pour fixer un prix.
- `included_items` (optionnel, liste) : accessoires/consommables couverts par une ligne groupée (ex. ligne « fournitures de pose » → `["visserie", "chevilles", "colle"]`).
- `notes` (optionnel) : réserve ou hypothèse explicite si une donnée est incertaine (ex. « section des conducteurs à confirmer selon cheminement réel »).

## Contrôle avant émission du devis

Avant de finaliser le devis, vérifier :

- Que chaque ouvrage peut réellement être exécuté avec les lignes proposées (rien d'indispensable oublié).
- Qu'aucun accessoire obligatoire de pose ou de raccordement n'a été omis.
- Que les matériaux coûteux ou susceptibles d'être discutés sont détaillés séparément, jamais noyés dans une ligne forfait.
- Que les consommables mineurs sont regroupés de façon transparente (catégories nommées, pas « divers »).
- Que les exclusions sont mentionnées clairement (voir `redaction-descriptif-chantier` pour leur mise en forme).

## Interdits absolus

- Aucun prix, tarif ou montant proposé par ce skill — FastAPI + catalogue seuls chiffrent.
- Aucune quantité, marque, référence ou dimension inventée. En cas d'information insuffisante, ne pas deviner : ajouter une `notes` de réserve ou renvoyer la question au skill appelant (`rapprochement-catalogue-sans-prix` si l'ambiguïté porte sur le catalogue).
- Aucune ligne « divers fournitures » sans détail des catégories couvertes.
- Ne jamais présenter une prestation comme complète si un élément indispensable à sa pose ou son raccordement n'apparaît nulle part dans les lignes proposées.
