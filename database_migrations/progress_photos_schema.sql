-- =====================================================
-- Progress Photos System Database Schema
-- =====================================================
-- This file contains the SQL schema for progress photos storage.
-- Run these statements in your Supabase SQL editor.

-- =====================================================
-- STORAGE BUCKET SETUP
-- =====================================================
-- Create storage bucket for progress photos
-- Run this in Supabase Dashboard > Storage

-- 1. Go to Storage in Supabase Dashboard
-- 2. Click "New Bucket"
-- 3. Name: "progress-photos"
-- 4. Public: OFF (keep private)
-- 5. Click "Create Bucket"

-- OR run this SQL to create the bucket programmatically:
INSERT INTO storage.buckets (id, name, public)
VALUES ('progress-photos', 'progress-photos', false)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STORAGE POLICIES (Row Level Security)
-- =====================================================

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
-- PROGRESS_PHOTOS TABLE (already exists from initial setup)
-- =====================================================
-- Verify the table exists and has correct structure

-- If table doesn't exist, create it:
CREATE TABLE IF NOT EXISTS progress_photos (
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
CREATE INDEX IF NOT EXISTS idx_progress_photos_user_id ON progress_photos(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_photos_taken_at ON progress_photos(user_id, taken_at DESC);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on progress_photos table
ALTER TABLE progress_photos ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (in case of re-run)
DROP POLICY IF EXISTS "Users can view their own progress photos" ON progress_photos;
DROP POLICY IF EXISTS "Users can insert their own progress photos" ON progress_photos;
DROP POLICY IF EXISTS "Users can update their own progress photos" ON progress_photos;
DROP POLICY IF EXISTS "Users can delete their own progress photos" ON progress_photos;

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
-- TRIGGER FOR UPDATED_AT
-- =====================================================

-- Create trigger to auto-update updated_at timestamp
CREATE TRIGGER update_progress_photos_updated_at 
    BEFORE UPDATE ON progress_photos
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- STORAGE SIZE LIMITS (Optional)
-- =====================================================
-- Set maximum file size for uploads (e.g., 10MB)
-- This is done in Supabase Dashboard > Storage > progress-photos > Settings
-- Or via Supabase API configuration

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify bucket exists
SELECT * FROM storage.buckets WHERE id = 'progress-photos';

-- Verify storage policies
SELECT * FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects' 
AND policyname LIKE '%progress photos%';

-- Verify table exists
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'progress_photos'
ORDER BY ordinal_position;

-- Verify RLS policies on table
SELECT * FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'progress_photos';

-- =====================================================
-- SAMPLE QUERIES FOR TESTING
-- =====================================================

-- Get all progress photos for a user (ordered by date)
-- SELECT * FROM progress_photos 
-- WHERE user_id = 'YOUR_USER_ID' 
-- ORDER BY taken_at DESC;

-- Get photos with weight measurements
-- SELECT * FROM progress_photos 
-- WHERE user_id = 'YOUR_USER_ID' 
-- AND weight IS NOT NULL
-- ORDER BY taken_at DESC;

-- Get photos in date range
-- SELECT * FROM progress_photos 
-- WHERE user_id = 'YOUR_USER_ID' 
-- AND taken_at BETWEEN '2025-01-01' AND '2025-12-31'
-- ORDER BY taken_at DESC;

-- Count total photos for user
-- SELECT COUNT(*) as total_photos 
-- FROM progress_photos 
-- WHERE user_id = 'YOUR_USER_ID';

