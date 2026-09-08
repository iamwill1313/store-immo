# 🚀 Commandes de déploiement - Intégration Resend

## Prérequis

Assurez-vous d'avoir Supabase CLI installé :
```bash
# macOS
brew install supabase/tap/supabase

# OU via npm
npm install -g supabase
```

---

## 1️⃣ Connexion et configuration

```bash
# Se connecter à Supabase (si pas déjà fait)
supabase login

# Lier le projet (remplacez par votre vrai project ref)
supabase link --project-ref VOTRE_PROJECT_REF

# Vérifier la connexion
supabase projects list
```

---

## 2️⃣ Vérifier/Configurer le secret RESEND_API_KEY

```bash
# Lister les secrets existants
supabase secrets list

# Si RESEND_API_KEY n'existe pas, la créer :
# (Remplacez re_xxxxx par votre vraie clé Resend)
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Vérifier que le secret a été créé
supabase secrets list
```

**⚠️ Important** : Ne jamais committer la clé API dans Git !

---

## 3️⃣ Appliquer la migration SQL

```bash
# Option A : Avec Supabase CLI (recommandé)
supabase db push

# Option B : Manuellement dans le Dashboard
# 1. Allez sur https://app.supabase.com
# 2. Sélectionnez votre projet
# 3. Database → SQL Editor
# 4. Copiez-collez le contenu de :
#    supabase/migrations/20260907_support_email_webhook.sql
# 5. Cliquez sur "Run"
```

**Cette migration crée** :
- Fonction `notify_support_ticket_created()` (logging)
- Trigger `on_support_ticket_created` sur `support_tickets`

---

## 4️⃣ Déployer l'Edge Function

```bash
# Déployer la fonction send-support-email
supabase functions deploy send-support-email

# Attendre que le déploiement soit terminé (quelques secondes)
# Vous devriez voir :
# ✓ Deployed Function send-support-email

# Vérifier que la fonction est bien déployée
supabase functions list

# Vous devriez voir :
# send-support-email | deployed | [version] | [date]
```

---

## 5️⃣ Configurer le Webhook (MANUEL - Dashboard Supabase)

⚠️ **Cette étape DOIT être faite manuellement dans le Dashboard Supabase.**

### Étapes :

1. Allez sur : https://app.supabase.com
2. Sélectionnez votre projet Store Immo
3. Menu latéral : **Database** → **Webhooks**
4. Cliquez sur **Create a new hook** ou **Enable Webhooks**

### Configuration :

| Champ | Valeur |
|-------|--------|
| Name | `Send Support Email` |
| Table | `support_tickets` |
| Events | ✅ INSERT (uniquement) |
| Type | HTTP Request |
| Method | POST |
| URL | `https://[PROJECT_REF].supabase.co/functions/v1/send-support-email` |

**Remplacez `[PROJECT_REF]`** par votre vrai project reference (ex: `abcdefgh`)

### HTTP Headers :

Ajoutez ces 2 headers (cliquez sur "Add header" pour chaque) :

```
Authorization: Bearer [VOTRE_ANON_KEY]
Content-Type: application/json
```

**Comment trouver votre ANON_KEY** :
1. Dans le même Dashboard Supabase
2. Menu latéral : **Settings** → **API**
3. Section "Project API keys"
4. Copiez la valeur de **anon** **public**

### Valider :

Cliquez sur **Create webhook** ou **Save**.

---

## 6️⃣ Tester l'intégration

### Test 1 : Depuis l'app iOS

1. Lancez l'app Store Immo (Xcode : ⌘+R)
2. Connectez-vous avec un compte test
3. Allez dans : **Compte** → **Aide et support** → **Signaler un problème**
4. Remplissez le formulaire :
   - Catégorie : "Problème technique"
   - Description : "Test d'intégration Resend"
5. Cliquez sur **Envoyer**
6. Vérifiez que le message de succès s'affiche

### Test 2 : Vérifier les logs de l'Edge Function

```bash
# Voir les logs en temps réel
supabase functions logs send-support-email --follow

# Logs attendus (dans l'ordre) :
# ✅ Nouveau ticket reçu: [UUID]
# 📧 Envoi de l'email via Resend...
# ✅ Email envoyé avec succès: { id: "..." }
```

### Test 3 : Vérifier la réception de l'email

1. Ouvrez la boîte email : `support@storeimmo.com`
2. Cherchez un email avec le sujet : `Nouveau ticket support #XXXX - Problème technique`
3. Vérifiez que l'email contient :
   - Les informations du ticket
   - Le message de l'utilisateur
   - Les métadonnées (version, date, etc.)

### Test 4 : Vérifier dans Resend Dashboard

1. Allez sur : https://resend.com/emails
2. Vous devriez voir l'email envoyé récemment
3. Statut devrait être : **Delivered**

---

## 7️⃣ Vérifications finales

```bash
# 1. Vérifier que le trigger existe
# Allez dans Dashboard → Database → Tables → support_tickets → Triggers
# Vous devriez voir : on_support_ticket_created

# 2. Vérifier que la fonction trigger existe
# Dashboard → Database → Functions
# Vous devriez voir : notify_support_ticket_created

# 3. Vérifier que le webhook est actif
# Dashboard → Database → Webhooks
# Vous devriez voir : Send Support Email (avec un toggle vert)

# 4. Voir les logs du webhook (après un test)
# Dashboard → Database → Webhooks → Send Support Email → Recent Deliveries
# Vous devriez voir les tentatives d'envoi avec leur statut
```

---

## 🐛 Dépannage

### Problème : "Function not found"

```bash
# Redéployer la fonction
supabase functions deploy send-support-email --no-verify-jwt
```

### Problème : "RESEND_API_KEY not found"

```bash
# Reconfigurer le secret
supabase secrets set RESEND_API_KEY=re_xxxxx

# Redéployer (nécessaire après changement de secret)
supabase functions deploy send-support-email
```

### Problème : Webhook ne se déclenche pas

1. Vérifiez que le webhook est activé (toggle vert)
2. Vérifiez l'URL du webhook (doit contenir le bon project ref)
3. Vérifiez les headers (Authorization doit contenir la anon key)
4. Consultez : Dashboard → Database → Webhooks → Recent Deliveries

### Problème : Email non reçu (mais logs OK)

1. Vérifiez les spams de `support@storeimmo.com`
2. Vérifiez dans Resend Dashboard → Emails que l'email a été envoyé
3. Vérifiez que le domaine `storeimmo.com` est vérifié dans Resend :
   - Allez sur : https://resend.com/domains
   - Le domaine doit avoir un badge vert "Verified"

### Problème : "Error calling function"

Le webhook ne peut pas joindre l'Edge Function. Causes possibles :
- URL du webhook incorrecte (vérifiez le project ref)
- Authorization header manquant ou invalide
- La fonction n'est pas déployée

```bash
# Vérifier que la fonction existe
supabase functions list

# Si elle n'existe pas, la redéployer
supabase functions deploy send-support-email
```

---

## 📊 Monitoring continu

### Logs en temps réel

```bash
# Suivre les logs de l'Edge Function
supabase functions logs send-support-email --follow

# Filtrer uniquement les erreurs
supabase functions logs send-support-email --follow | grep "❌"

# Afficher les 50 dernières lignes
supabase functions logs send-support-email --tail 50
```

### Dashboard Supabase

- **Edge Function Logs** : Functions → send-support-email → Logs
- **Webhook Deliveries** : Database → Webhooks → Send Support Email → Recent Deliveries
- **Database Logs** : Database → Logs → Postgres Logs (pour le trigger)

### Resend Dashboard

- **Emails envoyés** : https://resend.com/emails
- **Analytics** : https://resend.com/analytics
- **API Logs** : https://resend.com/logs

---

## 🔒 Sécurité - Checklist

Avant de déployer en production, vérifiez :

- [ ] `RESEND_API_KEY` est dans les secrets Supabase (pas dans Git)
- [ ] Aucune clé secrète dans le code Swift
- [ ] Le fichier `.env` n'est pas commité (si vous en avez un)
- [ ] Le domaine `storeimmo.com` est vérifié dans Resend
- [ ] Le webhook utilise la `anon key` (publique, rate-limitée)
- [ ] RLS est activé sur `support_tickets`
- [ ] Le trigger utilise `security definer` pour éviter les problèmes de permissions

---

## ✅ Checklist finale de déploiement

Cochez chaque étape au fur et à mesure :

- [ ] Supabase CLI installé
- [ ] Connecté à Supabase (`supabase login`)
- [ ] Projet lié (`supabase link`)
- [ ] Secret `RESEND_API_KEY` configuré
- [ ] Migration SQL appliquée (`supabase db push`)
- [ ] Edge Function déployée (`supabase functions deploy`)
- [ ] Webhook créé dans Dashboard
- [ ] Webhook configuré avec la bonne URL
- [ ] Webhook configuré avec les headers
- [ ] Test : Ticket créé depuis l'app iOS
- [ ] Test : Logs Edge Function OK
- [ ] Test : Email reçu à `support@storeimmo.com`
- [ ] Test : Reply-To fonctionne
- [ ] Vérifié dans Resend Dashboard

---

## 🎯 Résumé des commandes

```bash
# 1. Se connecter et lier le projet
supabase login
supabase link --project-ref VOTRE_PROJECT_REF

# 2. Configurer le secret (si nécessaire)
supabase secrets set RESEND_API_KEY=re_xxxxx

# 3. Appliquer la migration
supabase db push

# 4. Déployer l'Edge Function
supabase functions deploy send-support-email

# 5. Vérifier le déploiement
supabase functions list
supabase secrets list

# 6. Suivre les logs (après test)
supabase functions logs send-support-email --follow
```

**Note** : L'étape 5 (configuration du webhook) doit être faite manuellement dans le Dashboard.

---

**Déploiement terminé !** 🎉

L'intégration Resend est maintenant active. Chaque nouveau ticket créé dans `support_tickets` déclenchera automatiquement l'envoi d'un email à `support@storeimmo.com`.
