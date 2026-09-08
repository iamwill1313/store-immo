# 📧 Intégration Resend - Envoi automatique d'emails pour les tickets support

## 🎯 Objectif

Lorsqu'un utilisateur crée un nouveau ticket dans `support_tickets`, un email est automatiquement envoyé à l'équipe Store Immo via Resend.

---

## 📁 Fichiers créés

### 1. Edge Function
- **Fichier**: `supabase/functions/send-support-email/index.ts`
- **Rôle**: Reçoit les données du ticket et envoie un email via l'API Resend
- **Déclenchement**: Via webhook Supabase lors d'un INSERT dans `support_tickets`

### 2. Migration SQL
- **Fichier**: `supabase/migrations/20260907_support_email_webhook.sql`
- **Rôle**: Crée un trigger de logging et documente la configuration du webhook

### 3. Documentation
- **Fichier**: `RESEND_INTEGRATION.md` (ce fichier)

---

## 🔧 Architecture

```
┌─────────────────────┐
│  ReportProblemView  │
│  (App iOS)           │
└──────────┬──────────┘
           │ submitTicket()
           ▼
┌─────────────────────┐
│   AppViewModel      │
│ submitSupportTicket()│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ SupabaseRepository  │
│  saveSupportTicket()│
└──────────┬──────────┘
           │ INSERT INTO support_tickets
           ▼
┌─────────────────────────────┐
│   PostgreSQL Database       │
│   Table: support_tickets    │
└──────────┬──────────────────┘
           │ AFTER INSERT TRIGGER
           │ (log uniquement)
           ▼
┌─────────────────────────────┐
│   Supabase Webhook          │ ← Configuré dans Dashboard
│   (Database → Webhooks)     │
└──────────┬──────────────────┘
           │ POST automatique
           ▼
┌─────────────────────────────┐
│   Edge Function             │
│   send-support-email        │
│   - Récupère email user     │
│   - Formate email HTML      │
│   - Appelle API Resend      │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│   API Resend                │
│   POST /emails              │
│   - From: support@...       │
│   - To: support@...         │
│   - Reply-To: user email    │
└─────────────────────────────┘
```

---

## 🚀 Déploiement

### Étape 1 : Appliquer la migration SQL

```bash
# Si vous utilisez Supabase CLI
supabase db push

# OU exécutez manuellement dans le SQL Editor de Supabase Dashboard
# Le contenu de: supabase/migrations/20260907_support_email_webhook.sql
```

Cette migration crée un trigger de logging qui s'exécute après chaque INSERT dans `support_tickets`.

---

### Étape 2 : Déployer l'Edge Function

```bash
# Vérifier que vous êtes connecté à votre projet Supabase
supabase login

# Lier votre projet (si ce n'est pas déjà fait)
supabase link --project-ref [VOTRE_PROJECT_REF]

# Déployer l'Edge Function
supabase functions deploy send-support-email

# Vérifier que la fonction est bien déployée
supabase functions list
```

---

### Étape 3 : Vérifier les secrets Supabase

La clé API Resend doit être configurée comme secret. Vous m'avez indiqué qu'elle existe déjà, mais pour vérifier :

```bash
# Lister les secrets
supabase secrets list

# Si RESEND_API_KEY n'existe pas, la créer :
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxxx
```

**Important** : Ne jamais committer cette clé dans Git !

---

### Étape 4 : Configurer le Webhook Supabase (CRUCIAL)

⚠️ **Cette étape est OBLIGATOIRE et doit être faite manuellement dans le Dashboard Supabase.**

1. Allez sur : [https://app.supabase.com](https://app.supabase.com)
2. Sélectionnez votre projet Store Immo
3. Dans le menu latéral : **Database** → **Webhooks**
4. Cliquez sur **Create a new hook** ou **Enable Webhooks**
5. Remplissez les champs :

#### Configuration du Webhook

| Champ | Valeur |
|-------|--------|
| **Name** | `Send Support Email` |
| **Table** | `support_tickets` |
| **Events** | Cochez uniquement `INSERT` |
| **Type** | `HTTP Request` |
| **Method** | `POST` |
| **URL** | `https://[VOTRE_PROJECT_REF].supabase.co/functions/v1/send-support-email` |

**HTTP Headers** (cliquez sur "Add header" pour chaque ligne) :

```
Authorization: Bearer [VOTRE_ANON_KEY]
Content-Type: application/json
```

**Note** : Remplacez `[VOTRE_PROJECT_REF]` par votre vrai project ref (exemple: `abcdefghijklm`)

**Note** : La `ANON_KEY` se trouve dans **Settings** → **API** → **Project API keys** → **anon public**

6. Cliquez sur **Create webhook** ou **Save**

---

### Étape 5 : Tester l'intégration

#### Test 1 : Créer un ticket depuis l'app iOS

1. Lancez l'app Store Immo
2. Allez dans **Compte** → **Aide et support** → **Signaler un problème**
3. Remplissez le formulaire et envoyez
4. Vérifiez que :
   - ✅ Le ticket apparaît dans "Mes demandes"
   - ✅ Un email arrive à `support@storeimmo.com`

#### Test 2 : Vérifier les logs de l'Edge Function

```bash
# Voir les logs en temps réel
supabase functions logs send-support-email --follow

# Ou dans le Dashboard : Functions → send-support-email → Logs
```

Logs attendus :
```
✅ Nouveau ticket reçu: [UUID]
📧 Envoi de l'email via Resend...
✅ Email envoyé avec succès: { id: "..." }
```

#### Test 3 : Vérifier dans Resend Dashboard

1. Allez sur [https://resend.com](https://resend.com)
2. Dans **Emails** → **Logs**
3. Vous devriez voir l'email envoyé avec :
   - From: `Store Immo Support <support@storeimmo.com>`
   - To: `support@storeimmo.com`
   - Subject: `Nouveau ticket support #XXXX - [Catégorie]`

---

## 🔒 Sécurité

### ✅ Points sécurisés

1. **Clé API Resend** : Stockée uniquement dans les secrets Supabase, jamais dans le code Swift ou Git
2. **Accès à l'Edge Function** : Requiert une clé d'authentification Supabase (anon key via webhook)
3. **RLS** : La table `support_tickets` a déjà RLS activé, seul l'utilisateur voit ses propres tickets
4. **Logs** : Aucune clé secrète n'est loggée
5. **Isolation** : L'échec de l'envoi d'email n'empêche pas la création du ticket

### ⚠️ Points d'attention

1. **ANON_KEY publique** : C'est normal, elle est censée être publique mais rate-limitée
2. **Pas d'authentification sur l'Edge Function** : Le webhook Supabase est déjà authentifié
3. **Email utilisateur** : Récupéré via `SUPABASE_SERVICE_ROLE_KEY` (automatiquement disponible dans les Edge Functions)

---

## 📧 Format de l'email

### Sujet
```
Nouveau ticket support #[8_PREMIERS_CHARS] - [Catégorie]
```

Exemple : `Nouveau ticket support #A3B5C7D9 - Problème technique`

### Contenu (HTML)

L'email contient :
- **En-tête** : Design gradient violet avec titre "Nouveau Ticket Support"
- **ID du ticket** : Badge affiché en haut
- **Section Utilisateur** : Nom complet, rôle (Vendeur/Agent), email cliquable
- **Section Catégorie** : Catégorie du problème
- **Section Sujet** : Sujet du ticket
- **Section Message** : Le message complet de l'utilisateur (avec formatage)
- **Métadonnées** :
  - Statut (badge coloré)
  - Date de création
  - Version de l'app
  - ID complet du ticket
- **Footer** : "Store Immo Support System"

### Reply-To

Si l'email de l'utilisateur est disponible, le champ `reply-to` est automatiquement configuré. Cela permet à l'équipe support de répondre directement à l'utilisateur en cliquant sur "Répondre".

---

## 🐛 Dépannage

### Problème : Le ticket est créé mais aucun email n'est envoyé

**Causes possibles** :

1. **Webhook non configuré**
   - Solution : Vérifier dans Database → Webhooks que le webhook existe et est actif

2. **Edge Function pas déployée**
   - Solution : `supabase functions deploy send-support-email`

3. **URL du webhook incorrecte**
   - Solution : Vérifier que l'URL contient le bon project ref

4. **RESEND_API_KEY manquante**
   - Solution : `supabase secrets set RESEND_API_KEY=re_xxxxx`

5. **Domaine Resend non vérifié**
   - Solution : Dans Resend Dashboard, vérifier le domaine `storeimmo.com`

### Problème : Logs d'erreur "Configuration manquante"

```bash
# Vérifier que le secret existe
supabase secrets list

# Reconfigurer si nécessaire
supabase secrets set RESEND_API_KEY=re_xxxxx

# Redéployer la fonction
supabase functions deploy send-support-email
```

### Problème : Email non reçu (mais logs OK)

1. Vérifier les spams dans `support@storeimmo.com`
2. Vérifier dans Resend Dashboard → Emails → Logs le statut de l'email
3. Vérifier que le domaine `storeimmo.com` est vérifié dans Resend

### Problème : "Error calling function: FunctionsHttpError"

- Le webhook utilise probablement la mauvaise URL ou la mauvaise clé
- Vérifier que vous utilisez la `anon key` et non la `service_role_key` dans le header du webhook

---

## 📊 Monitoring

### Logs à surveiller

1. **Logs de l'Edge Function** :
   ```bash
   supabase functions logs send-support-email --follow
   ```

2. **Logs PostgreSQL** (trigger) :
   Dans Dashboard → Database → Logs → Postgres Logs
   Chercher : "Nouveau ticket support créé"

3. **Webhook Logs** :
   Dans Dashboard → Database → Webhooks → [Votre webhook] → Recent Deliveries

4. **Resend Dashboard** :
   [https://resend.com/emails](https://resend.com/emails)

---

## 🔄 Flux complet réussi

Voici ce qui se passe quand tout fonctionne correctement :

1. **T+0ms** : Utilisateur envoie le formulaire dans l'app iOS
2. **T+100ms** : `SupabaseRepository.saveSupportTicket()` exécute INSERT
3. **T+150ms** : PostgreSQL trigger `on_support_ticket_created` log l'événement
4. **T+200ms** : Webhook Supabase détecte l'INSERT et POST vers l'Edge Function
5. **T+300ms** : Edge Function reçoit le payload
6. **T+400ms** : Edge Function récupère l'email utilisateur depuis `sellers_profiles` ou `agents_profiles`
7. **T+500ms** : Edge Function construit l'email HTML
8. **T+600ms** : Edge Function POST vers API Resend
9. **T+800ms** : Resend confirme l'envoi (retourne un ID)
10. **T+1000ms** : Edge Function retourne succès au webhook
11. **T+2-5s** : Email arrive dans la boîte `support@storeimmo.com`

**Durée totale** : ~1-5 secondes du clic utilisateur à la réception de l'email.

---

## 📝 Maintenance

### Modifier le template d'email

Éditez : `supabase/functions/send-support-email/index.ts`

Puis :
```bash
supabase functions deploy send-support-email
```

### Modifier le destinataire

Dans le fichier `index.ts`, ligne avec `to: ["support@storeimmo.com"]`, remplacez par votre nouvelle adresse.

### Ajouter d'autres destinataires

```typescript
to: ["support@storeimmo.com", "admin@storeimmo.com"],
```

### Désactiver temporairement l'envoi d'emails

Dans Dashboard Supabase :
- Database → Webhooks → [Votre webhook]
- Toggle "Enabled" à OFF

---

## ✅ Checklist de déploiement

Avant de considérer l'intégration comme complète :

- [ ] Migration SQL appliquée (`20260907_support_email_webhook.sql`)
- [ ] Edge Function déployée (`send-support-email`)
- [ ] Secret `RESEND_API_KEY` configuré
- [ ] Webhook créé dans Dashboard Supabase
- [ ] Webhook configuré avec la bonne URL
- [ ] Webhook configuré avec les bons headers
- [ ] Domaine `storeimmo.com` vérifié dans Resend
- [ ] Test : Ticket créé depuis l'app
- [ ] Test : Email reçu à `support@storeimmo.com`
- [ ] Test : Reply-To fonctionne
- [ ] Logs de l'Edge Function vérifiés
- [ ] Logs Resend vérifiés

---

## 🎯 Résumé

**Fichiers créés** : 3
1. `supabase/functions/send-support-email/index.ts` (Edge Function)
2. `supabase/migrations/20260907_support_email_webhook.sql` (Migration SQL)
3. `RESEND_INTEGRATION.md` (Documentation)

**Fichiers modifiés** : 0 (aucune modification du code Swift ou des repositories existants)

**Fonctionnement** :
- INSERT dans `support_tickets` → Trigger PostgreSQL → Webhook Supabase → Edge Function → API Resend → Email envoyé

**Sécurité** :
- ✅ Aucune clé secrète dans le code Swift
- ✅ `RESEND_API_KEY` uniquement dans les secrets Supabase
- ✅ Échec d'envoi n'empêche pas la création du ticket
- ✅ RLS respecté sur `support_tickets`

**Actions requises** :
1. Déployer l'Edge Function : `supabase functions deploy send-support-email`
2. Appliquer la migration SQL : `supabase db push`
3. Configurer le webhook dans le Dashboard Supabase (manuel)
4. Tester en créant un ticket depuis l'app

---

**Status** : ✅ PRÊT POUR DÉPLOIEMENT

L'intégration est complète et prête à être déployée. Aucune modification du code Swift n'est nécessaire.
