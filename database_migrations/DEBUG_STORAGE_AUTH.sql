-- =====================================================
-- DEBUG: Storage Authentication Issues
-- =====================================================
-- Run this to diagnose the 403 storage error

-- 1. Check if you're authenticated
SELECT 
    '1. AUTH STATUS' as check,
    auth.uid() as current_user_id,
    CASE 
        WHEN auth.uid() IS NULL THEN '❌ NOT AUTHENTICATED VIA SUPABASE AUTH'
        ELSE '✅ AUTHENTICATED'
    END as status;

-- 2. Check your user record
SELECT 
    '2. USER RECORD' as check,
    id,
    email,
    created_at
FROM auth.users
LIMIT 1;

-- 3. Check storage policies exist
SELECT 
    '3. STORAGE POLICIES' as check,
    policyname,
    cmd as command,
    SUBSTRING(qual::text, 1, 100) as using_clause
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects' 
AND policyname LIKE '%progress photos%';

-- 4. Check what the policy expects vs what you have
SELECT 
    '4. PATH MATCHING' as check,
    auth.uid()::text as your_auth_uid,
    'Expected path format: ' || auth.uid()::text || '/filename.jpg' as expected_path;

-- 5. List all storage buckets
SELECT 
    '5. STORAGE BUCKETS' as check,
    id,
    name,
    public,
    allowed_mime_types,
    file_size_limit
FROM storage.buckets;

-- =====================================================
-- INTERPRETATION
-- =====================================================
-- 
-- If AUTH STATUS shows NULL:
-- → You're not authenticated via Supabase Auth
-- → This is the problem! The app might be using custom auth
--    instead of Supabase Auth (auth.users table)
-- 
-- If USER RECORD is empty:
-- → No users exist in auth.users table
-- → You need to use Supabase Auth for authentication
-- 
-- If STORAGE POLICIES shows 0 rows:
-- → Policies weren't created
-- → Re-run progress_photos_schema_FIXED.sql
-- 
-- If PATH MATCHING shows NULL:
-- → Not authenticated
-- → This is why the upload fails

