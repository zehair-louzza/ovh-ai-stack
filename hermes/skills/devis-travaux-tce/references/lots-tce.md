# Nomenclature des lots TCE et structuration du devis

## 1. Quand structurer en lots

- Devis multi-corps d'état, rénovation complète, aménagement de boutique/bureaux : **toujours** structurer en lots numérotés.
- Petite intervention mono-métier (ex. reprise peinture après dégât des eaux) : un seul bloc suffit, éventuellement scindé en « Préparation / Fournitures / Main-d'œuvre / Déplacement ».

## 2. Nomenclature TCE de référence

Numéroter les lots dans l'ordre logique d'exécution. N'utiliser que les lots réellement concernés :

| N° | Lot | Contenu typique |
|---|---|---|
| 0 | Installation de chantier / Préliminaires | Protections, signalétique, installations provisoires, gestion des accès, nettoyage courant |
| 1 | Démolition — Curage — Dépose | Dépose revêtements, cloisons, équipements ; tri et évacuation des déchets (benne, déchetterie) |
| 2 | Gros œuvre — Maçonnerie | Ouvertures, reprises structurelles, chapes, seuils, scellements |
| 3 | Plâtrerie — Cloisons — Faux plafonds | Cloisons sèches, doublages, isolation, faux plafonds démontables ou plaques, bandes et enduits |
| 4 | Menuiseries extérieures | Fenêtres, portes extérieures, vitrines, stores |
| 5 | Menuiseries intérieures — Agencement | Portes, blocs-portes, plinthes, placards, mobilier d'agencement |
| 6 | Électricité — Courants forts et faibles | Tableaux, distribution, appareillage, éclairage, RJ45, alarme, contrôle d'accès |
| 7 | Plomberie — Sanitaires | Alimentation, évacuation, appareils sanitaires, production ECS |
| 8 | CVC — Chauffage, Ventilation, Climatisation | Émetteurs, PAC, VMC, splits, réseaux aérauliques (souvent sous-traité : le préciser) |
| 9 | Revêtements de sols | Sols souples, carrelage, parquet, ragréage, plinthes |
| 10 | Revêtements muraux — Peinture | Préparation des supports, sous-couche, peinture, toile de verre, papier peint, faïence murale |
| 11 | Serrurerie — Métallerie | Garde-corps, grilles, portes métalliques, quincaillerie de sécurité |
| 12 | Nettoyage de fin de chantier — Repli | Nettoyage fin, remise en état des abords, levée de réserves |

Numérotation hiérarchique autorisée : `1`, `1.1`, `1.2`, `2`… selon la complexité du chantier.

### Familles catalogue ↔ lots du devis

La colonne `Famille` d'un catalogue (notamment le catalogue étendu type Blueseatra : gros œuvre, second œuvre, quincaillerie, électricité CFO/CFA, plomberie sanitaire, CVC, serrurerie, sécurité, consommables chantier, maintenance multitechnique) ne correspond pas toujours 1:1 à un numéro de lot d'exécution. Table de correspondance par défaut, à ajuster selon le chantier :

| Famille catalogue | Lot(s) TCE correspondant(s) |
|---|---|
| Gros œuvre | 2 — Gros œuvre — Maçonnerie |
| Second œuvre (plâtrerie, isolation, faux plafonds) | 3 — Plâtrerie — Cloisons — Faux plafonds |
| Quincaillerie | Répartie selon l'usage : lot 5 (menuiseries/agencement) ou lot 11 (serrurerie), jamais un lot à part entière |
| Électricité CFO/CFA | 6 — Électricité — Courants forts et faibles |
| Plomberie sanitaire | 7 — Plomberie — Sanitaires |
| CVC | 8 — CVC |
| Serrurerie | 11 — Serrurerie — Métallerie |
| Sécurité (alarme, détection incendie, contrôle d'accès, vidéosurveillance) | Intégré au lot 6 (Électricité CFO/CFA) sauf si le volume justifie un lot dédié « Sécurité » explicitement demandé |
| Consommables chantier | Répartis dans le lot 0 (Installation de chantier) ou dans le lot d'exécution concerné s'ils sont spécifiques à une prestation |
| Maintenance multitechnique | Un seul bloc « Maintenance » si intervention mono-site courte, sinon réparti par corps de métier concerné (électricité, serrurerie, CVC…) |

Ne jamais créer un lot vide par simple présence d'une famille dans le catalogue : un lot n'apparaît dans le devis que si des lignes chiffrées lui sont réellement rattachées.

## 3. Prestations à ne pas oublier par lot

- **Tous lots** : protections, consommables, évacuation des déchets, nettoyage.
- **Démolition** : benne ou sacs à gravats, coût d'évacuation et de traitement des déchets (obligation de tri 7 flux), dépose soignée si réemploi.
- **Plâtrerie** : bandes à joint, enduit, ponçage, renforts pour charges lourdes, blocs-portes à intégrer.
- **Peinture** : rebouchage, ponçage, sous-couche adaptée au support, 2 couches de finition par défaut, temps de séchage entre couches (impact planning).
- **Sols** : ragréage/préparation du support, barres de seuil, plinthes, temps de séchage du ragréage.
- **Électricité** : mise en sécurité/consuel si modification du tableau, repérage, essais.
- **Plomberie** : essais d'étanchéité, mise en service.
- **Maintenance multitechnique** : petit consommable, temps de diagnostic, rapport d'intervention.

## 4. Présentation dans le devis

- Chaque lot : **bandeau de titre**, lignes chiffrées, **sous-total HT du lot**.
- Avant les totaux généraux : **récapitulatif par lot** (tableau « Lot / Montant HT »).
- Totaux généraux : Total HT, TVA détaillée par taux, Total TTC.
- L'ordre des lignes dans un lot suit l'ordre d'exécution : préparation → fournitures/pose → finitions.

## 5. Cohérence inter-lots

Vérifier systématiquement :

- Les interfaces entre lots (ex. la peinture intervient après les bandes de plâtrerie et le passage des gaines électriques).
- Qu'aucune prestation n'est chiffrée deux fois dans deux lots différents.
- Que le planning respecte l'ordre d'exécution et les temps de séchage.
- Que les lots sous-traités (ex. CVC) sont signalés comme tels dans les conditions si l'utilisateur le précise.
