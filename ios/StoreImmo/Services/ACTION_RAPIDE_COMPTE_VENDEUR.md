# ⚡ ACTION RAPIDE — COMPILATION ET TEST

**Statut :** ✅ PRÊT À COMPILER

---

## 1️⃣ COMPILEZ (⏱️ 1 min)

```bash
⌘ + Shift + K  # Clean (optionnel)
⌘ + B          # Build
```

**Résultat attendu :** ✅ 0 erreur

---

## 2️⃣ TESTEZ VENDEUR (⏱️ 2 min)

```bash
⌘ + R  # Run
```

1. Connectez-vous en tant que **VENDEUR**
2. Ouvrez l'onglet **"Compte"** (dernier onglet)
3. Vérifiez :

```
┌─────────────────────────┐
│  👤 Jean Dupont         │ ← Votre nom
│  📧 jean@example.com    │ ← Votre email
│  📞 06 12 34 56 78      │ ← Votre téléphone
├─────────────────────────┤
│  👤 Mon profil          │
│     Info personnelles › │
├─────────────────────────┤
│  🏠 Mes projets         │
│  📁 Mes biens           │
│     3 projet(s)  [Voir] │ ← Cliquez
└─────────────────────────┘
```

4. Cliquez sur **"Voir"** → Doit ouvrir l'onglet **Dashboard**

✅ **Si tout fonctionne, c'est bon !**

---

## 3️⃣ TESTEZ AGENT (⏱️ 2 min)

1. Déconnectez-vous
2. Connectez-vous en tant que **AGENT**
3. Ouvrez l'onglet **"Compte"**
4. Vérifiez :

```
┌─────────────────────────┐
│  [Photo si elle existe] │
│  👤 Sophie Martin       │ ← Nom agent
│  📧 sophie@agence.fr    │
│  📞 07 89 12 34 56      │
├─────────────────────────┤
│  👤 Mon profil          │
│     Info personnelles › │
├─────────────────────────┤
│  🏠 Mes projets         │
│  ✨ Opportunités        │
│     12 projet(s) [Voir] │ ← Cliquez
│  ──────────────────     │
│  📄 Mes mandats         │
│     5 mandat(s)  [Voir] │ ← Cliquez
└─────────────────────────┘
```

5. Cliquez sur **"Voir" (Opportunités)** → Doit ouvrir l'onglet **Opportunities**
6. Revenez sur **"Compte"**
7. Cliquez sur **"Voir" (Mandats)** → Doit ouvrir l'onglet **Mandates**

✅ **Si tout fonctionne, c'est bon !**

---

## 4️⃣ TESTEZ LE SUPPORT (⏱️ 2 min)

1. En tant que **VENDEUR** ou **AGENT**
2. Ouvrez l'onglet **"Compte"**
3. Cliquez sur **"Signaler un problème"**
4. Remplissez :
   - Catégorie : **Problème technique**
   - Sujet : **Test**
   - Message : **Test d'envoi depuis StoreImmo**
5. Envoyez
6. Vérifiez :

### Dans Supabase :
```sql
SELECT * FROM support_tickets
ORDER BY created_at DESC
LIMIT 1;
```

**Résultat attendu :** ✅ Votre ticket apparaît

### Dans votre boîte mail :
**support@storeimmo.com**

**Résultat attendu :** ✅ Email reçu avec le ticket

---

## ✅ CHECKLIST FINALE

- [ ] ⌘ + B → 0 erreur
- [ ] Vendeur → En-tête OK
- [ ] Vendeur → "Mes biens" OK
- [ ] Vendeur → Navigation Dashboard OK
- [ ] Agent → En-tête + photo OK
- [ ] Agent → "Opportunités" OK
- [ ] Agent → "Mandats" OK
- [ ] Agent → Navigation OK
- [ ] Support → Ticket Supabase OK
- [ ] Support → Email reçu OK

---

## 🎉 SI TOUT EST ✅

**FÉLICITATIONS !**

Le compte vendeur est parfaitement harmonisé avec le compte agent.

**Résultat :**
- ✅ Même architecture vendeur/agent
- ✅ En-tête avec informations de contact
- ✅ Section "Mes projets" adaptée au rôle
- ✅ Navigation fonctionnelle
- ✅ Support intact (Supabase + email)
- ✅ Compte agent intact
- ✅ Design cohérent StoreImmo

---

## 🐛 SI QUELQUE CHOSE NE FONCTIONNE PAS

### Erreur de compilation
→ Ouvrez : **`GUIDE_VERIFICATION_COMPTE_VENDEUR.md`**  
→ Section : "En cas d'erreur"

### Erreur à l'exécution
→ Ouvrez : **`REFACTORISATION_COMPTE_VENDEUR.md`**  
→ Section : "Notes techniques"

### Support ne fonctionne pas
→ Vérifiez :
1. Table `support_tickets` existe dans Supabase
2. Edge Function `send-support-email` déployée avec `--no-verify-jwt`
3. Trigger PostgreSQL `on_support_ticket_insert` actif

### Navigation ne fonctionne pas
→ Vérifiez que `viewModel.sellerTab` et `viewModel.agentTab` sont correctement définis

---

## 📚 BESOIN DE PLUS D'INFOS ?

### Parcours Express (⏱️ 5 min)
→ **`COMMENCEZ_ICI_COMPTE_VENDEUR.md`**

### Parcours Complet (⏱️ 30 min)
→ **`INDEX_COMPTE_VENDEUR.md`** (navigation)

### Documentation technique
→ **`REFACTORISATION_COMPTE_VENDEUR.md`**

### Tests approfondis
→ **`GUIDE_VERIFICATION_COMPTE_VENDEUR.md`**

---

**Prêt ? Compilez ! 🚀**

```bash
⌘ + B
```
