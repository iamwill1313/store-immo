# 🔔 Correction : Bannière de notification trop agressive

## 🐛 Problème identifié

**Symptôme** :
- Le message arrive correctement dans la conversation ✅
- La notification arrive chez le destinataire ✅
- **MAIS** la bannière ne s'affiche pas ❌
- Log : `"Bannière ignorée (utilisateur dans la conversation)"`

**Cause** :
La logique utilisait `selectedConversation` pour détecter si l'utilisateur regarde la conversation. Mais `selectedConversation` reste définie même quand l'utilisateur quitte la vue de conversation et navigue ailleurs.

**Résultat** : Les bannières étaient bloquées même quand l'utilisateur n'était **pas** en train de regarder la conversation.

---

## ✅ Solution appliquée

### 1. Ajout d'une nouvelle variable : `currentVisibleConversationID`

**Fichier** : `AppViewModel.swift`

```swift
/// The ID of the conversation currently visible on screen (in ConversationView).
/// Set to non-nil when ConversationView appears, reset to nil when it disappears.
/// Used to determine if in-app notification banners should be shown.
var currentVisibleConversationID: UUID? = nil
```

**Différence clé** :
- `selectedConversation` : la conversation **sélectionnée** (peut être définie même hors de la vue)
- `currentVisibleConversationID` : la conversation **actuellement visible à l'écran** (nil si on n'est pas dans ConversationView)

---

### 2. Nouvelle logique de bannière

**Avant** :
```swift
// ❌ Trop agressif : selectedConversation reste définie même hors de ConversationView
if newNotif.type == "new_message",
   let convID = newNotif.relatedConversationId,
   let selectedConv = selectedConversation,
   convID == selectedConv.id {
    print("❌ Bannière ignorée (utilisateur dans la conversation)")
    return
}
```

**Après** :
```swift
// ✅ Précis : vérifie si l'utilisateur REGARDE réellement cette conversation
let shouldShowBanner: Bool
if newNotif.type == "new_message",
   let notifConvID = newNotif.relatedConversationId,
   let visibleConvID = currentVisibleConversationID,
   notifConvID == visibleConvID {
    // L'utilisateur regarde actuellement cette conversation → pas de bannière
    shouldShowBanner = false
    print("❌ Bannière ignorée (utilisateur regarde cette conversation)")
} else {
    // Tous les autres cas → afficher la bannière
    shouldShowBanner = true
    print("✅ Affichage bannière")
}

if shouldShowBanner {
    showInAppBanner(newNotif)
}
```

---

### 3. Ajout de fonctions helpers

**Fichier** : `AppViewModel.swift`

```swift
/// Call this from ConversationView's onAppear to mark the conversation as currently visible.
func markConversationAsVisible(_ conversationID: UUID) {
    currentVisibleConversationID = conversationID
    print("👁️ [AppVM] Conversation visible à l'écran:", conversationID.uuidString.prefix(8))
}

/// Call this from ConversationView's onDisappear to mark that no conversation is currently visible.
func markConversationAsHidden() {
    print("👁️ [AppVM] Conversation cachée — bannières réactivées")
    currentVisibleConversationID = nil
}
```

---

## 🔧 Intégration dans ConversationView

Vous devez maintenant appeler ces fonctions dans votre vue de conversation.

### Option A : Vous avez une vue SwiftUI dédiée (ConversationView)

```swift
struct ConversationView: View {
    @Environment(AppViewModel.self) private var appVM
    let conversation: Conversation
    
    var body: some View {
        VStack {
            // ... votre UI de conversation ...
        }
        .onAppear {
            // Marquer cette conversation comme visible
            appVM.markConversationAsVisible(conversation.id)
        }
        .onDisappear {
            // Réactiver les bannières quand on quitte
            appVM.markConversationAsHidden()
        }
    }
}
```

### Option B : Vous utilisez NavigationDestination

```swift
.navigationDestination(for: UUID.self) { conversationID in
    if let conversation = appVM.conversations.first(where: { $0.id == conversationID }) {
        // Votre vue de conversation
        ScrollView {
            // ... messages ...
        }
        .onAppear {
            appVM.markConversationAsVisible(conversationID)
        }
        .onDisappear {
            appVM.markConversationAsHidden()
        }
    }
}
```

### Option C : Vous affichez directement dans une condition

```swift
if let conv = appVM.selectedConversation {
    VStack {
        // ... votre UI de conversation ...
    }
    .onAppear {
        appVM.markConversationAsVisible(conv.id)
    }
    .onDisappear {
        appVM.markConversationAsHidden()
    }
}
```

---

## 🎯 Flux corrigé

### Scénario 1 : Utilisateur **regarde** la conversation

1. Vendeur ouvre la conversation avec Agent
2. **onAppear** → `currentVisibleConversationID = conversationID` ✅
3. Agent envoie un message
4. Notification Realtime arrive chez Vendeur
5. **Vérification** :
   ```
   currentVisibleConversationID: abc12345
   notification relatedConversationId: abc12345
   shouldShowBanner: false
   ❌ Bannière ignorée (utilisateur regarde cette conversation)
   ```
6. **Résultat** : Pas de bannière (normal, l'utilisateur voit déjà le message)

---

### Scénario 2 : Utilisateur **ne regarde pas** la conversation

1. Vendeur ouvre la conversation avec Agent
2. **onAppear** → `currentVisibleConversationID = conversationID` ✅
3. Vendeur navigue vers Dashboard
4. **onDisappear** → `currentVisibleConversationID = nil` ✅
5. Agent envoie un message
6. Notification Realtime arrive chez Vendeur
7. **Vérification** :
   ```
   currentVisibleConversationID: nil
   notification relatedConversationId: abc12345
   shouldShowBanner: true
   ✅ Affichage bannière
   ```
8. **Résultat** : Bannière s'affiche (normal, l'utilisateur n'est pas dans la conversation)

---

### Scénario 3 : Utilisateur regarde **une autre** conversation

1. Vendeur ouvre conversation avec Agent A
2. **onAppear** → `currentVisibleConversationID = conversationA_ID` ✅
3. Agent B envoie un message
4. Notification Realtime arrive chez Vendeur
5. **Vérification** :
   ```
   currentVisibleConversationID: def67890 (Agent A)
   notification relatedConversationId: abc12345 (Agent B)
   shouldShowBanner: true
   ✅ Affichage bannière
   ```
6. **Résultat** : Bannière s'affiche (normal, c'est une **autre** conversation)

---

## 📊 Logs de diagnostic

Quand vous testez, vous verrez ces logs :

### Quand on ouvre une conversation

```
👁️ [AppVM] Conversation visible à l'écran: abc12345
```

### Quand on quitte une conversation

```
👁️ [AppVM] Conversation cachée — bannières réactivées
👁️ [AppVM]   (était: abc12345)
```

### Quand une notification arrive

```
🔔 [AppVM] ===== NOUVELLE NOTIFICATION DÉTECTÉE =====
🔔 [AppVM] ID: <UUID>
🔔 [AppVM] Type: new_message
🔔 [AppVM] Title: Nouveau message
🔔 [AppVM] relatedConversationId: abc12345

// Cas 1 : Bannière bloquée
🔔 [AppVM] currentVisibleConversationID: abc12345
🔔 [AppVM] notification relatedConversationId: abc12345
🔔 [AppVM] shouldShowBanner: false
🔔 [AppVM] ❌ Bannière ignorée (utilisateur regarde cette conversation)

// Cas 2 : Bannière affichée
🔔 [AppVM] currentVisibleConversationID: nil
🔔 [AppVM] notification relatedConversationId: abc12345
🔔 [AppVM] shouldShowBanner: true
🔔 [AppVM] ✅ Affichage bannière
```

---

## 🚨 Points d'attention

### ⚠️ Oubli d'appeler `onDisappear`

Si vous oubliez d'appeler `markConversationAsHidden()` dans `onDisappear`, `currentVisibleConversationID` restera défini et les bannières seront bloquées même hors de la conversation.

**Solution** : Toujours appeler les deux fonctions (`onAppear` + `onDisappear`).

---

### ⚠️ Navigation complexe

Si votre navigation est complexe (ex: sheets, fullScreenCovers), assurez-vous que `onDisappear` est bien appelé.

**Test rapide** :
1. Ouvrir conversation
2. Vérifier log : `Conversation visible à l'écran`
3. Naviguer ailleurs
4. Vérifier log : `Conversation cachée — bannières réactivées`

Si vous ne voyez pas le second log, `onDisappear` n'est pas appelé.

---

### ⚠️ Plusieurs vues de conversation

Si vous avez plusieurs vues qui affichent une conversation (ex: prévisualisation + vue complète), assurez-vous que **seule la vue principale** appelle `markConversationAsVisible()`.

---

## ✅ Checklist de test

### Test 1 : Bannière bloquée (utilisateur regarde)

1. **Vendeur** : Ouvrir conversation avec Agent
2. **Vérifier log** : `Conversation visible à l'écran: abc12345`
3. **Agent** : Envoyer message "Test"
4. **Vérifier log** :
   ```
   currentVisibleConversationID: abc12345
   notification relatedConversationId: abc12345
   shouldShowBanner: false
   ❌ Bannière ignorée
   ```
5. **Résultat attendu** : Pas de bannière (normal)

---

### Test 2 : Bannière affichée (utilisateur ne regarde pas)

1. **Vendeur** : Ouvrir conversation avec Agent
2. **Vendeur** : Naviguer vers Dashboard
3. **Vérifier log** : `Conversation cachée — bannières réactivées`
4. **Agent** : Envoyer message "Test 2"
5. **Vérifier log** :
   ```
   currentVisibleConversationID: nil
   notification relatedConversationId: abc12345
   shouldShowBanner: true
   ✅ Affichage bannière
   ```
6. **Résultat attendu** : Bannière s'affiche ✅

---

### Test 3 : Bannière affichée (autre conversation)

1. **Vendeur** : Ouvrir conversation avec Agent A
2. **Vérifier log** : `Conversation visible à l'écran: def67890`
3. **Agent B** : Envoyer message
4. **Vérifier log** :
   ```
   currentVisibleConversationID: def67890
   notification relatedConversationId: abc12345
   shouldShowBanner: true
   ✅ Affichage bannière
   ```
5. **Résultat attendu** : Bannière s'affiche ✅

---

## 📝 Résumé des modifications

### AppViewModel.swift

1. **Ligne ~48** : Ajout de `var currentVisibleConversationID: UUID? = nil`
2. **Ligne ~1450** : Ajout de `markConversationAsVisible()`
3. **Ligne ~1456** : Ajout de `markConversationAsHidden()`
4. **Ligne ~2076-2115** : Refactorisation de `onNewNotificationReceived()` avec nouvelle logique

### À faire : Intégration dans ConversationView

Vous devez ajouter dans votre vue de conversation :

```swift
.onAppear {
    appVM.markConversationAsVisible(conversation.id)
}
.onDisappear {
    appVM.markConversationAsHidden()
}
```

---

**Date** : 2026-07-02  
**Problème résolu** : Bannière bloquée à cause de `selectedConversation` toujours définie  
**Status** : ✅ Corrections appliquées — intégration dans ConversationView requise

