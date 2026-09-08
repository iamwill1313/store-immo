# 🔨 Instructions de Build - Onglet Compte

## Avant de commencer

Assurez-vous d'avoir :
- ✅ Xcode ouvert avec le projet StoreImmo
- ✅ Tous les nouveaux fichiers ajoutés au target
- ✅ Lecture des documents :
  - `README_COMPTE.md` (vue d'ensemble)
  - `GUIDE_INTEGRATION_COMPTE.md` (étapes d'intégration)

## Étape 1 : Vérifier les fichiers

### Nouveaux fichiers Swift à vérifier

Dans le navigateur de projet (⌘1), assurez-vous que ces fichiers existent :

```
StoreImmo/
├── Views/
│   ├── AccountView.swift              ✅
│   ├── PersonalInfoView.swift         ✅
│   ├── NotificationSettingsView.swift ✅
│   ├── PrivacySettingsView.swift      ✅
│   ├── ReportProblemView.swift        ✅
│   ├── MyRequestsView.swift           ✅
│   └── FAQView.swift                  ✅
├── Models/
│   └── StoreImmoModels.swift          ✅ (modifié)
├── ViewModels/
│   └── AppViewModel.swift             ✅ (modifié)
└── Services/
    └── SupabaseRepository.swift       ✅ (modifié)
```

### Vérifier Target Membership

Pour chaque nouveau fichier :
1. Sélectionnez le fichier
2. Ouvrez File Inspector (⌥⌘1)
3. Section "Target Membership"
4. Cochez votre target principal (ex: "StoreImmo")

## Étape 2 : Recherche et remplacement

### Trouver le TabView

1. Recherche globale : `⌘⇧F`
2. Cherchez : `TabView`
3. Trouvez le fichier qui contient `AppTabSeller` ou `AppTabAgent`

### Remplacer .profile par .account

**Option A : Recherche/Remplacement globale**
1. `⌘⇧F` (Find)
2. Dans "Find", tapez : `\.profile`
3. Dans "Replace", tapez : `.account`
4. Cliquez "Replace All" (vérifiez d'abord les occurrences)

**Option B : Remplacement manuel**

Cherchez ces patterns et remplacez-les :

```swift
// AVANT
.tag(AppTabSeller.profile)
// APRÈS
.tag(AppTabSeller.account)

// AVANT
.tag(AppTabAgent.profile)
// APRÈS
.tag(AppTabAgent.account)

// AVANT
Label("Profil", systemImage: "person.circle")
// APRÈS
Label("Compte", systemImage: "person.circle")
```

### Remplacer la vue de profil

```swift
// AVANT (exemple, peut varier)
ProfileView()
    .tabItem {
        Label("Profil", systemImage: "person.circle")
    }
    .tag(AppTabSeller.profile)

// APRÈS
AccountView()
    .tabItem {
        Label("Compte", systemImage: "person.circle")
    }
    .tag(AppTabSeller.account)
```

## Étape 3 : Premier Build

### Nettoyer le build

1. `⌘⇧K` (Clean Build Folder)
2. Attendez la fin

### Build

1. `⌘B` (Build)
2. Observez les erreurs/warnings dans le navigator

### Erreurs courantes

#### "Cannot find 'AccountView' in scope"

**Cause** : Le fichier n'est pas dans le target

**Solution** :
1. Sélectionnez `AccountView.swift`
2. File Inspector (⌥⌘1)
3. Cochez votre target

#### "Type 'AppTabSeller' has no member 'profile'"

**Cause** : Vous n'avez pas remplacé `.profile` par `.account`

**Solution** :
1. Cliquez sur l'erreur
2. Remplacez `.profile` par `.account`

#### "Value of type 'AppViewModel' has no member 'supportTickets'"

**Cause** : `AppViewModel.swift` n'a pas été modifié correctement

**Solution** :
1. Ouvrez `AppViewModel.swift`
2. Vérifiez la présence de :
```swift
var supportTickets: [SupportTicket] = []
var notificationSettings: NotificationSettings = NotificationSettings()
```

#### "Cannot find 'SupportCategory' in scope"

**Cause** : `StoreImmoModels.swift` n'a pas été modifié

**Solution** :
1. Ouvrez `StoreImmoModels.swift`
2. Vérifiez la présence de :
```swift
nonisolated enum SupportCategory: String, CaseIterable, Identifiable, Sendable {
    // ...
}
```

## Étape 4 : Configuration Supabase

**AVANT** de run l'app :

1. Ouvrez [supabase.com](https://supabase.com)
2. Sélectionnez votre projet
3. Allez dans **SQL Editor**
4. Ouvrez `SETUP_SUPPORT_TICKETS.md`
5. Copiez tout le SQL
6. Collez dans l'éditeur Supabase
7. Cliquez **Run**
8. Vérifiez : "Success. No rows returned"

### Vérification table créée

1. Allez dans **Table Editor**
2. Cherchez `support_tickets`
3. Vérifiez les colonnes :
   - id
   - user_id
   - category
   - subject
   - message
   - status
   - user_role
   - app_version
   - created_at
   - updated_at

## Étape 5 : Premier Run

### Simulateur

1. Sélectionnez un simulateur (ex: iPhone 15 Pro)
2. `⌘R` (Run)
3. Attendez le lancement

### Sur appareil réel

1. Branchez votre iPhone/iPad
2. Sélectionnez-le comme destination
3. `⌘R` (Run)
4. Approuvez le certificat si demandé

## Étape 6 : Tests fonctionnels

### Test rapide (2 min)

1. ✅ L'app démarre
2. ✅ L'onglet "Compte" est visible en bas
3. ✅ Tap sur "Compte"
4. ✅ La page s'ouvre avec toutes les sections
5. ✅ Tap sur "Informations personnelles"
6. ✅ La fiche s'ouvre
7. ✅ Retour et tap sur "Signaler un problème"
8. ✅ Le formulaire s'ouvre

### Test complet vendeur (5 min)

1. ✅ Connexion en tant que vendeur
2. ✅ Onglet "Compte"
3. ✅ **Informations personnelles**
   - Prénom, nom, email, téléphone affichés
   - Mode lecture seule
4. ✅ **Notifications**
   - Toggles fonctionnent
   - Pas de section "Abonnement"
5. ✅ **Confidentialité**
   - Page s'ouvre
6. ✅ **Signaler un problème**
   - Catégories adaptées (pas Abonnement/Paiement)
   - Formulaire complet
   - Envoi fonctionne
7. ✅ **Mes demandes**
   - Ticket créé apparaît
   - Détail visible
8. ✅ **FAQ**
   - Questions vendeur affichées
   - Recherche fonctionne
9. ✅ **Version**
   - Numéro affiché
10. ✅ **Déconnexion**
    - Confirmation demandée
    - Retour à l'écran de connexion

### Test complet agent (7 min)

1. ✅ Connexion en tant qu'agent
2. ✅ Onglet "Compte"
3. ✅ **Informations personnelles**
   - Photo de profil affichée
   - Bouton "Modifier"
   - Édition fonctionne
   - Upload photo fonctionne
4. ✅ **Notifications**
   - Section "Abonnement" présente
   - Toggles fonctionnent
5. ✅ **Confidentialité**
   - Visibilité du profil disponible
   - Gestion des données
6. ✅ **Signaler un problème**
   - Toutes les catégories présentes
   - Envoi fonctionne
7. ✅ **Mes demandes**
   - Tickets visibles
8. ✅ **FAQ**
   - Questions agent affichées
   - Catégories correctes
9. ✅ **Déconnexion**
   - Fonctionne

## Étape 7 : Vérification Supabase

### Vérifier les tickets créés

1. Ouvrez Supabase Dashboard
2. **Table Editor** > `support_tickets`
3. Vérifiez :
   - ✅ Les tickets de test apparaissent
   - ✅ `user_id` correct
   - ✅ `category` correct
   - ✅ `status` = "Nouvelle"
   - ✅ `user_role` = "seller" ou "agent"
   - ✅ `app_version` renseignée

### Vérifier RLS (Row Level Security)

1. Créez deux comptes test (vendeur A, agent B)
2. Vendeur A crée un ticket
3. Agent B crée un ticket
4. Vérifiez :
   - ✅ Vendeur A voit uniquement son ticket
   - ✅ Agent B voit uniquement son ticket

## Étape 8 : Optimisations finales

### Performances

1. **Temps de chargement** : L'onglet Compte doit s'ouvrir < 0.5s
2. **Scrolling** : Fluide dans "Mes demandes" et FAQ
3. **Animations** : Naturelles lors des transitions

### Mémoire

1. Ouvrez **Debug Navigator** (⌘7)
2. Sélectionnez **Memory**
3. Naviguez dans Compte
4. Vérifiez : pas de fuite mémoire (courbe stable)

### Network

1. Activez **Network Link Conditioner**
2. Simulez 3G
3. Testez création de ticket
4. Vérifiez : feedback utilisateur (loading, succès/erreur)

## Checklist finale

Avant de considérer terminé :

### Build
- [ ] Build réussit sans erreur
- [ ] Aucun warning critique
- [ ] Tous les fichiers dans le target

### Fonctionnel
- [ ] Navigation vendeur OK
- [ ] Navigation agent OK
- [ ] Upload photo agent OK
- [ ] Création ticket OK
- [ ] Affichage tickets OK
- [ ] FAQ OK
- [ ] Déconnexion OK

### Supabase
- [ ] Table `support_tickets` créée
- [ ] RLS activé et fonctionnel
- [ ] Tickets s'enregistrent
- [ ] Tickets se chargent

### UX
- [ ] Animations fluides
- [ ] Pas de freeze UI
- [ ] Messages d'erreur clairs
- [ ] Loading indicators

## Problèmes fréquents

### L'app crash au lancement

**Vérifiez** :
1. Console Xcode pour l'erreur exacte
2. Tous les fichiers sont bien dans le target
3. Aucune référence à `.profile` restante

### Les tickets ne s'affichent pas

**Vérifiez** :
1. Table Supabase créée correctement
2. RLS configuré
3. Console Xcode pour erreurs réseau
4. URL et clé Supabase dans Config.swift

### Photo de profil ne s'upload pas

**Vérifiez** :
1. Permission Photos dans Info.plist
2. Bucket Supabase Storage configuré
3. Politiques Storage configurées

### FAQ ne recherche pas

**Vérifiez** :
1. Texte entré dans la barre de recherche
2. Questions contiennent bien le texte cherché
3. `searchText` binding fonctionne

## Commandes utiles

```bash
# Nettoyer build
Cmd + Shift + K

# Build
Cmd + B

# Run
Cmd + R

# Stop
Cmd + .

# Nettoyer derived data (problèmes persistants)
Xcode > Settings > Locations > Derived Data > Cliquez sur flèche > Supprimez le dossier
```

## Logs de debug

Pour debug, ajoutez dans les vues :

```swift
.onAppear {
    print("🔍 [AccountView] Apparue - Role: \(viewModel.selectedRole?.rawValue ?? "none")")
}
```

## Support

Si après tous ces tests, vous rencontrez un problème :

1. **Consultez les logs** Xcode Console
2. **Relisez** `GUIDE_INTEGRATION_COMPTE.md`
3. **Vérifiez** que vous avez bien suivi toutes les étapes
4. **Testez** sur un autre simulateur/appareil

---

**Bonne chance avec le build ! 🚀**

Si tout fonctionne, vous avez réussi la transformation Profil → Compte ! 🎉
