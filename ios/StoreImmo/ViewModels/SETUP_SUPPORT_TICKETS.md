# Configuration Support Tickets - Supabase

## Table SQL

Exécutez ce SQL dans l'éditeur SQL de Supabase :

```sql
-- Table support_tickets
create table if not exists support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  category text not null,
  subject text not null,
  message text not null,
  status text not null default 'Nouvelle',
  user_role text,
  app_version text,
  created_at timestamptz default now(),
  updated_at timestamptz
);

-- Index pour améliorer les performances
create index if not exists support_tickets_user_id_idx on support_tickets(user_id);
create index if not exists support_tickets_status_idx on support_tickets(status);
create index if not exists support_tickets_created_at_idx on support_tickets(created_at desc);

-- RLS (Row Level Security)
alter table support_tickets enable row level security;

-- Politique : Les utilisateurs peuvent voir leurs propres tickets
create policy "Users can view own tickets"
  on support_tickets for select
  using (auth.uid() = user_id);

-- Politique : Les utilisateurs peuvent créer leurs propres tickets
create policy "Users can create own tickets"
  on support_tickets for insert
  with check (auth.uid() = user_id);

-- Politique : Les utilisateurs peuvent mettre à jour leurs propres tickets (pour consultation)
create policy "Users can update own tickets"
  on support_tickets for update
  using (auth.uid() = user_id);

-- Fonction trigger pour mettre à jour updated_at automatiquement
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Trigger pour support_tickets
create trigger update_support_tickets_updated_at
  before update on support_tickets
  for each row
  execute function update_updated_at_column();
```

## Valeurs possibles

### Catégories (category)
- "Problème technique"
- "Abonnement"
- "Paiement"
- "Candidature"
- "Projet / bien immobilier"
- "Compte et connexion"
- "Autre"

### Statuts (status)
- "Nouvelle" (par défaut)
- "En cours"
- "Résolue"

## Notes

1. Les tickets sont automatiquement liés à l'utilisateur connecté via `auth.uid()`
2. La table est sécurisée avec RLS - chaque utilisateur ne voit que ses propres tickets
3. `updated_at` est automatiquement mis à jour lors de modifications
4. Les tickets sont conservés jusqu'à suppression manuelle du compte utilisateur
5. Pour un système d'administration, créez des politiques supplémentaires pour les administrateurs

## Accès Admin (optionnel)

Si vous voulez que les administrateurs puissent voir tous les tickets :

```sql
-- Créer d'abord une table admins si nécessaire
create table if not exists admins (
  user_id uuid primary key references auth.users(id)
);

-- Politique admin pour voir tous les tickets
create policy "Admins can view all tickets"
  on support_tickets for select
  using (
    exists (
      select 1 from admins
      where admins.user_id = auth.uid()
    )
  );

-- Politique admin pour mettre à jour tous les tickets (changer statut)
create policy "Admins can update all tickets"
  on support_tickets for update
  using (
    exists (
      select 1 from admins
      where admins.user_id = auth.uid()
    )
  );
```
