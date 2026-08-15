# Décommission Oracle Cloud (hébergement)

OracleMind (MCP) reste un produit. Ce qui doit disparaître : les *ressources d'hébergement* IA.

## Inventaire à vérifier dans la console OCI (`us-ashburn-1`, profil ORACLEMIND)

1. Instances Compute (VM Hermes / Ollama)
2. VNIC, IP publique, NSG / Security Lists ouvrant 22 / 11434
3. Block volumes orphelins
4. Object Storage contenant des documents clients
5. Clés API utilisateur / auth tokens encore actifs
6. Budgets / alertes FinOps devenus inutiles

## Ordre recommandé

1. Basculer `HERMES_BASE_URL` Render vers `https://$PUBLIC_DOMAIN`
2. Vérifier une extraction réelle Blueseatra
3. Arrêter la VM OCI (ne pas terminer tout de suite)
4. Conserver 7 jours au cas où
5. Terminer l'instance, détacher / détruire les volumes
6. Révoquer les clés API qui n'ont plus d'usage hors OracleMind
7. Documenter la date dans le registre des traitements

## Ce qu'on ne touche pas
- Dépôts `OracleMind` et `OracleMind-Pro`
- Licences Ed25519
- Tenancy OCI si elle sert encore au produit MCP
