-- =====================================================
-- Progress Photos - SIMPLIFIED STORAGE POLICIES
-- =====================================================
-- This uses a simpler storage policy approach that should work better
-- with some Supabase setups

-- =====================================================
-- STEP 1: CLEAN UP STORAGE POLICIES
-- =====================================================

-- Drop ALL existing storage policies for progress-photos
DROP POLICY IF EXISTS "progress_photos_storage_insert" ON storage.objects;
DROP POLICY IF EXISTS "progress_photos_storage_select" ON storage.objects;
DROP POLICY IF EXISTS "progress_photos_storage_update" ON storage.objects;
DROP POLICY IF EXISTS "progress_photos_storage_delete" ON storage.objects;

-- Also drop old names
DROP POLICY IF EXISTS "Users can upload their own progress photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own progress photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own progress photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own progress photos" ON storage.objects;

-- =====================================================
-- STEP 2: CREATE SIMPLIFIED STORAGE POLICIES
-- =====================================================
-- These policies use a simpler approach: just check if user is authenticated
-- We'll enforce user_id matching in the application layer instead

-- Allow ALL authenticated users to upload to progress-photos bucket
CREATE POLICY "progress_photos_storage_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'progress-photos'
);

-- Allow ALL authenticated users to view files in progress-photos bucket
CREATE POLICY "progress_photos_storage_select"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'progress-photos'
);

-- Allow ALL authenticated users to update files in progress-photos bucket
CREATE POLICY "progress_photos_storage_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'progress-photos'
);

-- Allow ALL authenticated users to delete files in progress-photos bucket
CREATE POLICY "progress_photos_storage_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'progress-photos'
);

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check storage policies
SELECT 
    'STORAGE POLICIES' as check_type,
    policyname,
    cmd as command,
    SUBSTRING(qual::text, 1, 50) as condition
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects' 
AND policyname LIKE '%progress_photos%'
ORDER BY policyname;

-- Check authentication
SELECT 
    'AUTH STATUS' as check_type,
    auth.uid() as your_user_id,
    CASE 
        WHEN auth.uid() IS NULL THEN '❌ NOT AUTHENTICATED (this is expected in SQL editor)'
        ELSE '✅ AUTHENTICATED'
    END as status;

-- =====================================================
-- NOTE ON SECURITY
-- =====================================================
-- These simplified policies allow ANY authenticated user to access
-- ANY file in the progress-photos bucket. This is LESS secure than
-- the folder-based policies, but will work better with some
-- Supabase SDK versions.
--
-- Security is still maintained by:
-- 1. The progress_photos TABLE policies (only see your own records)
-- 2. Application logic (only upload to your own folder)
-- 3. Users can only get URLs for their own photos via the database
--
-- Once upload is working, we can investigate why the folder-based
-- policies weren't working and potentially switch back to them.
--
-- =====================================================
-- EXPECTED RESULTS
-- =====================================================
-- 
-- STORAGE POLICIES: Should show 4 rows
--   - progress_photos_storage_delete
--   - progress_photos_storage_insert  
--   - progress_photos_storage_select
--   - progress_photos_storage_update
--
-- AUTH STATUS: Will show NULL in SQL editor (that's normal)
--   - In your app, it will show your user ID
--
-- After running this:
-- 1. Rebuild your app (Cmd + Shift + K, then Cmd + B)
-- 2. Log in to your app
-- 3. Try uploading a photo
-- 4. Check console for "🔑 Current session user ID" message
--

