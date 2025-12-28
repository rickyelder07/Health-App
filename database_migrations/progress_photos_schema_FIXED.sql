-- =====================================================
-- Progress Photos System Database Schema (FIXED VERSION)
-- =====================================================
-- This version handles existing tables with missing columns
-- Run this instead of the original progress_photos_schema.sql

-- =====================================================
-- STEP 1: DROP AND RECREATE TABLE WITH CORRECT SCHEMA
-- =====================================================
-- ⚠️ WARNING: This will delete any existing progress photos!
-- If you have important data, back it up first:
-- SELECT * FROM progress_photos; -- Copy results before running

DROP TABLE IF EXISTS progress_photos CASCADE;

-- Create table with complete schema
CREATE TABLE progress_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    thumbnail_url TEXT,
    weight DECIMAL(5, 2),
    notes TEXT,
    taken_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX idx_progress_photos_user_id ON progress_photos(user_id);
CREATE INDEX idx_progress_photos_taken_at ON progress_photos(user_id, taken_at DESC);

-- =====================================================
-- STEP 2: ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE progress_photos ENABLE ROW LEVEL SECURITY;

-- Users can only see their own progress photos
CREATE POLICY "Users can view their own progress photos"
    ON progress_photos FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own progress photos
CREATE POLICY "Users can insert their own progress photos"
    ON progress_photos FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own progress photos
CREATE POLICY "Users can update their own progress photos"
    ON progress_photos FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own progress photos
CREATE POLICY "Users can delete their own progress photos"
    ON progress_photos FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- STEP 3: CREATE TRIGGER FOR AUTO-UPDATING TIMESTAMPS
-- =====================================================

CREATE TRIGGER update_progress_photos_updated_at 
    BEFORE UPDATE ON progress_photos
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- STEP 4: SETUP STORAGE BUCKET
-- =====================================================

-- Create storage bucket (or skip if already exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('progress-photos', 'progress-photos', false)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STEP 5: STORAGE RLS POLICIES
-- =====================================================

-- Drop existing policies to avoid duplicates
DROP POLICY IF EXISTS "Users can upload their own progress photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own progress photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own progress photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own progress photos" ON storage.objects;

-- Allow authenticated users to upload their own photos
CREATE POLICY "Users can upload their own progress photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'progress-photos' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view their own photos
CREATE POLICY "Users can view their own progress photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'progress-photos' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to update their own photos
CREATE POLICY "Users can update their own progress photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'progress-photos' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own photos
CREATE POLICY "Users can delete their own progress photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'progress-photos' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- VERIFICATION: Check Everything Was Created
-- =====================================================

-- Check table structure
SELECT 
    'TABLE STRUCTURE' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'progress_photos'
ORDER BY ordinal_position;

-- Check table RLS policies
SELECT 
    'TABLE RLS POLICIES' as check_type,
    policyname,
    cmd as command
FROM pg_policies 
WHERE tablename = 'progress_photos';

-- Check storage bucket
SELECT 
    'STORAGE BUCKET' as check_type,
    id,
    name,
    public
FROM storage.buckets 
WHERE id = 'progress-photos';

-- Check storage policies
SELECT 
    'STORAGE POLICIES' as check_type,
    policyname,
    cmd as command
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects' 
AND policyname LIKE '%progress photos%';

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
-- If you see results above with:
-- ✅ 9 rows in TABLE STRUCTURE (including 'taken_at')
-- ✅ 4 rows in TABLE RLS POLICIES
-- ✅ 1 row in STORAGE BUCKET
-- ✅ 4 rows in STORAGE POLICIES
-- 
-- Then the migration was successful! 🎉

