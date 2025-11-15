-- SQL Migrations for Course Lessons and Course Level
-- Run these in Supabase SQL Editor

-- ============================================================
-- 1. Add 'level' column to courses table
-- ============================================================

-- Add level column to courses table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'courses' 
    AND column_name = 'level'
  ) THEN
    ALTER TABLE courses
    ADD COLUMN level TEXT DEFAULT 'beginner';
    
    -- Add check constraint separately
    ALTER TABLE courses
    ADD CONSTRAINT courses_level_check 
    CHECK (level IN ('beginner', 'intermediate', 'advanced'));
    
    -- Update existing courses to have default level
    UPDATE courses
    SET level = 'beginner'
    WHERE level IS NULL;
  END IF;
END $$;

-- ============================================================
-- 2. Create course_lessons table
-- ============================================================

-- Drop table if exists (only for development/testing - remove in production)
-- DROP TABLE IF EXISTS course_lessons CASCADE;

CREATE TABLE IF NOT EXISTS course_lessons (
  id TEXT PRIMARY KEY,
  course_id TEXT NOT NULL,
  lesson_number INT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL CHECK (file_type IN ('image', 'video')),
  lesson_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique lesson number per course
  UNIQUE(course_id, lesson_number)
);

-- Note: Foreign key constraint is not added here because courses.id might be UUID
-- and course_lessons.course_id is TEXT. The RLS policies handle referential integrity.

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_course_lessons_course_id ON course_lessons(course_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_lesson_number ON course_lessons(course_id, lesson_number);

-- ============================================================
-- 3. Enable Row Level Security (RLS) for course_lessons
-- ============================================================

ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow public read access to course_lessons" ON course_lessons;
DROP POLICY IF EXISTS "Allow instructors to insert lessons" ON course_lessons;
DROP POLICY IF EXISTS "Allow instructors to update lessons" ON course_lessons;
DROP POLICY IF EXISTS "Allow instructors to delete lessons" ON course_lessons;

-- Policy: Anyone can read lessons (public access)
CREATE POLICY "Allow public read access to course_lessons"
ON course_lessons
FOR SELECT
USING (true);

-- Policy: Only instructors (PTs) can insert lessons for their courses
-- Note: courses.id and courses.instructor_id are likely UUID, so we cast them to TEXT
CREATE POLICY "Allow instructors to insert lessons"
ON course_lessons
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM courses
    WHERE CAST(courses.id AS TEXT) = course_lessons.course_id
    AND CAST(courses.instructor_id AS TEXT) = CAST(auth.uid() AS TEXT)
  )
);

-- Policy: Only instructors (PTs) can update lessons for their courses
CREATE POLICY "Allow instructors to update lessons"
ON course_lessons
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM courses
    WHERE CAST(courses.id AS TEXT) = course_lessons.course_id
    AND CAST(courses.instructor_id AS TEXT) = CAST(auth.uid() AS TEXT)
  )
);

-- Policy: Only instructors (PTs) can delete lessons for their courses
CREATE POLICY "Allow instructors to delete lessons"
ON course_lessons
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM courses
    WHERE CAST(courses.id AS TEXT) = course_lessons.course_id
    AND CAST(courses.instructor_id AS TEXT) = CAST(auth.uid() AS TEXT)
  )
);

-- ============================================================
-- 4. Create trigger to update updated_at timestamp
-- ============================================================

CREATE OR REPLACE FUNCTION update_course_lessons_updated_at()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_course_lessons_updated_at ON course_lessons;

CREATE TRIGGER trigger_update_course_lessons_updated_at
BEFORE UPDATE ON course_lessons
FOR EACH ROW
EXECUTE FUNCTION update_course_lessons_updated_at();

-- ============================================================
-- TEST QUERIES - Run these to verify setup
-- ============================================================

-- Test 1: Check if level column exists in courses
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
-- AND table_name = 'courses' 
-- AND column_name = 'level';

-- Test 2: Check if course_lessons table exists
-- SELECT table_name, table_schema
-- FROM information_schema.tables
-- WHERE table_schema = 'public' 
-- AND table_name = 'course_lessons';

-- Test 3: Check courses table structure
-- SELECT column_name, data_type 
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
-- AND table_name = 'courses'
-- ORDER BY ordinal_position;

-- Test 4: Insert a test lesson (replace course_id with actual course ID)
-- Make sure course_id matches the TEXT representation of courses.id
-- INSERT INTO course_lessons (id, course_id, lesson_number, title, description, file_url, file_type)
-- VALUES (
--   'test_lesson_1',
--   (SELECT CAST(id AS TEXT) FROM courses LIMIT 1),
--   1,
--   'Introduction to Fitness',
--   'This is the first lesson covering basic fitness concepts.',
--   'https://example.com/image.jpg',
--   'image'
-- );

-- Test 5: Get all lessons for a course
-- SELECT * FROM course_lessons
-- WHERE course_id = (SELECT CAST(id AS TEXT) FROM courses LIMIT 1)
-- ORDER BY lesson_number;
