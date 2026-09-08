# ⚠️ IMPORTANT - Restructuration des fichiers

## Problème

Les fichiers ont été créés avec des noms aplatis à cause des limitations de l'environnement Xcode.

## Fichiers créés avec mauvais noms

1. `supabasefunctionssend-support-emailindex.ts` ❌
2. `supabasemigrations20260907_support_email_webhook.sql` ❌

## Action requise : Renommer et déplacer les fichiers

### Étape 1 : Créer la structure de dossiers

Dans le Terminal, à la racine de votre projet Store Immo :

```bash
# Créer la structure pour les Edge Functions
mkdir -p supabase/functions/send-support-email

# Créer la structure pour les migrations
mkdir -p supabase/migrations
```

### Étape 2 : Déplacer et renommer les fichiers

```bash
# Déplacer l'Edge Function
mv supabasefunctionssend-support-emailindex.ts supabase/functions/send-support-email/index.ts

# Déplacer la migration SQL
mv supabasemigrations20260907_support_email_webhook.sql supabase/migrations/20260907_support_email_webhook.sql
```

### Étape 3 : Vérifier la structure

```bash
# Vérifier que les fichiers sont au bon endroit
ls -la supabase/functions/send-support-email/
# Doit contenir : index.ts

ls -la supabase/migrations/
# Doit contenir : 20260907_support_email_webhook.sql
```

## Structure finale attendue

```
StoreImmo/
├── AccountView.swift
├── AppViewModel.swift
├── SupabaseRepository.swift
├── ... (autres fichiers Swift)
├── RESEND_SUMMARY.md
├── RESEND_INTEGRATION.md
├── DEPLOYMENT_RESEND.md
└── supabase/
    ├── functions/
    │   └── send-support-email/
    │       └── index.ts              ← Edge Function
    └── migrations/
        └── 20260907_support_email_webhook.sql  ← Migration SQL
```

## Vérification finale

Une fois la structure corrigée, exécutez :

```bash
# Vérifier que Supabase CLI reconnaît la fonction
supabase functions list

# Si la fonction n'apparaît pas, c'est normal (elle n'est pas encore déployée)
# Mais au moins la commande ne doit pas donner d'erreur
```

## Alternative : Recréer les fichiers manuellement

Si le renommage ne fonctionne pas, vous pouvez recréer les fichiers :

### 1. Créer l'Edge Function

```bash
# Créer la structure
mkdir -p supabase/functions/send-support-email

# Créer le fichier (il sera vide)
touch supabase/functions/send-support-email/index.ts
```

Puis dans Xcode ou votre éditeur :
- Ouvrez `supabasefunctionssend-support-emailindex.ts`
- Copiez tout le contenu
- Collez-le dans `supabase/functions/send-support-email/index.ts`
- Supprimez l'ancien fichier `supabasefunctionssend-support-emailindex.ts`

### 2. Créer la migration SQL

```bash
# Créer la structure
mkdir -p supabase/migrations

# Créer le fichier (il sera vide)
touch supabase/migrations/20260907_support_email_webhook.sql
```

Puis dans Xcode ou votre éditeur :
- Ouvrez `supabasemigrations20260907_support_email_webhook.sql`
- Copiez tout le contenu
- Collez-le dans `supabase/migrations/20260907_support_email_webhook.sql`
- Supprimez l'ancien fichier `supabasemigrations20260907_support_email_webhook.sql`

## Après correction

Une fois la structure corrigée, vous pouvez suivre `DEPLOYMENT_RESEND.md` normalement :

```bash
# 1. Se connecter
supabase login

# 2. Lier le projet
supabase link --project-ref VOTRE_PROJECT_REF

# 3. Configurer le secret
supabase secrets set RESEND_API_KEY=re_xxxxx

# 4. Appliquer la migration
supabase db push

# 5. Déployer la fonction
supabase functions deploy send-support-email
```

## En cas de problème

Si les commandes échouent :

1. Vérifiez que vous êtes à la racine du projet
2. Vérifiez que la structure `supabase/functions/` et `supabase/migrations/` existe
3. Vérifiez que les fichiers sont aux bons endroits
4. Vérifiez que `index.ts` a bien l'extension `.ts` (pas `.txt`)

---

**Important** : Cette étape de restructuration est nécessaire avant de pouvoir déployer. Les commandes Supabase CLI s'attendent à trouver les fichiers dans `supabase/functions/` et `supabase/migrations/`.
