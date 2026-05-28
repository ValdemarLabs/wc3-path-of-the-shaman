-- Fix max_stack constraint to allow 0
-- Current: CHECK ((max_stack >= 1))
-- New: CHECK ((max_stack >= 0))

BEGIN;

-- Drop old constraint
ALTER TABLE items DROP CONSTRAINT IF EXISTS check_max_stack;

-- Add new constraint allowing 0
ALTER TABLE items ADD CONSTRAINT check_max_stack CHECK (max_stack >= 0);

-- Verify the change
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'items'::regclass 
AND conname = 'check_max_stack';

COMMIT;

-- Test: This should now work
-- UPDATE items SET max_stack = 0 WHERE item_code = 'test';
