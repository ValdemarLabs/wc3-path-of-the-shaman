-- ============================================================
-- Fix Destructible Levels for Loot System
-- Sets proper levels for containers based on their type/name
-- ============================================================

-- Based on naming patterns observed:
-- B01P, B01U, B01V, B01W = Level 6-10 (tier 2, level 8)
-- B01Q, B01X, B01Y, B01Z = Level 11-15 (tier 3, level 13)
-- B01R, B020, B021, B022 = Level 16-20 (tier 4, level 18)
-- B01S, B023, B024, B025 = Level 21-25 (tier 5, level 23)
-- B01T, B026, B027, B028 = Level 26-30 (tier 6, level 28)
-- Dungeon containers get their dungeon's level

-- Set tier 2 containers (level 6-10)
UPDATE destructible_types 
SET destructible_level = 8 
WHERE destructible_code IN ('B01P', 'B01U', 'B01V', 'B01W');

-- Set tier 3 containers (level 11-15)
UPDATE destructible_types 
SET destructible_level = 13 
WHERE destructible_code IN ('B01Q', 'B01X', 'B01Y', 'B01Z');

-- Set tier 4 containers (level 16-20)
UPDATE destructible_types 
SET destructible_level = 18 
WHERE destructible_code IN ('B01R', 'B020', 'B021', 'B022');

-- Set tier 5 containers (level 21-25)
UPDATE destructible_types 
SET destructible_level = 23 
WHERE destructible_code IN ('B01S', 'B023', 'B024', 'B025');

-- Set tier 6 containers (level 26-30)
UPDATE destructible_types 
SET destructible_level = 28 
WHERE destructible_code IN ('B01T', 'B026', 'B027', 'B028');

-- Dungeon-specific containers
UPDATE destructible_types SET destructible_level = 8 WHERE destructible_code = 'B029';   -- Crypt (L8-20)
UPDATE destructible_types SET destructible_level = 6 WHERE destructible_code = 'B02A';   -- Gnoll Hideout (L5-12)
UPDATE destructible_types SET destructible_level = 12 WHERE destructible_code = 'B02B';  -- Boom Brothers Mine (L10-15)

-- FTtw (crate?) - assume low level
UPDATE destructible_types SET destructible_level = 5 WHERE destructible_code = 'FTtw';

-- Show what was updated
SELECT destructible_code, destructible_name, destructible_level, is_container, loot_mode
FROM destructible_types
WHERE destructible_level > 1
ORDER BY destructible_level;

-- Note: After running this, you need to re-export the loot definitions using:
-- WC3ItemManager -> Loot Tables -> Export All Loot Definitions
