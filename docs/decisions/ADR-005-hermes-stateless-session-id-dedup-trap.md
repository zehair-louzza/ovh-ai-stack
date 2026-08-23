# ADR-005 : Toujours envoyer un `X-Hermes-Session-Id` unique par appel API stateless

## Statut
Accepté

## Date
2026-08-23

## Contexte

`hermes.blueseatra.com/v1/chat/completions` (activé par ADR-004) est utilisé sans en-tête `X-Hermes-Session-Id`. D'après la documentation officielle et le code source d'Hermes (`gateway/platforms/api_server.py`), en l'absence de cet en-tête l'API est **stateless** : elle dérive un identifiant de session/tâche de façon déterministe à partir du contenu de la requête :

```python
seed = f"{system_prompt or ''}\n{first_user_message}"
digest = hashlib.sha256(seed.encode("utf-8")).hexdigest()[:16]
session_id = f"api-{digest}"
```

Cet identifiant devient ensuite le `task_id` transmis à `agent.run_conversation(task_id=...)`.

Séparément, `tools/skills_tool.py` implémente une déduplication du contenu des skills, **indexée par `task_id`** :

```python
_skill_view_tracker: Dict[str, Dict[tuple, tuple]] = {}
```

Quand `skill_view` est rappelé pour la même skill sous le même `task_id`, Hermes renvoie un accusé `{"status": "unchanged", "content_returned": false}` au lieu du contenu complet — en supposant que « le modèle a déjà ce contenu plus tôt dans cette conversation ». C'est une optimisation légitime et documentée dans le code (mesure réelle citée : ~286k tokens de rappels verbatim répétés sur une fenêtre de 400k messages) **pour une session multi-tours continue** où cette hypothèse est vraie.

Elle devient fausse dès que deux appels API **stateless indépendants** partagent le même `system_prompt` + premier message utilisateur : ils reçoivent le même `task_id` dérivé, alors qu'il s'agit de deux conversations totalement distinctes, chacune avec un historique vide. Le second appel se voit refuser le contenu d'une skill qu'il n'a, dans les faits, jamais reçu.

### Reproduction réelle (23/08/2026)

Un même message de test (« Remplacement du ballon eau chaude 100L… ») envoyé trois fois de suite (un premier essai abandonné côté client après un timeout de 400s, puis deux relances) a produit ce comportement exact sur le troisième appel :

```
"content": "We loaded devis-travaux-tce earlier; next we must load
devis-options-master as well.{\"success\": true, \"status\": \"unchanged\",
\"name\": \"devis-options-master\", \"file\": \"SKILL.md\", \"dedup\": true,
\"content_returned\": false, \"message\": \"Skill content unchanged?\"}"
```

Le modèle a reçu l'accusé de déduplication au lieu des règles réelles de `devis-options-master`, s'est retrouvé sans instructions à suivre, et a arrêté la génération (`finish_reason: "stop"`) en recopiant l'accusé au lieu de produire un devis.

### Pourquoi ce n'est pas un problème théorique

- `SOUL.md` impose de charger intégralement `devis-travaux-tce` puis `devis-options-master` à **chaque** tâche de devis — c'est le point d'entrée le plus exposé à ce piège.
- Le SaaS Blueseatra a déjà du code prêt à appeler ce gateway (`backend/ai_service.py::_call_hermes_gateway`, utilisé par `_call_reason` dès que `HERMES_GATEWAY_URL` est configuré), sans jamais avoir envoyé cet en-tête.
- Les temps de réponse observés (200 à 450+ secondes sur ce VPS sans GPU) rendent un scénario de retry après timeout **probable**, pas hypothétique.

## Décision

Tout appelant du gateway Hermes en mode stateless (pas de conversation multi-tours gérée côté client) doit générer un UUID aléatoire par appel et l'envoyer en en-tête :

```
X-Hermes-Session-Id: <uuid4 généré côté appelant>
```

Ne jamais laisser Hermes dériver cet identifiant du contenu de la requête pour un usage où chaque appel doit être traité comme une tâche isolée.

Appliqué dans `Blueseatra/backend/ai_service.py::_call_hermes_gateway` (voir commit associé) : un `uuid.uuid4()` frais est ajouté à chaque appel, avant même que `HERMES_GATEWAY_URL` soit configuré sur Render — pour que la protection soit déjà en place le jour où ce rebranchement FastAPI → Hermes sera activé.

## Alternatives considérées

### Ne rien faire, corriger uniquement si ça casse en production
Rejeté : le coût de la protection (un en-tête, une ligne de code) est nul, alors que le coût du bug en production (un devis silencieusement incomplet, livré sans que personne ne le remarque) est élevé et difficile à diagnostiquer après coup — le symptôme observé (le modèle recopie un JSON de contrôle interne) ne ressemble à rien d'évident pour quelqu'un qui ne connaît pas ce mécanisme.

### Patcher Hermes pour scoper la dédup autrement (ex. sur un hash de l'historique de conversation réel plutôt que sur le task_id dérivé)
Rejeté : nécessiterait de maintenir un fork du code source d'Hermes (composant tiers non maintenu par nous). Le correctif côté appelant (un en-tête) résout le problème à la source sans toucher au comportement d'Hermes, qui reste correct pour son cas d'usage principal (CLI/Telegram/Discord, sessions réellement continues).

### Désactiver le cache de dédup des skills globalement (`reset_skill_view_dedup` à chaque appel)
Rejeté : pas de mécanisme de configuration exposé pour ça sans modifier le code source ; et même si ça existait, ça pénaliserait aussi les usages où la dédup est légitime (une vraie session longue).

## Conséquences

- Chaque appel à `_call_hermes_gateway` porte désormais un `X-Hermes-Session-Id` unique — aucune conversation stateless ne peut plus jamais être confondue avec une autre par Hermes, quel que soit le contenu du message.
- Contrepartie acceptée : Hermes ne peut plus réutiliser un même répertoire sandbox Docker entre deux appels de notre part (fonctionnalité prévue pour des clients qui font suivre leur propre `X-Hermes-Session-Id` d'un tour à l'autre) — sans impact ici, ce chemin d'appel n'utilise jamais de sandbox.
- Si un jour Blueseatra veut faire suivre un vrai historique multi-tours à Hermes (au lieu de reconstruire le `system_prompt` à chaque appel), il faudra alors gérer explicitement la continuité de session côté FastAPI plutôt que de laisser Hermes la déduire — ce sera une nouvelle décision, pas une extension de celle-ci.
