# 🔧 Configuration Supabase - StoreImmo

## ⚠️ IMPORTANT : Fichier Config.swift requis

Ce projet nécessite un fichier `Config.swift` contenant vos identifiants Supabase.

**Ce fichier n'est PAS inclus dans le dépôt Git pour des raisons de sécurité.**

---

## 📋 Configuration initiale (première fois)

### Étape 1 : Récupérer vos identifiants Supabase

1. Connectez-vous à [supabase.com](https://supabase.com)
2. Sélectionnez votre projet StoreImmo
3. Allez dans **Project Settings** (icône ⚙️)
4. Cliquez sur **API** dans le menu latéral
5. Notez ces deux valeurs :
   - **Project URL** (ex: `https://abcdefgh.supabase.co`)
   - **anon/public key** (longue chaîne commençant par `eyJ...`)

### Étape 2 : Créer Config.swift

**Option A : Via Xcode (recommandé)**

1. Dans Xcode, faites un clic droit sur le dossier racine du projet
2. **New File...** → **Swift File**
3. Nommez-le **exactement** : `Config.swift`
4. Assurez-vous qu'il est bien ajouté au target "StoreImmo"

**Option B : Via le terminal**

```bash
cd /chemin/vers/store-immo
cp Config.example.swift Config.swift
```

### Étape 3 : Remplir Config.swift

Ouvrez `Config.swift` et remplacez les placeholders :

```swift
import Foundation

enum Config {
    static let allValues: [String: String] = [
        "EXPO_PUBLIC_SUPABASE_URL": "https://votre-projet.supabase.co",  // ← ICI
        "EXPO_PUBLIC_SUPABASE_ANON_KEY": "votre-clé-anon"  // ← ICI
    ]
}
```

**Exemple avec de vraies valeurs :**

```swift
import Foundation

enum Config {
    static let allValues: [String: String] = [
        "EXPO_PUBLIC_SUPABASE_URL": "https://xkcdabcdefgh.supabase.co",
        "EXPO_PUBLIC_SUPABASE_ANON_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhrc2RhYmNkZWZnaCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjIzMDAwMDAwLCJleHAiOjE5Mzg1NzYwMDB9.example-signature"
    ]
}
```

### Étape 4 : Vérifier .gitignore

Assurez-vous que `Config.swift` est bien dans `.gitignore` :

```bash
# Ouvrez .gitignore et vérifiez ces lignes :
Config.swift
ios/Config.swift
```

✅ **C'est déjà configuré dans ce projet.**

### Étape 5 : Build

1. Dans Xcode : `⌘ + B` (Build)
2. Vérifiez qu'il n'y a pas d'erreur de compilation
3. Si tout va bien : `⌘ + R` (Run)

---

## 🔐 Sécurité

### ✅ À FAIRE
- ✅ Garder `Config.swift` dans `.gitignore`
- ✅ Ne **JAMAIS** commit `Config.swift` avec de vraies clés
- ✅ Utiliser des clés différentes pour dev/staging/prod
- ✅ Régénérer les clés si elles sont accidentellement exposées

### ❌ NE PAS FAIRE
- ❌ Commit `Config.swift` dans Git
- ❌ Partager vos clés par email/chat
- ❌ Hardcoder les clés directement dans d'autres fichiers
- ❌ Utiliser les mêmes clés en production et développement

---

## 🛠️ Dépannage

### Erreur : "Build input file cannot be found: Config.swift"

**Cause :** Le fichier `Config.swift` n'existe pas.

**Solution :** Suivez les étapes 1-3 ci-dessus.

---

### Erreur : "Supabase URL or anon key missing"

**Cause :** Les valeurs dans `Config.swift` sont toujours des placeholders.

**Solution :** 
1. Ouvrez `Config.swift`
2. Remplacez `"https://your-project.supabase.co"` par votre vraie URL
3. Remplacez `"your-anon-key-here"` par votre vraie clé

---

### Erreur : "Cannot find 'Config' in scope"

**Cause :** `Config.swift` n'est pas ajouté au target Xcode.

**Solution :**
1. Sélectionnez `Config.swift` dans le navigateur
2. File Inspector (⌥⌘1)
3. Section "Target Membership"
4. Cochez votre target principal

---

### L'app démarre mais affiche "Mode démo"

**Cause :** Supabase n'est pas configuré correctement.

**Solution :**
1. Vérifiez que `Config.swift` contient les bonnes valeurs
2. Vérifiez que les clés sont bien copiées (pas d'espaces supplémentaires)
3. Dans la console Xcode, cherchez : `"Supabase URL or anon key missing"`

---

## 📦 Partage du projet

### Pour les nouveaux développeurs

Envoyez-leur ces instructions :

1. Clone le dépôt
   ```bash
   git clone [url-du-repo]
   cd store-immo
   ```

2. Créez `Config.swift` (voir Étape 2-3 ci-dessus)

3. Demandez les identifiants Supabase au chef de projet
   - **Ne jamais** les envoyer par email non chiffré
   - Utilisez un gestionnaire de mots de passe partagé (1Password, etc.)

4. Build le projet
   ```bash
   open StoreImmo.xcodeproj
   # Puis Cmd+B dans Xcode
   ```

---

## 🔄 Changement de projet Supabase

Si vous devez pointer vers un autre projet Supabase :

1. Récupérez les nouvelles clés (voir Étape 1)
2. Ouvrez `Config.swift`
3. Remplacez les valeurs
4. Clean build : `⌘⇧K`
5. Rebuild : `⌘B`

---

## 📚 Fichiers de configuration

| Fichier | Description | Versionné Git |
|---------|-------------|---------------|
| `Config.swift` | **Identifiants réels** | ❌ NON (gitignore) |
| `Config.example.swift` | Template avec placeholders | ✅ OUI |
| `.gitignore` | Exclusions Git | ✅ OUI |

---

## ✅ Checklist

Avant de pouvoir build le projet :

- [ ] J'ai mes identifiants Supabase (URL + anon key)
- [ ] J'ai créé `Config.swift`
- [ ] J'ai rempli `Config.swift` avec mes vraies clés
- [ ] `Config.swift` est bien dans `.gitignore`
- [ ] Le fichier est ajouté au target Xcode
- [ ] Build réussit (⌘B)

---

**Besoin d'aide ?** Consultez la documentation Supabase : https://supabase.com/docs

**Date de création :** 13 septembre 2026
