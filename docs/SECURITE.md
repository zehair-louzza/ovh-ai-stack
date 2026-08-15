# Contrôles de sécurité — VPS OVH

## État constaté le 15 août 2026 (journal d'install)

- Ubuntu 24.04.4, noyau en cours `6.8.0-106` — **reboot requis** vers `6.8.0-137`
- Docker CE 29.7.2 + Compose v5.4.0
- SSH encore en mot de passe (plusieurs échecs puis succès)
- `inetutils-telnet` présent (à purger)
- UFW 80/443/OpenSSH déjà ouvert dans la session précédente
- Swap 4 Go déjà créé
- Projet Supabase `Blueseatra` (`xmsxlochasjauhnxarvc`, `eu-west-1`) : **INACTIVE** — à restaurer avant prod

## Cible après le guide PowerShell

- [ ] Noyau à jour
- [ ] Clé Ed25519, mot de passe SSH off
- [ ] fail2ban actif
- [ ] Telnet retiré
- [ ] Ollama / n8n / Hermes sans port public
- [ ] Caddy TLS + `X-Api-Key`
- [ ] `.env` chmod 600 hors git
- [ ] DNS A pour les 3 hôtes
- [ ] Secret `HERMES_API_KEY` dans Render
- [ ] DPA OVH / Render / Supabase signés
