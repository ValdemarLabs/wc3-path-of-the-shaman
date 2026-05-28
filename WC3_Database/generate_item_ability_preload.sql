-- SQL Script: Generate JASS Item Ability Preload Code
-- This generates JASS code to preload item stat abilities for runtime use

-- =================================================================
-- Part 1: Show which items have stat abilities defined
-- =================================================================
SELECT 
    item_code,
    item_name,
    wc3_abilities,
    item_level
FROM items
WHERE wc3_abilities IS NOT NULL 
  AND wc3_abilities != ''
ORDER BY item_level, item_code;

-- =================================================================
-- Part 2: Generate JASS preload code for all items
-- =================================================================
-- Copy the output and paste into UnitStats.j PreloadItemAbilities function

SELECT 
    '    call SaveStr(ItemHook_Hash, ''' || item_code || ''', 0, "' || wc3_abilities || '")  // ' || item_name as jass_code
FROM items
WHERE wc3_abilities IS NOT NULL 
  AND wc3_abilities != ''
ORDER BY item_code;

-- =================================================================
-- Part 3: Count items by number of stat abilities
-- =================================================================
SELECT 
    CASE 
        WHEN ability_count = 1 THEN '1 ability'
        WHEN ability_count BETWEEN 2 AND 3 THEN '2-3 abilities'
        WHEN ability_count BETWEEN 4 AND 5 THEN '4-5 abilities'
        WHEN ability_count > 5 THEN '6+ abilities'
    END as ability_group,
    COUNT(*) as item_count
FROM (
    SELECT 
        item_code,
        array_length(string_to_array(wc3_abilities, ','), 1) as ability_count
    FROM items
    WHERE wc3_abilities IS NOT NULL AND wc3_abilities != ''
) counts
GROUP BY ability_group
ORDER BY ability_group;

-- =================================================================
-- Part 4: Check for items missing stat abilities
-- =================================================================
-- These items might have stats but no WC3 abilities mapped
SELECT 
    i.item_code,
    i.item_name,
    COUNT(isv.id) as stat_count,
    i.wc3_abilities
FROM items i
INNER JOIN item_stat_values isv ON i.id = isv.item_id
WHERE i.wc3_abilities IS NULL OR i.wc3_abilities = ''
GROUP BY i.item_code, i.item_name, i.wc3_abilities
ORDER BY stat_count DESC;

-- =================================================================
-- Part 5: Identify which specific stats need new 1-4% abilities
-- =================================================================
-- This shows which stat types would benefit from 1-4% abilities

WITH stat_values AS (
    SELECT 
        s.stat_name,
        s.stat_code,
        isv.stat_value,
        isv.stat_value % 5 as remainder
    FROM item_stat_values isv
    INNER JOIN item_stats s ON isv.stat_id = s.id
    WHERE s.stat_code IN ('crit', 'dodge', 'block', 'spell_power')
      AND isv.stat_value < 100
)
SELECT 
    stat_name,
    stat_code,
    COUNT(*) as total_items,
    COUNT(CASE WHEN remainder != 0 THEN 1 END) as needs_fine_tuning,
    ROUND(100.0 * COUNT(CASE WHEN remainder != 0 THEN 1 END) / COUNT(*), 2) as percent_need_finer
FROM stat_values
GROUP BY stat_name, stat_code
ORDER BY needs_fine_tuning DESC;

-- =================================================================
-- Part 6: Import existing 1-5% stat abilities into database
-- =================================================================
-- These abilities already exist in your map from old testing

-- Hit abilities 1-5%
INSERT INTO wc3_abilities (ability_code, ability_name, ability_type, stat_value) VALUES
('A649', '1% Hit Chance', 'hit', 1),
('A64A', '2% Hit Chance', 'hit', 2),
('A64C', '3% Hit Chance', 'hit', 3),
('A64D', '4% Hit Chance', 'hit', 4),
('A64B', '5% Hit Chance', 'hit', 5)
ON CONFLICT (ability_code) DO UPDATE SET
    ability_name = EXCLUDED.ability_name,
    ability_type = EXCLUDED.ability_type,
    stat_value = EXCLUDED.stat_value;

-- Crit abilities 1-5%
INSERT INTO wc3_abilities (ability_code, ability_name, ability_type, stat_value) VALUES
('A64E', '1% Crit Chance', 'crit', 1),
('A64F', '2% Crit Chance', 'crit', 2),
('A64G', '3% Crit Chance', 'crit', 3),
('A64H', '4% Crit Chance', 'crit', 4),
('A64I', '5% Crit Chance', 'crit', 5)
ON CONFLICT (ability_code) DO UPDATE SET
    ability_name = EXCLUDED.ability_name,
    ability_type = EXCLUDED.ability_type,
    stat_value = EXCLUDED.stat_value;

-- Block abilities 1-5%
INSERT INTO wc3_abilities (ability_code, ability_name, ability_type, stat_value) VALUES
('A64J', '1% Block Chance', 'block', 1),
('A64K', '2% Block Chance', 'block', 2),
('A64L', '3% Block Chance', 'block', 3),
('A64M', '4% Block Chance', 'block', 4),
('A64N', '5% Block Chance', 'block', 5),
('A64T', '100% Block Chance', 'block', 100)
ON CONFLICT (ability_code) DO UPDATE SET
    ability_name = EXCLUDED.ability_name,
    ability_type = EXCLUDED.ability_type,
    stat_value = EXCLUDED.stat_value;

-- Dodge abilities 1-5%
INSERT INTO wc3_abilities (ability_code, ability_name, ability_type, stat_value) VALUES
('A64O', '1% Dodge Chance', 'dodge', 1),
('A64P', '2% Dodge Chance', 'dodge', 2),
('A64Q', '3% Dodge Chance', 'dodge', 3),
('A64R', '4% Dodge Chance', 'dodge', 4),
('A64S', '5% Dodge Chance', 'dodge', 5)
ON CONFLICT (ability_code) DO UPDATE SET
    ability_name = EXCLUDED.ability_name,
    ability_type = EXCLUDED.ability_type,
    stat_value = EXCLUDED.stat_value;

-- Spell Power abilities 1-4% (newly created)
INSERT INTO wc3_abilities (ability_code, ability_name, ability_type, stat_value) VALUES
('A06M', '1% Spell Power', 'spell', 1),
('A06N', '2% Spell Power', 'spell', 2),
('A06O', '3% Spell Power', 'spell', 3),
('A06P', '4% Spell Power', 'spell', 4)
ON CONFLICT (ability_code) DO UPDATE SET
    ability_name = EXCLUDED.ability_name,
    ability_type = EXCLUDED.ability_type,
    stat_value = EXCLUDED.stat_value;

-- =================================================================
-- Part 7: Verify all stat abilities are in database
-- =================================================================
SELECT 
    ability_type,
    COUNT(*) as ability_count,
    array_agg(stat_value ORDER BY stat_value) as available_values
FROM wc3_abilities
WHERE ability_type IN ('hit', 'crit', 'block', 'dodge', 'spell')
GROUP BY ability_type
ORDER BY ability_type;

-- Expected output after importing all abilities:
-- ability_type | ability_count | available_values
-- -------------|---------------|--------------------------------------------------
-- block        | 18            | {1,2,3,4,5,10,15,20,25,30,35,40,50,60,75,90,100}
-- crit         | 18            | {1,2,3,4,5,10,15,20,25,30,35,40,50,60,75,90,100}
-- dodge        | 18            | {1,2,3,4,5,10,15,20,25,30,35,40,50,60,75,90,100}
-- hit          | 22            | {1,2,3,4,5,10,15,20,25,30,35,40,50,60,75,90,100}
-- spell        | 17            | {1,2,3,4,5,10,15,20,25,30,35,40,50,60,75,90,100}

-- =================================================================
-- Part 8: Sample output examples
-- =================================================================
-- Shows what the generated JASS code will look like

-- Example output from Part 2:
--     call SaveStr(ItemHook_Hash, 'I001', 0, "A01G,A04K")  // Sword of Power
--     call SaveStr(ItemHook_Hash, 'I002', 0, "A6EV")  // Shield of Defense
--     call SaveStr(ItemHook_Hash, 'I003', 0, "A01C,A04L,A6F1")  // Ring of Elements
