-- ============================================================================
-- Migration: Create news_articles table
-- Date: 2026-09-20
-- Description: Table for storing individual news articles within series
-- ============================================================================

-- Create news_articles table
create table if not exists public.news_articles (
  id uuid primary key default gen_random_uuid(),
  series_id uuid not null,
  title text not null,
  summary text not null,
  category text not null,
  source_name text not null,
  source_url text not null,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  content_hash text not null
);

-- ============================================================================
-- FOREIGN KEYS
-- ============================================================================

-- Foreign key to news_series with cascade delete
alter table public.news_articles
  add constraint news_articles_series_id_fkey
  foreign key (series_id)
  references public.news_series(id)
  on delete cascade;

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index on series_id for efficient joins and filtering by series
create index if not exists news_articles_series_id_idx 
  on public.news_articles(series_id);

-- Index on published_at for temporal ordering
create index if not exists news_articles_published_at_idx 
  on public.news_articles(published_at desc nulls last);

-- Index on content_hash for global deduplication across all series
create index if not exists news_articles_content_hash_idx 
  on public.news_articles(content_hash);

-- Composite index for category filtering within series
create index if not exists news_articles_series_category_idx 
  on public.news_articles(series_id, category);

-- Index on created_at for chronological ordering
create index if not exists news_articles_created_at_idx 
  on public.news_articles(created_at desc);

-- ============================================================================
-- CONSTRAINTS
-- ============================================================================

-- Ensure category is not empty
alter table public.news_articles
  add constraint news_articles_category_not_empty_check
  check (length(trim(category)) > 0);

-- Ensure source_url is a valid format (basic check)
alter table public.news_articles
  add constraint news_articles_source_url_check
  check (source_url ~* '^https?://');

-- Ensure content_hash is not empty
alter table public.news_articles
  add constraint news_articles_content_hash_not_empty_check
  check (length(trim(content_hash)) > 0);

-- ============================================================================
-- COMMENTS
-- ============================================================================

comment on table public.news_articles is 
  'Stores individual news articles belonging to weekly series. Articles are deduplicated globally using content_hash.';

comment on column public.news_articles.id is 
  'Unique identifier for the news article';

comment on column public.news_articles.series_id is 
  'Reference to the news series this article belongs to';

comment on column public.news_articles.title is 
  'Title of the news article';

comment on column public.news_articles.summary is 
  'Brief summary or excerpt of the article content';

comment on column public.news_articles.category is 
  'Category of the article (e.g., "Marché", "Réglementation", "DPE", "Investissement")';

comment on column public.news_articles.source_name is 
  'Name of the original source (e.g., "Le Figaro Immobilier", "SeLoger")';

comment on column public.news_articles.source_url is 
  'URL of the original article source';

comment on column public.news_articles.published_at is 
  'Original publication date of the article from the source';

comment on column public.news_articles.created_at is 
  'Timestamp when this article was added to the database';

comment on column public.news_articles.content_hash is 
  'Hash of the article content for global deduplication across all series';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

do $$
begin
  assert (select count(*) from information_schema.tables 
          where table_schema = 'public' and table_name = 'news_articles') = 1,
    'Table news_articles was not created';
  
  assert (select count(*) from information_schema.columns 
          where table_schema = 'public' and table_name = 'news_articles') = 10,
    'Table news_articles does not have the expected number of columns';
  
  assert (select count(*) from information_schema.table_constraints
          where table_schema = 'public' 
          and table_name = 'news_articles'
          and constraint_type = 'FOREIGN KEY') >= 1,
    'Foreign key constraint was not created';
  
  raise notice 'Migration 20260920000002_create_news_articles_table completed successfully';
end $$;
