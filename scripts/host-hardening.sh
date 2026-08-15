#!/usr/bin/env bash
# Durcissement Ubuntu 24.04 — à lancer en SSH APRÈS avoir validé la connexion par clé.
# Ne désactive le mot de passe SSH que si ~/.ssh/authorized_keys contient au moins une clé.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Relancer avec sudo."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  unattended-upgrades apt-listchanges fail2ban ufw auditd \
  needrestart

# Mises à jour de sécurité automatiques
dpkg-reconfigure -f noninteractive unattended-upgrades || true

# Pare-feu : SSH + HTTP/HTTPS uniquement
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# fail2ban SSH
cat >/etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 4
findtime = 10m
bantime = 1h
backend = systemd
EOF
systemctl enable --now fail2ban

# SSH : clé uniquement si une clé est déjà en place
AUTH_KEYS="/home/ubuntu/.ssh/authorized_keys"
if [[ -s "${AUTH_KEYS}" ]]; then
  SSHD="/etc/ssh/sshd_config.d/99-hardening.conf"
  cat >"${SSHD}" <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AllowUsers ubuntu
X11Forwarding no
AllowTcpForwarding yes
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
EOF
  sshd -t
  systemctl reload ssh
  echo "Auth SSH par mot de passe désactivée."
else
  echo "ATTENTION : aucune clé dans ${AUTH_KEYS} — mot de passe SSH conservé."
fi

# Paquets inutiles / surface d'attaque
apt-get purge -y inetutils-telnet telnet || true
apt-get autoremove -y

# Permissions home
chmod 700 /home/ubuntu/.ssh || true
chmod 600 /home/ubuntu/.ssh/authorized_keys || true
chown -R ubuntu:ubuntu /home/ubuntu/.ssh || true

echo "Durcissement terminé. Vérifiez : sudo ufw status && sudo fail2ban-client status sshd"
