-- =====================================================
-- Food Logging System Database Schema
-- =====================================================
-- This file contains the SQL schema for custom foods, meals, and meal foods.
-- Run these statements in your Supabase SQL editor.

-- =====================================================
-- CUSTOM FOODS TABLE
-- =====================================================
-- Stores user-created custom foods with full nutrition info
CREATE TABLE IF NOT EXISTS custom_foods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    brand TEXT,
    calories INTEGER NOT NULL,
    protein DECIMAL(10, 2) NOT NULL DEFAULT 0,
    carbs DECIMAL(10, 2) NOT NULL DEFAULT 0,
    fat DECIMAL(10, 2) NOT NULL DEFAULT 0,
    fiber DECIMAL(10, 2),
    sugar DECIMAL(10, 2),
    sodium DECIMAL(10, 2),
    serving_size TEXT NOT NULL,
    serving_unit TEXT NOT NULL,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast user queries
CREATE INDEX IF NOT EXISTS idx_custom_foods_user_id ON custom_foods(user_id);

-- Index for favorite foods
CREATE INDEX IF NOT EXISTS idx_custom_foods_favorites ON custom_foods(user_id, is_favorite) WHERE is_favorite = TRUE;

-- =====================================================
-- CUSTOM MEALS TABLE
-- =====================================================
-- Stores user-created meals (combinations of foods)
CREATE TABLE IF NOT EXISTS custom_meals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    total_calories INTEGER NOT NULL DEFAULT 0,
    total_protein DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_carbs DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_fat DECIMAL(10, 2) NOT NULL DEFAULT 0,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast user queries
CREATE INDEX IF NOT EXISTS idx_custom_meals_user_id ON custom_meals(user_id);

-- Index for favorite meals
CREATE INDEX IF NOT EXISTS idx_custom_meals_favorites ON custom_meals(user_id, is_favorite) WHERE is_favorite = TRUE;

-- =====================================================
-- CUSTOM MEAL FOODS TABLE (Junction Table)
-- =====================================================
-- Links foods to meals with quantities
CREATE TABLE IF NOT EXISTS custom_meal_foods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meal_id UUID NOT NULL REFERENCES custom_meals(id) ON DELETE CASCADE,
    
    -- Either custom food OR USDA food (one will be null)
    custom_food_id UUID REFERENCES custom_foods(id) ON DELETE SET NULL,
    usda_fdc_id TEXT,
    
    -- Cached food information (in case source is deleted)
    food_name TEXT NOT NULL,
    brand_name TEXT,
    
    -- Quantity and nutrition for this food in the meal
    quantity DECIMAL(10, 2) NOT NULL DEFAULT 1,
    serving_size TEXT NOT NULL,
    serving_unit TEXT NOT NULL,
    
    -- Nutritional values for this food item in the meal
    calories INTEGER NOT NULL,
    protein DECIMAL(10, 2) NOT NULL,
    carbs DECIMAL(10, 2) NOT NULL,
    fat DECIMAL(10, 2) NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint: must have either custom_food_id OR usda_fdc_id
    CONSTRAINT check_food_source CHECK (
        (custom_food_id IS NOT NULL AND usda_fdc_id IS NULL) OR
        (custom_food_id IS NULL AND usda_fdc_id IS NOT NULL)
    )
);

-- Index for fast meal queries
CREATE INDEX IF NOT EXISTS idx_custom_meal_foods_meal_id ON custom_meal_foods(meal_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE custom_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_meal_foods ENABLE ROW LEVEL SECURITY;

-- Custom Foods Policies
-- Users can only see their own custom foods
CREATE POLICY "Users can view their own custom foods"
    ON custom_foods FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own custom foods"
    ON custom_foods FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own custom foods"
    ON custom_foods FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own custom foods"
    ON custom_foods FOR DELETE
    USING (auth.uid() = user_id);

-- Custom Meals Policies
-- Users can only see their own custom meals
CREATE POLICY "Users can view their own custom meals"
    ON custom_meals FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own custom meals"
    ON custom_meals FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own custom meals"
    ON custom_meals FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own custom meals"
    ON custom_meals FOR DELETE
    USING (auth.uid() = user_id);

-- Custom Meal Foods Policies
-- Users can see meal foods for meals they own
CREATE POLICY "Users can view their own meal foods"
    ON custom_meal_foods FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM custom_meals
            WHERE custom_meals.id = custom_meal_foods.meal_id
            AND custom_meals.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert meal foods for their meals"
    ON custom_meal_foods FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM custom_meals
            WHERE custom_meals.id = custom_meal_foods.meal_id
            AND custom_meals.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update meal foods for their meals"
    ON custom_meal_foods FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM custom_meals
            WHERE custom_meals.id = custom_meal_foods.meal_id
            AND custom_meals.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete meal foods for their meals"
    ON custom_meal_foods FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM custom_meals
            WHERE custom_meals.id = custom_meal_foods.meal_id
            AND custom_meals.user_id = auth.uid()
        )
    );

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for custom_foods
CREATE TRIGGER update_custom_foods_updated_at BEFORE UPDATE ON custom_foods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for custom_meals
CREATE TRIGGER update_custom_meals_updated_at BEFORE UPDATE ON custom_meals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTION TO AUTO-UPDATE MEAL TOTALS
-- =====================================================
-- This function automatically recalculates meal totals when foods are added/removed/updated

CREATE OR REPLACE FUNCTION update_meal_totals()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the meal's total nutrition values
    UPDATE custom_meals
    SET
        total_calories = COALESCE((
            SELECT SUM(calories * quantity)
            FROM custom_meal_foods
            WHERE meal_id = COALESCE(NEW.meal_id, OLD.meal_id)
        ), 0),
        total_protein = COALESCE((
            SELECT SUM(protein * quantity)
            FROM custom_meal_foods
            WHERE meal_id = COALESCE(NEW.meal_id, OLD.meal_id)
        ), 0),
        total_carbs = COALESCE((
            SELECT SUM(carbs * quantity)
            FROM custom_meal_foods
            WHERE meal_id = COALESCE(NEW.meal_id, OLD.meal_id)
        ), 0),
        total_fat = COALESCE((
            SELECT SUM(fat * quantity)
            FROM custom_meal_foods
            WHERE meal_id = COALESCE(NEW.meal_id, OLD.meal_id)
        ), 0)
    WHERE id = COALESCE(NEW.meal_id, OLD.meal_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Triggers to update meal totals
CREATE TRIGGER update_meal_totals_on_insert
    AFTER INSERT ON custom_meal_foods
    FOR EACH ROW
    EXECUTE FUNCTION update_meal_totals();

CREATE TRIGGER update_meal_totals_on_update
    AFTER UPDATE ON custom_meal_foods
    FOR EACH ROW
    EXECUTE FUNCTION update_meal_totals();

CREATE TRIGGER update_meal_totals_on_delete
    AFTER DELETE ON custom_meal_foods
    FOR EACH ROW
    EXECUTE FUNCTION update_meal_totals();

-- =====================================================
-- FOOD_LOGS TABLE UPDATE
-- =====================================================
-- Add custom_food_id and custom_meal_id to food_logs if not exists

DO $$ 
BEGIN
    -- Check if custom_food_id column exists, if not add it
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'food_logs' AND column_name = 'custom_food_id'
    ) THEN
        ALTER TABLE food_logs ADD COLUMN custom_food_id UUID REFERENCES custom_foods(id) ON DELETE SET NULL;
    END IF;

    -- Check if custom_meal_id column exists, if not add it
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'food_logs' AND column_name = 'custom_meal_id'
    ) THEN
        ALTER TABLE food_logs ADD COLUMN custom_meal_id UUID REFERENCES custom_meals(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Index for custom food and meal lookups
CREATE INDEX IF NOT EXISTS idx_food_logs_custom_food ON food_logs(custom_food_id) WHERE custom_food_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_food_logs_custom_meal ON food_logs(custom_meal_id) WHERE custom_meal_id IS NOT NULL;

