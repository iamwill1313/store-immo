# 🔍 AUDIT DE L'ARCHITECTURE STOREIMMO - AVANT AJOUT HOME

**Date :** 2026-09-13  
**Objectif :** Analyser l'architecture existante AVANT d'ajouter la nouvelle Home publique  
**Statut :** ⏳ EN COURS

---

## 📋 FICHIERS ANALYSÉS

### ✅ AccountView.swift
- **Localisation :** `/repo/AccountView.swift`
- **Type :** Vue SwiftUI pour l'onglet Compte
- **Rôle :** Affiche le profil, paramètres, support, FAQ
- **Dépendances :**
  - `@Environment(AppViewModel.self)`
  - `import StoreKit` (pour notation app)
  - Utilise `viewModel.selectedRole` pour adapter l'UI
  - Navigue vers `PersonalInfoView`, `NotificationSettingsView`, etc.
  - Peut changer `viewModel.sellerTab` et `viewModel.agentTab`
- **⚠️ PROTECTION :** NE PAS MODIFIER - Fonctionne correctement

### ✅ AppViewModel.swift
- **Localisation :** `/repo/AppViewModel.swift`
- **Type :** `@Observable @MainActor final class`
- **Taille :** 3044 lignes
- **Propriétés clés identifiées :**
  ```swift
  var selectedRole: UserRole?
  var isAuthenticated: Bool = false
  var sellerTab: AppTabSeller = .dashboard
  var agentTab: AppTabAgent = .discover
  ```
- **Méthodes clés identifiées :**
  - `chooseRole(_ role: UserRole)`
  - `completeAuthentication()`
  - `loginExistingAccount(role:email:phone:)`
  - `signOut()`
  - `submitOTPCode()`
  - `loadUserDataFromSupabase()`
  - `loadSellerProjectsFromSupabase()`
  
- **⚠️ PROTECTION :** NE PAS RECONSTRUIRE - Étendre seulement si nécessaire

---

## ❓ FICHIERS À IDENTIFIER (PHASE 2)

### 🔴 CRITIQUE - Point d'entrée
- [ ] **StoreImmoApp.swift** ou **App.swift**
  - Recherche : `@main`, `WindowGroup`, `Scene`
  - Objectif : Comprendre où démarre l'application
  - Pourquoi : C'est ICI qu'on devra insérer la logique de routage Home vs Auth vs TabView

### 🔴 CRITIQUE - Vue racine
- [ ] **ContentView.swift** ou **RootView.swift**
  - Recherche : Premier écran affiché, contient TabView Agent/Seller
  - Objectif : Comprendre la navigation actuelle
  - Pourquoi : C'est ICI qu'on devra insérer une condition pour afficher Home ou TabView

### 🔴 CRITIQUE - Modèles
- [ ] **StoreImmoModels.swift**
  - Recherche : `enum AppTabSeller`, `enum AppTabAgent`, `enum UserRole`
  - Objectif : Comprendre les types utilisés
  - Pourquoi : On doit potentiellement ajouter des états pour Home

### 🟡 IMPORTANT - Onboarding Agent
- [ ] **AgentOnboardingView.swift** ou similaire
  - Recherche : Vue d'inscription/connexion agent
  - Objectif : Identifier le flow actuel
  - Pourquoi : On doit pouvoir y rediriger depuis la Home

### 🟡 IMPORTANT - Onboarding Seller
- [ ] **SellerOnboardingView.swift** ou similaire
  - Recherche : Vue d'inscription/connexion vendeur
  - Objectif : Identifier le flow actuel
  - Pourquoi : On doit pouvoir y rediriger depuis la Home

### 🟡 IMPORTANT - Auth
- [ ] **SupabaseRepository.swift**
  - Recherche : `isConfigured`, `currentUserID`, auth methods
  - Objectif : Comprendre l'état d'authentification
  - Pourquoi : La Home doit savoir si user connecté ou pas

- [ ] **SupabaseService.swift**
  - Recherche : `signInWithOTP`, `verifyOTP`, session management
  - Objectif : Comprendre le système d'auth
  - Pourquoi : Ne pas casser l'auth existante

---

## 🎯 QUESTIONS ARCHITECTURALES

### 1. Quel est le point d'entrée actuel de l'application ?
**Réponse :** ⏳ À déterminer
- [ ] Y a-t-il un fichier `@main struct StoreImmoApp` ?
- [ ] Quel est le premier écran affiché au lancement ?

### 2. Comment fonctionne la navigation actuelle ?
**Réponse :** ⏳ À déterminer
```
APP LAUNCH
    ↓
    ???
    ↓
Agent/Seller TabView
```

**Hypothèses :**
- Option A : Directement vers TabView (pas d'onboarding visible)
- Option B : Vers écran de choix Agent/Seller
- Option C : Vers écran d'authentification puis TabView

### 3. Y a-t-il déjà un système de routage/navigation principal ?
**Réponse :** ⏳ À déterminer
- [ ] NavigationStack au niveau racine ?
- [ ] if/else basé sur `isAuthenticated` ?
- [ ] if/else basé sur `selectedRole` ?

### 4. Où sont les TabView Agent et Seller ?
**Réponse :** ⏳ À déterminer
- [ ] Dans ContentView ?
- [ ] Dans des fichiers séparés (AgentTabView, SellerTabView) ?
- [ ] Imbriqués dans une vue parent ?

---

## 📐 ARCHITECTURE SOUHAITÉE (RAPPEL)

```
🚀 APP LAUNCH (@main)
     ↓
🏠 NOUVELLE HOME PUBLIQUE (si pas connecté)
     │
     ├─ 📰 Actualité
     ├─ 🏠 Biens
     ├─ 👤 Agents
     └─ 🔐 Choix parcours
           ↓
     ┌─────────────┴─────────────┐
     │                           │
  👨‍💼 AGENT              🏡 SELLER
     │                           │
Onboarding existant      Onboarding existant
     │                           │
TabView existant         TabView existant
(Découvrir/Opps/Msg/Cpt) (Dashboard/Msg/Cpt)
```

**SI DÉJÀ CONNECTÉ :**
```
APP LAUNCH
     ↓
Direct vers TabView correspondant au rôle
(pas de Home publique)
```

---

## 🛡️ RÈGLES DE SÉCURITÉ

### ❌ INTERDIT
1. Modifier AppViewModel sans nécessité absolue
2. Modifier AccountView ou vues associées
3. Modifier les TabView existants
4. Modifier les onboarding existants
5. Modifier SupabaseRepository/Service (sauf ajout queries publiques)
6. Modifier les modèles PropertyProject, Agent, Seller, etc.
7. Supprimer du code existant

### ✅ AUTORISÉ
1. Créer PublicHomeView.swift
2. Créer ActualityView.swift (pour actualités)
3. Créer PublicPropertyListView.swift (liste biens publique)
4. Créer PublicAgentListView.swift (liste agents publique)
5. Ajouter dans AppViewModel des propriétés pour Home (ex: `showPublicHome: Bool`)
6. Modifier le point d'entrée (@main) pour router vers Home SI pas connecté
7. Ajouter queries Supabase pour données publiques (fetch tous projets, tous agents)

---

## 📝 PROCHAINES ÉTAPES

### Phase 2 : Identification des fichiers manquants
1. Chercher `@main`
2. Chercher `ContentView`
3. Chercher `StoreImmoModels`
4. Chercher `AgentOnboarding`
5. Chercher `SellerOnboarding`
6. Chercher `SupabaseRepository`

### Phase 3 : Analyse complète
1. Dessiner l'architecture actuelle exacte
2. Identifier le point d'insertion optimal pour Home
3. Lister les fichiers à créer
4. Lister les modifications minimales à faire

### Phase 4 : Proposition au client
1. Présenter l'architecture actuelle (diagramme)
2. Présenter l'architecture proposée (diagramme)
3. Lister les risques identifiés
4. Demander validation AVANT modification

### Phase 5 : Implémentation (SEULEMENT après validation)
1. Créer PublicHomeView
2. Créer vues auxiliaires (actualité, biens, agents)
3. Ajouter queries publiques Supabase
4. Modifier point d'entrée
5. Tester chaque parcours
6. Rapport final

---

## 🚨 STOP - ATTENTE D'INSTRUCTIONS

**Je ne modifierai RIEN avant d'avoir :**
1. ✅ Identifié TOUS les fichiers critiques
2. ✅ Compris l'architecture actuelle complète
3. ✅ Présenté ma proposition au client
4. ✅ Obtenu validation explicite

**Prochaine action :** Chercher les fichiers manquants listés ci-dessus.

---

**Statut actuel :** 🟢 PHASE 1 TERMINÉE  
**Fichiers identifiés :** 3 / 7+ (ContentView trouvé !)  
**Prêt à modifier :** ⏳ EN ATTENTE ANALYSE COMPLÈTE  
**Raison :** Analyse de ContentView en cours

