# ADR-010 : Agent devis spécialisé, deux skills à schéma JSON

## Statut
Accepté (29/09/2026)

## Contexte
L'utilisateur a validé dans Mistral Studio un agent devis composé de trois éléments :
- des instructions de métreur et rédacteur TCE ;
- deux fonctions à schéma JSON strict, `extraire_demande_travaux` et `decrire_demande_travaux` ;
- un raisonnement élevé.

Il demande que l'agent Hermès du VPS devienne cet agent, et que les 12 skills devis créés ensemble soient supprimés au profit des deux nouveaux. Les skills fournis avec Hermès sont conservés.

## Décision
- Suppression des 12 skills de `hermes/skills/`.
- Deux skills dans `hermes/skills-blueseatra/`, chacun avec son schéma JSON dans `references/schema.json`, repris à l'identique des pièces fournies par l'utilisateur :
  - `extraire-demande-travaux` ;
  - `decrire-demande-travaux`.
- Montage en lecture seule sur `/opt/blueseatra-skills`, déclaré dans `skills.external_dirs`. `/opt/data/skills` n'est plus masqué par le montage, les skills fournis avec Hermès y sont donc resynchronisés au démarrage.
- `SOUL.md` reprend les instructions de l'agent Mistral : déroulement, métré en 14 familles, désignations, parties, rédaction et interdictions. Il impose ces deux skills en priorité. La section « Mémoire persistante » (ADR-008) est conservée.

## Conséquences
- Les règles des anciens skills qui ne figurent ni dans les deux nouveaux skills ni dans `SOUL.md` ne sont plus appliquées par l'agent : conformité et mentions légales, livrables XLSX/PDF, relances. Côté SaaS, ces fonctions restent assurées par le code de Blueseatra.
- Retour arrière : `git revert` de cette PR, puis `docker compose up -d --force-recreate hermes`.
