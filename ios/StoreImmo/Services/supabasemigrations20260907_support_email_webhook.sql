-- Migration: Déclenchement automatique d'email lors de la création d'un ticket support
-- Date: 2026-09-07
-- Description: Configure un webhook Supabase pour appeler l'Edge Function send-support-email
--              lors de chaque INSERT dans la table support_tickets.

-- Note: Cette migration configure uniquement la structure nécessaire.
-- Le webhook Supabase doit être configuré manuellement dans le Dashboard:
--
-- 1. Allez dans Database > Webhooks
-- 2. Créez un nouveau webhook avec:
--    - Name: "Send Support Email"
--    - Table: support_tickets
--    - Events: INSERT
--    - Type: HTTP Request
--    - Method: POST
--    - URL: https://[VOTRE_PROJECT_REF].supabase.co/functions/v1/send-support-email
--    - HTTP Headers:
--      * Authorization: Bearer [VOTRE_ANON_KEY]
--      * Content-Type: application/json
--
-- Alternative avec pg_net (si disponible):
-- Cette fonction PostgreSQL peut être utilisée comme alternative au webhook Dashboard.
-- Elle nécessite l'extension pg_net.

-- Vérifier si pg_net est disponible (optionnel)
-- create extension if not exists pg_net;

-- Fonction qui sera appelée par le trigger
create or replace function notify_support_ticket_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  project_url text;
  service_role_key text;
  payload jsonb;
begin
  -- Construire le payload JSON
  payload := jsonb_build_object(
    'type', 'INSERT',
    'table', 'support_tickets',
    'record', row_to_json(NEW),
    'old_record', null
  );

  -- Note: Cette fonction log uniquement le webhook.
  -- Le webhook réel doit être configuré dans le Dashboard Supabase.
  -- Cette approche garantit que l'INSERT n'échoue jamais à cause de l'email.
  
  raise log 'Nouveau ticket support créé: %', NEW.id;
  raise log 'Webhook devrait être déclenché pour: %', payload;

  -- Retourner NEW pour que l'INSERT se poursuive normalement
  return NEW;
end;
$$;

-- Créer le trigger sur support_tickets
drop trigger if exists on_support_ticket_created on support_tickets;

create trigger on_support_ticket_created
  after insert on support_tickets
  for each row
  execute function notify_support_ticket_created();

-- Commentaires pour la documentation
comment on function notify_support_ticket_created() is 
  'Fonction trigger appelée après insertion dans support_tickets. '
  'Elle log l''événement. Le webhook Dashboard Supabase se charge d''appeler l''Edge Function.';

comment on trigger on_support_ticket_created on support_tickets is
  'Trigger AFTER INSERT qui log la création d''un ticket. '
  'Le webhook Supabase (configuré dans le Dashboard) envoie l''email via send-support-email Edge Function.';

-- Grant nécessaire pour le trigger
grant execute on function notify_support_ticket_created() to authenticated;
grant execute on function notify_support_ticket_created() to service_role;
