# TVA bâtiment et mentions légales du devis (France)

> Règles applicables en France. En cas de doute sur un cas particulier, poser la question à l'utilisateur ou marquer la ligne « À confirmer ». Ne jamais trancher seul un cas fiscal ambigu.

## 1. Taux de TVA applicables aux travaux

### 20 % — taux normal

- Locaux **tertiaires et professionnels** (bureaux, boutiques, commerces, ERP) : le taux normal s'applique par défaut aux travaux.
- Logements achevés depuis **moins de 2 ans**.
- Construction neuve, surélévation, remise à neuf assimilable à du neuf.
- Fourniture seule de matériaux (sans pose) facturée directement au client.
- Gros équipements exclus des taux réduits (ex. chaudière fioul, certains équipements de climatisation).

### 10 % — taux intermédiaire (art. 279-0 bis du CGI)

- Travaux d'**amélioration, transformation, aménagement et entretien** dans des **locaux à usage d'habitation achevés depuis plus de 2 ans** (résidence principale ou secondaire, propriétaire ou locataire).
- Fournitures et pose facturées par l'entreprise qui réalise les travaux.
- Conditions : les travaux ne doivent pas aboutir à une remise à neuf (ne pas augmenter la surface de plancher de plus de 10 %, ne pas toucher plus de la moitié du gros œuvre ni plus des 2/3 des éléments de second œuvre).

### 5,5 % — taux réduit (art. 278-0 bis A du CGI)

- Travaux d'**amélioration de la performance énergétique** dans des logements achevés depuis plus de 2 ans : isolation thermique, chaudières à haute performance, pompes à chaleur (hors air/air), chauffe-eau solaires, régulation de chauffage, etc.
- Ainsi que les **travaux induits** indissociablement liés (ex. reprise de plâtrerie et peinture après isolation).

### 0 % — Franchise en base de TVA et autres cas de non-application

Un taux **0 %** signifie qu'aucune TVA n'est facturée sur la ligne ou sur le devis entier. Ne jamais l'appliquer par défaut ou par déduction : il doit toujours reposer sur une **confirmation explicite** du statut de l'entreprise ou de la nature de l'opération. Trois familles de cas, à ne pas confondre :

**a) Franchise en base de TVA (art. 293 B du CGI)** — cas le plus fréquent pour une entreprise qui démarre (ex. micro-entreprise / auto-entreprise) :

- S'applique quand le chiffre d'affaires annuel de l'entreprise reste sous les seuils légaux. Seuils en vigueur en 2026 (la réforme qui prévoyait un seuil unique à 25 000 € / 37 500 € a été abrogée par la loi n° 2025-1044 du 3 novembre 2025 ; les seuils antérieurs sont donc maintenus) :
  - Prestations de services (dont la plupart des activités artisanales du BTP) : **37 500 €** (année précédente) / **41 250 €** (seuil majoré, année en cours).
  - Ventes de marchandises, hébergement, restauration : **85 000 €** / **93 500 €**.
  - Avocats, auteurs, artistes-interprètes : **50 000 €** / **55 000 €**.
- Toute la facturation de l'entreprise est alors **hors TVA**, quel que soit le type de client (tertiaire ou particulier) et quel que soit le taux qui s'appliquerait normalement aux travaux.
- Ne jamais présumer ce statut : demander confirmation à l'utilisateur (« Ton entreprise est-elle en franchise en base de TVA, ou assujettie normalement ? ») si l'information n'est pas déjà connue.

**b) Opérations exonérées ou hors champ** (rare en travaux TCE courants, à ne traiter que sur indication explicite de l'utilisateur) :

- Exportations et livraisons intracommunautaires (art. 262 ter du CGI), certaines opérations exonérées par nature (art. 261 du CGI).
- Ne jamais appliquer ce cas sans que l'utilisateur l'ait explicitement signalé.

**c) Autoliquidation** — voir section 2 ci-dessous : ce **n'est pas** un taux 0 %, c'est une facturation HT avec TVA due par le client ; ne pas la confondre avec la franchise en base.

**Mention légale obligatoire lorsque le taux 0 % s'applique par franchise en base** (à afficher sur le devis/PDF client à la place de toute ligne de TVA) :

- Pour toute facture ou devis établi **jusqu'au 31 décembre 2027** : « TVA non applicable, art. 293 B du CGI » (mention encore admise en 2026).
- Pour toute facture ou devis établi **à partir du 1er septembre 2026** : la nouvelle référence légale devient « TVA non applicable, art. L. 223-3 du code des impositions sur les biens et des services (CIBS) ». Utiliser cette formulation pour les devis datés à partir de cette date ; l'ancienne mention 293 B reste tolérée en parallèle jusqu'à fin 2027.
- Ne jamais indiquer de montant de TVA ni de taux à côté de cette mention : les colonnes « Taux TVA » et « Montant TVA » du devis restent à 0,00 € / « — ».

### Attestation TVA taux réduit

- Pour appliquer 10 % ou 5,5 %, le client doit remettre à l'entreprise une **attestation** confirmant l'âge du logement et la nature des travaux (attestation simplifiée pour les travaux de second œuvre ; depuis 2025 une mention sur le devis/facture signée par le client peut en tenir lieu pour les travaux courants).
- Sur le devis à taux réduit, ajouter la mention type :
  > « TVA à taux réduit applicable sous réserve de la remise par le client d'une attestation confirmant que les locaux sont achevés depuis plus de deux ans et affectés à un usage d'habitation (art. 279-0 bis / 278-0 bis A du CGI). »

## 2. Application dans le devis

- Utiliser `TVA_%` du catalogue pour chaque fourniture si disponible ; sinon appliquer le taux du chantier.
- Pour la main-d'œuvre et le déplacement : taux communiqué par l'utilisateur ou taux du chantier.
- S'il existe plusieurs taux : calculer la TVA **ligne par ligne**, puis sommer et **détailler par taux** dans les totaux (ex. « TVA 10 % : … € / TVA 20 % : … € »).
- Ne jamais appliquer aveuglément 20 % sur tout le devis si plusieurs taux coexistent.
- Si un taux manque pour une ligne critique : demander confirmation avant PDF client.
- **Taux 0 % (franchise en base)** : si l'utilisateur confirme que son entreprise est en franchise en base de TVA, appliquer 0 % sur **l'ensemble du devis** (toutes les lignes, fournitures comme main-d'œuvre et déplacement) — ce n'est jamais un taux qui coexiste ligne à ligne avec du 20/10/5,5 %. Le devis affiche alors Total HT = Total TTC, sans colonne TVA active, et la mention légale correspondante (voir « 0 % — Franchise en base de TVA » ci-dessus) remplace le bloc « TVA détaillée par taux ».
- Autoliquidation (sous-traitance BTP, art. 283-2 nonies du CGI) : si l'utilisateur indique intervenir en sous-traitance, facturer HT avec la mention « Autoliquidation — TVA due par le preneur ». Ne l'appliquer que sur instruction explicite. Ne pas confondre avec le taux 0 % de franchise en base : ici l'entreprise reste assujettie, c'est le client professionnel qui autoliquide la taxe.

## 3. Mentions obligatoires sur le devis (PDF client)

### Identification de l'entreprise

- Raison sociale, forme juridique, adresse du siège.
- Numéro SIREN/SIRET, RCS ou RM, numéro de TVA intracommunautaire.
- Assurance professionnelle obligatoire : **assurance de responsabilité décennale** — mention de l'assureur, du numéro de contrat et de la **couverture géographique** (obligatoire pour les travaux de bâtiment).

### Identification du devis

- Mention « Devis » ou « Proposition de prix », numéro/référence, date d'établissement.
- **Durée de validité de l'offre** (ex. 30 jours).
- Nom et adresse du client ; adresse du lieu d'exécution des travaux si différente.

### Contenu

- Description détaillée de chaque prestation : quantité, unité, prix unitaire HT.
- Taux horaire de main-d'œuvre et frais de déplacement le cas échéant.
- Total HT, détail TVA par taux, Total TTC.
- Date prévue de début et durée estimée des travaux (recommandé ; obligatoire pour certaines prestations de dépannage).
- Modalités de paiement : acompte, échéancier, solde ; conditions de révision éventuelles.
- Caractère **gratuit ou payant** du devis.

### Clients particuliers (logement individuel) — mentions supplémentaires

- Signature précédée de la mention manuscrite ou imprimée : **« Devis reçu avant l'exécution des travaux — Bon pour accord »**, avec date et signature du client.
- **Médiateur de la consommation** : nom et coordonnées du médiateur dont relève l'entreprise (obligation légale vis-à-vis des consommateurs).
- **Droit de rétractation** : si le devis est signé hors établissement (au domicile du client), délai de rétractation de 14 jours — joindre le formulaire type. Le mentionner si le contexte l'indique.
- Garanties légales : garantie de parfait achèvement (1 an), garantie biennale de bon fonctionnement (2 ans), garantie décennale (10 ans).

### Pénalités et clauses usuelles (si fournies par l'utilisateur)

- Pénalités de retard et indemnité forfaitaire de recouvrement (40 €) pour les clients professionnels.
- Réserve de propriété, conditions de réception, gestion des travaux supplémentaires (avenant obligatoire).

## 4. Conditions commerciales

- **Ne jamais inventer** les conditions commerciales.
- Si fournies : durée de validité, délai d'intervention, modalités de règlement, acompte, garanties, réserves.
- Si non communiquées : ne pas les créer ; proposer à l'utilisateur la liste des champs à compléter (validité, acompte %, modalités de paiement, délai d'exécution, garanties, médiateur).

## 5. Cas tertiaire : documents associés

Pour les donneurs d'ordre tertiaires (enseignes, foncières, gestionnaires) prévoir, si l'utilisateur les demande : références du contrat-cadre ou du bon de commande, numéro de site/boutique, interlocuteur travaux, conditions d'accès au site, attestations (assurance, URSSAF) souvent exigées — à fournir par l'utilisateur, jamais inventées.
