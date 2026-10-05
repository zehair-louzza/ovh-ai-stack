# ADR-012 : noyau TCE v4 et références à la demande

Les 25 skills v4 sont montés en lecture seule dans le répertoire externe déjà
configuré. SOUL charge désormais le noyau seul ; les deux anciens skills restent
des alias compatibles, sans quantité minimale ni durée inventée.

La passerelle SaaS conserve ses outils désactivés : FastAPI injecte lui-même le
contrat et la fiche pertinente, dans des appels isolés. Installer des skills dans
l'agent ne suppose pas qu'un appel direct de passerelle les charge automatiquement.

Le workflow inclut maintenant les changements Markdown des skills et de SOUL.
Le contrôle après redémarrage vérifie la découverte réelle avec `skills_list`
et le chargement du noyau avec `skill_view`, sans appel à un modèle ni prix.

Retour arrière : revert de la PR, déploiement automatique. Le volume Hermes,
la mémoire, Ollama, ses modèles et les secrets ne sont ni supprimés ni remplacés.
Le script de déploiement garde son retour automatique au commit précédent en cas
de contrôle défaillant.
