# ADR-013 : configuration de l'agent dans son volume, OpenCode Free dans la passerelle

## Statut
Accepté (10/10/2026)

## Contexte
- **Tableau de bord** : le choix du modèle sur `hermes.blueseatra.com` ne s'enregistrait pas. `compose.yaml` montait `./hermes/config.yaml` en lecture seule sur `/opt/data/config.yaml`. Or Hermès enregistre en remplaçant le fichier, ce qui échoue sur un fichier monté seul (`Device or resource busy`, puis `Read-only file system`).
- **Correction manuelle** : le 9 octobre 2026, le montage a été retiré à la main sur le VPS. Cette modification locale bloquait le déploiement automatique ([ADR-011](ADR-011-deploiement-automatique-vps.md)).
- **OpenCode Free** : le SaaS Blueseatra propose désormais 13 modèles gratuits OpenCode Zen par la passerelle, avec `provider: opencode-free`. Ils nécessitent l'extension `oc-free-provider`. `hermes plugins install oc-free-provider --enable` installe bien l'extension dans le volume, mais l'activation échoue : la configuration de la passerelle est en lecture seule.

## Décision
- **Agent (`hermes`)** : plus de montage de `./hermes/config.yaml`. La configuration vit dans le volume `hermes_data` (propriétaire 10000:10000), modifiable par le tableau de bord. Le fichier du dépôt sert de modèle de départ.
- **Passerelle (`hermes-passerelle`)** : la configuration reste montée en lecture seule depuis le dépôt, pour que la production du SaaS ne change que par une PR. Les extensions sont installées dans le volume `hermes_passerelle_data`, puis activées par `plugins.enabled` dans `hermes/passerelle/config.yaml`.

## Conséquences
- **Agent** : ses réglages ne sont plus versionnés. Une recréation du volume `hermes_data` repart du fichier du dépôt.
- **Passerelle** : une extension non installée dans son volume mais déclarée dans `plugins.enabled` reste inactive. Vérifier avec `hermes plugins list`.
- **RGPD** : OpenCode Free héberge ses modèles aux États-Unis, et plusieurs modèles gratuits peuvent réutiliser les données. Blueseatra masque le texte de tous les appels IA avant l'envoi (Blueseatra PR #194). Voir [RGPD.md](../RGPD.md).
- **Procédures** : [EXPLOITATION-HERMES.md](../EXPLOITATION-HERMES.md).
