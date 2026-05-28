-- Clean up "Unknown Item" entries before reimport
-- These will be properly imported with new importer that saves abilities

-- Option 1: Delete all "Unknown Item" entries (will be reimported with abilities)
DELETE FROM items WHERE item_name LIKE 'Unknown Item%';

-- Option 2: Just see how many would be affected
SELECT COUNT(*) as unknown_items_count FROM items WHERE item_name LIKE 'Unknown Item%';

-- View which items have no abilities (will get them on reimport)
SELECT 
    COUNT(*) as items_without_abilities,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM items) as percentage
FROM items 
WHERE wc3_abilities IS NULL OR wc3_abilities = '';

-- After running the import script, verify abilities were imported
-- SELECT COUNT(*) as items_with_abilities FROM items WHERE wc3_abilities IS NOT NULL AND wc3_abilities != '';
