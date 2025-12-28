-- =====================================================
-- Daily Summary Automatic Calculation Triggers
-- =====================================================
-- This file contains database triggers to automatically
-- update daily_summaries when food_logs or activities change
--
-- NOTE: These are OPTIONAL. The app already handles
-- summary updates via DailySummaryService. These triggers
-- provide an additional layer of automation at the database level.

-- =====================================================
-- HELPER FUNCTION: Get User's TDEE
-- =====================================================

CREATE OR REPLACE FUNCTION get_user_tdee(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_tdee DECIMAL;
BEGIN
    SELECT tdee INTO v_tdee
    FROM users
    WHERE id = p_user_id;
    
    -- Return TDEE as integer, or default 2000 if not set
    RETURN COALESCE(v_tdee::INTEGER, 2000);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- HELPER FUNCTION: Calculate Food Totals for a Date
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_food_totals(
    p_user_id UUID,
    p_date DATE,
    OUT total_calories INTEGER,
    OUT total_protein DECIMAL,
    OUT total_carbs DECIMAL,
    OUT total_fat DECIMAL
) AS $$
BEGIN
    SELECT 
        COALESCE(SUM((calories * number_of_servings)::INTEGER), 0),
        COALESCE(SUM(protein * number_of_servings), 0),
        COALESCE(SUM(carbs * number_of_servings), 0),
        COALESCE(SUM(fat * number_of_servings), 0)
    INTO total_calories, total_protein, total_carbs, total_fat
    FROM food_logs
    WHERE user_id = p_user_id
    AND DATE(logged_at) = p_date;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- HELPER FUNCTION: Calculate Exercise Calories for a Date
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_exercise_calories(
    p_user_id UUID,
    p_date DATE
) RETURNS INTEGER AS $$
DECLARE
    v_total_exercise INTEGER;
BEGIN
    SELECT COALESCE(SUM(calories_burned::INTEGER), 0)
    INTO v_total_exercise
    FROM activities
    WHERE user_id = p_user_id
    AND DATE(start_date) = p_date;
    
    RETURN v_total_exercise;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- MAIN FUNCTION: Upsert Daily Summary
-- =====================================================

CREATE OR REPLACE FUNCTION upsert_daily_summary(
    p_user_id UUID,
    p_date DATE
) RETURNS VOID AS $$
DECLARE
    v_tdee INTEGER;
    v_calories INTEGER;
    v_protein DECIMAL;
    v_carbs DECIMAL;
    v_fat DECIMAL;
    v_exercise INTEGER;
BEGIN
    -- Get user's TDEE (daily baseline burn)
    v_tdee := get_user_tdee(p_user_id);
    
    -- Calculate food totals
    SELECT * INTO v_calories, v_protein, v_carbs, v_fat
    FROM calculate_food_totals(p_user_id, p_date);
    
    -- Calculate exercise calories
    v_exercise := calculate_exercise_calories(p_user_id, p_date);
    
    -- Upsert daily summary
    INSERT INTO daily_summaries (
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
        v_calories,
        v_protein,
        v_carbs,
        v_fat,
        v_tdee,
        v_exercise
    )
    ON CONFLICT (user_id, date) DO UPDATE SET
        calories_consumed = EXCLUDED.calories_consumed,
        protein_consumed = EXCLUDED.protein_consumed,
        carbs_consumed = EXCLUDED.carbs_consumed,
        fat_consumed = EXCLUDED.fat_consumed,
        calories_burned_bmr = EXCLUDED.calories_burned_bmr,
        calories_burned_exercise = EXCLUDED.calories_burned_exercise,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGER FUNCTION: After Food Log Insert/Update/Delete
-- =====================================================

CREATE OR REPLACE FUNCTION trigger_update_summary_after_food_change()
RETURNS TRIGGER AS $$
DECLARE
    v_date DATE;
    v_user_id UUID;
BEGIN
    -- Determine which date and user_id to update
    IF TG_OP = 'DELETE' THEN
        v_date := DATE(OLD.logged_at);
        v_user_id := OLD.user_id;
    ELSE
        v_date := DATE(NEW.logged_at);
        v_user_id := NEW.user_id;
    END IF;
    
    -- Update daily summary for that date
    PERFORM upsert_daily_summary(v_user_id, v_date);
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGER FUNCTION: After Activity Insert/Update/Delete
-- =====================================================

CREATE OR REPLACE FUNCTION trigger_update_summary_after_activity_change()
RETURNS TRIGGER AS $$
DECLARE
    v_date DATE;
    v_user_id UUID;
BEGIN
    -- Determine which date and user_id to update
    IF TG_OP = 'DELETE' THEN
        v_date := DATE(OLD.start_date);
        v_user_id := OLD.user_id;
    ELSE
        v_date := DATE(NEW.start_date);
        v_user_id := NEW.user_id;
    END IF;
    
    -- Update daily summary for that date
    PERFORM upsert_daily_summary(v_user_id, v_date);
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- CREATE TRIGGERS
-- =====================================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_summary_after_food_insert ON food_logs;
DROP TRIGGER IF EXISTS update_summary_after_food_update ON food_logs;
DROP TRIGGER IF EXISTS update_summary_after_food_delete ON food_logs;
DROP TRIGGER IF EXISTS update_summary_after_activity_insert ON activities;
DROP TRIGGER IF EXISTS update_summary_after_activity_update ON activities;
DROP TRIGGER IF EXISTS update_summary_after_activity_delete ON activities;

-- Create triggers for food_logs
CREATE TRIGGER update_summary_after_food_insert
    AFTER INSERT ON food_logs
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_summary_after_food_change();

CREATE TRIGGER update_summary_after_food_update
    AFTER UPDATE ON food_logs
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_summary_after_food_change();

CREATE TRIGGER update_summary_after_food_delete
    AFTER DELETE ON food_logs
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_summary_after_food_change();

-- Create triggers for activities
CREATE TRIGGER update_summary_after_activity_insert
    AFTER INSERT ON activities
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_summary_after_activity_change();

CREATE TRIGGER update_summary_after_activity_update
    AFTER UPDATE ON activities
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_summary_after_activity_change();

CREATE TRIGGER update_summary_after_activity_delete
    AFTER DELETE ON activities
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_summary_after_activity_change();

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check if triggers were created
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND (trigger_name LIKE '%summary%' OR event_object_table IN ('food_logs', 'activities'))
ORDER BY event_object_table, trigger_name;

-- =====================================================
-- TESTING (Optional)
-- =====================================================

-- Test the upsert function manually:
-- SELECT upsert_daily_summary('YOUR_USER_ID'::UUID, CURRENT_DATE);

-- Check the result:
-- SELECT * FROM daily_summaries WHERE user_id = 'YOUR_USER_ID'::UUID AND date = CURRENT_DATE;

-- =====================================================
-- NOTES
-- =====================================================
-- 
-- 1. These triggers run AFTER each insert/update/delete
-- 2. They recalculate the ENTIRE day's summary
-- 3. This ensures the database is always consistent
-- 4. The app's DailySummaryService provides the same functionality
-- 5. Having both provides redundancy and catches edge cases
-- 
-- Performance Considerations:
-- - Triggers add overhead to INSERT/UPDATE/DELETE operations
-- - For bulk operations, consider temporarily disabling triggers
-- - The calculations are efficient (using aggregates)
-- 
-- To disable triggers temporarily:
-- ALTER TABLE food_logs DISABLE TRIGGER update_summary_after_food_insert;
-- 
-- To re-enable:
-- ALTER TABLE food_logs ENABLE TRIGGER update_summary_after_food_insert;

