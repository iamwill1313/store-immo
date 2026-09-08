# 🔧 Corrections des erreurs de compilation

## Erreur : Type 'ShapeStyle' has no member 'accent'

Cette erreur se produit parce que `.accent` n'est disponible que depuis iOS 17. 
Pour compatibilité iOS 15+, utilisez `Color.accentColor`.

## Fichiers à corriger

### 1. AccountView.swift

**Ligne ~205 :**
```swift
// ❌ AVANT
.foregroundStyle(.accent)

// ✅ APRÈS
.foregroundStyle(Color.accentColor)
```

**Ligne ~235 :**
```swift
// ❌ AVANT
.foregroundStyle(.accent)

// ✅ APRÈS
.foregroundStyle(Color.accentColor)
```

**Recherche/Remplacement dans AccountView.swift :**
- Cherchez : `.foregroundStyle(.accent)`
- Remplacez par : `.foregroundStyle(Color.accentColor)`

---

### 2. MyRequestsView.swift

**Ligne ~45 :**
```swift
// ❌ AVANT
Image(systemName: ticket.category.symbolName)
    .foregroundStyle(.accent)

// ✅ APRÈS
Image(systemName: ticket.category.symbolName)
    .foregroundStyle(Color.accentColor)
```

**Ligne ~87 :**
```swift
// ❌ AVANT
.foregroundStyle(.accent)

// ✅ APRÈS
.foregroundStyle(Color.accentColor)
```

---

### 3. FAQView.swift

**Ligne ~104 :**
```swift
// ❌ AVANT
Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
    .font(.caption.weight(.semibold))
    .foregroundStyle(.accent)

// ✅ APRÈS
Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
    .font(.caption.weight(.semibold))
    .foregroundStyle(Color.accentColor)
```

---

### 4. ReportProblemView.swift

Vérifiez s'il y a des `.foregroundStyle(.accent)` et remplacez par `.foregroundStyle(Color.accentColor)`

---

### 5. PersonalInfoView.swift

Vérifiez s'il y a des `.foregroundStyle(.accent)` et remplacez par `.foregroundStyle(Color.accentColor)`

---

## Méthode rapide : Recherche/Remplacement globale

Dans Xcode :

1. **Ouvrir Find and Replace** : `⌘⇧F`
2. **Dans "Find"** : `.foregroundStyle(.accent)`
3. **Dans "Replace"** : `.foregroundStyle(Color.accentColor)`
4. **Scope** : Sélectionnez uniquement les nouveaux fichiers View
5. **Replace All**

## Alternative : Fonction d'extension

Si vous voulez garder `.accent`, ajoutez cette extension dans un fichier commun :

```swift
// Dans StoreImmoTheme.swift ou un nouveau fichier Extensions.swift
import SwiftUI

extension ShapeStyle where Self == Color {
    static var accent: Color {
        Color.accentColor
    }
}
```

Mais la méthode la plus simple est de remplacer directement par `Color.accentColor`.

## Autres erreurs potentielles

### .tertiary, .secondary, .primary

Ces styles fonctionnent nativement, pas besoin de les changer :
- ✅ `.foregroundStyle(.primary)` - OK
- ✅ `.foregroundStyle(.secondary)` - OK
- ✅ `.foregroundStyle(.tertiary)` - OK

### .tint vs .foregroundStyle

Si vous voyez des erreurs sur `.tint`, remplacez par `.foregroundColor` :
```swift
// iOS 15+
.foregroundColor(.blue)

// iOS 16+
.tint(.blue)
```

## Vérification finale

Après les corrections :

1. **Clean Build** : `⌘⇧K`
2. **Build** : `⌘B`
3. Vérifiez qu'il n'y a plus d'erreur `Type 'ShapeStyle' has no member 'accent'`

## Résumé des remplacements

| Avant | Après |
|-------|-------|
| `.foregroundStyle(.accent)` | `.foregroundStyle(Color.accentColor)` |

Nombre de remplacements à faire :
- AccountView.swift : **2 occurrences**
- MyRequestsView.swift : **2 occurrences**
- FAQView.swift : **1 occurrence**
- Autres fichiers : Vérifier

**Total estimé : ~5-7 remplacements**

---

## Si d'autres erreurs apparaissent

### "Cannot find 'Color' in scope"

Assurez-vous que `import SwiftUI` est au début du fichier.

### "Use of unresolved identifier 'accentColor'"

Utilisez `Color.accentColor` et non `accentColor` tout seul.

### Warnings "contrasts poorly"

Ce sont des warnings d'accessibilité, pas des erreurs. Vous pouvez les ignorer pour le moment.

---

**Après ces corrections, votre projet devrait compiler sans erreur ! 🎉**
