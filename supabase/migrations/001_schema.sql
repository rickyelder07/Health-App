-- Netfuel Database Schema
-- Consolidates: 001_initial_schema_safe, 003_add_user_name, 004_add_missing_schema,
--               005_add_food_log_references, 009_add_thumbnail_url
-- Safe to re-run (idempotent).
--
-- NOTE: progress_photos uses `taken_at` (not `date_taken`) to match the iOS model.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- USERS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
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

CREATE INDEX IF NOT EXISTS idx_users_updated_at ON public.users(updated_at);

-- =====================================================
-- PROGRESS PHOTOS
-- (uses taken_at, not date_taken — matches iOS ProgressPhoto model)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.progress_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    thumbnail_url TEXT,
    weight DECIMAL(5,2),
    notes TEXT,
    taken_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_progress_photos_user_id ON public.progress_photos(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_photos_taken_at ON public.progress_photos(user_id, taken_at DESC);

-- =====================================================
-- STRAVA CONNECTIONS
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

CREATE INDEX IF NOT EXISTS idx_strava_connections_athlete_id ON public.strava_connections(athlete_id);

-- =====================================================
-- ACTIVITIES
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

CREATE INDEX IF NOT EXISTS idx_activities_user_id ON public.activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_start_date ON public.activities(user_id, start_date DESC);
CREATE INDEX IF NOT EXISTS idx_activities_strava_id ON public.activities(strava_id);

-- =====================================================
-- FOOD LOGS
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
    custom_food_id UUID,  -- FK added after custom_foods table below
    custom_meal_id UUID,  -- FK added after custom_meals table below
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_food_logs_user_id ON public.food_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_food_logs_logged_at ON public.food_logs(user_id, logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_food_logs_meal_type ON public.food_logs(user_id, meal_type);

-- =====================================================
-- DAILY SUMMARIES
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
    calorie_goal INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    PRIMARY KEY (user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_daily_summaries_date ON public.daily_summaries(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_summaries_updated_at ON public.daily_summaries(updated_at);

-- =====================================================
-- CUSTOM FOODS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.custom_foods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    brand TEXT,
    calories INTEGER NOT NULL,
    protein DECIMAL(8,2) NOT NULL DEFAULT 0,
    carbs DECIMAL(8,2) NOT NULL DEFAULT 0,
    fat DECIMAL(8,2) NOT NULL DEFAULT 0,
    fiber DECIMAL(8,2),
    sugar DECIMAL(8,2),
    sodium DECIMAL(8,2),
    serving_size TEXT NOT NULL,
    serving_unit TEXT NOT NULL,
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_custom_foods_user_id ON public.custom_foods(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_foods_is_favorite ON public.custom_foods(user_id, is_favorite);

-- =====================================================
-- CUSTOM MEALS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.custom_meals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    total_calories INTEGER NOT NULL DEFAULT 0,
    total_protein DECIMAL(8,2) NOT NULL DEFAULT 0,
    total_carbs DECIMAL(8,2) NOT NULL DEFAULT 0,
    total_fat DECIMAL(8,2) NOT NULL DEFAULT 0,
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.custom_meal_foods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meal_id UUID NOT NULL REFERENCES public.custom_meals(id) ON DELETE CASCADE,
    custom_food_id UUID REFERENCES public.custom_foods(id) ON DELETE SET NULL,
    usda_fdc_id TEXT,
    food_name TEXT NOT NULL,
    brand_name TEXT,
    quantity DECIMAL(8,2) NOT NULL DEFAULT 1,
    serving_size TEXT NOT NULL,
    serving_unit TEXT NOT NULL,
    calories INTEGER NOT NULL DEFAULT 0,
    protein DECIMAL(8,2) NOT NULL DEFAULT 0,
    carbs DECIMAL(8,2) NOT NULL DEFAULT 0,
    fat DECIMAL(8,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT check_food_source CHECK (
        (custom_food_id IS NOT NULL AND usda_fdc_id IS NULL) OR
        (custom_food_id IS NULL AND usda_fdc_id IS NOT NULL) OR
        (custom_food_id IS NULL AND usda_fdc_id IS NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_custom_meals_user_id ON public.custom_meals(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_meal_foods_meal_id ON public.custom_meal_foods(meal_id);

-- Add FKs to food_logs now that custom_foods/custom_meals exist
ALTER TABLE public.food_logs
    ADD COLUMN IF NOT EXISTS custom_food_id UUID REFERENCES public.custom_foods(id) ON DELETE SET NULL;
ALTER TABLE public.food_logs
    ADD COLUMN IF NOT EXISTS custom_meal_id UUID REFERENCES public.custom_meals(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_food_logs_custom_food_id ON public.food_logs(custom_food_id) WHERE custom_food_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_food_logs_custom_meal_id ON public.food_logs(custom_meal_id) WHERE custom_meal_id IS NOT NULL;

-- =====================================================
-- SHARED FUNCTIONS
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

CREATE OR REPLACE FUNCTION update_custom_meal_totals()
RETURNS TRIGGER AS $$
DECLARE
    target_meal_id UUID;
BEGIN
    target_meal_id := COALESCE(NEW.meal_id, OLD.meal_id);
    UPDATE public.custom_meals SET
        total_calories = (SELECT COALESCE(SUM(calories), 0) FROM public.custom_meal_foods WHERE meal_id = target_meal_id),
        total_protein  = (SELECT COALESCE(SUM(protein),  0) FROM public.custom_meal_foods WHERE meal_id = target_meal_id),
        total_carbs    = (SELECT COALESCE(SUM(carbs),    0) FROM public.custom_meal_foods WHERE meal_id = target_meal_id),
        total_fat      = (SELECT COALESCE(SUM(fat),      0) FROM public.custom_meal_foods WHERE meal_id = target_meal_id),
        updated_at     = NOW()
    WHERE id = target_meal_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS
-- =====================================================

DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_strava_connections_updated_at ON public.strava_connections;
CREATE TRIGGER update_strava_connections_updated_at
    BEFORE UPDATE ON public.strava_connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_summaries_updated_at ON public.daily_summaries;
CREATE TRIGGER update_daily_summaries_updated_at
    BEFORE UPDATE ON public.daily_summaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_progress_photos_updated_at ON public.progress_photos;
CREATE TRIGGER update_progress_photos_updated_at
    BEFORE UPDATE ON public.progress_photos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_custom_foods_updated_at ON public.custom_foods;
CREATE TRIGGER update_custom_foods_updated_at
    BEFORE UPDATE ON public.custom_foods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_custom_meals_updated_at ON public.custom_meals;
CREATE TRIGGER update_custom_meals_updated_at
    BEFORE UPDATE ON public.custom_meals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS sync_custom_meal_totals ON public.custom_meal_foods;
CREATE TRIGGER sync_custom_meal_totals
    AFTER INSERT OR UPDATE OR DELETE ON public.custom_meal_foods
    FOR EACH ROW EXECUTE FUNCTION update_custom_meal_totals();

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
ALTER TABLE public.custom_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.custom_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.custom_meal_foods ENABLE ROW LEVEL SECURITY;

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
    DROP POLICY IF EXISTS "Users can view own custom foods" ON public.custom_foods;
    DROP POLICY IF EXISTS "Users can insert own custom foods" ON public.custom_foods;
    DROP POLICY IF EXISTS "Users can update own custom foods" ON public.custom_foods;
    DROP POLICY IF EXISTS "Users can delete own custom foods" ON public.custom_foods;
    DROP POLICY IF EXISTS "Users can view own custom meals" ON public.custom_meals;
    DROP POLICY IF EXISTS "Users can insert own custom meals" ON public.custom_meals;
    DROP POLICY IF EXISTS "Users can update own custom meals" ON public.custom_meals;
    DROP POLICY IF EXISTS "Users can delete own custom meals" ON public.custom_meals;
    DROP POLICY IF EXISTS "Users can view own meal foods" ON public.custom_meal_foods;
    DROP POLICY IF EXISTS "Users can insert own meal foods" ON public.custom_meal_foods;
    DROP POLICY IF EXISTS "Users can update own meal foods" ON public.custom_meal_foods;
    DROP POLICY IF EXISTS "Users can delete own meal foods" ON public.custom_meal_foods;
EXCEPTION WHEN undefined_object THEN NULL;
END $$;

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

CREATE POLICY "Users can view own custom foods" ON public.custom_foods FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own custom foods" ON public.custom_foods FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own custom foods" ON public.custom_foods FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own custom foods" ON public.custom_foods FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own custom meals" ON public.custom_meals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own custom meals" ON public.custom_meals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own custom meals" ON public.custom_meals FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own custom meals" ON public.custom_meals FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own meal foods" ON public.custom_meal_foods FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.custom_meals WHERE id = meal_id AND user_id = auth.uid())
);
CREATE POLICY "Users can insert own meal foods" ON public.custom_meal_foods FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.custom_meals WHERE id = meal_id AND user_id = auth.uid())
);
CREATE POLICY "Users can update own meal foods" ON public.custom_meal_foods FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.custom_meals WHERE id = meal_id AND user_id = auth.uid())
);
CREATE POLICY "Users can delete own meal foods" ON public.custom_meal_foods FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.custom_meals WHERE id = meal_id AND user_id = auth.uid())
);
