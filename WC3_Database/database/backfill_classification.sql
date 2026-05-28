-- Backfill classification for items with NULL wc3_classification
-- Default to 'Permanent' for all items

UPDATE items 
SET wc3_classification = 'Permanent' 
WHERE wc3_classification IS NULL OR wc3_classification = '';

-- Report results
SELECT 
    COUNT(*) as total_items,
    COUNT(CASE WHEN wc3_classification = 'Permanent' THEN 1 END) as permanent_items,
    COUNT(CASE WHEN wc3_classification = 'Charged' THEN 1 END) as charged_items,
    COUNT(CASE WHEN wc3_classification IS NULL THEN 1 END) as null_items
FROM items;
