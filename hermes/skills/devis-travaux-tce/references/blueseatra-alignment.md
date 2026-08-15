# Alignement avec le SaaS Blueseatra

> À lire quand un devis est produit **pour** ou **dans la logique de** Blueseatra (plateforme SaaS B2B multi-tenant , qui transforme des demandes clients en devis Pro Forma via extraction IA). Ce fichier garde ce skill cohérent avec le moteur IA `wWthone` (Hermes-3 / Ollama / OVH) déployé dans Blueseatra, avec le schéma Supabase réel, et avec le format d'import catalogue réellement utilisé par la plateforme. Objectif : que ce skill puisse servir de **spécification de référence** pour le comportement du moteur de devis Blueseatra, et que tout devis produit ici reste directement réutilisable dans la plateforme.

## 1. Ce skill face au « Skill Master » `wWthone`

Blueseatra embarque son propre prompt de compétence (`docs/Skill_MASTER_agent_wWthone.md` + complément `Skill_PROFIL_organisation_wWthone.md` dans le dépôt du projet). Ce skill `devis-travaux-tce` doit rester la **contrepartie Perplexity Computer** de ce même corpus de règles : mêmes formules, mêmes garde-fous, même vocabulaire (Confirmé / Estimé / À confirmer, statuts de devis, structure en lots). En cas d'évolution du Skill Master côté Blueseatra (nouvelle version dans le dépôt), reporter les changements ici pour éviter une dérive entre les deux moteurs.

## 2. Schéma de données réel (Supabase / PostgreSQL, schéma `blueseatra`)

14 tables, clés primaires en UUID, champs dynamiques en JSONB. Un devis produit selon ce skill doit rester **mappable sans perte** sur ces tables :

| Table | Rôle | Correspondance avec ce skill |
|---|---|---|
| `tenants` / `tenant_users` / `users` | Entreprise et utilisateurs (isolation multi-tenant) | Chaque devis appartient à une seule entreprise ; ne jamais mélanger les données de deux organisations dans un même fichier. |
| `catalogs` / `catalog_versions` | Catalogue et ses versions (`columns`, `mapping` en JSONB) | Le « catalogue en lecture seule » de ce skill = une `catalog_version` active. Le mapping de colonnes peut varier par tenant (voir §3). |
| `pricing_items` | Articles (label, prix, TVA, marge ; JSONB `suppliers`, `attributes`) | Une ligne de catalogue = un `pricing_item`. `attributes` porte les colonnes non standard (marque, référence, famille…). |
| `requests` | Demande client entrante + extraction IA (JSONB `extracted`) | Voir §4, intake multi-canal. |
| `quotes` / `quote_versions` | Devis (client, site, totaux ; JSONB `lines`, `meta`, `pricing_snapshot`) et historique de versions | Correspond directement à la section « Référence, version, statut » et au tableau `Devis` du XLSX interne. |
| `import_jobs` / `import_errors` | Journaux d'import CSV catalogue | Concerne l'alimentation du catalogue, jamais le devis lui-même : ne pas mélanger avec les fichiers de devis. |
| `company_profiles` | Profil entreprise utilisé pour le PDF | Alimente l'en-tête « Prestataire » (nom, adresse, SIRET, logo). Ne jamais inventer un champ manquant : le signaler « À confirmer ». |
| `settings_integrations` | Réglages IA/n8n par tenant | Hors périmètre de ce skill (concerne la configuration technique, pas le contenu du devis). |
| `audit_logs` | Journal d'audit | Informationnel uniquement ; ne jamais reconstituer un audit log dans un devis. |

## 3. Catalogue « ouvert » : mapping dynamique des colonnes

Contrairement à un catalogue à colonnes figées, Blueseatra accepte **n'importe quel format de colonnes** à l'import CSV : auto-détection des champs + mapping manuel ajustable, stocké dans `catalog_versions.mapping`. Les colonnes non reconnues sont conservées dans `pricing_items.attributes` (JSONB) sans être perdues.

Conséquences pour ce skill :

- La liste `Famille, Article, Unité, Marque, Référence, Fournisseur_principal, Fournisseur_alternatif_1, TVA_%, Marge_%, Prix_achat_HT, Prix_vente_HT, Délai` (voir SKILL.md) est un **schéma cible de référence**, pas une contrainte stricte : si le catalogue fourni par l'utilisateur utilise d'autres noms de colonnes, faire correspondre par le sens (ex. `Désignation` = `Article`, `Coût` = `Prix_achat_HT`) avant de chiffrer, et confirmer le mapping retenu si un doute existe sur une colonne critique (prix, unité, référence).
- Ne jamais renommer les colonnes **dans le fichier catalogue source** ; le mapping se fait uniquement en mémoire de travail pour produire le devis.
- Si deux colonnes du catalogue pourraient correspondre au même champ cible (ambiguïté de mapping), demander confirmation avant de chiffrer les lignes concernées plutôt que de choisir arbitrairement.

## 4. Intake multi-canal de la demande (email, PDF, image, formulaire)

Blueseatra reçoit les demandes clients comme « ordres de mission » au format PDF, image ou texte (y compris texte d'e-mail), et les fait passer par une extraction IA (`requests.extracted`) avant rapprochement catalogue. Ce skill doit traiter une demande transmise par e-mail, fichier joint, capture d'écran ou texte libre avec la **même rigueur** qu'une extraction automatique :

1. Identifier et extraire, quel que soit le canal : client, site d'intervention, objet de la demande, lignes de prestations pressenties, contraintes (délai, accès, horaires).
2. Classer chaque champ extrait selon le niveau de fiabilité habituel du skill (Confirmé / Estimé / À confirmer) — un champ lu textuellement dans l'e-mail ou le PDF est `Confirmé` ; un champ déduit ou reformulé est `Estimé` ; un champ absent mais nécessaire est `À confirmer`.
3. Ne jamais fusionner deux demandes de canaux différents sans le signaler si elles concernent le même client/site : le devis doit indiquer sa demande source (ex. « Demande reçue par e-mail le 12/08/2026 »).
4. Si la demande est une image ou un PDF scanné dont le texte est partiellement illisible, signaler les zones illisibles comme `À confirmer` plutôt que de deviner leur contenu.

## 5. Cycle de vie du devis et gel des prix (`pricing_snapshot`)

Dans `quotes`, chaque devis conserve un `pricing_snapshot` : une copie figée des prix catalogue au moment de la validation. Règle à respecter dans ce skill :

- Une fois un devis passé au statut `Validé`, ses prix sont **gelés** : une mise à jour ultérieure du catalogue (nouveaux prix, nouvelle version) ne doit **jamais** modifier rétroactivement un devis déjà validé.
- Pour appliquer une évolution tarifaire à un devis validé, créer une **nouvelle version** (V02, V03…) qui recalcule explicitement à partir du catalogue à jour, jamais une édition silencieuse de la version existante.
- Le XLSX interne peut noter, dans la feuille `Paramètres`, la version du catalogue utilisée au moment du calcul (nom + date), pour traçabilité — cela correspond au rôle de `pricing_snapshot` côté plateforme.

## 6. Multi-tenant : ne jamais mélanger deux organisations

Si l'utilisateur gère plusieurs entités ou catalogues (par ex. plusieurs enseignes clientes de Blueseatra), toujours vérifier explicitement quelle entreprise/quel catalogue est actif avant de chiffrer, et ne jamais réutiliser un tarif ou un profil d'entreprise d'une autre organisation sans confirmation.
