-- ============================================================================
-- Migration: Create news_series table
-- Date: 2026-09-20
-- Description: Table for storing weekly news series
-- ============================================================================

-- Create news_series table
create table if not exists public.news_series (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  week_start date not null,
  week_end date not null,
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index on is_active for quick lookup of active series
create index if not exists news_series_is_active_idx 
  on public.news_series(is_active) 
  where is_active = true;

-- Index on week_start for temporal queries
create index if not exists news_series_week_start_idx 
  on public.news_series(week_start desc);

-- Index on created_at for chronological ordering
create index if not exists news_series_created_at_idx 
  on public.news_series(created_at desc);

-- ============================================================================
-- CONSTRAINTS
-- ============================================================================

-- Ensure week_end is after week_start
alter table public.news_series
  add constraint news_series_week_dates_check
  check (week_end >= week_start);

-- Create unique partial index to ensure only one series can be active at a time
create unique index if not exists news_series_single_active_idx
  on public.news_series(is_active)
  where is_active = true;

-- ============================================================================
-- COMMENTS
-- ============================================================================

comment on table public.news_series is 
  'Stores weekly series of real estate news articles. Only one series can be active at a time.';

comment on column public.news_series.id is 
  'Unique identifier for the news series';

comment on column public.news_series.title is 
  'Title of the news series (e.g., "Actualités immobilières - Semaine du 20 septembre 2026")';

comment on column public.news_series.week_start is 
  'Start date of the week covered by this series';

comment on column public.news_series.week_end is 
  'End date of the week covered by this series';

comment on column public.news_series.is_active is 
  'Whether this series is currently active and displayed to users. Only one series can be active at a time.';

comment on column public.news_series.created_at is 
  'Timestamp when this series was created';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

do $$
begin
  assert (select count(*) from information_schema.tables 
          where table_schema = 'public' and table_name = 'news_series') = 1,
    'Table news_series was not created';
  
  assert (select count(*) from information_schema.columns 
          where table_schema = 'public' and table_name = 'news_series') = 6,
    'Table news_series does not have the expected number of columns';
  
  raise notice 'Migration 20260920000001_create_news_series_table completed successfully';
end $$;
