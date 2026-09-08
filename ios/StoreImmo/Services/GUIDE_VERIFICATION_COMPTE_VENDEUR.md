# ✅ GUIDE DE VÉRIFICATION — COMPTE VENDEUR HARMONISÉ

## 🎯 ÉTAPE 1 : COMPILATION

### 1. Ouvrir Xcode
```bash
# Si vous êtes dans le Terminal, ouvrez le projet :
open StoreImmo.xcodeproj
# ou
open StoreImmo.xcworkspace
```

### 2. Compiler l'application
1. Sélectionner un simulateur iOS (iPhone 15 Pro recommandé)
2. Appuyer sur **⌘ + B** (ou Product > Build)
3. Vérifier qu'il n'y a **aucune erreur de compilation**

### 3. En cas d'erreur
Si vous rencontrez des erreurs, vérifiez :
- [ ] `AccountView.swift` est bien dans le projet
- [ ] Les imports sont corrects (`SwiftUI`, `StoreKit`)
- [ ] Les vues suivantes existent et sont accessibles :
  - `PersonalInfoView`
  - `NotificationSettingsView`
  - `PrivacySettingsView`
  - `ReportProblemView`
  - `MyRequestsView`
  - `FAQView`

---

## 🧪 ÉTAPE 2 : TESTS FONCTIONNELS

### A. Tester le Compte VENDEUR

#### 1. Connexion en tant que vendeur
1. Lancer l'application (⌘ + R)
2. Se connecter avec un compte **vendeur**
3. Naviguer vers l'onglet **"Compte"** (dernier onglet)

#### 2. Vérifier l'en-tête du profil
- [ ] La photo de profil est affichée (icône par défaut)
- [ ] Le prénom et nom sont affichés correctement
- [ ] L'email est affiché sous le nom
- [ ] Le téléphone est affiché (si renseigné)

#### 3. Vérifier "Mon profil"
- [ ] Cliquer sur **"Informations personnelles"**
- [ ] La vue `PersonalInfoView` s'ouvre
- [ ] Les informations du vendeur sont affichées
- [ ] Fermer la vue (bouton "Fermer")

#### 4. Vérifier "Mes projets"
- [ ] La section **"Mes projets"** est visible
- [ ] L'icône 🏠 est affichée
- [ ] Le texte **"Mes biens"** est affiché
- [ ] Le nombre de projets est correct (ex: "3 projet(s)")
- [ ] Cliquer sur **"Voir"**
- [ ] L'application redirige vers l'onglet **Dashboard**
- [ ] Revenir sur l'onglet **"Compte"**

#### 5. Vérifier "Paramètres"
- [ ] Cliquer sur **"Notifications"**
- [ ] La vue s'ouvre correctement
- [ ] Fermer la vue
- [ ] Cliquer sur **"Confidentialité"**
- [ ] La vue s'ouvre correctement
- [ ] Fermer la vue

#### 6. Vérifier "Aide et support"
- [ ] Cliquer sur **"Signaler un problème"**
- [ ] La vue `ReportProblemView` s'ouvre
- [ ] Remplir le formulaire :
  - Catégorie : Problème technique
  - Sujet : Test vendeur
  - Message : Test d'envoi depuis le compte vendeur
- [ ] Envoyer le ticket
- [ ] Vérifier que le ticket est enregistré dans Supabase
- [ ] Vérifier que l'email est envoyé à **support@storeimmo.com**
- [ ] Cliquer sur **"Mes demandes"**
- [ ] Le ticket apparaît dans l'historique
- [ ] Cliquer sur **"Questions fréquentes"**
- [ ] La vue FAQ s'ouvre correctement

#### 7. Vérifier "À propos"
- [ ] Cliquer sur **"Conditions d'utilisation"** (TODO actuellement)
- [ ] Cliquer sur **"Politique de confidentialité"** (TODO actuellement)
- [ ] Cliquer sur **"Noter l'application"**
- [ ] L'alerte système iOS apparaît (sur device réel uniquement)
- [ ] La **version** de l'app est affichée en bas

#### 8. Vérifier "Se déconnecter"
- [ ] Cliquer sur **"Se déconnecter"**
- [ ] Une alerte de confirmation apparaît
- [ ] Confirmer la déconnexion
- [ ] L'utilisateur est redirigé vers l'écran de connexion

---

### B. Tester le Compte AGENT

#### 1. Connexion en tant qu'agent
1. Se connecter avec un compte **agent**
2. Naviguer vers l'onglet **"Compte"**

#### 2. Vérifier l'en-tête du profil
- [ ] La photo de profil est affichée (si elle existe dans Supabase)
- [ ] Si pas de photo, l'icône par défaut est affichée
- [ ] Le prénom et nom sont affichés correctement
- [ ] L'email est affiché
- [ ] Le téléphone est affiché

#### 3. Vérifier "Mon profil"
- [ ] Cliquer sur **"Informations personnelles"**
- [ ] La vue `PersonalInfoView` s'ouvre
- [ ] Les informations de l'agent sont affichées (avec agence, description, etc.)
- [ ] Le bouton **"Modifier"** est disponible pour l'agent
- [ ] Fermer la vue

#### 4. Vérifier "Mes projets"
- [ ] La section **"Mes projets"** est visible
- [ ] **Première sous-section : "Opportunités"**
  - Icône ✨ affichée
  - Nombre d'opportunités correct (ex: "12 projet(s)")
  - Cliquer sur **"Voir"** → Redirige vers l'onglet **Opportunities**
- [ ] Revenir sur l'onglet **"Compte"**
- [ ] **Deuxième sous-section : "Mes mandats"**
  - Icône 📄 affichée
  - Nombre de mandats correct (ex: "5 mandat(s)")
  - Cliquer sur **"Voir"** → Redirige vers l'onglet **Mandates**
- [ ] Revenir sur l'onglet **"Compte"**

#### 5. Vérifier les autres sections
- [ ] Tester **"Paramètres"** (Notifications, Confidentialité)
- [ ] Tester **"Aide et support"** (Signaler un problème, Mes demandes, FAQ)
- [ ] Tester **"À propos"** (CGU, Confidentialité, Noter l'app, Version)
- [ ] Tester **"Se déconnecter"**

---

## 🔍 ÉTAPE 3 : VÉRIFICATIONS SUPABASE

### 1. Vérifier l'envoi des tickets de support

#### Dans Supabase Studio :
1. Ouvrir la table **`support_tickets`**
2. Vérifier que les tickets créés depuis l'app sont enregistrés :
   ```sql
   SELECT * FROM support_tickets
   ORDER BY created_at DESC
   LIMIT 10;
   ```
3. Colonnes attendues :
   - `id` (UUID)
   - `user_id` (UUID de l'utilisateur)
   - `user_role` (seller ou agent)
   - `category` (ex: "Problème technique")
   - `subject` (ex: "Test vendeur")
   - `message` (ex: "Test d'envoi depuis le compte vendeur")
   - `status` (ex: "Nouvelle")
   - `created_at` (timestamp)

#### Dans votre boîte mail support@storeimmo.com :
1. Ouvrir la boîte de réception
2. Vérifier qu'un email a été reçu avec :
   - **Objet :** [STORE IMMO] Nouveau ticket support - [Catégorie]
   - **Contenu :**
     - Sujet du ticket
     - Message du ticket
     - Rôle de l'utilisateur (Vendeur ou Agent)
     - Email de l'utilisateur
     - Date de création

---

## 🎨 ÉTAPE 4 : VÉRIFICATIONS VISUELLES

### 1. Design général
- [ ] L'en-tête de profil est **élégant et épuré**
- [ ] Les sections sont **bien espacées**
- [ ] Les icônes sont **cohérentes** avec le reste de l'app
- [ ] Les couleurs sont **cohérentes** avec StoreImmo
- [ ] Les polices sont **cohérentes** avec le reste de l'app

### 2. Cohérence vendeur/agent
- [ ] Les deux comptes ont **exactement la même structure**
- [ ] Les intitulés de sections sont **identiques**
- [ ] Les icônes sont **identiques**
- [ ] Seules les **données spécifiques** changent :
  - Vendeur → "Mes biens"
  - Agent → "Opportunités" + "Mes mandats"

### 3. Responsive
- [ ] Tester sur **iPhone SE** (petit écran)
- [ ] Tester sur **iPhone 15 Pro Max** (grand écran)
- [ ] Tester sur **iPad** (si l'app supporte iPad)
- [ ] Vérifier que tout est lisible et bien aligné

---

## ⚠️ ÉTAPE 5 : VÉRIFICATION DES NON-MODIFICATIONS

### Vérifier que le compte AGENT n'a PAS été cassé
- [ ] L'agent peut toujours voir son profil complet
- [ ] L'agent peut toujours modifier ses informations
- [ ] L'agent peut toujours accéder à ses opportunités
- [ ] L'agent peut toujours accéder à ses mandats
- [ ] Toutes les fonctionnalités agent fonctionnent normalement

### Vérifier que la navigation n'a PAS été modifiée
- [ ] L'onglet "Dashboard" (vendeur) fonctionne
- [ ] L'onglet "Opportunities" (agent) fonctionne
- [ ] L'onglet "Mandates" fonctionne
- [ ] L'onglet "Messages" fonctionne
- [ ] La navigation entre onglets fonctionne correctement

### Vérifier que le support fonctionne toujours
- [ ] Les tickets sont enregistrés dans Supabase
- [ ] Les emails sont envoyés à support@storeimmo.com
- [ ] L'historique des tickets est visible dans "Mes demandes"
- [ ] Le système de support fonctionne pour vendeur ET agent

---

## ✅ CHECKLIST FINALE

### Compilation
- [ ] ✅ Aucune erreur de compilation
- [ ] ✅ Aucun warning critique

### Tests vendeur
- [ ] ✅ En-tête de profil affiché correctement
- [ ] ✅ Section "Mes biens" fonctionnelle
- [ ] ✅ Navigation vers Dashboard fonctionne
- [ ] ✅ Support fonctionne (tickets + emails)
- [ ] ✅ Déconnexion fonctionne

### Tests agent
- [ ] ✅ En-tête de profil + photo affichés correctement
- [ ] ✅ Section "Opportunités" fonctionnelle
- [ ] ✅ Section "Mes mandats" fonctionnelle
- [ ] ✅ Navigation vers Opportunities/Mandates fonctionne
- [ ] ✅ Toutes les fonctionnalités agent intactes

### Design
- [ ] ✅ Design cohérent StoreImmo
- [ ] ✅ Cohérence parfaite vendeur/agent
- [ ] ✅ Responsive sur tous les écrans

### Support
- [ ] ✅ Tickets enregistrés dans Supabase
- [ ] ✅ Emails reçus sur support@storeimmo.com
- [ ] ✅ Historique visible dans "Mes demandes"

---

## 🎉 SI TOUS LES TESTS PASSENT

**FÉLICITATIONS ! 🚀**

Le compte vendeur est maintenant **parfaitement harmonisé** avec le compte agent.

**Résultat final :**
- ✅ Même architecture
- ✅ Même design
- ✅ Même ordre des sections
- ✅ Données adaptées au rôle
- ✅ Compte agent intact
- ✅ Support fonctionnel
- ✅ Application stable

---

## 🐛 EN CAS DE PROBLÈME

### Erreur de compilation
1. Vérifier que tous les imports sont corrects
2. Vérifier que `AppViewModel` est bien accessible
3. Nettoyer le build : **⌘ + Shift + K**
4. Rebuild : **⌘ + B**

### Erreur à l'exécution
1. Vérifier les logs dans la console Xcode
2. Vérifier que `viewModel.selectedRole` n'est pas `nil`
3. Vérifier que les propriétés utilisées existent dans `AppViewModel`

### Problème de navigation
1. Vérifier que `viewModel.sellerTab` et `viewModel.agentTab` sont bien définis
2. Vérifier que les onglets sont bien liés dans la navigation principale

### Problème de support
1. Vérifier que la table `support_tickets` existe dans Supabase
2. Vérifier que l'Edge Function `send-support-email` est déployée
3. Vérifier que le trigger PostgreSQL est actif
4. Vérifier les logs Supabase pour voir les erreurs

---

**Bonne chance ! 🚀**
