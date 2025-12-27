-- Health Tracker Database Schema
-- Migration: 001_initial_schema
-- Description: Initial database setup for calorie tracking app with Strava integration

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- USERS TABLE (extends auth.users)
-- =====================================================
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    weight DECIMAL(5,2), -- in kg
    height DECIMAL(5,2), -- in cm
    age INTEGER CHECK (age > 0 AND age < 150),
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),
    activity_level TEXT CHECK (activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extra_active')),
    bmr DECIMAL(7,2), -- Basal Metabolic Rate
    tdee DECIMAL(7,2), -- Total Daily Energy Expenditure
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for users
CREATE INDEX idx_users_updated_at ON public.users(updated_at);

COMMENT ON TABLE public.users IS 'User profile data extending Supabase auth.users';
COMMENT ON COLUMN public.users.activity_level IS 'Activity level for TDEE calculation: sedentary, lightly_active, moderately_active, very_active, extra_active';

-- =====================================================
-- PROGRESS PHOTOS TABLE
-- =====================================================
CREATE TABLE public.progress_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    weight DECIMAL(5,2), -- Weight at time of photo (kg)
    date_taken TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for progress_photos
CREATE INDEX idx_progress_photos_user_id ON public.progress_photos(user_id);
CREATE INDEX idx_progress_photos_date_taken ON public.progress_photos(user_id, date_taken DESC);

COMMENT ON TABLE public.progress_photos IS 'User progress photos for visual tracking';

-- =====================================================
-- STRAVA CONNECTIONS TABLE
-- =====================================================
CREATE TABLE public.strava_connections (
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

-- Index for strava_connections
CREATE INDEX idx_strava_connections_athlete_id ON public.strava_connections(athlete_id);

COMMENT ON TABLE public.strava_connections IS 'Strava OAuth tokens and athlete information';

-- =====================================================
-- ACTIVITIES TABLE (from Strava)
-- =====================================================
CREATE TABLE public.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    strava_id BIGINT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- Run, Ride, Swim, etc.
    distance DECIMAL(10,2), -- in meters
    duration INTEGER NOT NULL, -- in seconds
    calories INTEGER NOT NULL,
    average_speed DECIMAL(8,2), -- in meters per second
    max_speed DECIMAL(8,2),
    average_heartrate DECIMAL(5,1),
    max_heartrate INTEGER,
    elevation_gain DECIMAL(8,2), -- in meters
    start_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for activities
CREATE INDEX idx_activities_user_id ON public.activities(user_id);
CREATE INDEX idx_activities_start_date ON public.activities(user_id, start_date DESC);
CREATE INDEX idx_activities_strava_id ON public.activities(strava_id);

COMMENT ON TABLE public.activities IS 'Exercise activities synced from Strava';
COMMENT ON COLUMN public.activities.strava_id IS 'Unique Strava activity ID for deduplication';

-- =====================================================
-- FOOD LOGS TABLE
-- =====================================================
CREATE TABLE public.food_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    food_name TEXT NOT NULL,
    brand_name TEXT,
    calories INTEGER NOT NULL CHECK (calories >= 0),
    protein DECIMAL(8,2) NOT NULL CHECK (protein >= 0), -- in grams
    carbs DECIMAL(8,2) NOT NULL CHECK (carbs >= 0), -- in grams
    fat DECIMAL(8,2) NOT NULL CHECK (fat >= 0), -- in grams
    fiber DECIMAL(6,2) CHECK (fiber >= 0), -- in grams
    sugar DECIMAL(6,2) CHECK (sugar >= 0), -- in grams
    sodium DECIMAL(8,2) CHECK (sodium >= 0), -- in mg
    serving_size TEXT NOT NULL,
    serving_unit TEXT NOT NULL DEFAULT 'g',
    servings DECIMAL(4,2) NOT NULL DEFAULT 1.0 CHECK (servings > 0),
    meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    usda_fdc_id TEXT, -- USDA FoodData Central ID
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for food_logs
CREATE INDEX idx_food_logs_user_id ON public.food_logs(user_id);
CREATE INDEX idx_food_logs_logged_at ON public.food_logs(user_id, logged_at DESC);
CREATE INDEX idx_food_logs_meal_type ON public.food_logs(user_id, meal_type);
CREATE INDEX idx_food_logs_date ON public.food_logs(user_id, DATE(logged_at));

COMMENT ON TABLE public.food_logs IS 'Individual food entries logged by users';
COMMENT ON COLUMN public.food_logs.usda_fdc_id IS 'Reference to USDA FoodData Central for nutrition info';

-- =====================================================
-- DAILY SUMMARIES TABLE
-- =====================================================
CREATE TABLE public.daily_summaries (
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    weight DECIMAL(5,2), -- Daily weight measurement (kg)
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

-- Indexes for daily_summaries
CREATE INDEX idx_daily_summaries_date ON public.daily_summaries(user_id, date DESC);
CREATE INDEX idx_daily_summaries_updated_at ON public.daily_summaries(updated_at);

COMMENT ON TABLE public.daily_summaries IS 'Aggregated daily nutrition and calorie data';
COMMENT ON COLUMN public.daily_summaries.total_calories_burned IS 'Computed: BMR + Exercise calories';
COMMENT ON COLUMN public.daily_summaries.net_calories IS 'Computed: Consumed - Total Burned';

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_strava_connections_updated_at BEFORE UPDATE ON public.strava_connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_summaries_updated_at BEFORE UPDATE ON public.daily_summaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create user profile after signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, created_at, updated_at)
    VALUES (NEW.id, NOW(), NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile on auth.users insert
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strava_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_summaries ENABLE ROW LEVEL SECURITY;

-- USERS TABLE POLICIES
CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

-- PROGRESS PHOTOS POLICIES
CREATE POLICY "Users can view own photos"
    ON public.progress_photos FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own photos"
    ON public.progress_photos FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own photos"
    ON public.progress_photos FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own photos"
    ON public.progress_photos FOR DELETE
    USING (auth.uid() = user_id);

-- STRAVA CONNECTIONS POLICIES
CREATE POLICY "Users can view own strava connection"
    ON public.strava_connections FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own strava connection"
    ON public.strava_connections FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own strava connection"
    ON public.strava_connections FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own strava connection"
    ON public.strava_connections FOR DELETE
    USING (auth.uid() = user_id);

-- ACTIVITIES POLICIES
CREATE POLICY "Users can view own activities"
    ON public.activities FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own activities"
    ON public.activities FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own activities"
    ON public.activities FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own activities"
    ON public.activities FOR DELETE
    USING (auth.uid() = user_id);

-- FOOD LOGS POLICIES
CREATE POLICY "Users can view own food logs"
    ON public.food_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own food logs"
    ON public.food_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own food logs"
    ON public.food_logs FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own food logs"
    ON public.food_logs FOR DELETE
    USING (auth.uid() = user_id);

-- DAILY SUMMARIES POLICIES
CREATE POLICY "Users can view own daily summaries"
    ON public.daily_summaries FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily summaries"
    ON public.daily_summaries FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily summaries"
    ON public.daily_summaries FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own daily summaries"
    ON public.daily_summaries FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- STORAGE BUCKET FOR PROGRESS PHOTOS
-- =====================================================

-- Create storage bucket for progress photos (run this in Supabase Dashboard or via API)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('progress-photos', 'progress-photos', false);

-- Storage policies (run after bucket is created)
-- CREATE POLICY "Users can upload own photos"
--     ON storage.objects FOR INSERT
--     WITH CHECK (
--         bucket_id = 'progress-photos' 
--         AND auth.uid()::text = (storage.foldername(name))[1]
--     );

-- CREATE POLICY "Users can view own photos"
--     ON storage.objects FOR SELECT
--     USING (
--         bucket_id = 'progress-photos' 
--         AND auth.uid()::text = (storage.foldername(name))[1]
--     );

-- CREATE POLICY "Users can delete own photos"
--     ON storage.objects FOR DELETE
--     USING (
--         bucket_id = 'progress-photos' 
--         AND auth.uid()::text = (storage.foldername(name))[1]
--     );

