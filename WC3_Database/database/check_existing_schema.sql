-- Quick analysis of existing database structure
-- Run this to see your current schema

\c WC3_POTS

-- Check items table structure
\d items

-- Check item_stats table structure
\d item_stats

-- Check stats table structure
\d stats

-- Check abilities table structure
\d abilities

-- Check item_abilities table structure
\d item_abilities

-- Count data
SELECT 'items' as table_name, COUNT(*) as row_count FROM items
UNION ALL
SELECT 'item_stats', COUNT(*) FROM item_stats
UNION ALL
SELECT 'stats', COUNT(*) FROM stats
UNION ALL
SELECT 'abilities', COUNT(*) FROM abilities
UNION ALL
SELECT 'item_abilities', COUNT(*) FROM item_abilities;

-- Show some sample data
SELECT * FROM stats LIMIT 10;
SELECT * FROM items LIMIT 5;
SELECT * FROM item_stats LIMIT 10;
