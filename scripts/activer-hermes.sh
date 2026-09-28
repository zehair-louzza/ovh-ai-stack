#!/usr/bin/env bash
# Active la passerelle Hermès du SaaS Blueseatra, Mistral, et l'accès web
# https://hermes.blueseatra.com (identifiant + mot de passe).
#   cd ~/ovh-ai-stack && ./scripts/activer-hermes.sh
# Rejouable. Aucun secret n'est affiché, sauf le mot de passe web s'il est créé.
set -euo pipefail
cd "$(dirname "$0")/.."
ENV=.env
[ -f "$ENV" ] || { echo "Fichier .env introuvable dans $(pwd)"; exit 1; }
umask 077
ecrire() { if grep -q "^$1=" "$ENV"; then sed -i "s|^$1=.*|$1=$2|" "$ENV"; else printf '%s=%s\n' "$1" "$2" >> "$ENV"; fi; }
lire()   { grep -E "^$1=" "$ENV" | tail -1 | cut -d= -f2- || true; }
alea()   { openssl rand -base64 64 | tr -dc 'A-Za-z0-9' | head -c "$1"; }
# Appel à la passerelle depuis le réseau Docker interne (image curl officielle,
# aucune dépendance au contenu de l'image Hermès).
api()    { docker run --rm -i --network ovh-ai-stack_backend curlimages/curl:8.10.1 -sS -m "${2:-300}" \
             -H "Authorization: Bearer $(lire API_SERVER_KEY)" -H 'Content-Type: application/json' \
             "http://hermes-passerelle:8642$1" ${3:+--data-binary @-}; }

echo "1/7 Mise à jour du dépôt"
GIT_SSH_COMMAND='ssh -i ~/.ssh/github_ovh_ai_stack -o IdentitiesOnly=yes' git pull --ff-only || true

echo "2/7 Clé Mistral"
if [ -z "$(lire MISTRAL_API_KEY)" ]; then
  read -r -s -p "   Collez la clé API Mistral (rien ne s'affiche, Entrée pour passer) : " CLE; echo
  [ -n "${CLE:-}" ] && ecrire MISTRAL_API_KEY "$CLE"
fi

echo "3/7 Identifiants de https://hermes.blueseatra.com"
UTIL=$(lire HERMES_WEB_USER); UTIL=${UTIL:-hermes-admin}; MDP=""
if [ -z "$(lire HERMES_WEB_HASH)" ]; then
  read -r -s -p "   Mot de passe web (Entrée = en générer un) : " MDP; echo
  MDP=${MDP:-$(alea 24)}; NOUVEAU=1
  HASH=$(docker run --rm caddy:2.10-alpine caddy hash-password --plaintext "$MDP" | base64 -w0)
  ecrire HERMES_WEB_USER "$UTIL"; ecrire HERMES_WEB_HASH "$HASH"
  ecrire HERMES_DASHBOARD_BASIC_AUTH_USERNAME "$UTIL"
  ecrire HERMES_DASHBOARD_BASIC_AUTH_PASSWORD "$MDP"
  ecrire HERMES_DASHBOARD_BASIC_AUTH_SECRET "$(alea 48)"
fi

echo "4/7 Démarrage (agent principal, passerelle, Caddy)"
docker compose pull hermes hermes-passerelle
docker compose up -d hermes hermes-passerelle
docker compose up -d --force-recreate caddy
for i in $(seq 1 40); do api /v1/models 10 >/dev/null 2>&1 && break; sleep 5; done

echo "5/7 Outils de la passerelle (attendu : 0)"
api /v1/toolsets 20 | python3 -c 'import json,sys; d=json.load(sys.stdin); d=d if isinstance(d,list) else d.get("data",[]); print("   outils actifs :", sum(len(t.get("tools",[])) for t in d if t.get("enabled")))' || echo "   (non lisible)"

echo "6/7 Essais réels par la passerelle"
essai() {  # essai LIBELLE FOURNISSEUR MODELE CONTENU_JSON
  local debut=$(date +%s) rep
  rep=$(printf '{"model":"%s","provider":"%s","stream":false,"messages":[{"role":"user","content":%s}]}' "$3" "$2" "$4" | api /v1/chat/completions 600 x 2>&1 | head -c 4000)
  printf '   %-28s %4ss  ' "$1" "$(( $(date +%s) - debut ))"
  printf '%s' "$rep" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin); c=d["choices"][0]["message"]["content"]; print("OK :", " ".join(str(c).split())[:90])
except Exception: print("ÉCHEC :", sys.stdin.read()[:0] or "voir ci-dessous")' || true
  printf '%s' "$rep" | grep -q '"choices"' || echo "      ${rep:0:300}"
}
IMG="data:image/png;base64,$(base64 -w0 scripts/ocr-essai.png)"
[ -n "$(lire MISTRAL_API_KEY)" ] && essai "Mistral Small" custom:mistral mistral-small-latest '"Reponds uniquement : OK"'
essai "Qwen2.5 7B (texte)" custom:ollama qwen2.5:7b '"Reponds uniquement : OK"'
essai "PaddleOCR-VL (image)" custom:ollama "AuditAid/PaddleOCR-VL-1.6-0.9B:latest" "[{\"type\":\"text\",\"text\":\"OCR:\"},{\"type\":\"image_url\",\"image_url\":{\"url\":\"$IMG\"}}]"
echo "   (l'image d'essai contient : DEVIS TEST 4217 / Pompe de relevage)"

echo "7/7 Accès web"
echo "   sans identifiants : $(curl -s -o /dev/null -w '%{http_code}' https://hermes.blueseatra.com/) (attendu 401)"
echo
echo "=== https://hermes.blueseatra.com ==="
echo "Identifiant  : $UTIL"
if [ "${NOUVEAU:-0}" = 1 ]; then echo "Mot de passe : $MDP"; else echo "Mot de passe : inchangé"; fi
echo "Copiez les 7 lignes « Essais réels » et envoyez-les à Blueseatra Computer."
