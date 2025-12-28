-- =====================================================
-- Fix Photo URLs - Convert Full URLs to Paths
-- =====================================================
-- This fixes photos that were uploaded with old code
-- that stored full URLs instead of storage paths

-- BEFORE RUNNING: Check what needs to be fixed
-- Run CHECK_PHOTO_URLS.sql first to see the current state

-- =====================================================
-- OPTION 1: Delete old photos and start fresh
-- =====================================================
-- ⚠️ WARNING: This deletes ALL progress photos!
-- Only use if you don't have important photos yet

-- DELETE FROM progress_photos;

-- =====================================================
-- OPTION 2: Extract paths from URLs (if possible)
-- =====================================================
-- This tries to extract the storage path from full URLs
-- Only works if URLs follow the pattern:
-- https://...supabase.co/storage/v1/object/public/progress-photos/USER_ID/TIMESTAMP.jpg
-- or
-- https://...supabase.co/storage/v1/object/sign/progress-photos/USER_ID/TIMESTAMP.jpg

-- Update photo_url: extract path from URL
UPDATE progress_photos
SET photo_url = REGEXP_REPLACE(
    photo_url,
    '^https?://[^/]+/storage/v1/object/(public|sign)/progress-photos/(.+?)(\?.*)?$',
    '\2'
)
WHERE photo_url LIKE 'https://%';

-- Update thumbnail_url: extract path from URL
UPDATE progress_photos
SET thumbnail_url = REGEXP_REPLACE(
    thumbnail_url,
    '^https?://[^/]+/storage/v1/object/(public|sign)/progress-photos/(.+?)(\?.*)?$',
    '\2'
)
WHERE thumbnail_url LIKE 'https://%';

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check results
SELECT 
    id,
    photo_url,
    thumbnail_url,
    CASE 
        WHEN photo_url LIKE 'https://%' THEN '❌ Still a URL'
        WHEN photo_url LIKE '%/%' THEN '✅ Now a path'
        ELSE '⚠️ Unknown'
    END as status
FROM progress_photos
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- IF REGEX DIDN'T WORK
-- =====================================================
-- Some Supabase versions don't support REGEXP_REPLACE
-- In that case, you'll need to:
-- 1. Delete the old photos (Option 1 above)
-- 2. Re-upload photos using the new app code
-- 
-- Or manually update each row:
-- UPDATE progress_photos 
-- SET photo_url = 'USER_ID/TIMESTAMP_full.jpg',
--     thumbnail_url = 'USER_ID/TIMESTAMP_thumb.jpg'
-- WHERE id = 'PHOTO_ID';

