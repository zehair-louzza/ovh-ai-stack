# ADR-006 : gpt-oss:20b comme modèle de raisonnement Blueseatra, avec niveau gradué

## Statut
Accepté

## Date
2026-08-23

## Contexte

Le 23/08, 6 modèles ont été supprimés du VPS pour libérer de l'espace disque (63 Go) : `gemma4:26b`, `qwen3.6:27b`, `qwen3:14b`, `deepseek-r1:14b`, `qwen2.5:14b`, `Phi-4-reasoning-vision-15B`. `gemma4:26b` était jusque-là le modèle de raisonnement utilisé par `Blueseatra/backend/ai_service.py` pour le rôle `reason` (décomposition matériaux/lots, `EXPAND_SYSTEM`), appelé via `_call_reason` → `_call_hermes_ollama`.

Après cette suppression, `HERMES_REASONING_MODEL` retombait sur son défaut de code (`qwen2.5vl:7b`) — un modèle sans capacité de raisonnement native. La fonction `_wants_think()` ne détectait que les familles `qwen3*`/`gemma4*`/`deepseek-r1*`, toutes supprimées : aucun modèle installé ne raisonnait plus, alors que `gpt-oss:20b` était déjà présent sur le VPS (utilisé comme modèle principal du gateway Hermes lui-même, voir ADR-002/ADR-003) et raisonne nativement.

### Vérification empirique (23/08)

```
$ docker exec ovh-ai-stack-ollama-1 ollama show gpt-oss:20b
Capabilities: completion, tools, thinking
```

Test réel via `/api/chat` :

| Requête | Résultat |
|---|---|
| `think: true` (booléen) | Accepté, champ `message.thinking` rempli |
| `think: "low"` | ~15 caractères de réflexion, ~3.2s total (prompt trivial) |
| `think: "medium"` | ~156 caractères de réflexion, ~8.9s total |
| `think: "high"` | ~275 caractères de réflexion, ~12.3s total |

`gpt-oss:20b` accepte donc un niveau de raisonnement **gradué**, pas seulement un booléen on/off comme `qwen3`/`gemma4`/`deepseek-r1`. Documenté aussi côté `hermes/config.yaml` de ce dépôt : Ollama n'accepte que `"low"`/`"medium"`/`"high"` pour ce modèle et **ignore silencieusement** `"think": false`/`None` — `gpt-oss:20b` ne peut pas désactiver son raisonnement, seulement en régler la profondeur.

## Décision

1. **`HERMES_REASONING_MODEL=gpt-oss:20b`** sur Render (Blueseatra) pour le rôle `reason` de `_call_reason`/`resolve_ai_config`. Le rôle `file`/`vision` reste sur `HERMES_VISION_MODEL` (`qwen2.5vl:7b`) : `gpt-oss:20b` n'a pas la vision.
2. **`_wants_think()`** (Blueseatra `ai_service.py`) détecte désormais aussi `gpt-oss*`, pour que le timeout correct (900s, pas 180s) s'applique et que le payload Ollama envoie bien un paramètre `think`.
3. **`HERMES_REASONING_EFFORT`** (env Render, défaut `"medium"`) contrôle le niveau gradué envoyé à Ollama pour ce modèle. Choix de `"medium"` par cohérence avec `agent.reasoning_effort: medium` déjà en place pour le même modèle côté gateway Hermes (`hermes/config.yaml`, ce dépôt).
4. **`_call_reason`/`_call_hermes_ollama`** (Blueseatra) acceptent un paramètre optionnel `reasoning_effort` par appel, pour un futur appelant qui voudrait un niveau différent du défaut global sans changer la variable d'environnement.
5. Le hint de prompt `_THINK_BREVITY_HINT` (« réfléchis brièvement »), conçu pour compenser l'absence de contrôle natif sur les modèles booléen-only, est **omis pour `gpt-oss`** : il contrôle déjà sa profondeur nativement via `think`, et ce hint serait contradictoire avec un niveau `"high"` explicitement demandé.

Correctifs appliqués sur `Blueseatra` : PR [#48](https://github.com/zehair-louzza/Blueseatra/pull/48) (détection `_wants_think`), PR [#49](https://github.com/zehair-louzza/Blueseatra/pull/49) (niveau gradué), PR [#50](https://github.com/zehair-louzza/Blueseatra/pull/50) (documentation).

## Alternatives considérées

### Réinstaller gemma4:26b ou un autre modèle boolean-only
Rejeté : réinstaller un modèle de 17 Go va à l'encontre de la suppression volontaire du 23/08 (contrainte disque). `gpt-oss:20b` était déjà présent et raisonne nativement — aucune installation supplémentaire nécessaire.

### Laisser `HERMES_REASONING_MODEL` sur `qwen2.5vl:7b` (aucun raisonnement)
Rejeté : revient sur la fiabilité gagnée par le raisonnement actif sur la décomposition matériaux/lots (décision du 2026-08-18), sans aucune contrepartie en performance puisque `gpt-oss:20b` est déjà chargé côté Hermes de toute façon.

### Envoyer systématiquement `think: true` (booléen) sans niveau gradué
Rejeté après mesure réelle (voir tableau ci-dessus) : le niveau gradué change réellement la profondeur ET la latence. Un simple `true` laisse Ollama choisir un niveau par défaut non documenté et non contrôlable, alors que le gradué permet d'ajuster explicitement le compromis vitesse/qualité par appelant.

## Conséquences

- Le rôle `reason` de Blueseatra bénéficie à nouveau d'un raisonnement natif réel, sans réinstaller de modèle supplémentaire sur un VPS CPU-only déjà contraint en disque.
- `HERMES_REASONING_EFFORT` devient le point de réglage central du compromis vitesse/qualité pour ce rôle — à ajuster si la décomposition matériaux/lots se révèle trop lente ou trop superficielle en usage réel.
- Le gateway Hermes (rôle `gpt-oss:20b` principal côté Hermes lui-même) n'est pas affecté : il gère déjà son propre `agent.reasoning_effort` via `hermes/config.yaml`, indépendamment de ce que Blueseatra configure pour son propre repli Ollama direct.
- Si un futur modèle booléen-only (`qwen3`/`gemma4`/`deepseek-r1`) est réinstallé, `_wants_think()` le détecte toujours correctement et bascule sur le comportement booléen + hint de brièveté — aucune régression pour ce cas.
