-- Fix RLS policies for locations table with proper type casting

-- First, let's check what type the user_id columns are:
-- Run this to see the column types:
-- SELECT column_name, data_type FROM information_schema.columns 
-- WHERE table_name IN ('locations', 'circle_members') AND column_name = 'user_id';

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view locations in their circles" ON locations;
DROP POLICY IF EXISTS "Users can update their own location" ON locations;

-- Enable RLS on locations table
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

-- Policy to allow users to read locations of users in their circles
-- Using UUID comparison (no casting needed if both are UUID)
CREATE POLICY "Users can view locations in their circles" ON locations
FOR SELECT USING (
  auth.uid() IN (
    SELECT user_id::uuid FROM circle_members WHERE circle_id = locations.circle_id
  )
);

-- Policy to allow users to insert/update their own location
CREATE POLICY "Users can manage their own location" ON locations
FOR ALL USING (auth.uid() = user_id::uuid)
WITH CHECK (auth.uid() = user_id::uuid);

-- Alternative version if user_id is TEXT type:
-- CREATE POLICY "Users can view locations in their circles" ON locations
-- FOR SELECT USING (
--   auth.uid()::text IN (
--     SELECT user_id FROM circle_members WHERE circle_id = locations.circle_id
--   )
-- );
-- 
-- CREATE POLICY "Users can manage their own location" ON locations
-- FOR ALL USING (auth.uid()::text = user_id)
-- WITH CHECK (auth.uid()::text = user_id);