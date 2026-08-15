# Règles de chiffrage — marges, main-d'œuvre, déplacement, quantités

## 1. Distinction des marges

Deux marges distinctes coexistent, à ne jamais confondre :

1. **`Marge_%` du catalogue** : donnée historique / informative. Ne jamais la modifier, ne jamais l'utiliser automatiquement pour le devis, sauf consigne explicite.
2. **Marge du devis interne** : coefficient réellement appliqué au devis. Visible et modifiable uniquement dans le XLSX interne. Jamais affichée dans le PDF client.

Coefficients par défaut (surchargeables par l'utilisateur) :

- Fournitures et matériaux : **× 1,40**.
- Main-d'œuvre : **× 1,00**.
- Déplacement : **× 1,00**.

## 2. Prix, marges et arrondis

Pour les fournitures et matériaux :

> `Prix_vente_HT = ARRONDI.SUP(Prix_achat_HT × Marge ; 0)`

Règles :

- Arrondir le prix de vente HT **unitaire** des fournitures **à l'euro supérieur**.
- Ne jamais appliquer automatiquement une marge à la main-d'œuvre ou au déplacement.
- Prix de vente HT de la MO et du déplacement = tarif défini par l'utilisateur.
- `Total_HT_ligne = Quantité × Prix_vente_HT`.

Exemple : prix achat 8,86 € × 1,40 = 12,40 € → **13,00 €** après arrondi supérieur. Quantité 1 rouleau → Total HT ligne : 13,00 €.

### Seuil d'alerte sur la marge

- Coefficient ≤ ×2,00 : appliquer normalement.
- Coefficient ≥ ×2,00 et < ×3,00 : appliquer uniquement après confirmation explicite de l'utilisateur.
- Coefficient ≥ ×3,00 : afficher une alerte de cohérence interne avant validation finale (écart important par rapport aux pratiques usuelles).

### Vérification automatique obligatoire avant toute livraison

Avant de livrer un chiffrage, XLSX ou PDF, vérifier systématiquement :

- `Total_TTC > Total_HT` si un taux de TVA > 0 % s'applique.
- `Total_HT` = somme exacte de tous les `Total_HT` de ligne (jamais un total saisi à la main).
- Aucune ligne n'a un `Total_HT = 0` sauf si sa quantité est explicitement `0` et signalée comme telle.
- Pour toute unité indivisible, la quantité facturée reste cohérente avec la quantité à commander (voir §6.3).

Si l'une de ces règles échoue, afficher avant livraison une alerte explicite du type :
> ⚠️ **[ALERTE CALCUL]** : la ligne [désignation] présente un Total HT à zéro, incohérent ou une quantité non facturable. Vérification requise avant validation.

## 3. Approche déboursé sec (contrôle interne)

Pour les devis importants ou les analyses de rentabilité, raisonner en économiste de la construction :

- **Déboursé sec (DS)** = coût direct = fournitures au prix d'achat + main-d'œuvre au coût réel + location de matériel.
- **Frais de chantier** : installation, protections, nettoyage, évacuation des gravats, benne, consommables.
- **Frais généraux et marge** : couverts par le coefficient de vente (par défaut 1,40 sur fournitures).
- Le XLSX interne doit permettre de visualiser : coût d'achat total, prix de vente total, **marge brute en € et en %** par lot et pour le devis global.

Ne jamais exposer ces notions dans le PDF client.

## 4. Main-d'œuvre : heures-homme

La main-d'œuvre est toujours calculée et affichée en **heures-homme**.

- Unité : `heure`. Ne jamais présenter la MO comme un forfait quand un taux horaire est fourni.
- Taux horaire HT = celui communiqué par l'utilisateur (défaut : 42 € HT/h).
- Quantité = total d'heures-homme.

> `Heures-homme = Nombre de personnes × Heures par jour par personne × Nombre de jours`

Exemple : 2 personnes × 4 h/jour × 2 jours = **16 heures-homme**.

### Exception : forfait explicite

Si l'utilisateur demande **explicitement** une main-d'œuvre au forfait (plutôt qu'en heures-homme) :

- Autoriser une ligne `forfait` uniquement dans ce cas, jamais par défaut.
- Reconstituer et conserver le détail (personnes × heures × jours estimés) dans les données internes.
- Ne jamais convertir silencieusement un forfait en heures-homme dans le PDF client, ni l'inverse.
- Marquer la ligne `Estimé` dans `Hypothèses & exclusions` si aucun détail horaire n'est disponible.

Ligne type :

> Main-d'œuvre | 16,00 | heure | 42,00 € | 1,00 | 42,00 € | 672,00 €

Si le calcul est ambigu, poser une seule question :
> « Les heures indiquées sont-elles prévues par jour, par personne ou pour l'ensemble de l'intervention ? »

### Limite journalière obligatoire

> Une personne ne doit jamais être planifiée plus de **7 heures ouvrables par jour**.

- Vérifier systématiquement : heures/personne/jour ≤ 7.
- Si le volume dépasse la limite, répartir sur plusieurs jours ; si le nombre de jours fourni est insuffisant, demander confirmation ou proposer une répartition réaliste.
- Capacité maximale : 1 personne = 7 h-h/jour ; 2 personnes = 14 h-h/jour ; 3 personnes = 21 h-h/jour.

### Temps à ne pas oublier

Intégrer dans les heures-homme (ou en ligne dédiée si l'utilisateur le souhaite) : installation et repli de chantier, protections, temps de séchage impliquant un second passage, nettoyage de fin de chantier, évacuation des déchets.

## 5. Déplacement : en jours

- Unité : `jour`. Ne jamais présenter le déplacement comme un forfait quand un tarif journalier est fourni.
- Nombre de jours de déplacement = jours réels d'intervention (2 jours de travaux → 2 jours de déplacement, sauf consigne contraire).

> `Total_déplacement_HT = Nombre_de_jours × Tarif_déplacement_journalier_HT`

Ligne type :

> Déplacement Île-de-France | 2,00 | jour | 40,00 € | 1,00 | 40,00 € | 80,00 €

## 6. Quantités, unités et unités d'achat

### 6.1 Quantités et unités

Chaque ligne comporte une **quantité réelle** et une **unité adaptée** : `m²`, `ml`, `m`, `L`, `kg`, `sac`, `rouleau`, `cartouche`, `boîte`, `u`, `heure`, `jour`, `forfait` (exceptionnel), `ens` (ensemble, exceptionnel).

- Ne jamais laisser une quantité vide ou à zéro.
- Ne jamais utiliser une unité incohérente avec l'article.
- Vérifier que chaque matériau est utile aux travaux décrits ; ne jamais ajouter de matériel non demandé.
- Ne pas oublier les indispensables : bandes à joint, enduit de rebouchage/lissage, ponçage, sous-couche, peinture (2 couches par défaut), protections (bâches, adhésifs, cartons), mastics, visserie, consommables.
- Si une quantité est estimée, le noter dans les informations internes (niveau « Estimé »).

### 6.2 Pertes et chutes (coefficients usuels)

Sauf consigne contraire, appliquer un coefficient de perte sur les quantités à commander :

- Peinture : rendement fabricant + 5–10 %.
- Sols souples / parquet : + 5–8 % (jusqu'à + 10 % en pose diagonale).
- Carrelage / faïence : + 8–10 %.
- Plaques de plâtre : + 5–10 %.

Noter le coefficient utilisé dans les hypothèses internes.

### 6.3 Unités d'achat (conditionnement) et trois niveaux de quantité

Respecter l'unité commerciale du catalogue, et distinguer systématiquement **trois** niveaux de quantité pour les fournitures :

1. **Quantité consommée estimée** : besoin réel calculé à partir des mesures/relevés (usage interne, analyse de rentabilité).
2. **Quantité à commander** : quantité consommée arrondie à l'unité commerciale supérieure pour les articles vendus au rouleau, sac, boîte, cartouche, pot ou à l'unité indivisible (`Qté_commandée = ARRONDI.SUP(Qté_consommée ; 0)` en unités de conditionnement). Fractions autorisées pour `m²`, `ml`, `m`, `L`, `kg` si compatibles avec le mode d'achat.
3. **Quantité facturée** : par défaut identique à la quantité à commander (le client paie l'unité d'achat complète), sauf instruction explicite de facturer la consommation réelle — dans ce cas, le signaler dans `Hypothèses & exclusions`.

Le XLSX interne conserve les trois colonnes (voir `references/livrables-xlsx-pdf.md`) ; le PDF client n'affiche jamais que la quantité facturée, sous le libellé `Qté`.

Ne jamais facturer une fraction impossible à acheter sans le mentionner dans les hypothèses internes.

## 7. Ratios de contrôle (vraisemblance, jamais pour chiffrer)

Ces ratios servent **uniquement à contrôler la vraisemblance** d'un chiffrage, jamais à fixer un prix (les prix viennent du catalogue) :

- Peinture murs/plafonds (2 couches, support préparé) : environ 8–12 m²/h par peintre.
- Pose sol souple en lés : environ 10–15 m²/h ; carrelage sol : environ 1–2 m²/h.
- Cloison plaques de plâtre sur ossature : environ 2–4 m²/h (structure + parement + bandes).

Si le chiffrage s'écarte fortement de ces ordres de grandeur, signaler l'écart à l'utilisateur en interne.

## 8. Spécificités par contexte

### Secteur tertiaire (boutiques, bureaux, commerces, ERP)

- Prévoir : travaux en horaires décalés ou de nuit si le site reste exploité (majoration éventuelle du taux horaire — demander), protections renforcées des zones ouvertes au public, contraintes ERP (dégagements, sécurité incendie), co-activité, plan de prévention éventuel.
- Chantiers boutiques (organisation type) : 2 techniciens ; peinture sur 2 jours — jour 1 : préparation, protections, rebouchage ; jour 2 : ponçage, peinture, finitions.

### Logement individuel (particuliers)

- Vérifier l'éligibilité aux taux réduits de TVA (voir `tva-mentions-legales.md`).
- Mentions consommateur obligatoires sur le devis (voir même fichier).
- Prévoir la protection des biens et le nettoyage de fin de chantier.
