# FreightFlow AI — MVP cloud starter

Application Next.js en français destinée aux transitaires et équipes logistiques. Elle permet de déposer des documents de transport, d'en extraire les champs avec Mindee V2, de les faire vérifier par un opérateur, puis de comparer et exporter les données validées.

## Fonctionnalités présentes dans le code
- Inscription et connexion via Supabase Auth.
- Tableau de bord et bibliothèque de documents.
- Dépôt PDF, JPG et PNG dans un bucket Supabase privé.
- Extraction Mindee V2 côté serveur avec stockage des données, du score de confiance et de l'identifiant d'inférence.
- Revue côte à côte du document et des champs extraits, avec correction manuelle et validation.
- Comparaison de documents sélectionnés et détection de divergences sur les champs métier configurés.
- Export Excel des documents validés sélectionnés.
- Pages de base pour dossiers, anomalies, historique, facturation et paramètres.

> Important : il s'agit d'un MVP technique. Le dépôt ne constitue pas encore un SaaS de production. Le déploiement cloud, la configuration des comptes externes et les tests de sécurité restent à effectuer.

## Prérequis
- Node.js 20 ou plus récent
- Un projet Supabase
- Un compte Mindee avec un modèle d'extraction V2
- npm

## Installation locale
1. `npm install`
2. Copier `.env.example` vers `.env.local` et renseigner les variables.
3. Exécuter `supabase/schema.sql` dans le SQL Editor de Supabase.
4. Vérifier que le bucket `freight-documents` est privé.
5. Lancer `npm run dev`, puis ouvrir `http://localhost:3000`.

## Configuration Mindee V2
1. Créer un modèle d'extraction V2 dans votre compte Mindee.
2. Configurer au minimum les champs : `supplier`, `consignee`, `invoice_number`, `issue_date`, `currency`, `total_amount`, `packages`, `gross_weight`, `net_weight`, `container_numbers`, `bill_of_lading_number` et `air_waybill_number`.
3. Tester le modèle avec des factures commerciales, packing lists, BL et AWB représentatifs.
4. Récupérer la clé API V2 et le Model ID.
5. Renseigner `MINDEE_V2_API_KEY` et `MINDEE_MODEL_ID` dans `.env.local` et dans les variables d'environnement Vercel.

L'API `POST /api/extract` lit le fichier depuis le bucket privé, l'envoie à Mindee et enregistre les résultats en statut `review`. Une extraction n'est jamais considérée comme validée automatiquement. Un modèle Mindee adapté doit être créé par le propriétaire du compte : aucun Model ID n'est inclus dans ce dépôt.

## Variables d'environnement
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (réservée au serveur si une fonction admin l'utilise ; ne jamais l'exposer au navigateur)
- `MINDEE_V2_API_KEY`
- `MINDEE_MODEL_ID`

Ne jamais placer une clé secrète dans une variable `NEXT_PUBLIC_*`.

## Déploiement cloud Vercel
1. Pousser le dossier dans un dépôt GitHub privé.
2. Importer le dépôt dans Vercel avec le preset Next.js.
3. Ajouter les variables d'environnement ci-dessus dans les paramètres du projet Vercel.
4. Exécuter le schéma SQL dans Supabase et configurer les URL de redirection Auth pour le domaine Vercel.
5. Déployer, puis tester le parcours complet avec des documents non sensibles.

## Limites à traiter avant un pilote client
- Onboarding des entreprises, invitations et gestion des rôles/membres.
- Isolation multi-tenant complète et tests RLS : le MVP repose principalement sur `user_id`.
- Association ergonomique des documents à un dossier d'expédition.
- Routage vers plusieurs modèles Mindee selon le type de document, si nécessaire.
- Quotas mensuels atomiques, paiement Stripe et webhooks.
- Export CSV, traitement asynchrone robuste, reprise sur erreur et limitation de débit.
- Validation stricte du type MIME par signature, antivirus et limites de taille côté interface et serveur.
- Tests automatisés, journalisation, sauvegardes, politique de conservation et conformité RGPD.
- Revue de sécurité et tests de charge.

## Tarifs envisagés (non activés)
- Starter : 149 €/mois — 300 documents/mois
- Professional : 349 €/mois — 1 500 documents/mois
- Business : 799 €/mois — 5 000 documents/mois

Ces offres sont indicatives : aucun paiement ni contrôle de quota n'est actif dans ce MVP.

## Documentation officielle
- Mindee API : https://docs.mindee.com/integrations/api-overview
- Mindee SDK : https://docs.mindee.com/integrations/client-libraries-sdk/send-a-file-or-url
- Supabase avec Next.js : https://supabase.com/docs/guides/getting-started/quickstarts/nextjs
- Variables d'environnement Vercel : https://vercel.com/docs/deployments/environments
