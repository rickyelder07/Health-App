# Supabase Database Setup

This directory contains SQL migration scripts for the Health Tracker app database.

## Migrations

1. **001_initial_schema.sql** - Core database tables and RLS policies
2. **002_helper_functions.sql** - Utility functions for calculations and automation

## How to Apply Migrations

### Option 1: Supabase Dashboard (Recommended for First Setup)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Click **"New Query"**
4. Copy the contents of `001_initial_schema.sql`
5. Paste and click **"Run"**
6. Repeat for `002_helper_functions.sql`

### Option 2: Supabase CLI

```bash
# Install Supabase CLI if you haven't
brew install supabase/tap/supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Apply migrations
supabase db push
```

### Option 3: Direct SQL Execution

```bash
# Using psql (requires database connection string)
psql "postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres" \
  -f migrations/001_initial_schema.sql

psql "postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres" \
  -f migrations/002_helper_functions.sql
```

## Database Schema Overview

### Tables

1. **users** - User profiles extending auth.users
   - Stores physical stats (weight, height, age, gender)
   - Auto-calculates BMR and TDEE
   - Links to auth.users via foreign key

2. **progress_photos** - Visual progress tracking
   - Stores photo URLs from Supabase Storage
   - Optional weight and notes per photo

3. **strava_connections** - Strava OAuth credentials
   - Stores access/refresh tokens
   - Athlete information
   - One connection per user

4. **activities** - Exercise data from Strava
   - Synced from Strava API
   - Prevents duplicates via unique strava_id
   - Includes calories, distance, duration, etc.

5. **food_logs** - Food entries with macros
   - Detailed nutrition information
   - References USDA FoodData Central
   - Supports multiple servings

6. **daily_summaries** - Aggregated daily data
   - Auto-calculated from food_logs and activities
   - Computed columns for totals and net calories
   - One row per user per day

### Key Features

#### Automatic BMR/TDEE Calculation
When a user updates their physical stats, BMR and TDEE are automatically calculated using the Mifflin-St Jeor equation.

#### Auto-Updating Daily Summaries
Daily summaries are automatically updated when:
- Food logs are added/updated/deleted
- Activities are added/updated/deleted
- User's BMR changes

#### Row Level Security (RLS)
All tables have RLS enabled. Users can only:
- View their own data
- Insert their own data
- Update their own data
- Delete their own data

#### Duplicate Prevention
- Strava activities are deduplicated by `strava_id`
- Daily summaries use composite primary key (user_id, date)

## Storage Bucket Setup

After running migrations, create the storage bucket for progress photos:

### Via Supabase Dashboard

1. Go to **Storage** in your Supabase dashboard
2. Click **"Create a new bucket"**
3. Name: `progress-photos`
4. Set to **Private**
5. Click **"Create bucket"**

### Storage Policies

Run these SQL commands in the SQL Editor:

```sql
-- Allow users to upload their own photos
CREATE POLICY "Users can upload own photos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'progress-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to view their own photos
CREATE POLICY "Users can view own photos"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'progress-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to delete their own photos
CREATE POLICY "Users can delete own photos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'progress-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);
```

## Useful SQL Queries

### Get User's Daily Summary for Today
```sql
SELECT * FROM daily_summaries
WHERE user_id = auth.uid()
  AND date = CURRENT_DATE;
```

### Get User's Weekly Average
```sql
SELECT * FROM get_weekly_summary(
    auth.uid(),
    CURRENT_DATE - INTERVAL '7 days',
    CURRENT_DATE
);
```

### Get Recent Food Logs
```sql
SELECT * FROM food_logs
WHERE user_id = auth.uid()
ORDER BY logged_at DESC
LIMIT 20;
```

### Get Recent Activities
```sql
SELECT * FROM activities
WHERE user_id = auth.uid()
ORDER BY start_date DESC
LIMIT 10;
```

### Calculate User's Current BMR
```sql
SELECT 
    weight,
    height,
    age,
    gender,
    calculate_bmr(weight, height, age, gender) as calculated_bmr,
    bmr as stored_bmr
FROM users
WHERE id = auth.uid();
```

## Testing the Setup

After applying migrations, test with these queries:

```sql
-- 1. Check if user profile was auto-created
SELECT * FROM users WHERE id = auth.uid();

-- 2. Update user stats and verify BMR/TDEE calculation
UPDATE users SET
    weight = 70,
    height = 175,
    age = 30,
    gender = 'male',
    activity_level = 'moderately_active'
WHERE id = auth.uid();

-- Verify BMR and TDEE were calculated
SELECT bmr, tdee FROM users WHERE id = auth.uid();

-- 3. Add a test food log
INSERT INTO food_logs (
    user_id, food_name, calories, protein, carbs, fat,
    serving_size, serving_unit, meal_type
) VALUES (
    auth.uid(), 'Test Food', 200, 10, 20, 5,
    '100', 'g', 'breakfast'
);

-- 4. Check if daily summary was auto-created
SELECT * FROM daily_summaries
WHERE user_id = auth.uid()
  AND date = CURRENT_DATE;
```

## Troubleshooting

### RLS Policies Not Working
Make sure you're authenticated when running queries. Use `auth.uid()` to reference the current user.

### BMR/TDEE Not Calculating
Ensure all required fields are set:
- weight (decimal)
- height (decimal)
- age (integer)
- gender ('male', 'female', or 'other')
- activity_level (one of the allowed values)

### Daily Summary Not Updating
Check that:
- Food logs have valid `logged_at` timestamps
- Activities have valid `start_date` timestamps
- User has a valid BMR in the users table

### Duplicate Strava Activities
The `strava_id` column has a unique constraint. If you try to insert a duplicate, it will fail. This is intentional to prevent duplicate activity imports.

## Maintenance

### Recalculate All Daily Summaries
```sql
-- For a specific user
SELECT upsert_daily_summary(auth.uid(), generate_series::date)
FROM generate_series(
    CURRENT_DATE - INTERVAL '30 days',
    CURRENT_DATE,
    '1 day'::interval
);
```

### Clean Up Old Data
```sql
-- Delete food logs older than 1 year
DELETE FROM food_logs
WHERE user_id = auth.uid()
  AND logged_at < CURRENT_DATE - INTERVAL '1 year';

-- Delete activities older than 1 year
DELETE FROM activities
WHERE user_id = auth.uid()
  AND start_date < CURRENT_DATE - INTERVAL '1 year';
```

## Support

For issues with the database schema or migrations, check:
- Supabase documentation: https://supabase.com/docs
- PostgreSQL documentation: https://www.postgresql.org/docs/

