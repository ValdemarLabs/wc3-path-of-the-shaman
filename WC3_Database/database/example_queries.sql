-- Example SQL Queries for WC3 Items Database
-- ================================================

-- ================================================
-- BASIC QUERIES
-- ================================================

-- Get all items
SELECT * FROM v_items_complete ORDER BY item_name;

-- Get specific item by code
SELECT * FROM v_items_complete WHERE item_code = 'I000';

-- Search items by name
SELECT item_code, item_name, rarity_name, item_level, gold_cost
FROM v_items_complete
WHERE item_name ILIKE '%potion%'
ORDER BY item_level DESC;

-- Get all legendary items
SELECT item_code, item_name, item_level, gold_cost
FROM v_items_complete
WHERE rarity_name = 'Legendary'
ORDER BY item_level DESC;

-- ================================================
-- FILTERING QUERIES
-- ================================================

-- Get all weapons
SELECT item_code, item_name, damage_min, damage_max, item_level
FROM v_items_complete
WHERE type_name = 'Weapon'
ORDER BY damage_max DESC;

-- Get all armor pieces
SELECT item_code, item_name, armor, item_level, class_name
FROM v_items_complete
WHERE type_name = 'Armor'
ORDER BY armor DESC;

-- Get items by level range
SELECT item_code, item_name, item_level, rarity_name
FROM v_items_complete
WHERE item_level BETWEEN 10 AND 20
ORDER BY item_level, rarity_level DESC;

-- Get soulbound items
SELECT item_code, item_name, item_level, rarity_name
FROM v_items_complete
WHERE is_soulbound = TRUE
ORDER BY item_level DESC;

-- Get unique items
SELECT item_code, item_name, item_level, rarity_name
FROM v_items_complete
WHERE is_unique = TRUE
ORDER BY rarity_level DESC, item_level DESC;

-- ================================================
-- STATISTICS QUERIES
-- ================================================

-- Count items by rarity
SELECT 
    rarity_name,
    COUNT(*) as item_count,
    AVG(gold_cost)::INTEGER as avg_gold_cost,
    MIN(item_level) as min_level,
    MAX(item_level) as max_level
FROM v_items_complete
GROUP BY rarity_name, rarity_level
ORDER BY rarity_level;

-- Count items by type
SELECT 
    type_name,
    COUNT(*) as item_count,
    AVG(item_level)::INTEGER as avg_level
FROM v_items_complete
GROUP BY type_name
ORDER BY item_count DESC;

-- Get items by equipment slot
SELECT 
    slot_type,
    COUNT(*) as item_count,
    AVG(armor)::INTEGER as avg_armor
FROM v_items_complete
WHERE slot_type IS NOT NULL
GROUP BY slot_type
ORDER BY item_count DESC;

-- Most expensive items
SELECT item_code, item_name, gold_cost, rarity_name
FROM v_items_complete
ORDER BY gold_cost DESC
LIMIT 10;

-- Most powerful weapons (by damage)
SELECT item_code, item_name, damage_min, damage_max, 
       (damage_min + damage_max) / 2 as avg_damage
FROM v_items_complete
WHERE damage_max > 0
ORDER BY avg_damage DESC
LIMIT 10;

-- ================================================
-- COMPLEX QUERIES
-- ================================================

-- Get items with bonuses
SELECT 
    i.item_code,
    i.item_name,
    b.bonus_type,
    b.bonus_name,
    b.bonus_value
FROM items i
INNER JOIN item_bonuses b ON i.id = b.item_id
ORDER BY i.item_name, b.bonus_type;

-- Get items with requirements
SELECT 
    i.item_code,
    i.item_name,
    r.requirement_type,
    r.requirement_value,
    r.description
FROM items i
INNER JOIN item_requirements r ON i.id = r.item_id
ORDER BY i.item_name;

-- Get items with abilities
SELECT 
    i.item_code,
    i.item_name,
    a.ability_code,
    a.ability_name,
    a.ability_description
FROM items i
INNER JOIN item_abilities a ON i.id = a.item_id
ORDER BY i.item_name;

-- Get items in sets
SELECT 
    s.set_name,
    i.item_code,
    i.item_name,
    i.class_name
FROM items i
INNER JOIN item_sets s ON i.set_id = s.id
ORDER BY s.set_name, i.class_name;

-- Get set bonuses
SELECT 
    s.set_name,
    sb.pieces_required,
    sb.bonus_type,
    sb.bonus_value,
    sb.bonus_description
FROM item_sets s
INNER JOIN item_set_bonuses sb ON s.id = sb.set_id
ORDER BY s.set_name, sb.pieces_required;

-- ================================================
-- EXPORT QUERIES
-- ================================================

-- Export DEquipment compatible items
SELECT * FROM v_deq_items ORDER BY item_code;

-- Export DInventory compatible items
SELECT * FROM v_dinv_items ORDER BY item_code;

-- Export items for specific level range
SELECT * FROM v_items_complete
WHERE item_level BETWEEN 1 AND 10
ORDER BY item_code;

-- Export items by rarity (for testing)
SELECT * FROM v_items_complete
WHERE rarity_name IN ('Common', 'Uncommon')
ORDER BY item_code;

-- ================================================
-- UPDATE QUERIES
-- ================================================

-- Update item gold cost
UPDATE items
SET gold_cost = 1000
WHERE item_code = 'I000';

-- Update item rarity
UPDATE items
SET rarity_id = (SELECT id FROM item_rarities WHERE rarity_name = 'Rare')
WHERE item_code = 'I000';

-- Update item level requirement
UPDATE items
SET required_level = 10
WHERE item_code = 'I000';

-- Mark item as soulbound
UPDATE items
SET is_soulbound = TRUE
WHERE item_code = 'I000';

-- Bulk update - set all potions as consumables
UPDATE items
SET type_id = (SELECT id FROM item_types WHERE type_name = 'Consumable')
WHERE item_name ILIKE '%potion%';

-- ================================================
-- INSERT QUERIES
-- ================================================

-- Insert a new item
INSERT INTO items (
    item_code, item_name, type_id, rarity_id,
    item_level, gold_cost, description
) VALUES (
    'I999',
    'Awesome Sword',
    (SELECT id FROM item_types WHERE type_name = 'Weapon'),
    (SELECT id FROM item_rarities WHERE rarity_name = 'Epic'),
    15,
    5000,
    'A really awesome sword'
);

-- Insert item with full details
INSERT INTO items (
    item_code, item_name, type_id, rarity_id, class_id,
    item_level, required_level, gold_cost,
    damage_min, damage_max, strength_bonus, agility_bonus,
    is_droppable, is_sellable, deq_compatible,
    tooltip, description
) VALUES (
    'I998',
    'Legendary Blade',
    (SELECT id FROM item_types WHERE type_name = 'Weapon'),
    (SELECT id FROM item_rarities WHERE rarity_name = 'Legendary'),
    (SELECT id FROM item_classes WHERE class_name = 'Two-Hand Weapon'),
    20, 20, 10000,
    50, 100, 10, 5,
    TRUE, TRUE, TRUE,
    'A legendary blade of immense power',
    'Forged in ancient times by master craftsmen'
);

-- Insert item bonus
INSERT INTO item_bonuses (
    item_id, bonus_type, bonus_name, bonus_value, description
) VALUES (
    (SELECT id FROM items WHERE item_code = 'I998'),
    'EFFECT',
    'Fire Damage',
    25,
    '+25 Fire Damage on hit'
);

-- Insert item requirement
INSERT INTO item_requirements (
    item_id, requirement_type, requirement_value, description
) VALUES (
    (SELECT id FROM items WHERE item_code = 'I998'),
    'LEVEL',
    '20',
    'Requires level 20'
);

-- ================================================
-- DELETE QUERIES
-- ================================================

-- Delete a specific item
DELETE FROM items WHERE item_code = 'I999';

-- Delete all items of a specific type
-- DELETE FROM items WHERE type_id = (SELECT id FROM item_types WHERE type_name = 'Other');

-- Delete all test items (codes starting with 'TEST')
-- DELETE FROM items WHERE item_code LIKE 'TEST%';

-- ================================================
-- MAINTENANCE QUERIES
-- ================================================

-- Calculate and update sell values for all items
UPDATE items
SET sell_value = calculate_sell_value(id)
WHERE sell_value IS NULL;

-- View import history
SELECT * FROM import_history ORDER BY import_date DESC;

-- View export history
SELECT * FROM export_history ORDER BY export_date DESC;

-- View recent changes
SELECT item_code, item_name, updated_at
FROM items
WHERE updated_at > CURRENT_DATE - INTERVAL '7 days'
ORDER BY updated_at DESC;

-- ================================================
-- ADVANCED QUERIES
-- ================================================

-- Find items with similar stats (example: similar to a specific item)
WITH target_item AS (
    SELECT * FROM items WHERE item_code = 'I000'
)
SELECT 
    i.item_code,
    i.item_name,
    i.item_level,
    ABS(i.gold_cost - t.gold_cost) as cost_diff,
    ABS(i.item_level - t.item_level) as level_diff
FROM items i, target_item t
WHERE i.item_code != 'I000'
  AND i.type_id = t.type_id
ORDER BY cost_diff + level_diff
LIMIT 10;

-- Items with the most bonuses
SELECT 
    i.item_code,
    i.item_name,
    COUNT(b.id) as bonus_count
FROM items i
LEFT JOIN item_bonuses b ON i.id = b.item_id
GROUP BY i.id, i.item_code, i.item_name
ORDER BY bonus_count DESC
LIMIT 10;

-- Complete item data in JSON format
SELECT row_to_json(t) FROM (
    SELECT 
        i.*,
        (SELECT json_agg(b) FROM item_bonuses b WHERE b.item_id = i.id) as bonuses,
        (SELECT json_agg(r) FROM item_requirements r WHERE r.item_id = i.id) as requirements,
        (SELECT json_agg(a) FROM item_abilities a WHERE a.item_id = i.id) as abilities
    FROM items i
    WHERE i.item_code = 'I000'
) t;

-- ================================================
-- UTILITY QUERIES
-- ================================================

-- Get next available item code
SELECT 'I' || LPAD((MAX(SUBSTRING(item_code FROM 2)::INTEGER) + 1)::TEXT, 3, '0') as next_code
FROM items
WHERE item_code ~ '^I[0-9]{3}$';

-- Validate data integrity
SELECT 
    'Missing Type' as issue,
    item_code,
    item_name
FROM items
WHERE type_id IS NULL
UNION ALL
SELECT 
    'Missing Rarity' as issue,
    item_code,
    item_name
FROM items
WHERE rarity_id IS NULL
UNION ALL
SELECT 
    'Invalid Level' as issue,
    item_code,
    item_name
FROM items
WHERE item_level < 1 OR item_level > 100;

-- Backup items to JSON (for external backup)
COPY (
    SELECT row_to_json(t) FROM v_items_complete t
) TO 'h:/Pelit/PotS_JASS/WC3_Database/backup_items.json';
