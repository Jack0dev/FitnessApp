-- SQL Triggers for Course Enrollment and Payment Processing
-- Run these in Supabase SQL Editor

-- 1. Trigger to update course current_students when payment status changes
-- This trigger fires AFTER enrollment payment_status is updated
-- SECURITY DEFINER allows the function to bypass RLS policies

CREATE OR REPLACE FUNCTION update_course_students_on_payment()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  course_exists BOOLEAN;
  old_status TEXT;
  new_status TEXT;
  affected_rows INT;
BEGIN
  -- Get old and new payment status (handle NULL)
  old_status := COALESCE(OLD.payment_status, 'pending');
  new_status := COALESCE(NEW.payment_status, 'pending');
  
  -- Only proceed if payment_status actually changed
  IF old_status = new_status THEN
    RETURN NEW;
  END IF;

  -- Check if course exists
  SELECT EXISTS(SELECT 1 FROM courses WHERE id = NEW.course_id) INTO course_exists;
  
  IF NOT course_exists THEN
    RAISE WARNING 'Course not found: %', NEW.course_id;
    RETURN NEW;
  END IF;

  -- Case 1: Payment status changed from non-paid to paid -> INCREMENT students
  IF new_status = 'paid' AND old_status != 'paid' THEN
    UPDATE courses
    SET current_students = COALESCE(current_students, 0) + 1,
        updated_at = NOW()
    WHERE id = NEW.course_id;
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    
    IF affected_rows > 0 THEN
      RAISE NOTICE '✅ Course % students incremented: payment confirmed (from % to paid) for enrollment %', NEW.course_id, old_status, NEW.id;
    ELSE
      RAISE WARNING '⚠️ Failed to increment course % students for enrollment %', NEW.course_id, NEW.id;
    END IF;
  END IF;

  -- Case 2: Payment status changed from paid to non-paid (pending/failed) -> DECREMENT students
  IF old_status = 'paid' AND new_status != 'paid' THEN
    UPDATE courses
    SET current_students = GREATEST(0, COALESCE(current_students, 0) - 1), -- Ensure it doesn't go below 0
        updated_at = NOW()
    WHERE id = NEW.course_id;
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    
    IF affected_rows > 0 THEN
      RAISE NOTICE '⚠️ Course % students decremented: payment reverted (from paid to %) for enrollment %', NEW.course_id, new_status, NEW.id;
    ELSE
      RAISE WARNING '⚠️ Failed to decrement course % students for enrollment %', NEW.course_id, NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger on enrollments table for payment status updates
DROP TRIGGER IF EXISTS trigger_update_course_students ON enrollments;
CREATE TRIGGER trigger_update_course_students
AFTER UPDATE ON enrollments
FOR EACH ROW
WHEN (
  -- Only fire when payment_status actually changed
  OLD.payment_status IS DISTINCT FROM NEW.payment_status
)
EXECUTE FUNCTION update_course_students_on_payment();

-- 1b. Trigger to decrease course students when a paid enrollment is deleted
CREATE OR REPLACE FUNCTION decrease_course_students_on_enrollment_delete()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  affected_rows INT;
BEGIN
  -- If deleted enrollment had paid status, decrease course students
  IF OLD.payment_status = 'paid' THEN
    UPDATE courses
    SET current_students = GREATEST(0, COALESCE(current_students, 0) - 1), -- Ensure it doesn't go below 0
        updated_at = NOW()
    WHERE id = OLD.course_id;
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    
    IF affected_rows > 0 THEN
      RAISE NOTICE '⚠️ Course % students decremented: paid enrollment % deleted', OLD.course_id, OLD.id;
    ELSE
      RAISE WARNING '⚠️ Failed to decrement course % students for deleted enrollment %', OLD.course_id, OLD.id;
    END IF;
  END IF;
  
  RETURN OLD;
END;
$$;

-- Create trigger on enrollments table for deletions
DROP TRIGGER IF EXISTS trigger_decrease_course_students_on_delete ON enrollments;
CREATE TRIGGER trigger_decrease_course_students_on_delete
AFTER DELETE ON enrollments
FOR EACH ROW
WHEN (OLD.payment_status = 'paid')
EXECUTE FUNCTION decrease_course_students_on_enrollment_delete();

-- 2. Trigger to update enrollment course_title when course title changes
-- This ensures enrollment records always have the correct course title

CREATE OR REPLACE FUNCTION update_enrollment_course_title()
RETURNS TRIGGER AS $$
BEGIN
  -- Update all enrollments for this course with the new title
  UPDATE enrollments
  SET course_title = NEW.title,
      updated_at = NOW()
  WHERE course_id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on courses table
DROP TRIGGER IF EXISTS trigger_update_enrollment_title ON courses;
CREATE TRIGGER trigger_update_enrollment_title
AFTER UPDATE OF title ON courses
FOR EACH ROW
WHEN (OLD.title IS DISTINCT FROM NEW.title)
EXECUTE FUNCTION update_enrollment_course_title();

-- 3. Trigger to validate enrollment before allowing payment
-- Ensure course is not full and status is active before allowing enrollment

CREATE OR REPLACE FUNCTION validate_enrollment()
RETURNS TRIGGER AS $$
DECLARE
  course_record RECORD;
BEGIN
  -- Get course information
  SELECT * INTO course_record
  FROM courses
  WHERE id = NEW.course_id;
  
  -- Check if course exists
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Course not found: %', NEW.course_id;
  END IF;
  
  -- Check if course is active
  IF course_record.status != 'active' THEN
    RAISE EXCEPTION 'Course is not active: %', course_record.status;
  END IF;
  
  -- Check if course is full (only if payment is confirmed)
  IF NEW.payment_status = 'paid' AND course_record.current_students >= course_record.max_students THEN
    RAISE EXCEPTION 'Course is full. Cannot enroll more students.';
  END IF;
  
  -- Set course_title if not provided
  IF NEW.course_title IS NULL THEN
    NEW.course_title := course_record.title;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on enrollments table
DROP TRIGGER IF EXISTS trigger_validate_enrollment ON enrollments;
CREATE TRIGGER trigger_validate_enrollment
BEFORE INSERT OR UPDATE ON enrollments
FOR EACH ROW
EXECUTE FUNCTION validate_enrollment();

-- 4. Trigger to prevent enrollment if user is already enrolled (optional - can be handled in app)
-- Uncomment if you want database-level duplicate prevention

-- CREATE OR REPLACE FUNCTION prevent_duplicate_enrollment()
-- RETURNS TRIGGER AS $$
-- BEGIN
--   IF EXISTS (
--     SELECT 1 FROM enrollments
--     WHERE user_id = NEW.user_id
--     AND course_id = NEW.course_id
--     AND id != NEW.id
--   ) THEN
--     RAISE EXCEPTION 'User is already enrolled in this course';
--   END IF;
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- DROP TRIGGER IF EXISTS trigger_prevent_duplicate_enrollment ON enrollments;
-- CREATE TRIGGER trigger_prevent_duplicate_enrollment
-- BEFORE INSERT ON enrollments
-- FOR EACH ROW
-- EXECUTE FUNCTION prevent_duplicate_enrollment();

-- ============================================================
-- TEST QUERIES - Run these to verify triggers are working
-- ============================================================

-- Test 1: Check if trigger exists
-- SELECT tgname, tgrelid::regclass, tgenabled, tgisinternal
-- FROM pg_trigger
-- WHERE tgname = 'trigger_update_course_students';

-- Test 2: Check if function exists
-- SELECT proname, prosecdef, proconfig
-- FROM pg_proc
-- WHERE proname = 'update_course_students_on_payment';

-- Test 3: Manual test - Update an enrollment payment status to 'paid' and check course current_students
-- Step 1: Get a pending enrollment
-- SELECT id, course_id, payment_status, user_id 
-- FROM enrollments 
-- WHERE payment_status != 'paid' 
-- LIMIT 1;

-- Step 2: Get course current_students before update
-- SELECT id, title, current_students, max_students 
-- FROM courses 
-- WHERE id = 'YOUR_COURSE_ID_HERE';

-- Step 3: Update enrollment payment_status to 'paid' (this should trigger the update)
-- UPDATE enrollments
-- SET payment_status = 'paid',
--     payment_at = NOW()
-- WHERE id = 'YOUR_ENROLLMENT_ID_HERE';

-- Step 4: Check course current_students after update (should be incremented)
-- SELECT id, title, current_students, max_students 
-- FROM courses 
-- WHERE id = 'YOUR_COURSE_ID_HERE';

-- Test 4: Verify trigger is firing (check logs in Supabase)
-- Note: RAISE NOTICE messages appear in Supabase logs, not in query results

