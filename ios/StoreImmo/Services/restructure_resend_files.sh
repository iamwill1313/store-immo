#!/bin/bash
# Script de restructuration des fichiers Resend pour Store Immo
# Usage: ./restructure_resend_files.sh

set -e

echo "🔧 Restructuration des fichiers Resend pour Store Immo..."
echo ""

# Vérifier qu'on est à la racine du projet
if [ ! -f "AccountView.swift" ]; then
    echo "❌ Erreur : Ce script doit être exécuté depuis la racine du projet Store Immo"
    echo "   (Le fichier AccountView.swift doit être présent dans le dossier courant)"
    exit 1
fi

echo "✅ Détection du projet Store Immo OK"
echo ""

# Créer la structure de dossiers
echo "📁 Création de la structure de dossiers..."
mkdir -p supabase/functions/send-support-email
mkdir -p supabase/migrations

echo "✅ Dossiers créés :"
echo "   - supabase/functions/send-support-email/"
echo "   - supabase/migrations/"
echo ""

# Déplacer l'Edge Function
if [ -f "supabasefunctionssend-support-emailindex.ts" ]; then
    echo "📦 Déplacement de l'Edge Function..."
    mv supabasefunctionssend-support-emailindex.ts supabase/functions/send-support-email/index.ts
    echo "✅ Edge Function déplacée vers : supabase/functions/send-support-email/index.ts"
else
    echo "⚠️  Fichier source non trouvé : supabasefunctionssend-support-emailindex.ts"
    echo "   Vérifiez qu'il existe ou créez-le manuellement."
fi
echo ""

# Déplacer la migration SQL
if [ -f "supabasemigrations20260907_support_email_webhook.sql" ]; then
    echo "📦 Déplacement de la migration SQL..."
    mv supabasemigrations20260907_support_email_webhook.sql supabase/migrations/20260907_support_email_webhook.sql
    echo "✅ Migration SQL déplacée vers : supabase/migrations/20260907_support_email_webhook.sql"
else
    echo "⚠️  Fichier source non trouvé : supabasemigrations20260907_support_email_webhook.sql"
    echo "   Vérifiez qu'il existe ou créez-le manuellement."
fi
echo ""

# Vérifier la structure finale
echo "🔍 Vérification de la structure finale..."
echo ""

if [ -f "supabase/functions/send-support-email/index.ts" ]; then
    echo "✅ Edge Function : supabase/functions/send-support-email/index.ts"
    echo "   Taille : $(wc -c < supabase/functions/send-support-email/index.ts) octets"
else
    echo "❌ Edge Function manquante : supabase/functions/send-support-email/index.ts"
fi

if [ -f "supabase/migrations/20260907_support_email_webhook.sql" ]; then
    echo "✅ Migration SQL : supabase/migrations/20260907_support_email_webhook.sql"
    echo "   Taille : $(wc -c < supabase/migrations/20260907_support_email_webhook.sql) octets"
else
    echo "❌ Migration SQL manquante : supabase/migrations/20260907_support_email_webhook.sql"
fi

echo ""
echo "📋 Structure finale :"
echo ""
tree -L 3 supabase/ 2>/dev/null || (
    echo "supabase/"
    echo "├── functions/"
    echo "│   └── send-support-email/"
    echo "│       └── index.ts"
    echo "└── migrations/"
    echo "    └── 20260907_support_email_webhook.sql"
)

echo ""
echo "✅ Restructuration terminée !"
echo ""
echo "📝 Prochaines étapes :"
echo "   1. Vérifiez que les fichiers sont correctement placés"
echo "   2. Suivez les instructions de DEPLOYMENT_RESEND.md pour déployer"
echo "   3. Commandes à exécuter :"
echo ""
echo "      supabase login"
echo "      supabase link --project-ref VOTRE_PROJECT_REF"
echo "      supabase secrets set RESEND_API_KEY=re_xxxxx"
echo "      supabase db push"
echo "      supabase functions deploy send-support-email"
echo ""
echo "🎉 Bonne chance !"
