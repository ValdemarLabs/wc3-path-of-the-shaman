-- Add sort_order column to item_stat_values to support custom stat ordering
BEGIN;

-- Add column
ALTER TABLE item_stat_values 
ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;

-- Update existing records with display_order from item_stats
UPDATE item_stat_values isv
SET sort_order = s.display_order
FROM item_stats s
WHERE isv.stat_id = s.id AND isv.sort_order = 0;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_item_stat_values_sort_order 
ON item_stat_values(item_id, sort_order);

COMMIT;

-- Verify
SELECT 'Updated item_stat_values table with sort_order column' as message;
