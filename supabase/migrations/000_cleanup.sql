-- Cleanup Script - DROP ALL TABLES
-- WARNING: This will delete all data!
-- Only use this in development

-- Drop triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_strava_connections_updated_at ON public.strava_connections;
DROP TRIGGER IF EXISTS update_daily_summaries_updated_at ON public.daily_summaries;

-- Drop functions
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop tables in reverse order (to handle foreign keys)
DROP TABLE IF EXISTS public.daily_summaries CASCADE;
DROP TABLE IF EXISTS public.food_logs CASCADE;
DROP TABLE IF EXISTS public.activities CASCADE;
DROP TABLE IF EXISTS public.strava_connections CASCADE;
DROP TABLE IF EXISTS public.progress_photos CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Note: This does not drop the auth.users table (managed by Supabase)

