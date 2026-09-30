#!/usr/bin/env bash
# À lancer UNE FOIS sur le VPS : crée la clé SSH réservée au déploiement
# automatique (ADR-011) et la limite à scripts/deployer-vps.sh.
#   cd ~/ovh-ai-stack && ./scripts/installer-deploiement-auto.sh
# Affiche ensuite les 3 valeurs à coller dans GitHub (Settings > Secrets).
set -euo pipefail
CLE="$HOME/.ssh/deploiement_github"
SCRIPT="$HOME/ovh-ai-stack/scripts/deployer-vps.sh"
AUTH="$HOME/.ssh/authorized_keys"
install -m 700 -d "$HOME/.ssh"
[ -f "$CLE" ] || ssh-keygen -q -t ed25519 -N "" -C "deploiement-github-ovh-ai-stack" -f "$CLE"
LIGNE="command=\"$SCRIPT\",no-pty,no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-user-rc $(cat "$CLE.pub")"
touch "$AUTH" && chmod 600 "$AUTH"
grep -qF "$(cut -d' ' -f2 "$CLE.pub")" "$AUTH" || printf '%s\n' "$LIGNE" >> "$AUTH"
echo "Clé installée et limitée à : $SCRIPT"
echo
echo "=== Secret VPS_HOST ==="
curl -s -4 -m 10 https://ifconfig.me || hostname -I | awk '{print $1}'; echo
echo
echo "=== Secret VPS_KNOWN_HOSTS ==="
IP=$(curl -s -4 -m 10 https://ifconfig.me || hostname -I | awk '{print $1}')
for f in /etc/ssh/ssh_host_*_key.pub; do printf '%s %s\n' "$IP" "$(cut -d' ' -f1,2 "$f")"; done
echo
echo "=== Secret VPS_SSH_KEY (tout le bloc, lignes BEGIN et END comprises) ==="
cat "$CLE"
echo
echo "Collez ces 3 valeurs dans GitHub puis effacez l'écran : clear"
