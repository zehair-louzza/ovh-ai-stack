# ADR-012 : noyau TCE v4 et références à la demande

Les 25 skills v4 sont montés en lecture seule dans le répertoire externe déjà
configuré. SOUL charge désormais le noyau seul. À la demande explicite du
05/10/2026, les anciens skills `extraire-demande-travaux` et
`decrire-demande-travaux` sont retirés, avec leurs références dupliquées.
Les éventuelles copies locales sont archivées hors de l'index avant contrôle.

La passerelle SaaS conserve ses outils désactivés : FastAPI injecte lui-même le
contrat et la fiche pertinente, dans des appels isolés. Installer des skills dans
l'agent ne suppose pas qu'un appel direct de passerelle les charge automatiquement.

Le workflow inclut maintenant les changements Markdown des skills et de SOUL.
Le contrôle après redémarrage vérifie la découverte réelle avec `skills_list`
et le chargement du noyau avec `skill_view`. Un test synthétique du modèle via
la passerelle vérifie ensuite quatre assertions, sans données clients ni prix.

Retour arrière : revert de la PR, déploiement automatique. Le volume Hermes,
la mémoire, Ollama, ses modèles et les secrets ne sont ni supprimés ni remplacés.
Le script de déploiement garde son retour automatique au commit précédent en cas
de contrôle défaillant.
