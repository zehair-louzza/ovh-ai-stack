# Guide PowerShell — finir l'install OVH

Règle : **une seule commande à la fois**. Collez, validez, lisez le résultat, passez à la suivante. Les pipes multi-lignes cassent sous Windows PowerShell 5.

Deux machines, deux invites. Ne jamais mélanger.

| Invite | Où vous êtes | Commandes autorisées |
|---|---|---|
| `PS C:\...>` | Windows | `Test-Path`, `ssh-keygen -f $env:USERPROFILE\...`, `Get-Content` |
| `ubuntu@vps-...:~$` | VPS Linux | `sudo`, `docker`, `git`, `nano`, `exit` |

Si vous voyez `ubuntu@vps-...$`, tapez `exit` avant toute commande PowerShell.

Hôte : `vps-b377201e.vps.ovh.net` · IP `162.19.44.2` · user `ubuntu`

---

## 0. Avant de commencer

Dans [hPanel Hostinger](https://hpanel.hostinger.com) → Domaines → `blueseatra.com` → Zone DNS, créez 3 enregistrements **A** vers `162.19.44.2` :

- `ia` → `ia.blueseatra.com`
- `n8n` → `n8n.blueseatra.com`
- `hermes` → `hermes.blueseatra.com`

Sans DNS, Let's Encrypt échouera. Vous pouvez quand même durcir SSH et lancer Docker, et brancher Caddy plus tard.

Ouvrez PowerShell **en utilisateur normal** (pas besoin d'admin sauf pour générer une clé si le dossier `.ssh` n'existe pas).

---

## 1. Clé SSH (sur Windows)

```powershell
Test-Path $env:USERPROFILE\.ssh
```

Si `False` :

```powershell
New-Item -ItemType Directory -Path $env:USERPROFILE\.ssh -Force
```

```powershell
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\ovh_vps" -C louzza-ovh-vps -N '""'
```

Sous PowerShell 5, `-N ""` est ignoré. Les simples quotes autour de `""` sont obligatoires.

```powershell
Get-Content $env:USERPROFILE\.ssh\ovh_vps.pub
```

Copiez la ligne `ssh-ed25519 ...`.

Fichier de config SSH :

```powershell
@"
Host ovh-vps
    HostName vps-b377201e.vps.ovh.net
    User ubuntu
    IdentityFile ~/.ssh/ovh_vps
    IdentitiesOnly yes
"@ | Add-Content $env:USERPROFILE\.ssh\config
```

---

## 2. Installer la clé sur le VPS

Toujours en mot de passe **une dernière fois** :

```powershell
type $env:USERPROFILE\.ssh\ovh_vps.pub | ssh ubuntu@vps-b377201e.vps.ovh.net "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

Test **sans mot de passe** :

```powershell
ssh ovh-vps "echo OK && whoami"
```

Attendu : `OK` puis `ubuntu`. Si on redemande le mot de passe, arrêtez-vous et renvoyez la clé.

---

## 3. Reboot noyau (obligatoire)

Le journal d'install montre `6.8.0-106` alors que `6.8.0-137` est installé.

```powershell
ssh ovh-vps "uname -r"
```

```powershell
ssh ovh-vps "sudo reboot"
```

Attendez 30–45 s.

```powershell
ssh ovh-vps "uname -r"
```

Attendu : `6.8.0-137-generic` (ou plus récent).

Vérifier Docker après reboot :

```powershell
ssh ovh-vps "docker --version && docker compose version"
```

Attendu : `Docker version 29.7.2` et `Docker Compose version v5.4.0`.

---

## 4. Durcir le VPS

```powershell
ssh ovh-vps "sudo apt-get update"
```

```powershell
ssh ovh-vps "sudo apt-get install -y git fail2ban unattended-upgrades"
```

Les scripts de durcissement sont dans le dépôt (étape 5). Ne désactivez **pas** le mot de passe SSH avant d'avoir validé `ssh ovh-vps`.

---

## 5. Cloner le dépôt sur le VPS

Sur GitHub : Settings du repo `ovh-ai-stack` → Deploy keys → ajouter `ovh_vps.pub` en **lecture seule**.

Sinon, créez un Personal Access Token `repo` (privé) et utilisez HTTPS.

```powershell
ssh ovh-vps "git --version"
```

HTTPS + token (le token ne s'affiche pas ensuite) :

```powershell
ssh ovh-vps
```

Une fois **dans** la session SSH Linux :

```bash
cd ~
```

```bash
git clone https://github.com/zehair-louzza/ovh-ai-stack.git
```

```bash
cd ovh-ai-stack
```

```bash
bash scripts/generate-secrets.sh
```

```bash
nano .env
```

Vérifiez que `.env` contient déjà `ia.blueseatra.com`, `n8n.blueseatra.com`, `hermes.blueseatra.com`. Ajustez seulement `ACME_EMAIL` si `contact@blueseatra.com` n'est pas une boîte que vous lisez. Enregistrez : `Ctrl+O`, Entrée, `Ctrl+X`.

```bash
sudo bash scripts/host-hardening.sh
```

Vérifications :

```bash
sudo ufw status
```

```bash
sudo fail2ban-client status sshd
```

```bash
sudo ss -lntp | grep -E ':22|:80|:443'
```

---

## 6. Démarrer la stack

Toujours dans `~/ovh-ai-stack` sur le VPS :

```bash
mkdir -p n8n-files
```

```bash
docker compose pull
```

```bash
docker compose up -d
```

```bash
docker compose ps
```

Les 4 services (`caddy`, `ollama`, `n8n`, `hermes`) doivent être `running`. Hermes peut redémarrer tant qu'Ollama n'est pas healthy : attendre 1 minute puis `docker compose ps` à nouveau.

```bash
docker compose logs --tail=50 caddy
```

```bash
docker compose logs --tail=50 hermes
```

---

## 7. Télécharger les modèles (long)

`gpt-oss:20b` ≈ 13 Go, `qwen2.5vl:7b` ≈ 6 Go. Ne coupez pas la session.

```bash
bash scripts/pull-models.sh
```

Si la session SSH tombe, relancez le script : `ollama pull` reprend.

Contrôle RAM :

```bash
free -h
```

```bash
docker stats --no-stream
```

Ollama doit rester sous ~18 Go. Si `gpt-oss:20b` swap trop : dans `.env` mettez `HERMES_MODEL=hermes3` (seul modèle installé avec tools + contexte ≥64K, voir ADR-006/ADR-007) puis `docker compose up -d hermes`.

---

## 8. Tests depuis Windows

Récupérez la clé (sur le VPS) :

```bash
grep OLLAMA_API_KEY .env
```

Sur PowerShell, remplacez les deux valeurs :

```powershell
$domain = "ia.blueseatra.com"
$key = "COLLEZ_LA_CLE"
```

Sans clé → 401 :

```powershell
curl.exe -s -o NUL -w "%{http_code}" https://$domain/api/tags
```

Avec clé → 200 et liste JSON :

```powershell
curl.exe -s -H "X-Api-Key: $key" https://$domain/api/tags
```

Chat court (Hermes 3) :

```powershell
curl.exe -s -H "X-Api-Key: $key" -H "Content-Type: application/json" -d "{\"model\":\"hermes-3\",\"messages\":[{\"role\":\"user\",\"content\":\"dis seulement OK\"}],\"stream\":false}" https://$domain/api/chat
```

n8n : ouvrez `https://n8n.blueseatra.com` et créez le compte owner **immédiatement**.

---

## 9. Brancher Blueseatra (Render)

Variables backend :

| Variable | Valeur |
|---|---|
| `HERMES_BASE_URL` | `https://ia.blueseatra.com` |
| `HERMES_DEFAULT_MODEL` | `hermes-3` |
| `HERMES_API_KEY` | la même que `OLLAMA_API_KEY` |

Le backend envoie l'en-tête `X-Api-Key` (commit `feature/ovh-hermes-api-key`).

Projet Supabase `Blueseatra` (`xmsxlochasjauhnxarvc`) : statut **INACTIVE**. Restaurez-le dans le dashboard avant un test métier.

---

## 10. Contrôle SSH après durcissement

Fermez toutes les sessions. Depuis Windows :

```powershell
ssh ovh-vps "echo cle-ok"
```

Si ça marche, le mot de passe SSH est déjà désactivé par `host-hardening.sh`. Gardez `ovh_vps` (fichier privé) hors OneDrive public et hors git.

---

## Dépannage express

| Symptôme | Action |
|---|---|
| `Permission denied (publickey)` | `ssh-add $env:USERPROFILE\.ssh\ovh_vps` puis réessayer `ssh ovh-vps` |
| Caddy `NXDOMAIN` / ACME fail | DNS A pas encore propagé : `nslookup ia.blueseatra.com` |
| Hermes restart loop | `docker compose logs hermes` — souvent Ollama pas ready |
| OOM / freeze | passer sur `hermes3` (`HERMES_MODEL=hermes3` dans `.env`, seul fallback fonctionnel testé — voir ADR-006/ADR-007) |
| `docker: command not found` après reboot | `sudo usermod -aG docker ubuntu` puis se reconnecter |
| Port 11434 visible de l'extérieur | `sudo ss -lntp` — il ne doit PAS écouter sur `0.0.0.0:11434` |

## Suite Oracle

Quand l'extraction Blueseatra marche via OVH : [DECOMMISSION-ORACLE.md](DECOMMISSION-ORACLE.md).
