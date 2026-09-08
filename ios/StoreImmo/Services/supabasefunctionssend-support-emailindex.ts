// Edge Function: send-support-email
// Description: Envoie les tickets de support par email via Resend
// Runtime: Deno

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// Interface pour le payload reçu
interface SupportTicketPayload {
  userEmail: string;
  subject: string;
  message: string;
  timestamp?: string;
}

// Interface pour la réponse Resend
interface ResendResponse {
  id?: string;
  error?: {
    message: string;
    name: string;
  };
}

serve(async (req: Request) => {
  // Configuration CORS pour permettre les requêtes depuis l'app
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  // Gestion du preflight CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  try {
    // Validation de la méthode HTTP
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Méthode non autorisée. Utilisez POST.",
        }),
        {
          status: 405,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Récupération de la clé API Resend depuis les variables d'environnement
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      console.error("❌ RESEND_API_KEY non configurée");
      return new Response(
        JSON.stringify({
          success: false,
          error: "Configuration serveur manquante (RESEND_API_KEY)",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse du body JSON
    let payload: SupportTicketPayload;
    try {
      payload = await req.json();
    } catch (parseError) {
      console.error("❌ Erreur de parsing JSON:", parseError);
      return new Response(
        JSON.stringify({
          success: false,
          error: "Body JSON invalide",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validation des champs requis
    const { userEmail, subject, message, timestamp } = payload;

    if (!userEmail || !subject || !message) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Champs manquants. Requis: userEmail, subject, message",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validation du format email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(userEmail)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Format d'email invalide",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Création de l'horodatage si non fourni
    const ticketTimestamp = timestamp || new Date().toISOString();
    const formattedDate = new Date(ticketTimestamp).toLocaleString("fr-FR", {
      dateStyle: "full",
      timeStyle: "medium",
    });

    // Construction du contenu HTML de l'email
    const htmlContent = `
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Nouveau Ticket Support - Store Immo</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  
  <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
    <h1 style="color: white; margin: 0; font-size: 28px;">📧 Nouveau Ticket Support</h1>
  </div>
  
  <div style="background: #f9f9f9; padding: 30px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 10px 10px;">
    
    <div style="background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
      <h2 style="color: #667eea; margin-top: 0; font-size: 20px; border-bottom: 2px solid #667eea; padding-bottom: 10px;">
        👤 Informations de l'utilisateur
      </h2>
      <p style="margin: 10px 0;">
        <strong>Email :</strong> 
        <a href="mailto:${userEmail}" style="color: #667eea; text-decoration: none;">
          ${userEmail}
        </a>
      </p>
      <p style="margin: 10px 0; color: #666; font-size: 14px;">
        <strong>Date :</strong> ${formattedDate}
      </p>
    </div>
    
    <div style="background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
      <h2 style="color: #667eea; margin-top: 0; font-size: 20px; border-bottom: 2px solid #667eea; padding-bottom: 10px;">
        📋 Sujet
      </h2>
      <p style="margin: 10px 0; font-size: 16px; color: #333;">
        ${subject}
      </p>
    </div>
    
    <div style="background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
      <h2 style="color: #667eea; margin-top: 0; font-size: 20px; border-bottom: 2px solid #667eea; padding-bottom: 10px;">
        💬 Message
      </h2>
      <div style="margin: 15px 0; padding: 15px; background: #f5f5f5; border-left: 4px solid #667eea; border-radius: 4px;">
        <p style="margin: 0; white-space: pre-wrap; word-wrap: break-word;">${message}</p>
      </div>
    </div>
    
  </div>
  
  <div style="margin-top: 20px; padding: 20px; text-align: center; color: #666; font-size: 12px;">
    <p style="margin: 5px 0;">🏢 <strong>Store Immo</strong> - Gestion de Support</p>
    <p style="margin: 5px 0;">Ce ticket a été envoyé automatiquement depuis l'application mobile</p>
    <p style="margin: 5px 0; color: #999;">Horodatage: ${ticketTimestamp}</p>
  </div>
  
</body>
</html>
    `.trim();

    // Construction de la version texte brut
    const textContent = `
🎫 NOUVEAU TICKET SUPPORT - STORE IMMO

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

👤 UTILISATEUR
Email: ${userEmail}
Date: ${formattedDate}

📋 SUJET
${subject}

💬 MESSAGE
${message}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏢 Store Immo - Gestion de Support
Horodatage: ${ticketTimestamp}
    `.trim();

    console.log(`📤 Envoi d'email pour le ticket de: ${userEmail}`);

    // Appel à l'API Resend
    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Store Immo Support <support@storeimmo.com>",
        to: ["support@storeimmo.com"],
        reply_to: userEmail,
        subject: `[Ticket Support] ${subject}`,
        html: htmlContent,
        text: textContent,
      }),
    });

    const resendData: ResendResponse = await resendResponse.json();

    // Gestion des erreurs Resend
    if (!resendResponse.ok || resendData.error) {
      console.error("❌ Erreur Resend:", resendData.error);
      return new Response(
        JSON.stringify({
          success: false,
          error: `Erreur d'envoi d'email: ${resendData.error?.message || "Erreur inconnue"}`,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`✅ Email envoyé avec succès. ID: ${resendData.id}`);

    // Réponse de succès
    return new Response(
      JSON.stringify({
        success: true,
        message: "Ticket envoyé avec succès",
        emailId: resendData.id,
        timestamp: ticketTimestamp,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    // Gestion globale des erreurs non capturées
    console.error("❌ Erreur serveur:", error);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: "Erreur interne du serveur",
        details: error instanceof Error ? error.message : "Erreur inconnue",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
