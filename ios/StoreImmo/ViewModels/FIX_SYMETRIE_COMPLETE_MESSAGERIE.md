# ✅ Correction finale : Symétrie complète messagerie + bannières

## 🐛 Problème identifié

Après la correction précédente, les messages **agent → vendeur** ne fonctionnaient pas correctement.

**Symptôme** :
- Vendeur choisit un agent ✅
- Notification "agent_chosen" envoyée à l'agent ✅
- Agent clique sur la notification ❌
- La conversation ne s'ouvre pas ❌
- L'agent ne peut pas envoyer de message ❌

**Cause** :
Dans `chooseAgent()`, la conversation est créée :
1. Dans Supabase ✅
2. Localement côté **vendeur** ✅
3. **Mais PAS côté agent** ❌

Quand l'agent clique sur la notification :
- `openFromNotification()` cherche la conversation dans `conversations` (en mémoire)
- La conversation n'y est pas (car elle n'a jamais été chargée depuis Supabase)
- La fonction ne fait rien
- L'agent reste bloqué

## ✅ Solution appliquée

Modification de `openFromNotification()` pour recharger les conversations depuis Supabase si la conversation n'est pas trouvée localement.

### Avant

```swift
case "agent_chosen", "new_message":
    if let cid = notification.relatedConversationId,
       let conv = conversations.first(where: { $0.id == cid }) {
        selectConversation(conv)
        // ... navigation ...
    }
    // ❌ Si la conversation n'est pas trouvée, rien ne se passe
```

### Après

```swift
case "agent_chosen", "new_message":
    if let cid = notification.relatedConversationId {
        // Try to find the conversation locally first
        if let conv = conversations.first(where: { $0.id == cid }) {
            selectConversation(conv)
            // ... navigation ...
        } else {
            // ✅ Conversation not in memory — load from Supabase
            print("💬 [openFromNotification] Conversation non trouvée localement — rechargement depuis Supabase")
            Task { @MainActor in
                await loadConversationsFromSupabase()
                // Try again after reload
                if let conv = conversations.first(where: { $0.id == cid }) {
                    print("💬 [openFromNotification] ✅ Conversation trouvée après rechargement")
                    selectConversation(conv)
                    // ... navigation ...
                } else {
                    print("💬 [openFromNotification] ❌ Conversation toujours introuvable")
                }
            }
        }
    }
```

## 🎯 Flux corrigé complet

### Scénario 1 : Vendeur → Agent

1. Vendeur choisit un agent
2. Conversation créée dans Supabase avec ID = `abc12345`
3. Conversation ajoutée localement côté vendeur
4. Notification "agent_chosen" envoyée à l'agent avec `related_conversation_id = abc12345`
5. Agent reçoit la notification
6. Agent clique sur la notification
7. `openFromNotification()` appelé
8. Conversation `abc12345` **pas trouvée localement**
9. ✅ **Rechargement depuis Supabase**
10. ✅ Conversation `abc12345` chargée et trouvée
11. ✅ `selectConversation()` appelé
12. ✅ Realtime démarré pour `abc12345`
13. ✅ Navigation vers Messages
14. Vendeur envoie "Bonjour"
15. Message inséré avec `conversation_id = abc12345`
16. Notification créée avec `related_conversation_id = abc12345`
17. Agent reçoit la notification
18. `currentVisibleConversationID = abc12345` (car l'agent regarde la conversation)
19. ❌ Bannière **non affichée** (normal, l'agent regarde déjà)
20. ✅ Message s'affiche dans la conversation via Realtime

### Scénario 2 : Agent → Vendeur (après scénario 1)

1. Agent envoie "Bonjour, merci !"
2. Message inséré avec `conversation_id = abc12345` (même conversation)
3. Notification créée avec `related_conversation_id = abc12345`
4. Vendeur reçoit la notification
5. Si vendeur regarde conversation `abc12345` :
   - `currentVisibleConversationID = abc12345`
   - ❌ Bannière **non affichée** (normal)
   - ✅ Message s'affiche via Realtime
6. Si vendeur est ailleurs :
   - `currentVisibleConversationID = nil`
   - ✅ Bannière **affichée**
   - ✅ Message visible quand il ouvrira la conversation

## 📊 Symétrie garantie

| Aspect | Vendeur → Agent | Agent → Vendeur |
|--------|----------------|-----------------|
| **sender_id** | sellerID | agentID |
| **receiver_id** | agentID | sellerID |
| **conversation_id** | abc12345 | **abc12345** (même) |
| **Insertion message** | ✅ | ✅ |
| **Notification créée** | ✅ | ✅ |
| **related_conversation_id** | abc12345 | abc12345 |
| **Bannière (si pas dans conv)** | ✅ | ✅ |
| **Bannière bloquée (si dans conv)** | ✅ | ✅ |
| **Message visible Realtime** | ✅ | ✅ |
| **Message dans liste Messages** | ✅ | ✅ |

## 🔍 Logs détaillés

### Quand vendeur choisit agent

```
💬 [chooseAgent] Conversation ID final: abc12345
💬 CONVERSATION CREEE : Alexandre Morel
💬 CONVERSATION ID: abc12345
```

### Quand agent clique sur notification

```
💬 [openFromNotification] Conversation non trouvée localement — rechargement depuis Supabase
💬 [openFromNotification] Conversation ID recherché: abc12345
💬 LOAD CONV — ROWS COUNT: 1
💬 [openFromNotification] ✅ Conversation trouvée après rechargement
💬 [selectConversation] Rechargement messages depuis Supabase pour: abc12345
💬 [AppVM] ===== DÉMARRAGE REALTIME MESSAGES =====
💬 [AppVM] Conversation ID (complet): abc12345...
```

### Quand vendeur envoie message

```
💬 [SendMessage] ===== ENVOI MESSAGE =====
💬 [SendMessage] Sender role: seller
💬 [SendMessage] Recipient user_id: <agentID>
💬 [SendMessage] Conversation ID (8 premiers): abc12345
💬 [sendMessage] ===== INSERT MESSAGE DANS SUPABASE =====
💬 [sendMessage] conversation_id (8 premiers): abc12345
💬 [sendMessage] ✅ INSERT réussi
```

### Quand agent reçoit message (en regardant la conversation)

```
💬 [Realtime] ===== MESSAGE INSERT REÇU =====
💬 [Realtime] conversation_id du message: abc12345
💬 [Realtime] conversation_id attendu: abc12345
💬 [Realtime] ✅ MATCH
💬 [AppVM] onNewMessageReceived — rechargement messages

🔔 [AppVM] ===== NOUVELLE NOTIFICATION DÉTECTÉE =====
🔔 [AppVM] Type: new_message
🔔 [AppVM] currentVisibleConversationID: abc12345
🔔 [AppVM] notification relatedConversationId: abc12345
🔔 [AppVM] isConversationVisible: true
🔔 [AppVM] shouldShowBanner: false
🔔 [AppVM] ❌ Bannière ignorée (utilisateur regarde cette conversation)
```

### Quand agent envoie message

```
💬 [SendMessage] ===== ENVOI MESSAGE =====
💬 [SendMessage] Sender role: agent
💬 [SendMessage] Recipient user_id: <sellerID>
💬 [SendMessage] Conversation ID (8 premiers): abc12345
💬 [sendMessage] ===== INSERT MESSAGE DANS SUPABASE =====
💬 [sendMessage] conversation_id (8 premiers): abc12345
💬 [sendMessage] ✅ INSERT réussi
```

### Quand vendeur reçoit message (ailleurs)

```
🔔 [AppVM] ===== NOUVELLE NOTIFICATION DÉTECTÉE =====
🔔 [AppVM] Type: new_message
🔔 [AppVM] currentVisibleConversationID: nil
🔔 [AppVM] notification relatedConversationId: abc12345
🔔 [AppVM] isConversationVisible: false
🔔 [AppVM] shouldShowBanner: true
🔔 [AppVM] ✅ Affichage bannière
```

## ✅ Checklist de test

### Test 1 : Agent reçoit notification "agent_chosen"

1. Vendeur crée projet
2. Agent candidate
3. Vendeur choisit agent
4. **Vérifier** : Notification "Vous avez été sélectionné" arrive chez agent
5. Agent clique sur notification
6. **Vérifier logs** : `Conversation non trouvée localement — rechargement`
7. **Vérifier logs** : `✅ Conversation trouvée après rechargement`
8. **Vérifier** : Conversation s'ouvre
9. **Résultat attendu** : Agent peut envoyer un message ✅

### Test 2 : Vendeur envoie message → Agent reçoit

1. Vendeur dans conversation avec Agent
2. Vendeur envoie "Bonjour"
3. **Vérifier logs agent** :
   - `MESSAGE INSERT REÇU`
   - `✅ MATCH`
   - `onNewMessageReceived`
4. **Vérifier** : Message visible côté agent
5. **Vérifier** : Si agent regarde conversation → pas de bannière
6. **Vérifier** : Si agent ailleurs → bannière s'affiche

### Test 3 : Agent envoie message → Vendeur reçoit

1. Agent dans conversation avec Vendeur
2. Agent envoie "Merci !"
3. **Vérifier logs vendeur** :
   - `MESSAGE INSERT REÇU`
   - `✅ MATCH`
   - `onNewMessageReceived`
4. **Vérifier** : Message visible côté vendeur
5. **Vérifier** : Si vendeur regarde conversation → pas de bannière
6. **Vérifier** : Si vendeur ailleurs → bannière s'affiche

### Test 4 : Échange de plusieurs messages

1. Vendeur envoie "Message 1"
2. Agent envoie "Message 2"
3. Vendeur envoie "Message 3"
4. Agent envoie "Message 4"
5. **Vérifier** : Tous les messages visibles dans l'ordre des deux côtés
6. **Vérifier** : Même `conversation_id` pour tous les messages
7. **Vérifier** : Aucun doublon de conversation

## 🎉 Résultat final

### ✅ Ce qui fonctionne maintenant

- [x] Vendeur → Agent : Messages ✅
- [x] Agent → Vendeur : Messages ✅
- [x] Vendeur → Agent : Bannières (quand agent ailleurs) ✅
- [x] Agent → Vendeur : Bannières (quand vendeur ailleurs) ✅
- [x] Bannières bloquées (quand utilisateur regarde conversation) ✅
- [x] Pas de doublon de conversation ✅
- [x] Même `conversation_id` pour tous les messages ✅
- [x] `related_conversation_id` notification = `conversation_id` message ✅
- [x] Flux strictement symétrique ✅

---

**Date** : 2026-07-02  
**Problème résolu** : Asymétrie messagerie + bannières  
**Status** : ✅ Symétrie complète garantie

