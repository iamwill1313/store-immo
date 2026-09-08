# 🚀 Script de correction rapide

## Problème identifié

L'erreur `Type 'ShapeStyle' has no member 'accent'` apparaît dans plusieurs fichiers.

## Solution : Recherche/Remplacement global dans Xcode

### Étape 1 : Ouvrir Find and Replace
- Appuyez sur `⌘⇧F` (Command + Shift + F)

### Étape 2 : Configurer la recherche
Dans la barre de recherche en haut :

**Find :**
```
.foregroundStyle(.accent)
```

**Replace :**
```
.foregroundStyle(Color.accentColor)
```

### Étape 3 : Limiter la recherche
- Cliquez sur "In Workspace" → Choisissez un dossier spécifique si possible
- Ou cochez manuellement les fichiers suivants :
  - ✅ AccountView.swift (déjà corrigé)
  - ✅ MyRequestsView.swift
  - ✅ FAQView.swift
  - ✅ ReportProblemView.swift
  - ✅ PersonalInfoView.swift
  - ✅ NotificationSettingsView.swift
  - ✅ PrivacySettingsView.swift

### Étape 4 : Preview et Replace
1. Cliquez sur "Replace" pour voir les occurrences
2. Vérifiez les preview (normalement 5-7 occurrences)
3. Cliquez sur "Replace All"

### Étape 5 : Build
```bash
⌘⇧K  # Clean
⌘B   # Build
```

## Alternative manuelle

Si vous préférez corriger manuellement, voici les fichiers et lignes à corriger :

### MyRequestsView.swift
```swift
// Ligne ~45
Image(systemName: ticket.category.symbolName)
    .foregroundStyle(Color.accentColor)  // ← Changé

// Ligne ~87
.foregroundStyle(Color.accentColor)  // ← Changé
```

### FAQView.swift
```swift
// Ligne ~104
Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
    .font(.caption.weight(.semibold))
    .foregroundStyle(Color.accentColor)  // ← Changé
```

### ReportProblemView.swift
Vérifiez et remplacez si présent.

### PersonalInfoView.swift
Vérifiez et remplacez si présent.

## Vérification après correction

Dans Xcode, vérifiez :
- ✅ Aucune erreur rouge dans la liste des erreurs
- ✅ Build réussit (`⌘B`)
- ✅ Aucun "Type 'ShapeStyle' has no member 'accent'"

## Note technique

`.accent` est disponible depuis iOS 17.
Pour compatibilité iOS 15+, utilisez `Color.accentColor`.

Si votre app cible uniquement iOS 17+, vous pouvez garder `.accent` 
et ajouter dans votre target : iOS Deployment Target = 17.0

---

**Durée estimée : 2 minutes**
