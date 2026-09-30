# ADR-011 : Déploiement automatique du VPS par GitHub Actions

## Statut
Accepté (30/09/2026)

## Contexte
Chaque fusion dans `main` demandait de lancer à la main, sur le VPS, `git pull` puis le redémarrage de Hermès. Oublis et commandes interrompues ont laissé plusieurs fois le VPS en retard sur `main`. Les derniers correctifs concernés : GLM-OCR et l'erreur 429.

## Décision
- Le workflow `.github/workflows/deployer-vps.yml` se lance à chaque push sur `main` (hors documentation), ou à la main :
  1. il vérifie les fichiers YAML et les scripts ;
  2. il se connecte en SSH au VPS.
- La clé SSH est dédiée : elle est créée sur le VPS par `scripts/installer-deploiement-auto.sh`. Dans `authorized_keys`, elle est limitée par `command=` à `scripts/deployer-vps.sh`, sans terminal ni redirection de port. Elle ne peut donc lancer aucune autre commande.
- L'empreinte du VPS est vérifiée (`StrictHostKeyChecking=yes`, secret `VPS_KNOWN_HOSTS`).
- `deployer-vps.sh` :
  - n'avance que vers `main` et refuse le déploiement si le dépôt du VPS a des modifications locales ;
  - ne redémarre que ce qui a changé ;
  - contrôle la passerelle, l'agent et l'accès web ;
  - revient au commit précédent en cas d'échec ;
  - n'affiche aucun secret ;
  - empêche deux déploiements simultanés.

## Conséquences
- Tout ce qui est fusionné dans `main` part sur le VPS. La règle « demander avant de fusionner » devient donc aussi la validation du déploiement.
- Le contenu de `main` est exécuté sur le VPS. La protection repose sur les droits d'écriture du dépôt.
- Désactivation : supprimer la ligne `deploiement-github-ovh-ai-stack` de `~/.ssh/authorized_keys`, ou désactiver le workflow dans GitHub.
