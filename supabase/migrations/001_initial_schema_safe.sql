-- Health Tracker Database Schema (Safe Version)
-- Migration: 001_initial_schema_safe
-- Description: Initial database setup - safe to run multiple times

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- USERS TABLE (extends auth.users)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    weight DECIMAL(5,2),
    height DECIMAL(5,2),
    age INTEGER CHECK (age > 0 AND age < 150),
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),
    activity_level TEXT CHECK (activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extra_active')),
    bmr DECIMAL(7,2),
    tdee DECIMAL(7,2),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create index only if column exists
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'updated_at') THEN
        CREATE INDEX IF NOT EXISTS idx_users_updated_at ON public.users(updated_at);
    END IF;
END $$;

-- =====================================================
-- PROGRESS PHOTOS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.progress_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    weight DECIMAL(5,2),
    date_taken TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create indexes only if columns exist
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'progress_photos' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_progress_photos_user_id ON public.progress_photos(user_id);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'progress_photos' AND column_name = 'date_taken') THEN
        CREATE INDEX IF NOT EXISTS idx_progress_photos_date_taken ON public.progress_photos(user_id, date_taken DESC);
    END IF;
END $$;

-- =====================================================
-- STRAVA CONNECTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.strava_connections (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    athlete_id TEXT NOT NULL,
    athlete_username TEXT,
    athlete_firstname TEXT,
    athlete_lastname TEXT,
    connected_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create index only if column exists
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'strava_connections' AND column_name = 'athlete_id') THEN
        CREATE INDEX IF NOT EXISTS idx_strava_connections_athlete_id ON public.strava_connections(athlete_id);
    END IF;
END $$;

-- =====================================================
-- ACTIVITIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    strava_id BIGINT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    distance DECIMAL(10,2),
    duration INTEGER NOT NULL,
    calories INTEGER NOT NULL,
    average_speed DECIMAL(8,2),
    max_speed DECIMAL(8,2),
    average_heartrate DECIMAL(5,1),
    max_heartrate INTEGER,
    elevation_gain DECIMAL(8,2),
    start_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create indexes only if columns exist
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'activities' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_activities_user_id ON public.activities(user_id);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'activities' AND column_name = 'start_date') THEN
        CREATE INDEX IF NOT EXISTS idx_activities_start_date ON public.activities(user_id, start_date DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'activities' AND column_name = 'strava_id') THEN
        CREATE INDEX IF NOT EXISTS idx_activities_strava_id ON public.activities(strava_id);
    END IF;
END $$;

-- =====================================================
-- FOOD LOGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.food_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    food_name TEXT NOT NULL,
    brand_name TEXT,
    calories INTEGER NOT NULL CHECK (calories >= 0),
    protein DECIMAL(8,2) NOT NULL CHECK (protein >= 0),
    carbs DECIMAL(8,2) NOT NULL CHECK (carbs >= 0),
    fat DECIMAL(8,2) NOT NULL CHECK (fat >= 0),
    fiber DECIMAL(6,2) CHECK (fiber >= 0),
    sugar DECIMAL(6,2) CHECK (sugar >= 0),
    sodium DECIMAL(8,2) CHECK (sodium >= 0),
    serving_size TEXT NOT NULL,
    serving_unit TEXT NOT NULL DEFAULT 'g',
    servings DECIMAL(4,2) NOT NULL DEFAULT 1.0 CHECK (servings > 0),
    meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    usda_fdc_id TEXT,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create indexes only if columns exist
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'food_logs' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_food_logs_user_id ON public.food_logs(user_id);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'food_logs' AND column_name = 'logged_at') THEN
        -- Index on logged_at is sufficient for date-based queries
        CREATE INDEX IF NOT EXISTS idx_food_logs_logged_at ON public.food_logs(user_id, logged_at DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'food_logs' AND column_name = 'meal_type') THEN
        CREATE INDEX IF NOT EXISTS idx_food_logs_meal_type ON public.food_logs(user_id, meal_type);
    END IF;
END $$;

-- =====================================================
-- DAILY SUMMARIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.daily_summaries (
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    weight DECIMAL(5,2),
    calories_consumed INTEGER NOT NULL DEFAULT 0,
    protein_consumed DECIMAL(8,2) NOT NULL DEFAULT 0,
    carbs_consumed DECIMAL(8,2) NOT NULL DEFAULT 0,
    fat_consumed DECIMAL(8,2) NOT NULL DEFAULT 0,
    calories_burned_bmr INTEGER NOT NULL DEFAULT 0,
    calories_burned_exercise INTEGER NOT NULL DEFAULT 0,
    total_calories_burned INTEGER GENERATED ALWAYS AS (calories_burned_bmr + calories_burned_exercise) STORED,
    net_calories INTEGER GENERATED ALWAYS AS (calories_consumed - (calories_burned_bmr + calories_burned_exercise)) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    PRIMARY KEY (user_id, date)
);

-- Create indexes only if columns exist
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_summaries' AND column_name = 'date') THEN
        CREATE INDEX IF NOT EXISTS idx_daily_summaries_date ON public.daily_summaries(user_id, date DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_summaries' AND column_name = 'updated_at') THEN
        CREATE INDEX IF NOT EXISTS idx_daily_summaries_updated_at ON public.daily_summaries(updated_at);
    END IF;
END $$;

-- =====================================================
-- FUNCTIONS
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, created_at, updated_at)
    VALUES (NEW.id, NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRIGGERS
-- =====================================================

DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_strava_connections_updated_at ON public.strava_connections;
CREATE TRIGGER update_strava_connections_updated_at BEFORE UPDATE ON public.strava_connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_summaries_updated_at ON public.daily_summaries;
CREATE TRIGGER update_daily_summaries_updated_at BEFORE UPDATE ON public.daily_summaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strava_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_summaries ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
    DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
    DROP POLICY IF EXISTS "Allow trigger to insert users" ON public.users;
    DROP POLICY IF EXISTS "Users can view own photos" ON public.progress_photos;
    DROP POLICY IF EXISTS "Users can insert own photos" ON public.progress_photos;
    DROP POLICY IF EXISTS "Users can update own photos" ON public.progress_photos;
    DROP POLICY IF EXISTS "Users can delete own photos" ON public.progress_photos;
    DROP POLICY IF EXISTS "Users can view own strava connection" ON public.strava_connections;
    DROP POLICY IF EXISTS "Users can insert own strava connection" ON public.strava_connections;
    DROP POLICY IF EXISTS "Users can update own strava connection" ON public.strava_connections;
    DROP POLICY IF EXISTS "Users can delete own strava connection" ON public.strava_connections;
    DROP POLICY IF EXISTS "Users can view own activities" ON public.activities;
    DROP POLICY IF EXISTS "Users can insert own activities" ON public.activities;
    DROP POLICY IF EXISTS "Users can update own activities" ON public.activities;
    DROP POLICY IF EXISTS "Users can delete own activities" ON public.activities;
    DROP POLICY IF EXISTS "Users can view own food logs" ON public.food_logs;
    DROP POLICY IF EXISTS "Users can insert own food logs" ON public.food_logs;
    DROP POLICY IF EXISTS "Users can update own food logs" ON public.food_logs;
    DROP POLICY IF EXISTS "Users can delete own food logs" ON public.food_logs;
    DROP POLICY IF EXISTS "Users can view own daily summaries" ON public.daily_summaries;
    DROP POLICY IF EXISTS "Users can insert own daily summaries" ON public.daily_summaries;
    DROP POLICY IF EXISTS "Users can update own daily summaries" ON public.daily_summaries;
    DROP POLICY IF EXISTS "Users can delete own daily summaries" ON public.daily_summaries;
EXCEPTION WHEN undefined_object THEN NULL;
END $$;

-- Create policies
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Allow trigger to insert users" ON public.users FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view own photos" ON public.progress_photos FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own photos" ON public.progress_photos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own photos" ON public.progress_photos FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own photos" ON public.progress_photos FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own strava connection" ON public.strava_connections FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own strava connection" ON public.strava_connections FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own strava connection" ON public.strava_connections FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own strava connection" ON public.strava_connections FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own activities" ON public.activities FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own activities" ON public.activities FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own activities" ON public.activities FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own activities" ON public.activities FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own food logs" ON public.food_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own food logs" ON public.food_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own food logs" ON public.food_logs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own food logs" ON public.food_logs FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own daily summaries" ON public.daily_summaries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own daily summaries" ON public.daily_summaries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own daily summaries" ON public.daily_summaries FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own daily summaries" ON public.daily_summaries FOR DELETE USING (auth.uid() = user_id);

