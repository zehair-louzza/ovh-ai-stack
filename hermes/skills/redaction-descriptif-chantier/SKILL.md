# Rédaction du descriptif chantier

## Quand utiliser ce skill

Ce skill ne se déclenche jamais seul. Il est appelé par :

- `devis-options-master` (§2 Descriptif de travaux) — un devis par option exclusive ;
- `devis-travaux-tce` (section Description des travaux) ;
- `preparation-technique-tce` (§6 Rédiger le descriptif client).

Chacun de ces skills prépare les données réelles (périmètre validé, phases techniques, effectif, heures-homme, jours de déplacement, exclusions). Ce skill ne fait qu'une chose : mettre ces données en forme dans le bloc client, en français **clair et concis, avec un détail technique par étape**. Il n'invente, ne complète et ne corrige aucune donnée d'entrée.

## Règle de style : clair et concis, avec détail technique

- Une idée principale = une phrase courte, mais chaque phase de déroulement porte en plus **un détail technique concret** (matériel utilisé, point de contrôle qualité, norme applicable) quand il est connu — concis ne veut pas dire vague.
- Verbe d'action + objet + détail technique le cas échéant. Éviter les subordonnées empilées au-delà de ce détail.
- Aucune formule de remplissage (« il convient de », « il sera procédé à », « dans le cadre de », « en vue de »).
- Ne jamais répéter le titre/l'intitulé dans le corps du texte.
- Vocabulaire professionnel standard du secteur autorisé (DTU, TCE, ERP, etc.), jargon interne ou administratif interdit côté client.
- Chaque phase du déroulement : une ligne, ~30 mots maximum (le détail technique ajouté justifie une marge par rapport à une phase purement descriptive).
- Concis ne veut pas dire incomplet : chaque étape réelle du chantier doit apparaître avec son détail technique s'il est connu, mais en une ligne, jamais en paragraphe. Si une étape ne tient pas en une ligne claire, c'est qu'elle mélange plusieurs actions — la découper en deux lignes plutôt que l'alourdir. Aucun détail technique inventé : si le matériel ou le point de contrôle n'est pas connu, ne pas le mentionner plutôt que d'en inventer un plausible.

## Structure fixe du bloc client

1. **Intitulé** — `Option i/n — {label}` s'il y a plusieurs options, sinon le titre seul.
2. **Périmètre** — ce qui est fourni et posé, site d'intervention.
3. **Déroulement** — étapes de réalisation du chantier, numérotées (voir liste canonique ci-dessous).
4. **Déplacement** — nombre de jours de présence. Jamais de tarif en euros dans le texte.
5. **Main-d'œuvre** — effectif × heures/jour × jours, plafond 7 h/personne/jour. Jamais de tarif en euros dans le texte.
6. **Hors périmètre** — exclusions et, si applicable, l'autre option.

## Étapes de réalisation du chantier (Déroulement)

Liste canonique de phases, avec le type de détail technique attendu par phase (à renseigner seulement si connu — voir interdit ci-dessous). Adapter au scénario réel : retirer une phase non applicable (ex. pas de « dépose » sur une installation neuve), ne jamais en ajouter une non demandée ni non constatée.

1. **Arrivée et prise de contact sur site** — détail : point de contact, accès/horaires si contraints.
2. **Sécurisation de la zone d'intervention** — détail : balisage, coupure(s) électrique/fluide si applicable, EPI requis.
3. **Dépose de l'existant** (si remplacement) — détail : matériel/élément déposé, mode d'évacuation.
4. **Pose / installation** — détail : référence normative ou DTU applicable, matériel posé.
5. **Essais et remise en service** — détail : nature du contrôle (test fonctionnel, mesure, vérification d'étanchéité...).
6. **Nettoyage de la zone** — détail : évacuation des déchets/gravats si applicable.
7. **Repli de chantier** — détail : restitution de la zone en état.

Un détail non connu n'apparaît simplement pas sur la ligne : la phase reste valide sans lui, elle n'est jamais complétée par une supposition.

## Interdits absolus

- Aucun prix, tarif ou montant en euros dans le texte — le montant vit uniquement dans le tableau chiffré ; le répéter en prose crée un décalage garanti si le catalogue change.
- Aucun diagnostic, cause de panne ou travaux non demandés/non constatés inventés.
- Aucune fusion silencieuse entre deux scénarios ou options distincts.
- Aucune donnée d'entrée modifiée ou complétée : ce skill rédige, il ne chiffre pas et ne complète pas un périmètre incomplet (renvoyer la donnée manquante au skill appelant plutôt que de l'estimer ici).

## Entrée attendue du skill appelant

- Label du scénario (et position `i/n` si options multiples).
- Périmètre validé et site d'intervention.
- Liste des phases techniques réellement prévues.
- Effectif, heures/jour, nombre de jours.
- Jours de déplacement.
- Exclusions et hypothèses `Estimé`/`À confirmer` à faire apparaître.

## Sortie

Un bloc de texte prêt à insérer dans le PDF client, suivant la structure fixe ci-dessus, en français clair et concis, sans aucune donnée interne (prix, marge, fournisseur, référence catalogue).
