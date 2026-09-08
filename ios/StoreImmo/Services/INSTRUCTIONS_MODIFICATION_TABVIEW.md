# 🔧 CORRECTION IMMÉDIATE — Routage Compte Vendeur vers AccountView

## 📍 FICHIER À MODIFIER

Cherchez dans votre projet Xcode le fichier qui contient le `TabView` du vendeur.

**Nom probable** : `ContentView.swift`

**Comment le trouver** :
1. Dans Xcode : `⌘` + `⇧` + `O`
2. Tapez : `ContentView`
3. Ouvrez le fichier

**OU** :
1. Dans Xcode : `⌘` + `⇧` + `F`
2. Cherchez : `TabView(selection: $viewModel.sellerTab)`
3. Ouvrez le fichier trouvé

---

## 🎯 MODIFICATION À EFFECTUER

### Cherchez ce pattern dans le fichier :

Le TabView vendeur ressemble probablement à ceci :

```swift
if viewModel.selectedRole == .seller {
    TabView(selection: $viewModel.sellerTab) {
        // Premier onglet (Dashboard/Projets)
        SomeView()
            .tabItem {
                Label("Projets", systemImage: "house")
            }
            .tag(AppTabSeller.dashboard)
        
        // Deuxième onglet (Messages)
        MessagesView()
            .tabItem {
                Label("Messages", systemImage: "message")
            }
            .tag(AppTabSeller.messages)
        
        // ⚠️ ONGLET À MODIFIER — Compte/Profil
        ProfileView()  // ← OU SellerProfileView() OU autre
            .tabItem {
                Label("Compte", systemImage: "person.circle")  // ou "Profil"
            }
            .tag(AppTabSeller.account)  // ou .profile
    }
}
```

### Modifiez UNIQUEMENT la section de l'onglet Compte :

**AVANT** (une de ces variantes) :
```swift
ProfileView()
    .tabItem {
        Label("Compte", systemImage: "person.circle")
    }
    .tag(AppTabSeller.account)
```

**OU** :
```swift
SellerProfileView()
    .tabItem {
        Label("Profil", systemImage: "person.circle")
    }
    .tag(AppTabSeller.profile)
```

**OU** :
```swift
SomeOldView()
    .tabItem {
        Label("Compte", systemImage: "person.circle")
    }
    .tag(AppTabSeller.account)
```

**APRÈS** (version finale) :
```swift
AccountView()
    .tabItem {
        Label("Compte", systemImage: "person.circle")
    }
    .tag(AppTabSeller.account)
```

---

## ⚠️ RÈGLES ABSOLUES

### ✅ À FAIRE
- Remplacer UNIQUEMENT la vue de l'onglet compte vendeur
- Utiliser `AccountView()`
- Garder `.tabItem { Label("Compte", systemImage: "person.circle") }`
- Garder `.tag(AppTabSeller.account)`

### ❌ NE PAS FAIRE
- Ne touchez PAS au TabView de l'agent
- Ne modifiez PAS les autres onglets vendeur
- Ne créez PAS de nouveau fichier
- Ne dupliquez PAS AccountView

---

## 🔍 SI VOUS AVEZ AUSSI UN TAG .profile

Si vous voyez `.tag(AppTabSeller.profile)` au lieu de `.account` :

**Remplacez** :
```swift
ProfileView()
    .tabItem {
        Label("Profil", systemImage: "person.circle")
    }
    .tag(AppTabSeller.profile)  // ← Ancien tag
```

**Par** :
```swift
AccountView()
    .tabItem {
        Label("Compte", systemImage: "person.circle")
    }
    .tag(AppTabSeller.account)  // ← Nouveau tag
```

**ET** vérifiez dans `StoreImmoModels.swift` que l'enum contient bien `.account` :

```swift
nonisolated enum AppTabSeller: Hashable, Sendable {
    case dashboard
    case mandates  // Peut-être pas utilisé
    case messages
    case account   // ← Doit être présent
}
```

Si `.profile` existe encore dans l'enum, remplacez-le par `.account`.

---

## ✅ VÉRIFICATION COMPTE AGENT

**Le TabView agent ne doit PAS être modifié.**

Si vous voyez un bloc similaire pour l'agent :

```swift
if viewModel.selectedRole == .agent {
    TabView(selection: $viewModel.agentTab) {
        // ... onglets agent
        
        AccountView()  // ← SI DÉJÀ AccountView, NE PAS TOUCHER
            .tabItem {
                Label("Compte", systemImage: "person.circle")
            }
            .tag(AppTabAgent.account)
    }
}
```

**NE LE MODIFIEZ PAS.**

L'agent utilise probablement déjà `AccountView()` correctement.

---

## 🚀 APRÈS LA MODIFICATION

### 1. Compilez
```bash
⌘ + B
```

**Résultat attendu** : ✅ 0 erreur

### 2. Testez
```bash
⌘ + R
```

**Test Vendeur** :
1. Connectez-vous en tant que vendeur
2. Allez dans l'onglet "Compte"
3. Vérifiez que vous voyez :
   - Photo (icône par défaut)
   - Nom complet
   - Email + Téléphone
   - Mon profil → Informations personnelles
   - Mes projets
   - Paramètres
   - Aide et support
   - À propos
   - Se déconnecter

**Test Agent** :
1. Connectez-vous en tant qu'agent
2. Vérifiez que RIEN n'a changé
3. Le compte agent doit être exactement comme avant

---

## 📋 EXEMPLE COMPLET

Voici à quoi devrait ressembler le fichier APRÈS modification :

```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        if viewModel.selectedRole == .seller {
            // TabView VENDEUR
            TabView(selection: $viewModel.sellerTab) {
                SellerDashboardView()
                    .tabItem {
                        Label("Projets", systemImage: "house")
                    }
                    .tag(AppTabSeller.dashboard)
                
                SellerMessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "message")
                    }
                    .tag(AppTabSeller.messages)
                
                AccountView()  // ← MODIFICATION ICI
                    .tabItem {
                        Label("Compte", systemImage: "person.circle")
                    }
                    .tag(AppTabSeller.account)
            }
        } else if viewModel.selectedRole == .agent {
            // TabView AGENT (NE PAS MODIFIER)
            TabView(selection: $viewModel.agentTab) {
                AgentOpportunitiesView()
                    .tabItem {
                        Label("Opportunités", systemImage: "sparkles")
                    }
                    .tag(AppTabAgent.opportunities)
                
                DiscoverView()
                    .tabItem {
                        Label("Découvrir", systemImage: "map")
                    }
                    .tag(AppTabAgent.discover)
                
                AgentMessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "message")
                    }
                    .tag(AppTabAgent.messages)
                
                AccountView()  // ← DÉJÀ CORRECT POUR AGENT
                    .tabItem {
                        Label("Compte", systemImage: "person.circle")
                    }
                    .tag(AppTabAgent.account)
            }
        }
    }
}
```

---

## ❓ SI VOUS NE TROUVEZ PAS LE FICHIER

**Montrez-moi** le résultat de la recherche :
1. `⌘` + `⇧` + `F`
2. Cherchez : `sellerTab`
3. Copiez-collez les résultats

Je vous dirai exactement quel fichier modifier.

---

## ✅ RÉSUMÉ

| Action | Détail |
|--------|--------|
| **Fichier à modifier** | ContentView.swift (ou similaire) |
| **Ligne à chercher** | `ProfileView()` ou équivalent dans TabView vendeur |
| **Ligne à mettre** | `AccountView()` |
| **Tag à utiliser** | `.tag(AppTabSeller.account)` |
| **Compte Agent** | NE PAS TOUCHER |
| **Compilation** | ⌘ + B → 0 erreur attendu |

---

**Date** : 8 septembre 2026  
**Statut** : Instructions prêtes — En attente de modification  
**Temps estimé** : 30 secondes

---
