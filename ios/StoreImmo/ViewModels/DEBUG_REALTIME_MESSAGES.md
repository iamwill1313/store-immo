# 🐛 Debug Realtime Notifications Messages

## Problème identifié

**Symptôme** : Quand un agent envoie un message, le vendeur ne voit pas la bannière en temps réel, mais le message apparaît après redémarrage.

**Diagnostic** : L'insertion Supabase fonctionne, mais soit le Realtime ne reçoit pas l'événement, soit la bannière n'est pas affichée.

---

## ✅ Corrections apportées

### 1. **Logs complets ajoutés** dans tout le flux

#### **Côté envoi (agent envoie message)** :
- ✅ Log du `recipientID` (user_id du vendeur)
- ✅ Log de la création de notification
- ✅ Log du résultat d'insertion

#### **Côté Realtime (SupabaseRepository)** :
- ✅ Log de connexion au channel
- ✅ Log de chaque INSERT reçu
- ✅ Log de comparaison user_id
- ✅ Log si notification ignorée ou acceptée

#### **Côté réception (AppViewModel)** :
- ✅ Log dans `onNewNotificationReceived()`
- ✅ Log du nombre de notifications avant/après rechargement
- ✅ Log de détection de nouvelle notification
- ✅ Log si bannière affichée ou ignorée
- ✅ Log de la raison si ignorée

### 2. **Logique intelligente de bannière**

```swift
// Ne pas afficher si l'utilisateur est DANS la conversation
if newNotif.type == "new_message",
   let convID = newNotif.relatedConversationId,
   let selectedConv = selectedConversation,
   convID == selectedConv.id {
    print("🔔 [AppVM] ❌ Bannière ignorée (utilisateur dans la conversation)")
    return
}
```

---

## 🔍 Points de vérification

### **Test 1 : Vérifier que l'abonnement Realtime est actif**

**Log attendu côté vendeur** :
```
🔔 [startNotificationsRealtime] Démarrage abonnement pour user: <UUID_VENDEUR>
🔔 [Realtime] Connecté notifications pour user: <UUID_VENDEUR>
```

✅ Si ces logs apparaissent → Abonnement OK  
❌ Si absents → Problème de démarrage

---

### **Test 2 : Vérifier que la notification est créée**

**Log attendu côté agent (qui envoie)** :
```
💬 [SendMessage] Conversation ID: <UUID_CONV>
💬 [SendMessage] Sender role: agent
💬 [SendMessage] Recipient user_id: <UUID_VENDEUR>
💬 [SendMessage] Création notification pour user: <UUID_VENDEUR>
💬 [SendMessage] Type: new_message
💬 [SendMessage] relatedConversationId: <UUID_CONV>
🔔 [createNotificationForUser] Insertion notification:
🔔   - id: <UUID_NOTIF>
🔔   - user_id: <UUID_VENDEUR>
🔔   - type: new_message
🔔   - title: Nouveau message
🔔   - related_conversation_id: <UUID_CONV>
🔔 [createNotificationForUser] Résultat insertion: ✅
💬 [SendMessage] Notification créée: ✅
```

✅ Si `Résultat insertion: ✅` → Notification créée  
❌ Si `Résultat insertion: ❌` → Problème RLS Supabase

---

### **Test 3 : Vérifier que le Realtime reçoit l'INSERT**

**Log attendu côté vendeur (après envoi du message)** :
```
🔔 [Realtime] Notification INSERT reçue
🔔 [Realtime] Record: ["user_id": <UUID_VENDEUR>, "type": "new_message", ...]
🔔 [Realtime] ✅ Notification pour cet utilisateur (user_id match)
🔔 [Realtime] Notification user_id: <UUID_VENDEUR>
🔔 [Realtime] Current user: <UUID_VENDEUR>
```

✅ Si `✅ Notification pour cet utilisateur` → Realtime OK  
❌ Si `❌ Notification ignorée (user_id mismatch)` → Problème d'UUID

---

### **Test 4 : Vérifier que la bannière est déclenchée**

**Log attendu côté vendeur** :
```
🔔 [AppVM] onNewNotificationReceived appelé
🔔 [AppVM] Notifications avant rechargement: 5
🔔 [AppVM] Notifications après rechargement: 6
🔔 [AppVM] Nouvelle notification détectée:
🔔 [AppVM]   - ID: <UUID_NOTIF>
🔔 [AppVM]   - Type: new_message
🔔 [AppVM]   - Title: Nouveau message
🔔 [AppVM]   - relatedConversationId: <UUID_CONV>
🔔 [AppVM]   - selectedConversation: nil (ou différent)
🔔 [AppVM] ✅ Affichage bannière
🔔 [showInAppBanner] Affichage bannière:
🔔   - ID: <UUID_NOTIF>
🔔   - Type: new_message
🔔   - Title: Nouveau message
🔔   - Body: Agent : Salut
```

✅ Si `✅ Affichage bannière` → Bannière affichée  
❌ Si `❌ Bannière ignorée (utilisateur dans la conversation)` → Normal si dans la conv  
❌ Si `❌ Aucune nouvelle notification à afficher` → Problème de filtrage

---

## 🔧 Problèmes possibles et solutions

### **Problème A : Aucun log Realtime**
**Symptôme** : Pas de log `🔔 [Realtime] Notification INSERT reçue`  
**Cause possible** :
- Le channel Realtime n'est pas connecté
- La table `notifications` n'a pas Realtime activé dans Supabase

**Solution** :
1. Vérifier dans Supabase Dashboard → Database → Replication
2. Activer Realtime pour la table `notifications`
3. Redémarrer l'app

---

### **Problème B : user_id mismatch**
**Symptôme** : Log `❌ Notification ignorée (user_id mismatch)`  
**Cause possible** :
- Le `recipientID` ne correspond pas au `currentUserID` du vendeur
- Problème de casse (uppercase/lowercase)
- `conversation.sellerId` pointe vers un mauvais ID

**Solution** :
1. Comparer les logs :
   ```
   💬 [SendMessage] Recipient user_id: <UUID_AGENT>
   🔔 [Realtime] Current user: <UUID_VENDEUR>
   ```
2. Vérifier que le vendeur connecté a bien le bon `user_id`
3. Vérifier la table `conversations` :
   ```sql
   SELECT id, seller_id, agent_id FROM conversations WHERE id = '<UUID_CONV>';
   ```
4. S'assurer que `seller_id` = `user_id` du vendeur (pas `sellers_profiles.id`)

---

### **Problème C : Notification filtrée (self-type)**
**Symptôme** : Log `Raison: notification self-type ou déjà vue`  
**Cause possible** :
- Le type `"new_message"` est dans `selfNotificationTypes`

**Solution** :
Vérifier dans `AppViewModel` :
```swift
private let selfNotificationTypes: Set<String> = ["application_sent", "project_published"]
```
✅ `"new_message"` n'est PAS dans cette liste → OK

---

### **Problème D : RLS Supabase bloque l'insertion**
**Symptôme** : Log `🔔 [createNotificationForUser] Résultat insertion: ❌`  
**Cause possible** :
- Row Level Security (RLS) empêche l'agent de créer une notification pour le vendeur

**Solution** :
Créer une politique RLS permissive pour `INSERT` :
```sql
CREATE POLICY "Allow cross-user notification insert"
ON notifications
FOR INSERT
TO authenticated
WITH CHECK (true);
```

**OU** plus restrictif :
```sql
CREATE POLICY "Allow agent to notify seller"
ON notifications
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM conversations
    WHERE (agent_id = auth.uid() AND seller_id = user_id)
       OR (seller_id = auth.uid() AND agent_id = user_id)
  )
);
```

---

## 🎯 Checklist de test

Quand un agent envoie un message au vendeur :

- [ ] **Log 1** : Agent voit `💬 [SendMessage] Recipient user_id: <UUID_VENDEUR>`
- [ ] **Log 2** : Agent voit `🔔 [createNotificationForUser] Résultat insertion: ✅`
- [ ] **Log 3** : Vendeur voit `🔔 [Realtime] Notification INSERT reçue`
- [ ] **Log 4** : Vendeur voit `🔔 [Realtime] ✅ Notification pour cet utilisateur`
- [ ] **Log 5** : Vendeur voit `🔔 [AppVM] Nouvelle notification détectée`
- [ ] **Log 6** : Vendeur voit `🔔 [AppVM] ✅ Affichage bannière`
- [ ] **Log 7** : Vendeur voit `🔔 [showInAppBanner] Affichage bannière`
- [ ] **UI** : La bannière s'affiche en haut de l'écran pendant 4s
- [ ] **Badge** : Le badge Messages s'incrémente
- [ ] **Centre** : La notification apparaît dans le centre de notifications

---

## 📝 Notes importantes

1. **Timing** : La bannière s'affiche IMMÉDIATEMENT sans redémarrage
2. **Exception** : Si le vendeur est DANS la conversation, la bannière ne s'affiche PAS
3. **Auto-masquage** : La bannière disparaît après 4 secondes
4. **Types filtrés** : `application_sent` et `project_published` ne déclenchent jamais de bannière

---

## 🚀 Prochaines étapes

1. **Lancer l'app** sur simulateur (agent) + iPhone (vendeur)
2. **Se connecter** en tant qu'agent sur simulateur
3. **Se connecter** en tant que vendeur sur iPhone
4. **Envoyer un message** depuis l'agent
5. **Observer les logs** dans Xcode Console (filtre : `🔔` ou `💬`)
6. **Vérifier** que les 7 logs de la checklist apparaissent
7. **Confirmer** que la bannière s'affiche côté vendeur

Si un log manque → identifier le problème avec ce guide !
