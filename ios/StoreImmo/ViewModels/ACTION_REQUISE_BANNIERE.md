# ✅ Correction appliquée : Bannière de notification

## 🎯 Problème résolu

La bannière ne s'affichait pas car la logique était trop agressive. Elle bloquait les bannières même quand l'utilisateur **n'était pas** en train de regarder la conversation.

## 🔧 Ce qui a été modifié

1. **Ajout d'une variable** `currentVisibleConversationID` qui suit **précisément** quelle conversation est affichée à l'écran
2. **Nouvelle logique** : La bannière est bloquée **uniquement** si `currentVisibleConversationID == notification.relatedConversationId`
3. **Logs détaillés** pour diagnostiquer

## 📋 Action requise de votre part

Vous devez ajouter 2 lignes dans votre **ConversationView** :

```swift
.onAppear {
    appVM.markConversationAsVisible(conversation.id)
}
.onDisappear {
    appVM.markConversationAsHidden()
}
```

### Où ajouter ces lignes ?

Cherchez dans votre code où vous affichez la conversation (messages, champ de texte, etc.).

**Exemple 1** : Vue dédiée
```swift
struct ConversationView: View {
    @Environment(AppViewModel.self) private var appVM
    let conversation: Conversation
    
    var body: some View {
        VStack {
            // ... messages ...
        }
        .onAppear { appVM.markConversationAsVisible(conversation.id) }
        .onDisappear { appVM.markConversationAsHidden() }
    }
}
```

**Exemple 2** : NavigationDestination
```swift
.navigationDestination(for: UUID.self) { conversationID in
    // ... votre vue de conversation ...
    .onAppear { appVM.markConversationAsVisible(conversationID) }
    .onDisappear { appVM.markConversationAsHidden() }
}
```

**Exemple 3** : Condition if let
```swift
if let conv = appVM.selectedConversation {
    VStack {
        // ... messages ...
    }
    .onAppear { appVM.markConversationAsVisible(conv.id) }
    .onDisappear { appVM.markConversationAsHidden() }
}
```

## ✅ Comment tester

### Test 1 : Pas de bannière (utilisateur regarde)
1. Vendeur ouvre conversation avec Agent
2. Agent envoie message
3. **Attendu** : Pas de bannière (utilisateur voit déjà le message)

### Test 2 : Bannière affichée (utilisateur ne regarde pas)
1. Vendeur ouvre conversation avec Agent
2. Vendeur navigue vers Dashboard
3. Agent envoie message
4. **Attendu** : Bannière s'affiche ✅

### Test 3 : Bannière affichée (autre conversation)
1. Vendeur regarde conversation avec Agent A
2. Agent B envoie message
3. **Attendu** : Bannière s'affiche ✅

## 📊 Logs à vérifier

Quand vous ouvrez une conversation :
```
👁️ [AppVM] Conversation visible à l'écran: abc12345
```

Quand vous quittez une conversation :
```
👁️ [AppVM] Conversation cachée — bannières réactivées
```

Quand une notification arrive :
```
🔔 [AppVM] currentVisibleConversationID: abc12345 (ou nil)
🔔 [AppVM] notification relatedConversationId: abc12345
🔔 [AppVM] shouldShowBanner: true (ou false)
```

## 🚨 Si la bannière ne s'affiche toujours pas

Vérifiez que vous voyez bien ces logs quand vous **quittez** la conversation :
```
👁️ [AppVM] Conversation cachée — bannières réactivées
```

Si vous ne voyez pas ce log, c'est que `onDisappear` n'est pas appelé. Assurez-vous de l'ajouter au bon endroit.

---

**Prochaine étape** : Ajoutez les 2 lignes (`onAppear` + `onDisappear`) dans votre ConversationView et testez !

