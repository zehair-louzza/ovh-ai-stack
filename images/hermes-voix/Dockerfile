# Image de l'agent Hermès du tableau de bord, avec la voix locale (12/10/2026).
#
# L'image officielle ne contient pas l'extra « voice » et refuse les
# installations à la demande. Sans ces deux moteurs, Hermès Desktop affichait
# « No STT provider available ». On les ajoute ici pour qu'ils survivent à la
# recréation du conteneur et aux mises à jour (méthode de l'image dérivée,
# https://hermes-agent.nousresearch.com/docs/user-guide/docker/).
#
#   - faster-whisper : transcription locale (stt.provider: local, modèle small, fr)
#   - piper-tts      : voix locale (tts.provider: piper, fr_FR-siwis-medium)
#
# La voix ne quitte pas le VPS. La passerelle du SaaS (hermes-passerelle) garde
# l'image officielle, sans ces moteurs ni outils.
#
# Mise à jour : docker compose build --pull hermes && docker compose up -d hermes
FROM nousresearch/hermes-agent:latest

USER root

# uv est fourni par l'image (gestionnaire PM) dans /opt/hermes/tools/uv-*/uv.
RUN UV="$(find /opt/hermes/tools -name uv -type f | head -1)" \
 && test -x "$UV" \
 && "$UV" pip install --no-cache --python /opt/hermes/.venv/bin/python \
      "faster-whisper==1.2.1" \
      "piper-tts==1.8.0" \
 && /opt/hermes/.venv/bin/python -c "import faster_whisper, piper; print('voix locale OK')"

# Garder l'entrée de l'image officielle : s6 abaisse les droits au démarrage.
