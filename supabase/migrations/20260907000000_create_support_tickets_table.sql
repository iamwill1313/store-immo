-- Migration: Création de la table support_tickets
-- Date: 2026-09-07
-- Description: Crée la table pour stocker les tickets de support utilisateur
-- Dépendances: Nécessite auth.users

-- ============================================
-- 1. CRÉATION DE LA TABLE
-- ============================================

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  category text not null,
  subject text not null,
  message text not null,
  status text not null default 'Nouvelle',
  user_role text,
  app_version text,
  created_at timestamptz default now() not null,
  updated_at timestamptz
);

-- ============================================
-- 2. COMMENTAIRES (Documentation)
-- ============================================

comment on table public.support_tickets is 
  'Tickets de support créés par les utilisateurs de l''application mobile Store Immo';

comment on column public.support_tickets.id is 
  'Identifiant unique du ticket (UUID)';

comment on column public.support_tickets.user_id is 
  'Référence vers l''utilisateur qui a créé le ticket (auth.users)';

comment on column public.support_tickets.category is 
  'Catégorie du problème (Problème technique, Abonnement, Paiement, etc.)';

comment on column public.support_tickets.subject is 
  'Sujet/titre du ticket';

comment on column public.support_tickets.message is 
  'Description détaillée du problème';

comment on column public.support_tickets.status is 
  'Statut actuel: Nouvelle, En cours, Résolue';

comment on column public.support_tickets.user_role is 
  'Rôle de l''utilisateur: seller ou agent';

comment on column public.support_tickets.app_version is 
  'Version de l''application au moment de la création du ticket';

-- ============================================
-- 3. INDEX (Performance)
-- ============================================

create index if not exists support_tickets_user_id_idx 
  on public.support_tickets(user_id);

create index if not exists support_tickets_status_idx 
  on public.support_tickets(status);

create index if not exists support_tickets_created_at_idx 
  on public.support_tickets(created_at desc);

comment on index public.support_tickets_user_id_idx is 
  'Index pour accélérer les requêtes de tickets par utilisateur';

comment on index public.support_tickets_status_idx is 
  'Index pour accélérer les filtres par statut';

comment on index public.support_tickets_created_at_idx is 
  'Index pour accélérer le tri par date de création (DESC)';

-- ============================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================

alter table public.support_tickets enable row level security;

-- Politique : Les utilisateurs peuvent voir leurs propres tickets
create policy "Users can view own tickets"
  on public.support_tickets
  for select
  using (auth.uid() = user_id);

-- Politique : Les utilisateurs peuvent créer leurs propres tickets
create policy "Users can create own tickets"
  on public.support_tickets
  for insert
  with check (auth.uid() = user_id);

-- Politique : Les utilisateurs peuvent mettre à jour leurs propres tickets
create policy "Users can update own tickets"
  on public.support_tickets
  for update
  using (auth.uid() = user_id);

comment on policy "Users can view own tickets" on public.support_tickets is 
  'RLS: Un utilisateur ne peut voir que ses propres tickets';

comment on policy "Users can create own tickets" on public.support_tickets is 
  'RLS: Un utilisateur ne peut créer que des tickets pour lui-même';

comment on policy "Users can update own tickets" on public.support_tickets is 
  'RLS: Un utilisateur ne peut modifier que ses propres tickets';

-- ============================================
-- 5. FONCTION TRIGGER updated_at
-- ============================================

-- Créer la fonction si elle n'existe pas (peut être partagée par d'autres tables)
create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function public.update_updated_at_column() is 
  'Fonction trigger générique pour mettre à jour automatiquement la colonne updated_at';

-- Créer le trigger sur support_tickets
drop trigger if exists update_support_tickets_updated_at on public.support_tickets;

create trigger update_support_tickets_updated_at
  before update on public.support_tickets
  for each row
  execute function public.update_updated_at_column();

comment on trigger update_support_tickets_updated_at on public.support_tickets is 
  'Trigger BEFORE UPDATE qui met à jour automatiquement updated_at à la date/heure actuelle';

-- ============================================
-- 6. GRANTS (Permissions)
-- ============================================

-- Les utilisateurs authentifiés peuvent insérer/select
grant select, insert, update on public.support_tickets to authenticated;

-- Service role a tous les droits (pour le webhook/edge function)
grant all on public.support_tickets to service_role;

-- ============================================
-- 7. VÉRIFICATION FINALE
-- ============================================

-- Vérifier que la table existe
do $$
begin
  if not exists (
    select 1 from information_schema.tables 
    where table_schema = 'public' 
    and table_name = 'support_tickets'
  ) then
    raise exception 'ERREUR: La table support_tickets n''a pas été créée';
  end if;
  
  raise notice '✅ Migration réussie: Table support_tickets créée avec succès';
end $$;
