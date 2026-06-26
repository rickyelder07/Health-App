# Migration Notes

## One-time data repair: photo URLs

`database_migrations/FIX_PHOTO_URLS.sql` was the only file from the old `database_migrations/`
folder that isn't covered by the consolidated migrations.

If any rows in `progress_photos` have `photo_url` or `thumbnail_url` stored as full
Supabase URLs (starting with `https://`) instead of relative storage paths, run this
in the SQL editor:

```sql
UPDATE progress_photos
SET photo_url = REGEXP_REPLACE(
    photo_url,
    '^https?://[^/]+/storage/v1/object/(public|sign)/progress-photos/(.+?)(\?.*)?$',
    '\2'
)
WHERE photo_url LIKE 'https://%';

UPDATE progress_photos
SET thumbnail_url = REGEXP_REPLACE(
    thumbnail_url,
    '^https?://[^/]+/storage/v1/object/(public|sign)/progress-photos/(.+?)(\?.*)?$',
    '\2'
)
WHERE thumbnail_url LIKE 'https://%';
```

This is only needed for records created before the app was fixed to store paths instead
of full URLs. New uploads are fine.

---

## Schema correction applied during consolidation

The old `001_initial_schema_safe.sql` had `date_taken` on the `progress_photos` table.
The live database (rebuilt via `progress_photos_schema_FIXED.sql`) uses `taken_at` and
also adds an `updated_at` column. The consolidated `001_schema.sql` reflects the correct
live schema (`taken_at` + `updated_at`).
