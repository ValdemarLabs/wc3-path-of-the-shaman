BEGIN;

-- These base-game units are not present in custom .w3u imports, but the loot
-- manager still needs them as unit_types rows for unit-specific drop records.
INSERT INTO unit_types (
    unit_code, base_id, unit_name, editor_suffix, unit_level,
    is_boss, loot_mode, drop_count_min, drop_count_max, notes
)
VALUES
    ('nggr', 'nggr', 'Granite Golem', NULL, 9, false, 'both', 1, 1, 'Base-game elemental essence source'),
    ('ngst', 'ngst', 'Rock Golem', NULL, 6, false, 'both', 1, 1, 'Base-game elemental essence source'),
    ('ngrk', 'ngrk', 'Mud Golem', NULL, 3, false, 'both', 1, 1, 'Base-game elemental essence source')
ON CONFLICT (unit_code) DO UPDATE
SET loot_mode = CASE
        WHEN unit_types.loot_mode IN ('generic', 'both') THEN 'both'
        ELSE 'specific'
    END,
    updated_at = CURRENT_TIMESTAMP;

UPDATE items
SET specific_drop_only = true,
    updated_at = CURRENT_TIMESTAMP
WHERE item_code IN ('I6C7', 'I6C8', 'I6C5', 'I6C6');

DELETE FROM unit_specific_drops
WHERE item_code IN ('I6C7', 'I6C8', 'I6C5', 'I6C6');

WITH essence_drops(unit_code, item_code, drop_chance, is_guaranteed, notes) AS (
    VALUES
        ('n628', 'I6C8', 100.00::decimal, true,  'Lava Annihilator (Level 15) - Essence of Earth'),
        ('n61K', 'I6C8', 100.00::decimal, true,  'Lava Annihilator (Level 30) - Essence of Earth'),
        ('n61J', 'I6C8', 100.00::decimal, true,  'Lava Reaver (Level 30) - Essence of Earth'),
        ('nggr', 'I6C8',  75.00::decimal, false, 'Granite Golem - Essence of Earth'),
        ('ngst', 'I6C8',  15.00::decimal, false, 'Rock Golem - Essence of Earth'),
        ('ngrk', 'I6C8',   1.00::decimal, false, 'Mud Golem - Essence of Earth'),
        ('h60T', 'I6C7', 100.00::decimal, true,  'Zephyros the Tempest - Essence of Air'),
        ('h60S', 'I6C6', 100.00::decimal, true,  'Aqualon the Tidebringer - Essence of Water'),
        ('n627', 'I6C5', 100.00::decimal, true,  'Fire Lord (Level 15) - Essence of Fire'),
        ('n61I', 'I6C5', 100.00::decimal, true,  'Fire Lord (Level 30) - Essence of Fire'),
        ('n641', 'I6C5', 100.00::decimal, true,  'Fire Lord (Level 25) - Essence of Fire'),
        ('n61H', 'I6C5', 100.00::decimal, true,  'Fire Spawn (Level 30) - Essence of Fire'),
        ('n64F', 'I6C5', 100.00::decimal, true,  'Ragnaros - Essence of Fire'),
        ('n00E', 'I6C5', 100.00::decimal, true,  'Scorchion - Essence of Fire'),
        ('n00K', 'I6C5',  50.00::decimal, false, 'Enslaved Fire Spirit - Essence of Fire')
)
INSERT INTO unit_specific_drops (
    unit_code, item_code, drop_chance, min_quantity, max_quantity,
    is_guaranteed, weight, enabled, notes
)
SELECT
    unit_code, item_code, drop_chance, 1, 1,
    is_guaranteed, 100, true, notes
FROM essence_drops;

WITH essence_units(unit_code) AS (
    VALUES
        ('n628'), ('n61K'), ('n61J'), ('nggr'), ('ngst'), ('ngrk'),
        ('h60T'), ('h60S'),
        ('n627'), ('n61I'), ('n641'), ('n61H'), ('n64F'), ('n00E'), ('n00K')
)
UPDATE unit_types ut
SET loot_mode = CASE
        WHEN ut.loot_mode IN ('generic', 'both') THEN 'both'
        ELSE 'specific'
    END,
    updated_at = CURRENT_TIMESTAMP
FROM essence_units eu
WHERE ut.unit_code = eu.unit_code;

COMMIT;
