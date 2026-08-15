# Livrables : XLSX interne et PDF client

## 1. XLSX interne — structure

Le XLSX interne est **strictement réservé à l'utilisateur**. Feuilles minimales :

### Feuille `Devis` (obligatoire)

Colonnes **exactement** dans cet ordre (alignées sur le tableau interne de référence du moteur Blueseatra) :

| Lot | Désignation | Qté consommée | Qté à commander | Qté facturée | Unité | Prix achat HT | Marge | Prix vente HT | Total HT |

Pour une ligne de main-d'œuvre ou de déplacement (unité `heure` ou `jour`, non soumise à conditionnement), les trois colonnes de quantité sont identiques.

Règles :

- `Marge` visible et modifiable uniquement en interne.
- Cellules de quantité, Prix achat, Marge, Prix vente, Total : **numériques** (jamais du texte).
- Formules fonctionnelles (pas des valeurs figées) :
  - Fournitures : `Prix_vente_HT = ARRONDI.SUP(Prix_achat_HT × Marge ; 0)` — en anglais : `=ROUNDUP(achat*marge;0)`.
  - MO et déplacement : `Prix_vente_HT = Prix_achat_HT × Marge`.
  - `Qté_à_commander = ARRONDI.SUP(Qté_consommée ; 0)` pour les unités de conditionnement indivisibles (voir `regles-chiffrage.md` §6.3).
  - `Total_HT_ligne = Qté_facturée × Prix_vente_HT`.
- En bas : Total HT (somme des lignes), TVA (par taux, ou mention franchise en base si 0 %), Total TTC.
- Si devis en lots : une section par lot avec sous-total, puis récapitulatif.
- Ajouter en zone interne : marge brute totale en € et en % (Total vente − Total achat).
- Si une ligne porte un prix hors catalogue, préfixer sa désignation par `[PRIX MANUEL — hors catalogue]`.
- Une fois le devis au statut `Validé`, cette feuille représente le **gel des prix** (équivalent du `pricing_snapshot` dans Blueseatra, voir `blueseatra-alignment.md` §5) : ne plus la modifier rétroactivement si le catalogue évolue ensuite ; créer une nouvelle version à la place.

### Feuille `Préparation interne`

Par article : Référence catalogue, Fournisseur, Marque, Délai, Quantité consommée estimée, **Quantité à commander** (arrondie au conditionnement), Date de commande prévue, Date de réception souhaitée, Alerte (délai long, rupture, à confirmer).

### Feuille `Planning`

Par jour : Date, Nombre de personnes, Heures par personne (≤ 7), Tâches prévues, Contraintes (séchage, accès, horaires site, co-activité).

### Feuille `Hypothèses & exclusions`

Deux tableaux : Hypothèses (libellé + niveau Confirmé/Estimé/À confirmer + impact) ; Exclusions (libellé + motif).

### Feuille `Paramètres`

Taux horaire MO, tarif déplacement, coefficients de marge, taux de TVA par catégorie (y compris mention si franchise en base 0 % appliquée), référence du catalogue utilisé (nom de fichier/version + date — pour traçabilité équivalente au `pricing_snapshot`), référence/version/statut du devis.

### Feuille `Suivi de chantier` (si demandée)

Dates prévues/réelles, tâches, matériaux livrés/posés, contrôles qualité, réserves et levées de réserves, réception. **Strictement interne**, jamais exportée dans le PDF client sauf demande explicite.

## 2. Informations internes confidentielles

Ne vont **jamais** dans le PDF client sans ordre explicite :

- Prix d'achat HT, marge catalogue, marge appliquée, coefficients.
- Références article, fournisseurs, marques, délais fournisseurs.
- Quantités à commander, dates de commande/réception, alertes d'approvisionnement.
- Planning détaillé, heures par personne, données de rentabilité.
- Hypothèses internes, risques, commentaires, réserves techniques.

## 3. PDF client — contenu

Le PDF client contient :

- **En-tête 3 colonnes** : Prestataire / Donneur d'ordre (client) / Site d'intervention. Les champs du bloc Prestataire (nom, adresse, SIRET, logo) proviennent du profil entreprise de l'utilisateur (équivalent `company_profiles` dans Blueseatra) ; ne jamais en inventer un champ manquant, le signaler « À confirmer ».
- Titre principal : `DEVIS N° [RÉFÉRENCE] — [CLIENT / ENSEIGNE] / [VILLE / SITE]`.
- Référence, date, version (si pertinent), durée de validité.
- Section **Objet** : description des travaux (issue des constats + demande).
- Lots numérotés avec bandeaux, lignes chiffrées, sous-totaux par lot.
- **Récapitulatif par lot** avant les totaux.
- Totaux : Total HT, TVA détaillée par taux, Total TTC.
- Exclusions validées si pertinentes.
- Conditions commerciales **fournies par l'utilisateur** (jamais inventées).
- Mentions légales obligatoires (voir `tva-mentions-legales.md`) : identification entreprise, décennale, validité, modalités de paiement, mention taux réduit le cas échéant, zone de signature « Devis reçu avant l'exécution des travaux — Bon pour accord » pour les particuliers.
- Si statut ≠ Validé et qu'un brouillon est explicitement demandé : mention ou filigrane « BROUILLON ».

### Tableau client standard (5 colonnes)

| Désignation / Matériaux | Qté | Unité | PV HT unit. | Total HT |

> `PV HT unit.` = `Prix_vente_HT` issu du XLSX. Jamais de colonne prix d'achat ni marge.

## 4. PDF client — mise en page (profil avancé)

Mise en page de référence (format A4 portrait, ReportLab ou équivalent) :

- Largeur totale du tableau `TABLE_W = 19,5 cm`. Largeurs de colonnes exactes (somme = 19,5 cm) :
  - Désignation : 10,8 cm — Qté : 1,2 cm — Unité : 1,8 cm — PV HT unit. : 2,5 cm — Total HT : 3,2 cm.
- Marges de page : `L_MARGIN = R_MARGIN = (21,0 cm − 19,5 cm) / 2 = 0,75 cm`.
- **Bandeaux de LOT** : largeur = `TABLE_W`, `leftPadding = rightPadding = 0`, texte centré, blanc, 9 pt, fond bleu `#2E75B6`, parfaitement alignés avec les tableaux.
- En-têtes de colonnes : fond bleu nuit `#1A3E5C`, texte blanc.
- Lignes alternées blanc / gris clair (`#F2F2F2`).
- Chaque bloc lot (bandeau + tableau + sous-total) groupé dans un `KeepTogether` (ou équivalent) pour éviter les coupures de page.
- Montants alignés à droite, format français : `1 234,56 €`.
- Pied de page : pagination, référence du devis, mentions légales.

## 5. Notes de chantier (OneNote ou équivalent)

Si l'utilisateur utilise un carnet de chantier (OneNote, notes, etc.) :

- **Toujours** relire les notes du chantier avant chaque version de devis.
- Intégrer : dernières dimensions relevées (locaux, baies, hauteurs), photos et croquis, remarques du client ou de la direction de site (ex. isolation phonique obligatoire, porte coulissante).
- Si les notes contredisent une version précédente du devis, **les notes les plus récentes priment** — signaler l'écart à l'utilisateur.

## 6. Contrôles avant génération

Avant de générer un fichier :

- Recalculer tous les totaux à partir des lignes (jamais de totaux saisis à la main).
- Vérifier la somme : Total TTC = Total HT + Σ TVA par taux.
- Vérifier l'alignement bandeaux/tableaux et l'absence de texte tronqué dans le PDF.
- Nommer les fichiers d'après la référence du devis : `DEV-AAAAMMJJ-CLIENT-SITE-V01.xlsx` / `.pdf`.
