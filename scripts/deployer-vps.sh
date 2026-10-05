#!/usr/bin/env bash
# Déploiement automatique du VPS (ADR-011), lancé par GitHub Actions à chaque
# fusion dans main. La clé SSH de GitHub est limitée à ce seul script
# (command="..." dans ~/.ssh/authorized_keys) : elle ne peut rien lancer d'autre.
# Lancement manuel possible : ~/ovh-ai-stack/scripts/deployer-vps.sh
#
# 1. récupère main en HTTPS (dépôt public), en avance rapide uniquement ;
# 2. refuse si le dépôt du VPS contient des modifications locales ;
# 3. ne redémarre que ce qui a changé (Hermès, Caddy, services du compose) ;
# 4. contrôle : passerelle Hermès, agent Hermès, accès web ;
# 5. en cas d'échec, revient au commit précédent et redémarre à l'identique.
# Aucun secret n'est affiché. Ollama et ses modèles ne sont jamais supprimés.
set -euo pipefail
DEPOT="$HOME/ovh-ai-stack"
URL="https://github.com/zehair-louzza/ovh-ai-stack.git"
cd "$DEPOT"
exec 9>/tmp/ovh-ai-stack-deploiement.lock
flock -w 600 9 || { echo "ÉCHEC : un autre déploiement est en cours"; exit 1; }

lire() { grep -E "^$1=" .env | tail -1 | cut -d= -f2- || true; }
horodate() { date '+%H:%M:%S'; }

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ÉCHEC : modifications locales dans $DEPOT (git status). Rien n'est déployé."
  git status --short | head -20
  exit 1
fi

AVANT=$(git rev-parse HEAD)
git fetch -q "$URL" main
APRES=$(git rev-parse FETCH_HEAD)
echo "$(horodate) Commit actuel : ${AVANT:0:7}  →  main : ${APRES:0:7}"
if [ "$AVANT" = "$APRES" ]; then
  echo "Déjà à jour. Contrôles seulement."
else
  git merge -q --ff-only FETCH_HEAD || { echo "ÉCHEC : main n'est pas une avance rapide du VPS"; exit 1; }
fi
CHANGES=$(git diff --name-only "$AVANT" "$APRES" || true)

appliquer() {  # appliquer LISTE_DES_FICHIERS_CHANGÉS
  local ch="$1"
  docker compose config -q || return 1
  if printf '%s\n' "$ch" | grep -qE '^(compose\.yaml|\.env\.example)$'; then
    echo "$(horodate) compose.yaml modifié : docker compose up -d"
    docker compose up -d || return 1
  fi
  if printf '%s\n' "$ch" | grep -qE '^hermes/'; then
    echo "$(horodate) Hermès modifié : redémarrage de hermes et hermes-passerelle"
    docker compose up -d --force-recreate hermes hermes-passerelle || return 1
  fi
  if printf '%s\n' "$ch" | grep -qE '^caddy/'; then
    echo "$(horodate) Caddy modifié : validation puis rechargement"
    docker compose exec -T caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null || return 1
    docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile || return 1
  fi
  return 0
}

controler() {
  local ok=0 code
  for _ in $(seq 1 40); do
    code=$(docker run --rm --network ovh-ai-stack_backend curlimages/curl:8.10.1 -s -o /dev/null -w '%{http_code}' -m 10 \
             -H "Authorization: Bearer $(lire API_SERVER_KEY)" http://hermes-passerelle:8642/v1/models || true)
    [ "$code" = 200 ] && { ok=1; break; }
    sleep 5
  done
  [ "$ok" = 1 ] || { echo "   passerelle Hermès : ÉCHEC (HTTP ${code:-aucune réponse})"; return 1; }
  echo "   passerelle Hermès : OK"
  docker compose ps --status running --services | grep -qx hermes || { echo "   agent Hermès : ÉCHEC (arrêté)"; return 1; }
  echo "   agent Hermès : OK"
  if [ -f scripts/verifier-tce.py ]; then
    docker compose exec -T hermes python3 - < scripts/verifier-tce.py || return 1
  fi
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 15 https://hermes.blueseatra.com/ || true)
  [ "$code" = 401 ] || { echo "   accès web : ÉCHEC (HTTP $code, attendu 401)"; return 1; }
  echo "   accès web protégé : OK"
}

if [ -n "$CHANGES" ]; then
  echo "Fichiers modifiés :"; printf '   %s\n' $CHANGES
fi
if appliquer "$CHANGES" && echo "$(horodate) Contrôles" && controler; then
  if printf '%s\n' "$CHANGES" | grep -qE '^hermes/skills-blueseatra/blueseatra-'; then
    if ! docker compose exec -T hermes python3 - --smoke < scripts/verifier-tce.py; then
      echo "$(horodate) ÉCHEC du test modèle TCE : retour au commit ${AVANT:0:7}"
      git reset -q --hard "$AVANT" || exit 1
      appliquer "$CHANGES" || exit 1
      controler || echo "ATTENTION : contrôler le retour arrière manuellement."
      exit 1
    fi
  fi
  echo "$(horodate) DÉPLOIEMENT RÉUSSI : ${APRES:0:7}"
  exit 0
fi

echo "$(horodate) ÉCHEC : retour au commit ${AVANT:0:7}"
git reset -q --hard "$AVANT" || { echo "ÉCHEC du retour au commit précédent"; exit 1; }
appliquer "$CHANGES" || { echo "ÉCHEC de réapplication du commit précédent"; exit 1; }
controler || echo "ATTENTION : le retour arrière ne répond pas non plus, intervention manuelle nécessaire."
exit 1
