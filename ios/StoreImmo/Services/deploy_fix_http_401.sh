#!/bin/bash

# 🔧 Script de correction HTTP 401 - Edge Function send-support-email
# Date: 2026-09-07
# Objectif: Redéployer l'Edge Function avec verify_jwt = false

set -e  # Arrêter en cas d'erreur

echo "🔧 CORRECTION HTTP 401 - Edge Function send-support-email"
echo "════════════════════════════════════════════════════════════"
echo ""

# Vérifier que Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo "❌ Erreur: Supabase CLI n'est pas installé"
    echo ""
    echo "Installation:"
    echo "  macOS:  brew install supabase/tap/supabase"
    echo "  npm:    npm install -g supabase"
    echo ""
    exit 1
fi

echo "✅ Supabase CLI détecté"
echo ""

# Vérifier que nous sommes connectés
if ! supabase projects list &> /dev/null; then
    echo "❌ Erreur: Vous n'êtes pas connecté à Supabase"
    echo ""
    echo "Pour vous connecter:"
    echo "  supabase login"
    echo ""
    exit 1
fi

echo "✅ Connexion Supabase active"
echo ""

# Vérifier que le projet est lié
if [ ! -f ".supabase/config.toml" ] && [ ! -f "supabase/config.toml" ]; then
    echo "⚠️  Avertissement: Aucun fichier config.toml détecté"
    echo ""
    echo "Si vous n'avez pas lié de projet, exécutez:"
    echo "  supabase link --project-ref VOTRE_PROJECT_REF"
    echo ""
    read -p "Continuer quand même ? (o/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        echo "Abandon."
        exit 1
    fi
fi

echo "✅ Configuration détectée"
echo ""

# Vérifier que RESEND_API_KEY est configurée
echo "🔍 Vérification de RESEND_API_KEY..."
if supabase secrets list 2>/dev/null | grep -q "RESEND_API_KEY"; then
    echo "✅ RESEND_API_KEY est configurée"
else
    echo "⚠️  Avertissement: RESEND_API_KEY n'est pas configurée"
    echo ""
    echo "Pour la configurer:"
    echo "  supabase secrets set RESEND_API_KEY=re_xxxxx"
    echo ""
    read -p "Continuer quand même ? (o/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        echo "Abandon."
        exit 1
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "🚀 DÉPLOIEMENT de send-support-email"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Configuration:"
echo "  - verify_jwt: false"
echo "  - CORS: *"
echo ""
echo "⏳ Déploiement en cours..."
echo ""

# Déployer la fonction avec --no-verify-jwt
if supabase functions deploy send-support-email --no-verify-jwt; then
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "✅ DÉPLOIEMENT RÉUSSI"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    # Afficher les fonctions déployées
    echo "📋 Fonctions déployées:"
    echo ""
    supabase functions list
    echo ""
    
    # Afficher l'URL de la fonction
    echo "🌐 URL de la fonction:"
    PROJECT_REF=$(grep 'project_id' .supabase/config.toml 2>/dev/null | cut -d '"' -f 2 || echo "XXXXX")
    if [ "$PROJECT_REF" != "XXXXX" ]; then
        echo "  https://${PROJECT_REF}.supabase.co/functions/v1/send-support-email"
    else
        echo "  https://VOTRE_PROJECT_REF.supabase.co/functions/v1/send-support-email"
    fi
    echo ""
    
    echo "════════════════════════════════════════════════════════════"
    echo "🧪 TESTS RECOMMANDÉS"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "1. Créer un ticket depuis l'app iOS"
    echo "2. Vérifier les logs:"
    echo "   supabase functions logs send-support-email --follow"
    echo ""
    echo "3. Vérifier l'email reçu à support@storeimmo.com"
    echo ""
    echo "4. Vérifier dans Resend Dashboard:"
    echo "   https://resend.com/emails"
    echo ""
    
    echo "════════════════════════════════════════════════════════════"
    echo "✅ CORRECTION HTTP 401 TERMINÉE"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "L'Edge Function send-support-email accepte maintenant"
    echo "les appels du trigger PostgreSQL sans JWT utilisateur."
    echo ""
    echo "Le problème UNAUTHORIZED_NO_AUTH_HEADER est résolu ! 🎉"
    echo ""
    
    exit 0
else
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "❌ ÉCHEC DU DÉPLOIEMENT"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Le déploiement a échoué. Causes possibles:"
    echo ""
    echo "1. Pas connecté à Supabase:"
    echo "   supabase login"
    echo ""
    echo "2. Projet non lié:"
    echo "   supabase link --project-ref VOTRE_PROJECT_REF"
    echo ""
    echo "3. Fonction introuvable:"
    echo "   Vérifiez que le dossier existe:"
    echo "   supabase/functions/send-support-email/index.ts"
    echo ""
    echo "4. Erreur réseau:"
    echo "   Vérifiez votre connexion Internet"
    echo ""
    
    exit 1
fi
