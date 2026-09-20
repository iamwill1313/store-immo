-- ============================================================================
-- Migration: Create RLS policies for news tables
-- Date: 2026-09-20
-- Description: Row Level Security policies for news_series and news_articles
-- ============================================================================

-- ============================================================================
-- ENABLE RLS
-- ============================================================================

-- Enable Row Level Security on news_series
alter table public.news_series enable row level security;

-- Enable Row Level Security on news_articles
alter table public.news_articles enable row level security;

-- ============================================================================
-- RLS POLICIES - news_series
-- ============================================================================

-- PUBLIC READ: Anyone can view news series
create policy "Public read access for news_series"
  on public.news_series
  for select
  using (true);

-- SERVICE ROLE INSERT: Only service_role can create new series
create policy "Service role can insert news_series"
  on public.news_series
  for insert
  to service_role
  with check (true);

-- SERVICE ROLE UPDATE: Only service_role can update series
create policy "Service role can update news_series"
  on public.news_series
  for update
  to service_role
  using (true)
  with check (true);

-- SERVICE ROLE DELETE: Only service_role can delete series
create policy "Service role can delete news_series"
  on public.news_series
  for delete
  to service_role
  using (true);

-- ============================================================================
-- RLS POLICIES - news_articles
-- ============================================================================

-- PUBLIC READ: Anyone can view news articles
create policy "Public read access for news_articles"
  on public.news_articles
  for select
  using (true);

-- SERVICE ROLE INSERT: Only service_role can create new articles
create policy "Service role can insert news_articles"
  on public.news_articles
  for insert
  to service_role
  with check (true);

-- SERVICE ROLE UPDATE: Only service_role can update articles
create policy "Service role can update news_articles"
  on public.news_articles
  for update
  to service_role
  using (true)
  with check (true);

-- SERVICE ROLE DELETE: Only service_role can delete articles
create policy "Service role can delete news_articles"
  on public.news_articles
  for delete
  to service_role
  using (true);

-- ============================================================================
-- GRANTS
-- ============================================================================

-- Grant SELECT to authenticated users (implicit through RLS policy)
grant select on public.news_series to authenticated;
grant select on public.news_articles to authenticated;

-- Grant SELECT to anonymous users (for public access)
grant select on public.news_series to anon;
grant select on public.news_articles to anon;

-- Grant ALL to service_role (for Edge Functions)
grant all on public.news_series to service_role;
grant all on public.news_articles to service_role;

-- ============================================================================
-- COMMENTS
-- ============================================================================

comment on policy "Public read access for news_series" on public.news_series is
  'Allows public read access to all news series. Anyone can view series without authentication.';

comment on policy "Service role can insert news_series" on public.news_series is
  'Only the service role (Edge Functions) can create new news series.';

comment on policy "Service role can update news_series" on public.news_series is
  'Only the service role (Edge Functions) can update existing news series, including activating/deactivating them.';

comment on policy "Service role can delete news_series" on public.news_series is
  'Only the service role (Edge Functions) can delete news series.';

comment on policy "Public read access for news_articles" on public.news_articles is
  'Allows public read access to all news articles. Anyone can view articles without authentication.';

comment on policy "Service role can insert news_articles" on public.news_articles is
  'Only the service role (Edge Functions) can create new news articles.';

comment on policy "Service role can update news_articles" on public.news_articles is
  'Only the service role (Edge Functions) can update existing news articles.';

comment on policy "Service role can delete news_articles" on public.news_articles is
  'Only the service role (Edge Functions) can delete news articles.';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

do $$
declare
  series_policies_count integer;
  articles_policies_count integer;
begin
  -- Count RLS policies for news_series
  select count(*) into series_policies_count
  from pg_policies
  where schemaname = 'public'
  and tablename = 'news_series';
  
  assert series_policies_count = 4,
    'Expected 4 RLS policies for news_series, found ' || series_policies_count;
  
  -- Count RLS policies for news_articles
  select count(*) into articles_policies_count
  from pg_policies
  where schemaname = 'public'
  and tablename = 'news_articles';
  
  assert articles_policies_count = 4,
    'Expected 4 RLS policies for news_articles, found ' || articles_policies_count;
  
  -- Verify RLS is enabled
  assert (select relrowsecurity from pg_class 
          where relname = 'news_series' and relnamespace = 'public'::regnamespace) = true,
    'RLS is not enabled on news_series';
  
  assert (select relrowsecurity from pg_class 
          where relname = 'news_articles' and relnamespace = 'public'::regnamespace) = true,
    'RLS is not enabled on news_articles';
  
  raise notice 'Migration 20260920000003_create_news_rls_policies completed successfully';
end $$;
