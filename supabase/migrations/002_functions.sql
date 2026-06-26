-- Netfuel Database Functions & Triggers
-- Consolidates: 002_helper_functions, 007_fix_burned_calories_tdee
-- Note: upsert_daily_summary uses TDEE (not raw BMR) as the daily baseline burn.

-- =====================================================
-- BMR / TDEE CALCULATION
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_bmr(
    p_weight DECIMAL, p_height DECIMAL, p_age INTEGER, p_gender TEXT
) RETURNS DECIMAL AS $$
DECLARE base_bmr DECIMAL;
BEGIN
    base_bmr := (10 * p_weight) + (6.25 * p_height) - (5 * p_age);
    RETURN CASE
        WHEN p_gender = 'male'   THEN base_bmr + 5
        WHEN p_gender = 'female' THEN base_bmr - 161
        ELSE base_bmr - 78
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION calculate_tdee(p_bmr DECIMAL, p_activity_level TEXT)
RETURNS DECIMAL AS $$
BEGIN
    RETURN p_bmr * CASE p_activity_level
        WHEN 'sedentary'          THEN 1.2
        WHEN 'lightly_active'     THEN 1.375
        WHEN 'moderately_active'  THEN 1.55
        WHEN 'very_active'        THEN 1.725
        WHEN 'extra_active'       THEN 1.9
        ELSE 1.2
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION update_user_bmr_tdee()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.weight IS NOT NULL AND NEW.height IS NOT NULL
       AND NEW.age IS NOT NULL AND NEW.gender IS NOT NULL
       AND NEW.activity_level IS NOT NULL THEN
        NEW.bmr  := calculate_bmr(NEW.weight, NEW.height, NEW.age, NEW.gender);
        NEW.tdee := calculate_tdee(NEW.bmr, NEW.activity_level);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS calculate_user_bmr_tdee ON public.users;
CREATE TRIGGER calculate_user_bmr_tdee
    BEFORE INSERT OR UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_user_bmr_tdee();

-- =====================================================
-- DAILY SUMMARY HELPERS
-- =====================================================

CREATE OR REPLACE FUNCTION aggregate_daily_food_logs(p_user_id UUID, p_date DATE)
RETURNS TABLE (total_calories INTEGER, total_protein DECIMAL, total_carbs DECIMAL, total_fat DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(calories * servings)::INTEGER, 0),
        COALESCE(SUM(protein  * servings), 0),
        COALESCE(SUM(carbs    * servings), 0),
        COALESCE(SUM(fat      * servings), 0)
    FROM public.food_logs
    WHERE user_id = p_user_id AND DATE(logged_at) = p_date;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION aggregate_daily_exercise_calories(p_user_id UUID, p_date DATE)
RETURNS INTEGER AS $$
DECLARE total INTEGER;
BEGIN
    SELECT COALESCE(SUM(calories), 0) INTO total
    FROM public.activities
    WHERE user_id = p_user_id AND DATE(start_date) = p_date;
    RETURN total;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- UPSERT DAILY SUMMARY
-- Uses TDEE as the daily baseline burn so the DB trigger
-- and the iOS app agree on what calories_burned_bmr means.
-- =====================================================

CREATE OR REPLACE FUNCTION upsert_daily_summary(p_user_id UUID, p_date DATE)
RETURNS VOID AS $$
DECLARE
    v_food_data RECORD;
    v_exercise_calories INTEGER;
    v_daily_burn INTEGER;
BEGIN
    SELECT COALESCE(tdee::INTEGER, COALESCE(bmr::INTEGER, 0))
    INTO v_daily_burn
    FROM public.users WHERE id = p_user_id;

    SELECT * INTO v_food_data FROM aggregate_daily_food_logs(p_user_id, p_date);
    v_exercise_calories := aggregate_daily_exercise_calories(p_user_id, p_date);

    INSERT INTO public.daily_summaries (
        user_id, date,
        calories_consumed, protein_consumed, carbs_consumed, fat_consumed,
        calories_burned_bmr, calories_burned_exercise
    ) VALUES (
        p_user_id, p_date,
        v_food_data.total_calories, v_food_data.total_protein,
        v_food_data.total_carbs, v_food_data.total_fat,
        v_daily_burn, v_exercise_calories
    )
    ON CONFLICT (user_id, date) DO UPDATE SET
        calories_consumed    = EXCLUDED.calories_consumed,
        protein_consumed     = EXCLUDED.protein_consumed,
        carbs_consumed       = EXCLUDED.carbs_consumed,
        fat_consumed         = EXCLUDED.fat_consumed,
        calories_burned_bmr  = EXCLUDED.calories_burned_bmr,
        calories_burned_exercise = EXCLUDED.calories_burned_exercise,
        updated_at           = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS: AUTO-UPDATE DAILY SUMMARY
-- =====================================================

CREATE OR REPLACE FUNCTION trigger_update_daily_summary_food()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM upsert_daily_summary(OLD.user_id, DATE(OLD.logged_at));
    ELSE
        PERFORM upsert_daily_summary(NEW.user_id, DATE(NEW.logged_at));
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_daily_summary_on_food_change ON public.food_logs;
CREATE TRIGGER update_daily_summary_on_food_change
    AFTER INSERT OR UPDATE OR DELETE ON public.food_logs
    FOR EACH ROW EXECUTE FUNCTION trigger_update_daily_summary_food();

CREATE OR REPLACE FUNCTION trigger_update_daily_summary_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM upsert_daily_summary(OLD.user_id, DATE(OLD.start_date));
    ELSE
        PERFORM upsert_daily_summary(NEW.user_id, DATE(NEW.start_date));
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_daily_summary_on_activity_change ON public.activities;
CREATE TRIGGER update_daily_summary_on_activity_change
    AFTER INSERT OR UPDATE OR DELETE ON public.activities
    FOR EACH ROW EXECUTE FUNCTION trigger_update_daily_summary_activity();

-- =====================================================
-- WEEKLY SUMMARY
-- =====================================================

CREATE OR REPLACE FUNCTION get_weekly_summary(p_user_id UUID, p_start_date DATE, p_end_date DATE)
RETURNS TABLE (
    avg_calories_consumed DECIMAL, avg_protein DECIMAL, avg_carbs DECIMAL, avg_fat DECIMAL,
    avg_calories_burned DECIMAL, avg_net_calories DECIMAL, total_exercise_minutes INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(AVG(calories_consumed), 0)::DECIMAL,
        COALESCE(AVG(protein_consumed),  0)::DECIMAL,
        COALESCE(AVG(carbs_consumed),    0)::DECIMAL,
        COALESCE(AVG(fat_consumed),      0)::DECIMAL,
        COALESCE(AVG(total_calories_burned), 0)::DECIMAL,
        COALESCE(AVG(net_calories),      0)::DECIMAL,
        (SELECT COALESCE(SUM(duration) / 60, 0)::INTEGER
         FROM public.activities
         WHERE user_id = p_user_id AND DATE(start_date) BETWEEN p_start_date AND p_end_date)
    FROM public.daily_summaries
    WHERE user_id = p_user_id AND date BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- DUPLICATE STRAVA ACTIVITY GUARD
-- =====================================================

CREATE OR REPLACE FUNCTION check_duplicate_strava_activity()
RETURNS TRIGGER AS $$
BEGIN
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

DROP TRIGGER IF EXISTS prevent_duplicate_strava_activity ON public.activities;
CREATE TRIGGER prevent_duplicate_strava_activity
    BEFORE INSERT OR UPDATE ON public.activities
    FOR EACH ROW EXECUTE FUNCTION check_duplicate_strava_activity();
