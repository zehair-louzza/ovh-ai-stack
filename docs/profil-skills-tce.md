# Profil de skills pour les devis TCE

L'inventaire du 5 octobre 2026 a observé 25 skills TCE et 78 skills généraux actifs.
À la demande de l'utilisateur, 50 skills hors du périmètre courant sont désactivés,
et non supprimés. Ils restent réactivables en retirant leur nom de `skills.disabled`.

## Ce qui reste actif

- **TCE** : noyau, quatre étapes et vingt lots.
- **Documents** : OCR, PDF, Word, Excel, Google Workspace, cartes et sessions.
- **Email** : tri de la boîte et Himalaya, conservés ensemble.
- **Maintenance** : outils de pilotage ordinateur/Hermes, skills GitHub, inspection
  du code, rédaction de skills, planification, débogage Python, revue, simplification
  et tests, ainsi que récupération de pages bloquées et citations vérifiables.

Le résultat attendu est 53 skills actifs : 25 TCE et 28 supports. Les outils
Hermes (terminal, fichiers, mémoire, web, etc.) sont un mécanisme séparé et ne sont
pas modifiés. Leurs permissions ne sont pas élargies.

## Ce qui est désactivé

Création artistique, musique/vidéo, agents de code alternatifs, recherche académique,
entraînement/serving de modèles, services non utilisés pour les devis, réseaux sociaux,
domotique personnelle et certains doublons de workflows. La liste exacte des
50 identifiants est versionnée dans `hermes/config.yaml`.

`product-price-monitor` est également désactivé : les tarifs de devis doivent
rester dans le moteur métier SaaS, et non être recherchés par une routine IA.

## Contrôle et retour arrière

La clé officielle `skills.disabled` est décrite dans la
[documentation Hermes](https://hermes-agent.nousresearch.com/docs/reference/faq/).
Le déploiement redémarre l'agent, puis vérifie que ces noms sont absents de
`skills_list()` et que les 25 skills TCE restent disponibles.

Pour réactiver un skill, retirer uniquement son nom de la liste puis redéployer.
Aucun modèle, aucune mémoire ni donnée métier n'est supprimé.
