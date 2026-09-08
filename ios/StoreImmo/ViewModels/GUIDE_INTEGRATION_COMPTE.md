# 🔧 Guide d'intégration de l'onglet Compte

## Étape 1 : Trouver la vue avec TabView

Recherchez dans votre projet le fichier qui contient le `TabView`. Il peut s'appeler :
- `ContentView.swift`
- `MainView.swift`
- `SellerDashboardView.swift` / `AgentDashboardView.swift`
- `AppRootView.swift`

Le code ressemble probablement à ceci :

```swift
TabView(selection: $viewModel.sellerTab) {
    // ... autres tabs
    
    SomeProfileView()  // ← À remplacer
        .tabItem {
            Label("Profil", systemImage: "person.circle")  // ← À changer
        }
        .tag(AppTabSeller.profile)  // ← À changer
}
```

## Étape 2 : Remplacer l'onglet Profil par Compte

### Pour les vendeurs (SellerTab)

Remplacez le code de l'onglet profil par :

```swift
AccountView()
    .tabItem {
        Label("Compte", systemImage: "person.circle")
    }
    .tag(AppTabSeller.account)
```

### Pour les agents (AgentTab)

Remplacez le code de l'onglet profil par :

```swift
AccountView()
    .tabItem {
        Label("Compte", systemImage: "person.circle")
    }
    .tag(AppTabAgent.account)
```

## Étape 3 : Supprimer l'ancienne vue de profil (optionnel)

Si vous aviez des fichiers comme :
- `ProfileView.swift`
- `SellerProfileView.swift`
- `AgentProfileView.swift`

Vous pouvez les supprimer car leur fonctionnalité est maintenant dans :
- `AccountView.swift` (vue principale)
- `PersonalInfoView.swift` (informations personnelles)

## Étape 4 : Compiler et vérifier

1. **Build le projet** : `Cmd + B`
2. **Vérifier les erreurs** : S'il y a des références à `.profile`, remplacez-les par `.account`
3. **Run** : `Cmd + R`

## Étape 5 : Tester la navigation

### Tests vendeur :
1. Connexion en tant que vendeur
2. Aller dans l'onglet "Compte" (anciennement "Profil")
3. Vérifier chaque section :
   - [ ] Informations personnelles s'affichent
   - [ ] Paramètres de notifications fonctionnent
   - [ ] Paramètres de confidentialité s'ouvrent
   - [ ] Signaler un problème fonctionne
   - [ ] Mes demandes (vide au début)
   - [ ] FAQ affiche les bonnes questions
   - [ ] Version de l'app s'affiche
   - [ ] Déconnexion fonctionne

### Tests agent :
1. Connexion en tant qu'agent
2. Aller dans l'onglet "Compte"
3. Vérifier chaque section :
   - [ ] Photo de profil s'affiche ou permet l'upload
   - [ ] Informations personnelles modifiables
   - [ ] Paramètres de notifications (avec abonnement)
   - [ ] Paramètres de confidentialité (avec visibilité)
   - [ ] Support avec toutes les catégories
   - [ ] FAQ orientée agent

## Étape 6 : Configuration Supabase

1. **Ouvrir Supabase Dashboard**
2. **Aller dans SQL Editor**
3. **Exécuter le SQL** de `SETUP_SUPPORT_TICKETS.md`
4. **Vérifier la table** dans Table Editor
5. **Tester** : Créer un ticket depuis l'app

## Erreurs courantes et solutions

### Erreur : "Cannot find 'AccountView' in scope"

**Solution** : Assurez-vous que `AccountView.swift` est bien ajouté au target de votre app.
Dans Xcode :
1. Cliquez sur `AccountView.swift` dans le navigateur
2. File Inspector (⌥⌘1)
3. Vérifiez "Target Membership"

### Erreur : Type 'AppTabSeller' has no member 'profile'

**Solution** : C'est normal ! Vous devez remplacer `.profile` par `.account` partout.

Recherche globale dans Xcode :
1. `Cmd + Shift + F`
2. Cherchez : `.profile`
3. Remplacez par : `.account` (seulement pour AppTabSeller et AppTabAgent)

### Erreur : "Value of type 'AppViewModel' has no member 'supportTickets'"

**Solution** : Assurez-vous que les modifications dans `AppViewModel.swift` ont bien été appliquées.
Vérifiez la présence de :
```swift
var supportTickets: [SupportTicket] = []
var notificationSettings: NotificationSettings = NotificationSettings()
```

### Warning : "Result of call is unused"

Dans `AccountView.swift`, méthode `rateApp()`.

**Solution** : C'est normal, le résultat de `SKStoreReviewController.requestReview()` n'a pas besoin d'être utilisé.

## Personnalisation avancée

### Changer les URLs des documents légaux

Dans `AccountView.swift` et `PrivacySettingsView.swift`, remplacez :

```swift
Link(destination: URL(string: "https://storeimmo.fr/privacy")!) {
```

Par votre vraie URL.

### Ajouter des questions FAQ

Dans `FAQView.swift`, ajoutez dans les arrays `sellerFAQItems` ou `agentFAQItems` :

```swift
FAQItem(
    question: "Votre question ?",
    answer: "La réponse détaillée...",
    category: "Catégorie"
)
```

### Personnaliser les catégories de support

Dans `StoreImmoModels.swift`, modifiez l'enum `SupportCategory` :

```swift
case maNouvelleCat = "Ma catégorie"

var symbolName: String {
    switch self {
    case .maNouvelleCat: return "star.circle"
    // ...
    }
}
```

### Persister les paramètres de notification

Dans `AppViewModel.swift`, ajoutez dans `saveSession()` :

```swift
d.set(notificationSettings.projectsEnabled, forKey: "si_notif_projects")
d.set(notificationSettings.applicationsEnabled, forKey: "si_notif_applications")
d.set(notificationSettings.messagesEnabled, forKey: "si_notif_messages")
d.set(notificationSettings.subscriptionEnabled, forKey: "si_notif_subscription")
d.set(notificationSettings.generalEnabled, forKey: "si_notif_general")
```

Et dans `loadPersistedSession()` :

```swift
notificationSettings.projectsEnabled = d.bool(forKey: "si_notif_projects")
notificationSettings.applicationsEnabled = d.bool(forKey: "si_notif_applications")
notificationSettings.messagesEnabled = d.bool(forKey: "si_notif_messages")
notificationSettings.subscriptionEnabled = d.bool(forKey: "si_notif_subscription")
notificationSettings.generalEnabled = d.bool(forKey: "si_notif_general")
```

## Checklist finale

Avant de considérer la transformation terminée :

- [ ] Build réussit sans erreurs
- [ ] Navigation vendeur fonctionne
- [ ] Navigation agent fonctionne
- [ ] Chaque bouton/lien fonctionne
- [ ] Photos de profil agent fonctionnent (upload/suppression)
- [ ] Notifications se configurent
- [ ] Tickets de support se créent
- [ ] Tickets s'affichent dans "Mes demandes"
- [ ] FAQ s'affiche et recherche fonctionne
- [ ] Déconnexion fonctionne
- [ ] Table Supabase créée et testée
- [ ] RLS fonctionne (chaque utilisateur voit ses tickets)

## Support

Si vous rencontrez des problèmes :

1. **Vérifiez les logs** dans Xcode Console
2. **Consultez** `TRANSFORMATION_COMPTE.md` pour la liste complète des changements
3. **Vérifiez** que tous les fichiers sont bien ajoutés au target
4. **Testez** avec des comptes vendeur ET agent

---

**Bon courage ! 🚀**
