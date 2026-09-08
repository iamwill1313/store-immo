# 🚀 DÉMARRAGE RAPIDE - Intégration Resend

## ⚠️ IMPORTANT - À LIRE EN PREMIER

Les fichiers ont été créés mais avec des noms aplatis. **Vous devez d'abord restructurer les fichiers** avant de déployer.

---

## ÉTAPE 0 : Restructurer les fichiers (OBLIGATOIRE)

### Option A : Script automatique (recommandé)

```bash
# Rendre le script exécutable
chmod +x restructure_resend_files.sh

# Exécuter le script
./restructure_resend_files.sh
```

### Option B : Commandes manuelles

```bash
# Créer les dossiers
mkdir -p supabase/functions/send-support-email
mkdir -p supabase/migrations

# Déplacer les fichiers
mv supabasefunctionssend-support-emailindex.ts supabase/functions/send-support-email/index.ts
mv supabasemigrations20260907_support_email_webhook.sql supabase/migrations/20260907_support_email_webhook.sql

# Vérifier
ls -la supabase/functions/send-support-email/index.ts
ls -la supabase/migrations/20260907_support_email_webhook.sql
```

### Option C : Fichier par fichier dans Xcode

Consultez `RESTRUCTURE_FILES.md` pour les instructions détaillées.

---

## ÉTAPE 1 : Déployer (après restructuration)

```bash
# Se connecter
supabase login

# Lier le projet
supabase link --project-ref VOTRE_PROJECT_REF

# Vérifier/configurer le secret
supabase secrets list
# Si absent :
supabase secrets set RESEND_API_KEY=re_xxxxx

# Appliquer la migration
supabase db push

# Déployer la fonction
supabase functions deploy send-support-email

# Vérifier
supabase functions list
```

---

## ÉTAPE 2 : Configurer le Webhook (Dashboard Supabase)

1. https://app.supabase.com → Votre projet
2. **Database** → **Webhooks** → **Create a new hook**
3. Remplissez :
   - Name: `Send Support Email`
   - Table: `support_tickets`
   - Events: ✅ INSERT
   - Method: POST
   - URL: `https://[PROJECT_REF].supabase.co/functions/v1/send-support-email`
   - Headers:
     ```
     Authorization: Bearer [VOTRE_ANON_KEY]
     Content-Type: application/json
     ```
4. Save

---

## ÉTAPE 3 : Tester

1. Lancez l'app Store Immo
2. **Compte** → **Aide et support** → **Signaler un problème**
3. Envoyez un ticket
4. Vérifiez :
   ```bash
   supabase functions logs send-support-email --follow
   ```
5. Vérifiez l'email à `support@storeimmo.com`

---

## 📚 Documentation complète

- **Ce guide** : Démarrage rapide
- **RESTRUCTURE_FILES.md** : Comment corriger la structure des fichiers
- **RESEND_SUMMARY.md** : Vue d'ensemble complète
- **RESEND_INTEGRATION.md** : Documentation technique détaillée
- **DEPLOYMENT_RESEND.md** : Guide de déploiement pas à pas

---

## ✅ Checklist

- [ ] Fichiers restructurés (Option A, B ou C ci-dessus)
- [ ] Supabase CLI installé
- [ ] Connecté à Supabase (`supabase login`)
- [ ] Projet lié (`supabase link`)
- [ ] Secret configuré (`RESEND_API_KEY`)
- [ ] Migration appliquée (`supabase db push`)
- [ ] Edge Function déployée (`supabase functions deploy`)
- [ ] Webhook configuré dans Dashboard
- [ ] Test effectué depuis l'app
- [ ] Email reçu à `support@storeimmo.com`

---

## 🆘 Problème ?

1. Consultez `DEPLOYMENT_RESEND.md` → Section "Dépannage"
2. Vérifiez les logs : `supabase functions logs send-support-email`
3. Vérifiez le webhook : Dashboard → Database → Webhooks → Recent Deliveries
4. Vérifiez Resend : https://resend.com/emails

---

**Durée estimée** : 10 minutes (restructuration + déploiement + test)

**Prêt ?** Commencez par l'ÉTAPE 0 ci-dessus ! 🚀
