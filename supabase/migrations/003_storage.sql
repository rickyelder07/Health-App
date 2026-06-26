-- Netfuel Storage: progress-photos bucket + RLS policies
-- Each user's files must live under their own UID folder: {user_id}/filename

INSERT INTO storage.buckets (id, name, public)
VALUES ('progress-photos', 'progress-photos', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Users can upload own photos"  ON storage.objects;
DROP POLICY IF EXISTS "Users can view own photos"    ON storage.objects;
DROP POLICY IF EXISTS "Users can update own photos"  ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own photos"  ON storage.objects;

CREATE POLICY "Users can upload own photos" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'progress-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can view own photos" ON storage.objects
    FOR SELECT TO authenticated
    USING (bucket_id = 'progress-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can update own photos" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id = 'progress-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can delete own photos" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'progress-photos' AND (storage.foldername(name))[1] = auth.uid()::text);
