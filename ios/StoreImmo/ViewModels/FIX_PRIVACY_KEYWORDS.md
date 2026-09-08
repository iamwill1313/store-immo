# 🔧 Correction erreur mots-clés réservés (public/private)

## ❌ Erreur détectée

```
error: Keyword 'public' cannot be used as an identifier here
        case public = "Public"
             ^

error: Keyword 'private' cannot be used as an identifier here
        case private = "Privé"
```

**Fichier concerné :** `PrivacySettingsView.swift`

## 🔍 Cause

En Swift, `public` et `private` sont des mots-clés réservés (modificateurs d'accès).
Ils ne peuvent pas être utilisés comme noms de case dans un enum.

## ✅ Solution

### Dans PrivacySettingsView.swift

**Cherchez cet enum (vers ligne 10-20) :**

```swift
// ❌ INCORRECT
enum ProfileVisibility: String, CaseIterable, Identifiable {
    case public = "Public"      // ← Erreur !
    case private = "Privé"      // ← Erreur !
    
    var id: String { rawValue }
}
```

**Remplacez par :**

```swift
// ✅ CORRECT
enum ProfileVisibility: String, CaseIterable, Identifiable {
    case publicProfile = "Public"
    case privateProfile = "Privé"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .publicProfile:
            return "Votre profil est visible par tous les utilisateurs"
        case .privateProfile:
            return "Votre profil n'est visible que par vos contacts"
        }
    }
}
```

**Et plus bas dans le fichier, remplacez les références :**

```swift
// ❌ AVANT
case .public:
    return "Votre profil est visible par tous les utilisateurs"
case .private:
    return "Votre profil n'est visible que par vos contacts"

// ✅ APRÈS
case .publicProfile:
    return "Votre profil est visible par tous les utilisateurs"
case .privateProfile:
    return "Votre profil n'est visible que par vos contacts"
```

## 📝 Fichier complet corrigé

Voici le code complet de `PrivacySettingsView.swift` avec la correction :

```swift
import SwiftUI

struct PrivacySettingsView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var profileVisibility: ProfileVisibility = .publicProfile
    
    enum ProfileVisibility: String, CaseIterable, Identifiable {
        case publicProfile = "Public"
        case privateProfile = "Privé"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .publicProfile:
                return "Votre profil est visible par tous les utilisateurs"
            case .privateProfile:
                return "Votre profil n'est visible que par vos contacts"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if viewModel.selectedRole == .agent {
                    Section {
                        Picker("Visibilité du profil", selection: $profileVisibility) {
                            ForEach(ProfileVisibility.allCases) { visibility in
                                Text(visibility.rawValue).tag(visibility)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text(profileVisibility.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Visibilité du profil")
                    } footer: {
                        Text("En mode public, les vendeurs peuvent voir votre profil complet lorsque vous postulez.")
                    }
                }
                
                Section {
                    NavigationLink {
                        dataManagementView
                    } label: {
                        Label("Gestion des données", systemImage: "folder")
                    }
                } header: {
                    Text("Données personnelles")
                } footer: {
                    Text("Consultez et gérez vos données personnelles.")
                }
                
                Section {
                    Link(destination: URL(string: "https://storeimmo.fr/privacy")!) {
                        HStack {
                            Label("Politique de confidentialité", systemImage: "hand.raised.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Consultez notre politique de confidentialité pour plus d'informations sur la collecte et l'utilisation de vos données.")
                }
            }
            .navigationTitle("Confidentialité")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Terminé") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var dataManagementView: some View {
        Form {
            Section {
                Text("Vous pouvez demander une copie de toutes vos données personnelles ou demander leur suppression.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Button {
                    requestDataExport()
                } label: {
                    Label("Télécharger mes données", systemImage: "arrow.down.circle")
                }
                
                Button(role: .destructive) {
                    requestDataDeletion()
                } label: {
                    Label("Supprimer mon compte", systemImage: "trash")
                }
            } footer: {
                Text("La suppression de votre compte est irréversible. Toutes vos données seront définitivement supprimées.")
            }
        }
        .navigationTitle("Gestion des données")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func requestDataExport() {
        viewModel.appStatusMessage = "Demande d'export de données enregistrée. Vous recevrez un email sous 48h."
    }
    
    private func requestDataDeletion() {
        viewModel.appStatusMessage = "Demande de suppression enregistrée. Contactez le support pour confirmer."
    }
}

#Preview {
    @Previewable @State var viewModel = AppViewModel()
    PrivacySettingsView()
        .environment(viewModel)
}
```

## 🎯 Résumé des changements

| Avant (❌) | Après (✅) |
|-----------|----------|
| `case public` | `case publicProfile` |
| `case private` | `case privateProfile` |
| `.public` | `.publicProfile` |
| `.private` | `.privateProfile` |

## 📋 Checklist

- [ ] Ouvrir `PrivacySettingsView.swift`
- [ ] Remplacer `case public` par `case publicProfile`
- [ ] Remplacer `case private` par `case privateProfile`
- [ ] Remplacer tous les `.public` par `.publicProfile`
- [ ] Remplacer tous les `.private` par `.privateProfile`
- [ ] `⌘B` pour vérifier que ça compile

## ⏱️ Temps estimé : 1 minute

---

**Alternative rapide :** Copiez-collez le code complet ci-dessus pour remplacer 
tout le contenu de `PrivacySettingsView.swift`
