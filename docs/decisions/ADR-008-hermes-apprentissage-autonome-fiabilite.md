# ADR-008 : Fiabilité de l'apprentissage autonome Hermes (mémoire persistante)

## Status
Accepted

## Date
2026-08-25

## Contexte

Hermes Agent expose une boucle d'apprentissage intégrée activée par défaut :
mémoire persistante (`MEMORY.md`/`USER.md`, clés `memory.memory_enabled` /
`memory.user_profile_enabled`, toutes deux `true` par défaut) et une revue
autonome post-tour (`auxiliary.background_review.enabled`, `true` par
défaut) pouvant écrire une mémoire ou faire évoluer un skill. Aucune de ces
clés n'était surchargée dans `hermes/config.yaml` sur ce VPS — en théorie,
tout était donc déjà actif.

En testant ce mécanisme en réel le 25/08/2026 (demande explicite à l'agent
de retenir une information durable), aucun fichier n'existait dans
`/opt/data/memories/` malgré des dizaines de sessions réelles depuis la
création du conteneur (15/08/2026). Diagnostic via export de session
(`hermes sessions export --format md`) :

1. **Bug de fond.** Le modèle (`gpt-oss:20b`) appelait
   `memory(action="write", content=...)`. `write` n'existe pas dans le
   schéma réel de l'outil — seules `add`, `replace`, `remove` sont valides
   (https://hermes-agent.nousresearch.com/docs/user-guide/features/memory).
   L'appel échouait (`{"error": "Unknown action 'write'..."}`), le modèle
   abandonnait avec une réponse générique sans jamais écrire la mémoire.
   Rien dans `SOUL.md` ne documentait ce schéma.
2. **Distraction.** Sur une formulation différente, le modèle appelait
   `skill_view("hermes-agent")` (un skill qui n'existe pas dans ce
   déploiement, qui n'a que les 12 skills devis Blueseatra) au lieu de
   `memory` — probablement à cause du réflexe "Skills toujours actives" en
   tête de `SOUL.md`, pensé pour les demandes de devis, mal généralisé à
   une demande de mémoire pure.
3. **Confirmation hallucinée.** Sur une troisième tentative, le modèle a
   répondu "Mémorisation effectuée" avec **zéro appel d'outil réel**
   (`tool_call_count: 0` dans l'export de session) — une confirmation
   mensongère sans action derrière.

## Décision

Documenter et contraindre l'usage de l'outil `memory` directement dans
`hermes/SOUL.md` (chargé au début de chaque session), plutôt que de
compter sur la connaissance générique du modèle du schéma de l'outil :

- Section "Mémoire persistante — apprentissage autonome" : paramètres
  exacts (`action`: `add`/`replace`/`remove` uniquement, `target`:
  `memory`/`user`, `content`, `old_text`), avec un exemple d'appel correct.
- Section "Règles strictes" : détection prioritaire d'une demande de
  mémoire pure (verbes retiens/mémorise/note durablement/n'oublie jamais)
  pour ne PAS déclencher `skill_view` dans ce cas ; le tool call `memory`
  doit être le premier acte, avant tout texte ; interdiction absolue de
  confirmer une mémorisation sans `success: true` réel dans la même
  réponse.

## Alternatives considérées

### Changer de modèle pour le rôle agent Hermes
- Rejeté : `gpt-oss:20b` reste le seul modèle installé avec `tools` +
  contexte ≥64K + vitesse réelle validée pour ce rôle (voir ADR-006/007).
  Le bug n'était pas une limite de capacité du modèle mais une absence de
  documentation du schéma d'outil dans le prompt système.

### Forcer `memory.write_approval: true` pour auditer chaque écriture
- Rejeté pour l'instant : contredit l'objectif d'apprentissage
  **autonome** demandé explicitement par l'utilisateur (sans validation
  humaine à chaque écriture). Reste une option si des écritures
  indésirables apparaissent en usage réel.

### Désactiver `auxiliary.background_review` et se limiter à des écritures manuelles
- Rejeté : perd tout l'intérêt de la fonctionnalité.

## Validation réelle

Après déploiement (`docker compose up -d --force-recreate hermes`), avec
`--reasoning high` explicite (config.yaml a déjà `agent.reasoning_effort:
high` par défaut depuis l'ADR-007 — ce flag confirme le niveau plutôt que
de le changer ; Ollama n'accepte que `low`/`medium`/`high` pour
`gpt-oss:20b`, pas de niveau supérieur côté modèle) :

- Test du bug de fond (action invalide) : corrigé, `memory(action="add",
  target="memory", ...)` réussit, `MEMORY.md` créé.
- Test de non-régression sur la formulation qui causait la distraction
  vers `skill_view` : corrigé après renforcement de `SOUL.md`.
- 3 tests réels sur 3 réussis après renforcement (contre 0 sur 2 avant).

## Conséquences

- `MEMORY.md`/`USER.md` peuvent désormais accumuler des faits réels entre
  sessions CLI (`hermes -z`, `hermes chat`) sur ce VPS.
- Échantillon de validation encore petit (3/3) sur un modèle local 20B
  CPU-only : amélioration nette et vérifiée, pas une garantie formelle de
  fiabilité à 100 % dans tous les cas de figure. Si de nouveaux modes
  d'échec apparaissent en usage réel, ajouter une nouvelle règle ciblée
  dans `SOUL.md` plutôt que de réécrire cette section en entier.
- Cette boucle d'apprentissage ne concerne que l'agent Hermes lui-même
  (CLI/gateway), pas le pipeline SaaS Blueseatra qui appelle Ollama
  directement sans passer par Hermes (voir README, section Architecture).
