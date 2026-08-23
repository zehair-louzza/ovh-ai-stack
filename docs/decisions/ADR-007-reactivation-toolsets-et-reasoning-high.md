# ADR-007 : Réactivation de tous les toolsets Hermes et raisonnement principal sur "high"

## Statut
Accepté

## Date
2026-08-23

## Contexte

Le 23/08 (même jour), 6 toolsets avaient été désactivés (`disabled_toolsets: [memory, session_search, code_execution, delegation, tts, todo]`) pour réduire l'empreinte du prompt système Hermes, avec une justification documentée par toolset (voir historique de `hermes/config.yaml` avant ce commit). Le raisonnement principal (`agent.reasoning_effort`) était réglé sur `medium`, choisi comme compromis qualité/latence sur ce VPS CPU-only.

L'utilisateur a demandé explicitement, plus tard le même jour :

1. Réactiver tous les toolsets désactivés et les garder toujours actifs.
2. Passer le niveau de raisonnement du modèle principal (`gpt-oss:20b`) sur `"high"`.

Ces deux points ont été confirmés par des questions de clarification directes (voir échange du 23/08 23h43) : « skills supprimées » désignait bien les **toolsets désactivés**, pas les modèles Ollama supprimés du VPS (sujet distinct, voir ADR-006) ; et le niveau `"high"` s'applique au modèle principal côté gateway Hermes (`hermes/config.yaml`), en plus du rôle `reason` de Blueseatra (`HERMES_REASONING_EFFORT` sur Render).

## Décision

### Toolsets

Suppression complète de la clé `disabled_toolsets` : tous les toolsets Hermes sont désormais actifs (`memory`, `session_search`, `code_execution`, `delegation`, `tts`, `todo`, en plus de ceux déjà actifs : `file`, `skills`, `clarify`, `browser`, `terminal`, `vision`).

**Point d'attention explicitement signalé et accepté par l'utilisateur avant application** : réactiver `code_execution` donne à l'agent Hermes une capacité de calcul propre, ce qui va à l'encontre de la règle métier stricte « FastAPI est le seul moteur de prix, l'IA n'invente et ne calcule jamais de prix » (documentée dans les skills `devis-options-master` et `securite-donnees-devis`, et dans les instructions permanentes de ce projet). Cette règle reste en vigueur au niveau **skill/instruction** (SOUL.md, `devis-options-master`) — réactiver le toolset ne change pas la consigne donnée au modèle de ne jamais calculer de prix lui-même, seulement sa capacité technique de le faire s'il ignorait cette consigne. Le risque résiduel (le modèle utilise `code_execution` pour calculer un prix malgré la consigne) est accepté explicitement par l'utilisateur, pas éliminé par ce changement.

### Raisonnement

`agent.reasoning_effort: medium` → `high` dans `hermes/config.yaml` (modèle principal `gpt-oss:20b`, conversation devis). Mesuré en réel le même jour sur ce VPS CPU-only (prompt trivial, voir ADR-006) : `high` ~12.3s contre ~8.9s en `medium` — un écart qui sera plus marqué sur un vrai devis complet, à surveiller en usage réel.

Les slots auxiliaires (`web_extract`, `compression`, `vision`, `title_generation`, `mcp`, `skills_hub`, `approval`, `triage_specifier`) ne sont **pas** concernés par ce changement : chacun garde son niveau différencié pour sa tâche propre (`low` pour le routage/résumé, `none` pour la vision qui ne pense pas, `medium` pour l'approbation).

Côté Blueseatra (rôle `reason`, décomposition matériaux/lots), `HERMES_REASONING_EFFORT` passe de `medium` à `high` sur Render, en cohérence avec ce même changement côté gateway.

## Alternatives considérées

### Réactiver uniquement les 5 toolsets sans risque métier, laisser code_execution désactivé
Proposé explicitement à l'utilisateur avant d'agir (confirmation demandée). Rejeté par l'utilisateur, qui a choisi de réactiver `code_execution` malgré le risque signalé.

### Passer aussi les slots auxiliaires sur "high"
Rejeté : la demande de l'utilisateur, après clarification, portait sur le modèle principal, pas sur les slots de routage/résumé qui n'ont jamais besoin de profondeur (titre de conversation, routage MCP, etc.). Les faire passer sur `high` ralentirait toute la plateforme sans bénéfice pour des tâches mécaniques.

## Conséquences

- Le prompt système Hermes redevient plus lourd (retour vers ~18 outils / 46,2 Ko de schémas, l'inverse de la réduction du 23/08 matin) — le gain de latence obtenu ce jour-là par la réduction du prompt est annulé par cette décision.
- Chaque conversation devis principale sera plus lente (`high` vs `medium`), potentiellement significativement sur un devis complexe — à mesurer en usage réel et à revoir si la latence devient un problème pratique.
- La protection technique contre un calcul de prix par l'IA elle-même (retirer l'outil) n'existe plus ; seule la consigne au niveau skill/instruction protège désormais cette règle. Une revue de `devis-options-master`/`securite-donnees-devis` pour vérifier que la consigne "ne jamais calculer de prix" y est bien explicite et visible reste recommandée en suivi de cette décision.
- `terminal`/`browser` (dépendance silencieuse documentée le 23/08 matin) restent tous les deux actifs de toute façon dans ce nouvel état "tout actif" — le risque de dépendance cachée entre toolsets ne se manifeste que lors d'une prochaine désactivation partielle, pas maintenant.
