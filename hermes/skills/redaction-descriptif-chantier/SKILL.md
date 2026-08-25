# Rédaction du descriptif chantier

## Quand utiliser ce skill

Ce skill ne se déclenche jamais seul. Il est appelé par :

- `devis-options-master` (§2 Descriptif de travaux) — un devis par option exclusive ;
- `devis-travaux-tce` (section Description des travaux) ;
- `preparation-technique-tce` (§6 Rédiger le descriptif client).

Chacun de ces skills prépare les données réelles (périmètre validé, phases techniques, effectif, heures-homme, jours de déplacement, exclusions). Ce skill ne fait qu'une chose : mettre ces données en forme dans le bloc client, en français **clair et concis**. Il n'invente, ne complète et ne corrige aucune donnée d'entrée.

**Pont Blueseatra (2026-08-25)** : le pipeline SaaS automatisé (FastAPI → Ollama direct) n'appelle jamais le gateway Hermes et ne voit donc jamais ce fichier. Les règles de ce skill (liste canonique des phases, style clair/concis, interdits absolus) ont été recopiées directement dans `DESCRIPTION_SYSTEM` (`backend/ai_service.py`, role=describe, modèle `glm-4.7-flash`) pour qu'elles s'appliquent réellement aux devis générés par le SaaS. Toute modification de ce skill doit être répercutée manuellement dans `DESCRIPTION_SYSTEM` — aucune synchronisation automatique n'existe entre les deux.

## Règle de style : clair et concis

- Une idée = une phrase courte. Verbe d'action + objet. Éviter les subordonnées empilées.
- Aucune formule de remplissage (« il convient de », « il sera procédé à », « dans le cadre de », « en vue de »).
- Ne jamais répéter le titre/l'intitulé dans le corps du texte.
- Vocabulaire professionnel standard du secteur autorisé (DTU, TCE, ERP, etc.), jargon interne ou administratif interdit côté client.
- Chaque phase du déroulement : une ligne, 20 mots maximum.
- Concis ne veut pas dire incomplet : chaque étape réelle du chantier doit apparaître, mais en une ligne, jamais en paragraphe. Si une étape ne tient pas en une ligne claire, c'est qu'elle mélange plusieurs actions — la découper en deux lignes plutôt que l'alourdir.

## Structure fixe du bloc client

1. **Intitulé** — `Option i/n — {label}` s'il y a plusieurs options, sinon le titre seul.
2. **Périmètre** — ce qui est fourni et posé, site d'intervention.
3. **Déroulement** — étapes de réalisation du chantier, numérotées (voir liste canonique ci-dessous).
4. **Déplacement** — nombre de jours de présence. Jamais de tarif en euros dans le texte.
5. **Main-d'œuvre** — effectif × heures/jour × jours, plafond 7 h/personne/jour. Jamais de tarif en euros dans le texte.
6. **Hors périmètre** — exclusions et, si applicable, l'autre option.

## Étapes de réalisation du chantier (Déroulement)

Liste canonique de phases. Adapter au scénario réel : retirer une phase non applicable (ex. pas de « dépose » sur une installation neuve), ne jamais en ajouter une non demandée ni non constatée.

1. Arrivée et prise de contact sur site.
2. Sécurisation de la zone d'intervention.
3. Dépose de l'existant (si remplacement).
4. Pose / installation.
5. Essais et remise en service.
6. Nettoyage de la zone.
7. Repli de chantier.

## Interdits absolus

- Aucun prix, tarif ou montant en euros dans le texte — le montant vit uniquement dans le tableau chiffré ; le répéter en prose crée un décalage garanti si le catalogue change.
- Aucun diagnostic, cause de panne ou travaux non demandés/non constatés inventés.
- Aucune fusion silencieuse entre deux scénarios ou options distincts.
- Aucune donnée d'entrée modifiée ou complétée : ce skill rédige, il ne chiffre pas et ne complète pas un périmètre incomplet (renvoyer la donnée manquante au skill appelant plutôt que de l'estimer ici).
- Aucune exclusion, contrainte ou hypothèse ajoutée si elle n'est pas déjà fournie explicitement par le skill appelant — ne jamais en inventer une pour paraître complet.

## Limite réelle testée (2026-08-25) — ne pas supposer une obéissance à 100 %

Test réel côté Blueseatra (`glm-4.7-flash`, prompt reprenant fidèlement les règles ci-dessus) : le modèle a violé DEUX interdits explicites malgré leur présence dans le prompt :

1. A ajouté une étape « Retrait des spots existants » alors que le titre disait explicitement « installation neuve » (violation directe de la règle de la §Étapes de réalisation : « pas de dépose sur une installation neuve »).
2. A inventé « Exclusion : travaux de plomberie ou peinture » alors qu'aucune exclusion n'était fournie.

Conclusion : le prompt seul ne garantit pas l'obéissance, quel que soit le modèle. Un filet de sécurité heuristique post-génération (rejet par mots-clés + repli sur un gabarit 100 % déterministe) a été ajouté côté Blueseatra (`generate_ai_works_narrative`, `ai_service.py`) pour ces deux cas précis — imparfait (basé sur des mots-clés), mais couvre les deux échecs réels observés. Si ce skill est un jour utilisé pour de la génération à enjeu réel (pas seulement Hermes en conversation supervisée), prévoir une validation humaine avant export final, jamais une confiance aveugle dans le respect du prompt.

## Entrée attendue du skill appelant

- Label du scénario (et position `i/n` si options multiples).
- Périmètre validé et site d'intervention.
- Liste des phases techniques réellement prévues.
- Effectif, heures/jour, nombre de jours.
- Jours de déplacement.
- Exclusions et hypothèses `Estimé`/`À confirmer` à faire apparaître.

## Sortie

Un bloc de texte prêt à insérer dans le PDF client, suivant la structure fixe ci-dessus, en français clair et concis, sans aucune donnée interne (prix, marge, fournisseur, référence catalogue).
