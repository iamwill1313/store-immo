# Transformation de l'onglet "Profil" en "Compte"

## ✅ Modifications effectuées

### 1. Modèles et Types (StoreImmoModels.swift)

#### Enums mis à jour :
- `AppTabSeller.profile` → `AppTabSeller.account`
- `AppTabAgent.profile` → `AppTabAgent.account`

#### Nouveaux modèles ajoutés :
- `SupportCategory` : Catégories de problèmes pour le support
  - Problème technique
  - Abonnement
  - Paiement
  - Candidature
  - Projet / bien immobilier
  - Compte et connexion
  - Autre

- `SupportTicketStatus` : Statuts des tickets
  - Nouvelle
  - En cours
  - Résolue

- `SupportTicket` : Modèle complet pour les tickets de support
  - ID, catégorie, sujet, message
  - Statut, dates de création et mise à jour

- `FAQItem` : Questions fréquentes
  - Question, réponse, catégorie

- `NotificationSettings` : Paramètres de notifications
  - Projets, candidatures, messages, abonnement, général

### 2. AppViewModel

#### Nouvelles propriétés :
```swift
var supportTickets: [SupportTicket] = []
var notificationSettings: NotificationSettings = NotificationSettings()
```

#### Nouvelles méthodes :
- `submitSupportTicket(category:subject:message:)` : Envoie un ticket de support
- `loadSupportTickets()` : Charge les tickets depuis Supabase

### 3. SupabaseRepository

#### Nouvelles méthodes :
- `saveSupportTicket(ticket:userRole:appVersion:)` : Enregistre un ticket dans Supabase
- `fetchSupportTickets()` : Récupère les tickets de l'utilisateur

#### Nouveau DTO :
- `SupportTicketRow` : Structure pour la sérialisation Supabase

### 4. Nouvelles Vues créées

#### AccountView.swift
Vue principale du compte avec sections :
- 👤 Mon profil
  - Informations personnelles
- ⚙️ Paramètres
  - Notifications
  - Confidentialité
- 🆘 Aide et support
  - Signaler un problème
  - Mes demandes
  - Questions fréquentes
- ℹ️ À propos
  - Conditions d'utilisation
  - Politique de confidentialité
  - Noter l'application
  - Version de l'application
- 🚪 Déconnexion

#### PersonalInfoView.swift
- Affiche et permet la modification des informations personnelles
- **Agent** : Photo de profil, prénom, nom, email, ville, agence, téléphone, description
- **Vendeur** : Prénom, nom, email, téléphone (lecture seule)
- Upload/suppression de photo pour les agents
- Mode édition pour les agents

#### NotificationSettingsView.swift
- Paramètres de notifications par catégorie
- Adapté selon le rôle (vendeur/agent)
- Lien vers les paramètres système
- Catégories :
  - Projets / Biens
  - Candidatures
  - Messages
  - Abonnement (agents uniquement)
  - Notifications générales

#### PrivacySettingsView.swift
- Visibilité du profil (agents)
- Gestion des données personnelles
  - Télécharger mes données
  - Supprimer mon compte
- Lien vers la politique de confidentialité

#### ReportProblemView.swift
- Formulaire de signalement de problème
- Sélection de catégorie
- Description détaillée
- Option d'ajout de capture d'écran
- Informations techniques automatiques :
  - Rôle utilisateur
  - Version de l'application
  - Modèle d'appareil
- Envoi vers Supabase avec confirmation

#### MyRequestsView.swift
- Liste des tickets de support de l'utilisateur
- État vide si aucun ticket
- Vue détaillée de chaque ticket
- Badges de statut colorés
- Affichage des dates de création/mise à jour

#### FAQView.swift
- Questions fréquentes adaptées au rôle
- Recherche dans les questions/réponses
- Liste extensible (accordion)
- Badges de catégorie
- **FAQ Vendeur** : 6 questions sur projets, agents, messages, compte
- **FAQ Agent** : 7 questions sur abonnement, candidatures, profil, recherche

### 5. Base de données Supabase

#### Nouvelle table : support_tickets
Voir `SETUP_SUPPORT_TICKETS.md` pour le SQL complet.

Colonnes :
- `id` : UUID primary key
- `user_id` : Référence vers auth.users
- `category` : Text (catégorie du problème)
- `subject` : Text (sujet)
- `message` : Text (description)
- `status` : Text (Nouvelle/En cours/Résolue)
- `user_role` : Text (seller/agent)
- `app_version` : Text
- `created_at` : Timestamptz
- `updated_at` : Timestamptz

Fonctionnalités :
- RLS activé (utilisateurs voient uniquement leurs tickets)
- Index sur user_id, status, created_at
- Trigger pour updated_at automatique
- Politiques optionnelles pour admins

## ⚠️ Actions restantes

### 1. Intégration dans ContentView
**IMPORTANT** : Vous devez trouver le fichier ContentView (ou la vue principale qui affiche les TabView) et :

1. Remplacer toutes les références à `.profile` par `.account`
2. Remplacer l'ancienne vue de profil par `AccountView()`

Exemple de ce à quoi devrait ressembler le TabView pour un vendeur :
```swift
TabView(selection: $viewModel.sellerTab) {
    DashboardView()
        .tabItem {
            Label("Tableau de bord", systemImage: "square.grid.2x2")
        }
        .tag(AppTabSeller.dashboard)
    
    MandatesView()
        .tabItem {
            Label("Mandats", systemImage: "doc.text")
        }
        .tag(AppTabSeller.mandates)
    
    MessagesView()
        .tabItem {
            Label("Messages", systemImage: "message")
        }
        .badge(viewModel.unreadConversationCount)
        .tag(AppTabSeller.messages)
    
    AccountView()  // ← CHANGEMENT ICI
        .tabItem {
            Label("Compte", systemImage: "person.circle")  // ← ET ICI
        }
        .tag(AppTabSeller.account)  // ← ET ICI
}
```

### 2. Méthodes de sauvegarde des modifications de profil

Dans `PersonalInfoView.swift`, la méthode `saveAgentChanges()` est marquée TODO.
Vous devez ajouter dans `SupabaseRepository.swift` :

```swift
func updateAgentProfile(
    firstName: String,
    lastName: String,
    city: String,
    agency: String,
    phone: String,
    description: String
) async -> Bool {
    // Implémenter la mise à jour
}
```

Et appeler cette méthode depuis `AppViewModel`.

### 3. Liens vers documents légaux

Dans `AccountView.swift` et `PrivacySettingsView.swift`, remplacez les placeholders par vos vraies URLs :
- Conditions d'utilisation
- Politique de confidentialité

### 4. Mise à jour des paramètres de notifications

Les paramètres de notifications sont stockés localement. Pour les persister, ajoutez dans `AppViewModel` :

```swift
// Dans saveSession()
d.set(notificationSettings.projectsEnabled, forKey: "si_notif_projects")
d.set(notificationSettings.applicationsEnabled, forKey: "si_notif_applications")
// etc.

// Dans loadPersistedSession()
notificationSettings.projectsEnabled = d.bool(forKey: "si_notif_projects")
// etc.
```

### 5. Création de la table Supabase

Exécutez le SQL dans `SETUP_SUPPORT_TICKETS.md` dans l'éditeur SQL de Supabase.

### 6. Tests à effectuer

1. ✅ **Navigation** : Vérifier que l'onglet "Compte" s'affiche correctement
2. ✅ **Profil vendeur** : Affichage correct des informations
3. ✅ **Profil agent** : Affichage + édition + photo
4. ✅ **Notifications** : Toggle fonctionnels
5. ✅ **Confidentialité** : Navigation et liens
6. ✅ **Support** : Création de ticket
7. ✅ **Mes demandes** : Liste et détails
8. ✅ **FAQ** : Recherche et expansion
9. ✅ **Déconnexion** : Confirmation et action
10. ✅ **Adaptation rôle** : Différences vendeur/agent

## 📋 Différences vendeur/agent

### Vendeur
- ✅ Informations personnelles en lecture seule
- ✅ Pas de photo de profil
- ✅ Pas d'abonnement dans les notifications
- ✅ Catégories de support adaptées (pas "Abonnement", "Paiement")
- ✅ FAQ orientée vendeur

### Agent
- ✅ Informations modifiables
- ✅ Photo de profil uploadable/supprimable
- ✅ Paramètres d'abonnement
- ✅ Toutes les catégories de support
- ✅ FAQ orientée agent
- ✅ Visibilité du profil dans paramètres de confidentialité

## 🎯 Résumé technique

**Fichiers créés** : 8
- AccountView.swift
- PersonalInfoView.swift
- NotificationSettingsView.swift
- PrivacySettingsView.swift
- ReportProblemView.swift
- MyRequestsView.swift
- FAQView.swift
- SETUP_SUPPORT_TICKETS.md

**Fichiers modifiés** : 3
- StoreImmoModels.swift
- AppViewModel.swift
- SupabaseRepository.swift

**Nouvelles tables Supabase** : 1
- support_tickets

**Nouveaux types** : 5
- SupportCategory
- SupportTicketStatus
- SupportTicket
- FAQItem
- NotificationSettings

**Nouvelles méthodes AppViewModel** : 2
- submitSupportTicket()
- loadSupportTickets()

**Nouvelles méthodes Supabase** : 2
- saveSupportTicket()
- fetchSupportTickets()

## 🔍 Notes importantes

1. **Design cohérent** : Toutes les vues utilisent le design système d'iOS avec Form, List, NavigationStack
2. **Accessibilité** : Labels, icônes et textes descriptifs partout
3. **Sécurité** : RLS sur support_tickets, pas d'exposition d'infos sensibles
4. **Performance** : Index sur les colonnes fréquemment requêtées
5. **UX** : Confirmations, états vides, messages d'erreur, badges de statut
6. **Responsive** : Adapté aux différentes tailles d'écran iOS
7. **Modularité** : Chaque vue est indépendante et réutilisable
