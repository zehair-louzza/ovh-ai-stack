# ADR-015 — Voix locale pour l'agent Hermès, par Hermès Desktop et une image dérivée

- Statut : accepté
- Date : 12 octobre 2026

## Contexte

Le propriétaire veut parler à l'agent Hermès du VPS avec le micro de son PC. Le tableau de bord web n'a pas d'accès au micro (terminal distant sans audio, ticket Hermès #20765). Une carte son virtuelle sur le VPS ne transporterait pas la voix du PC ; le renvoi audio PulseAudio par SSH est jugé fragile par les développeurs d'Hermès.

Hermès Desktop se connecte à un Hermès distant et capte le micro du PC. Avec une transcription locale, l'audio est envoyé au VPS, transcrit et synthétisé sur place.

L'image officielle ne contient pas l'extra `voice` (faster-whisper) ni Piper, et désactive les installations à la demande. Une installation dans le conteneur disparaît à chaque recréation.

## Décision

1. Transcription faster-whisper (`small`, français) et voix Piper (`fr_FR-siwis-medium`), sur le VPS.
2. Image dérivée `images/hermes-voix/Dockerfile` pour le seul service `hermes`, versions épinglées, construite sur le VPS (`pull_policy: build`). La passerelle du SaaS garde l'image officielle.
3. Connexion d'Hermès Desktop par tunnel SSH vers le port 9119 du conteneur, sans nouvelle exposition sur Internet.

## Conséquences

- La voix ne quitte pas le VPS.
- Chaque mise à jour d'Hermès demande `docker compose build hermes` après `docker compose pull hermes-passerelle` (procédure dans `docs/EXPLOITATION-HERMES.md`).
- L'adresse interne du conteneur change à chaque recréation : la commande de tunnel la récupère.

## Rejeté

- **Carte son virtuelle ou renvoi PulseAudio par SSH** : ne capte pas le micro du PC, ou fragile.
- **Transcription en ligne (Groq, Mistral, OpenAI)** : l'audio sortirait du VPS.
- **Connexion directe d'Hermès Desktop à hermes.blueseatra.com** : le `basic_auth` de Caddy n'est pas géré par l'application ; le retirer affaiblirait l'accès au tableau de bord.
