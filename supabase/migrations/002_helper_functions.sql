-- Health Tracker Helper Functions
-- Migration: 002_helper_functions
-- Description: Utility functions for BMR/TDEE calculation and daily summary aggregation

-- =====================================================
-- BMR CALCULATION FUNCTION (Mifflin-St Jeor Equation)
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_bmr(
    p_weight DECIMAL,
    p_height DECIMAL,
    p_age INTEGER,
    p_gender TEXT
)
RETURNS DECIMAL AS $$
DECLARE
    base_bmr DECIMAL;
BEGIN
    -- Mifflin-St Jeor Equation: (10 × weight in kg) + (6.25 × height in cm) − (5 × age in years)
    base_bmr := (10 * p_weight) + (6.25 * p_height) - (5 * p_age);
    
    -- Add gender adjustment
    RETURN CASE
        WHEN p_gender = 'male' THEN base_bmr + 5
        WHEN p_gender = 'female' THEN base_bmr - 161
        ELSE base_bmr - 78 -- Average for 'other'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION calculate_bmr IS 'Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation';

-- =====================================================
-- TDEE CALCULATION FUNCTION
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_tdee(
    p_bmr DECIMAL,
    p_activity_level TEXT
)
RETURNS DECIMAL AS $$
BEGIN
    RETURN p_bmr * CASE p_activity_level
        WHEN 'sedentary' THEN 1.2
        WHEN 'lightly_active' THEN 1.375
        WHEN 'moderately_active' THEN 1.55
        WHEN 'very_active' THEN 1.725
        WHEN 'extra_active' THEN 1.9
        ELSE 1.2 -- Default to sedentary
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION calculate_tdee IS 'Calculate Total Daily Energy Expenditure based on BMR and activity level';

-- =====================================================
-- AUTO-UPDATE BMR/TDEE ON USER UPDATE
-- =====================================================
CREATE OR REPLACE FUNCTION update_user_bmr_tdee()
RETURNS TRIGGER AS $$
BEGIN
    -- Only calculate if all required fields are present
    IF NEW.weight IS NOT NULL 
       AND NEW.height IS NOT NULL 
       AND NEW.age IS NOT NULL 
       AND NEW.gender IS NOT NULL 
       AND NEW.activity_level IS NOT NULL THEN
        
        -- Calculate BMR
        NEW.bmr := calculate_bmr(NEW.weight, NEW.height, NEW.age, NEW.gender);
        
        -- Calculate TDEE
        NEW.tdee := calculate_tdee(NEW.bmr, NEW.activity_level);
    END IF;
    -- Note: No ELSE needed - bmr/tdee will remain NULL if not calculated
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-calculate BMR/TDEE
CREATE TRIGGER calculate_user_bmr_tdee
    BEFORE INSERT OR UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_user_bmr_tdee();

COMMENT ON FUNCTION update_user_bmr_tdee IS 'Automatically calculate and update BMR/TDEE when user stats change';

-- =====================================================
-- AGGREGATE DAILY FOOD LOGS
-- =====================================================
CREATE OR REPLACE FUNCTION aggregate_daily_food_logs(
    p_user_id UUID,
    p_date DATE
)
RETURNS TABLE (
    total_calories INTEGER,
    total_protein DECIMAL,
    total_carbs DECIMAL,
    total_fat DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(calories * servings)::INTEGER, 0) as total_calories,
        COALESCE(SUM(protein * servings), 0) as total_protein,
        COALESCE(SUM(carbs * servings), 0) as total_carbs,
        COALESCE(SUM(fat * servings), 0) as total_fat
    FROM public.food_logs
    WHERE user_id = p_user_id
      AND DATE(logged_at) = p_date;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION aggregate_daily_food_logs IS 'Sum up all food log macros for a specific day';

-- =====================================================
-- AGGREGATE DAILY EXERCISE CALORIES
-- =====================================================
CREATE OR REPLACE FUNCTION aggregate_daily_exercise_calories(
    p_user_id UUID,
    p_date DATE
)
RETURNS INTEGER AS $$
DECLARE
    total_exercise_calories INTEGER;
BEGIN
    SELECT COALESCE(SUM(calories), 0)
    INTO total_exercise_calories
    FROM public.activities
    WHERE user_id = p_user_id
      AND DATE(start_date) = p_date;
    
    RETURN total_exercise_calories;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION aggregate_daily_exercise_calories IS 'Sum up all exercise calories for a specific day';

-- =====================================================
-- UPDATE OR CREATE DAILY SUMMARY
-- =====================================================
CREATE OR REPLACE FUNCTION upsert_daily_summary(
    p_user_id UUID,
    p_date DATE
)
RETURNS VOID AS $$
DECLARE
    v_food_data RECORD;
    v_exercise_calories INTEGER;
    v_bmr INTEGER;
BEGIN
    -- Get user's BMR
    SELECT COALESCE(bmr::INTEGER, 0)
    INTO v_bmr
    FROM public.users
    WHERE id = p_user_id;
    
    -- Get aggregated food data
    SELECT * INTO v_food_data
    FROM aggregate_daily_food_logs(p_user_id, p_date);
    
    -- Get exercise calories
    v_exercise_calories := aggregate_daily_exercise_calories(p_user_id, p_date);
    
    -- Insert or update daily summary
    INSERT INTO public.daily_summaries (
        user_id,
        date,
        calories_consumed,
        protein_consumed,
        carbs_consumed,
        fat_consumed,
        calories_burned_bmr,
        calories_burned_exercise
    ) VALUES (
        p_user_id,
        p_date,
        v_food_data.total_calories,
        v_food_data.total_protein,
        v_food_data.total_carbs,
        v_food_data.total_fat,
        v_bmr,
        v_exercise_calories
    )
    ON CONFLICT (user_id, date)
    DO UPDATE SET
        calories_consumed = EXCLUDED.calories_consumed,
        protein_consumed = EXCLUDED.protein_consumed,
        carbs_consumed = EXCLUDED.carbs_consumed,
        fat_consumed = EXCLUDED.fat_consumed,
        calories_burned_bmr = EXCLUDED.calories_burned_bmr,
        calories_burned_exercise = EXCLUDED.calories_burned_exercise,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION upsert_daily_summary IS 'Calculate and update daily summary for a specific date';

-- =====================================================
-- AUTO-UPDATE DAILY SUMMARY ON FOOD LOG CHANGE
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_update_daily_summary_food()
RETURNS TRIGGER AS $$
BEGIN
    -- Update summary for the affected date
    IF TG_OP = 'DELETE' THEN
        PERFORM upsert_daily_summary(OLD.user_id, DATE(OLD.logged_at));
    ELSE
        PERFORM upsert_daily_summary(NEW.user_id, DATE(NEW.logged_at));
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_daily_summary_on_food_change
    AFTER INSERT OR UPDATE OR DELETE ON public.food_logs
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_daily_summary_food();

-- =====================================================
-- AUTO-UPDATE DAILY SUMMARY ON ACTIVITY CHANGE
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_update_daily_summary_activity()
RETURNS TRIGGER AS $$
BEGIN
    -- Update summary for the affected date
    IF TG_OP = 'DELETE' THEN
        PERFORM upsert_daily_summary(OLD.user_id, DATE(OLD.start_date));
    ELSE
        PERFORM upsert_daily_summary(NEW.user_id, DATE(NEW.start_date));
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_daily_summary_on_activity_change
    AFTER INSERT OR UPDATE OR DELETE ON public.activities
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_daily_summary_activity();

-- =====================================================
-- GET USER WEEKLY SUMMARY
-- =====================================================
CREATE OR REPLACE FUNCTION get_weekly_summary(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    avg_calories_consumed DECIMAL,
    avg_protein DECIMAL,
    avg_carbs DECIMAL,
    avg_fat DECIMAL,
    avg_calories_burned DECIMAL,
    avg_net_calories DECIMAL,
    total_exercise_minutes INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(AVG(calories_consumed), 0)::DECIMAL as avg_calories_consumed,
        COALESCE(AVG(protein_consumed), 0)::DECIMAL as avg_protein,
        COALESCE(AVG(carbs_consumed), 0)::DECIMAL as avg_carbs,
        COALESCE(AVG(fat_consumed), 0)::DECIMAL as avg_fat,
        COALESCE(AVG(total_calories_burned), 0)::DECIMAL as avg_calories_burned,
        COALESCE(AVG(net_calories), 0)::DECIMAL as avg_net_calories,
        (
            SELECT COALESCE(SUM(duration) / 60, 0)::INTEGER
            FROM public.activities
            WHERE user_id = p_user_id
              AND DATE(start_date) BETWEEN p_start_date AND p_end_date
        ) as total_exercise_minutes
    FROM public.daily_summaries
    WHERE user_id = p_user_id
      AND date BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_weekly_summary IS 'Get aggregated weekly statistics for a date range';

-- =====================================================
-- CHECK FOR DUPLICATE STRAVA ACTIVITY
-- =====================================================
CREATE OR REPLACE FUNCTION check_duplicate_strava_activity()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent duplicate Strava activities
    IF EXISTS (
        SELECT 1 FROM public.activities
        WHERE strava_id = NEW.strava_id
          AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
    ) THEN
        RAISE EXCEPTION 'Activity with strava_id % already exists', NEW.strava_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_duplicate_strava_activity
    BEFORE INSERT OR UPDATE ON public.activities
    FOR EACH ROW
    EXECUTE FUNCTION check_duplicate_strava_activity();

COMMENT ON FUNCTION check_duplicate_strava_activity IS 'Prevent duplicate Strava activities from being inserted';

