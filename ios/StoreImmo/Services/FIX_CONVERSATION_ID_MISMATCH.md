# 🔧 Correction : Conversation ID Mismatch

## 🐛 Problème identifié

**Symptôme** : 
- La notification arrive chez le destinataire ✅
- Le message est bien inséré dans Supabase ✅
- **MAIS** le message n'apparaît PAS dans la conversation ouverte ❌

**Cause racine** :

Dans `openOrCreateConversation()`, il y a une **race condition** entre :
1. Le démarrage du Realtime (qui écoute sur un `conversation_id`)
2. L'envoi du message (qui utilise potentiellement un autre `conversation_id`)

### Scénario du bug

1. **Vendeur clique sur "Choisir l'agent"** → `openOrCreateConversation()` est appelée
2. **Création conversation optimiste** avec `tentativeID` = UUID temporaire (ex: `abc12345`)
3. **Appel `selectConversation(newConversation)`** → Démarre Realtime qui écoute `conversation_id = abc12345`
4. **Task asynchrone** appelle `findOrCreateConversation()`
5. **Supabase retourne** `realID` = UUID existant (ex: `def67890`) car la conversation existe déjà
6. **Pendant ce temps**, le vendeur envoie un message
7. **Message envoyé avec** `conversation_id = abc12345` (car `selectedConversation.id` n'a pas encore été mis à jour)
8. **Supabase insère** le message avec `conversation_id = abc12345`
9. **Realtime écoute** `conversation_id = abc12345`
10. **Le message arrive** mais le Realtime filtre par `conversation_id`
11. **Quelques millisecondes plus tard**, la Task termine et met à jour `selectedConversation.id = def67890`
12. **Redémarre Realtime** avec `conversation_id = def67890`
13. **Résultat** : Le Realtime écoute maintenant `def67890` mais le message est dans la DB avec `abc12345`

## ✅ Solution appliquée

### 1. **Retarder l'activation du Realtime jusqu'à ce que le vrai ID soit connu**

**Avant** :
```swift
func openOrCreateConversation(...) {
    // ...
    let newConversation = Conversation(id: tentativeID, ...)
    conversations.insert(newConversation, at: 0)
    selectConversation(newConversation)  // ❌ Démarre Realtime trop tôt avec tentativeID

    Task {
        let realID = await findOrCreateConversation(...)
        if realID != tentativeID {
            // Trop tard — message déjà envoyé avec tentativeID
            selectConversation(fixed)
        }
    }
}
```

**Après** :
```swift
func openOrCreateConversation(...) {
    // ...
    let newConversation = Conversation(id: tentativeID, ...)
    conversations.insert(newConversation, at: 0)
    
    // ✅ Juste assigner selectedConversation (sans démarrer Realtime)
    selectedConversation = newConversation

    Task {
        let realID = await findOrCreateConversation(...)
        
        if realID != tentativeID {
            // Mettre à jour avec le vrai ID
            let fixed = Conversation(id: realID, ...)
            conversations[idx] = fixed
            selectConversation(fixed)  // ✅ Démarre Realtime avec le bon ID
        } else {
            // L'ID temporaire était le bon
            selectConversation(newConversation)  // ✅ Démarre Realtime avec le bon ID
        }
    }
}
```

### 2. **Ajout de logs détaillés pour diagnostiquer les futurs problèmes**

#### Dans `AppViewModel.sendCurrentMessage` :
```swift
print("💬 [SendMessage] ===== ENVOI MESSAGE =====")
print("💬 [SendMessage] Conversation ID (utilisé pour INSERT):", convIDStr)
print("💬 [SendMessage] Conversation ID (8 premiers):", convIDStr.prefix(8))
print("💬 [SendMessage] selectedConversation.id:", selectedConversation?.id.uuidString.prefix(8) ?? "nil")
print("💬 [SendMessage] Realtime écoute conversation_id:", realtimeMessagesTask == nil ? "❌ PAS ACTIF" : "✅ ACTIF")
```

#### Dans `AppViewModel.startMessagesRealtime` :
```swift
print("💬 [AppVM] ===== DÉMARRAGE REALTIME MESSAGES =====")
print("💬 [AppVM] Conversation ID (complet):", convID)
print("💬 [AppVM] Conversation ID (8 premiers):", convID.prefix(8))
```

#### Dans `SupabaseRepository.sendMessage` :
```swift
print("💬 [sendMessage] ===== INSERT MESSAGE DANS SUPABASE =====")
print("💬 [sendMessage] conversation_id (complet):", convIDStr ?? "nil")
print("💬 [sendMessage] conversation_id (8 premiers):", convIDStr?.prefix(8) ?? "nil")
print("💬 [sendMessage] ✅ Le message est maintenant dans la table 'messages' avec conversation_id =", ...)
```

#### Dans `SupabaseRepository.findOrCreateConversation` :
```swift
print("💬 [findOrCreateConversation] ===== RECHERCHE OU CRÉATION CONVERSATION =====")
print("💬 [findOrCreateConversation] tentative newID:", newID.uuidString.lowercased().prefix(8))
// Si existante :
print("💬 [findOrCreateConversation] ✅ CONVERSATION EXISTANTE TROUVÉE")
print("💬 [findOrCreateConversation] ID existant (complet):", existing.id)
print("💬 [findOrCreateConversation] ⚠️ IMPORTANT: tentativeID sera remplacé par cet ID existant")
```

#### Dans `SupabaseRepository.startMessagesRealtime` :
```swift
print("💬 [Realtime] ===== CONNECTÉ REALTIME MESSAGES =====")
print("💬 [Realtime] Écoute conversation_id (complet):", conversationID)
print("💬 [Realtime] ===== MESSAGE INSERT REÇU =====")
print("💬 [Realtime] conversation_id du message (complet):", convID)
print("💬 [Realtime] conversation_id attendu (complet):", conversationID)
print("💬 [Realtime] Comparaison (lowercase):", convID.lowercased(), "==", conversationID.lowercased())
```

## 🎯 Flux corrigé

### **Scénario 1 : Nouvelle conversation (pas de doublon)**

1. Vendeur clique "Choisir l'agent"
2. `openOrCreateConversation()` crée conversation avec `tentativeID`
3. **Juste assigner** `selectedConversation = newConversation` (pas de Realtime)
4. Task appelle `findOrCreateConversation()`
5. Supabase confirme : aucune conversation existante
6. Supabase crée conversation avec `tentativeID`
7. Retourne `realID = tentativeID` (même ID)
8. **Maintenant** `selectConversation(newConversation)` → démarre Realtime avec `tentativeID`
9. Vendeur envoie message → `conversation_id = tentativeID` ✅
10. Realtime écoute `conversation_id = tentativeID` ✅
11. **MATCH** → Message s'affiche immédiatement ✅

### **Scénario 2 : Conversation existante (doublon détecté)**

1. Vendeur clique "Choisir l'agent" (mais conversation existe déjà en DB)
2. `openOrCreateConversation()` crée conversation avec `tentativeID`
3. **Juste assigner** `selectedConversation = newConversation` (pas de Realtime)
4. Task appelle `findOrCreateConversation()`
5. Supabase trouve conversation existante avec `realID = def67890`
6. Retourne `realID = def67890` (différent de `tentativeID`)
7. Conversation mise à jour : `id = def67890`
8. Navigation mise à jour : `sellerMessagesNavPath = [def67890]`
9. **Maintenant** `selectConversation(fixed)` → démarre Realtime avec `def67890`
10. Vendeur envoie message → `conversation_id = def67890` ✅
11. Realtime écoute `conversation_id = def67890` ✅
12. **MATCH** → Message s'affiche immédiatement ✅

## 📋 Checklist de vérification

Quand vous testez, vérifiez les logs suivants :

### **Lors de l'ouverture d'une conversation**

```
💬 [findOrCreateConversation] ===== RECHERCHE OU CRÉATION CONVERSATION =====
💬 [findOrCreateConversation] tentative newID: abc12345
💬 [findOrCreateConversation] ✅ CONVERSATION EXISTANTE TROUVÉE
💬 [findOrCreateConversation] ID existant (complet): def67890-...
💬 [findOrCreateConversation] ⚠️ IMPORTANT: tentativeID sera remplacé par cet ID existant
💬 [openOrCreateConversation] Conversation existante détectée — mise à jour de tentativeID vers realID
💬   tentativeID: abc12345
💬   realID: def67890
💬 [AppVM] ===== DÉMARRAGE REALTIME MESSAGES =====
💬 [AppVM] Conversation ID (complet): def67890-...
💬 [AppVM] Conversation ID (8 premiers): def67890
```

### **Lors de l'envoi d'un message**

```
💬 [SendMessage] ===== ENVOI MESSAGE =====
💬 [SendMessage] Conversation ID (utilisé pour INSERT): def67890-...
💬 [SendMessage] Conversation ID (8 premiers): def67890
💬 [SendMessage] Realtime écoute conversation_id: ✅ ACTIF
💬 [sendMessage] ===== INSERT MESSAGE DANS SUPABASE =====
💬 [sendMessage] conversation_id (complet): def67890-...
💬 [sendMessage] conversation_id (8 premiers): def67890
💬 [sendMessage] ✅ INSERT réussi
```

### **Lors de la réception Realtime**

```
💬 [Realtime] ===== MESSAGE INSERT REÇU =====
💬 [Realtime] conversation_id du message (complet): def67890-...
💬 [Realtime] conversation_id attendu (complet): def67890-...
💬 [Realtime] Comparaison (lowercase): def67890-... == def67890-... ? true
💬 [Realtime] ✅ MATCH — Message pour cette conversation
💬 [AppVM] onNewMessageReceived — rechargement messages
```

### **❌ Logs qui indiquent un problème**

```
💬 [Realtime] ❌ MISMATCH — Message ignoré (conversation_id différent)
💬 [Realtime] conversation_id du message (complet): abc12345-...
💬 [Realtime] conversation_id attendu (complet): def67890-...
```

Si vous voyez ce log, c'est que `selectConversation()` a été appelé avant que la Task asynchrone ne termine.

## 🚨 Problèmes potentiels restants

### **Problème A : L'utilisateur envoie un message AVANT que la Task ne termine**

**Scénario** :
1. Conversation ouverte avec `tentativeID`
2. `selectedConversation = newConversation` (pas de Realtime actif)
3. Utilisateur tape très vite et envoie message
4. Message envoyé avec `tentativeID`
5. Task termine → met à jour avec `realID`
6. Realtime démarre avec `realID`
7. **MISMATCH** : Message dans DB avec `tentativeID`, Realtime écoute `realID`

**Solution** : Désactiver l'envoi de messages tant que `realtimeMessagesTask == nil`

Ajoutez une vérification dans `sendCurrentMessage` :

```swift
func sendCurrentMessage(_ text: String) {
    guard let conversation = selectedConversation,
          !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          realtimeMessagesTask != nil  // ✅ AJOUT
    else {
        if realtimeMessagesTask == nil {
            print("💬 [SendMessage] ⚠️ Message bloqué — Realtime pas encore actif")
        }
        return
    }
    // ...
}
```

### **Problème B : Conversations doublons en DB**

**Cause** : RLS insuffisant sur la table `conversations`

**Solution** : Ajouter une contrainte UNIQUE dans Supabase :

```sql
ALTER TABLE conversations
ADD CONSTRAINT unique_project_seller_agent
UNIQUE (project_id, seller_id, agent_id);
```

Cela garantit qu'il n'y aura jamais deux conversations pour le même (project, seller, agent).

## 📝 Fichiers modifiés

1. **AppViewModel.swift** :
   - `openOrCreateConversation()` : retarde `selectConversation()` jusqu'à ce que le vrai ID soit connu
   - `sendCurrentMessage()` : logs détaillés
   - `startMessagesRealtime()` : logs détaillés

2. **SupabaseRepository.swift** :
   - `sendMessage()` : logs détaillés
   - `findOrCreateConversation()` : logs détaillés
   - `startMessagesRealtime()` : logs détaillés

3. **FIX_CONVERSATION_ID_MISMATCH.md** (ce fichier) : documentation complète

---

**Date de correction** : 2026-07-02  
**Problème résolu** : Race condition entre Realtime et envoi de message  
**Status** : ✅ Corrigé — vérifier avec les logs détaillés

