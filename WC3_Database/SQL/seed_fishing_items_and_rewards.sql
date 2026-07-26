-- ============================================================
-- PotS Fishing Item Rewards
-- Adds fish items and zone-level fish-pool rewards for ItemManager.
-- ============================================================

BEGIN;

ALTER TABLE gather_unit_node_drops
    ADD COLUMN IF NOT EXISTS zone_id INT NOT NULL DEFAULT 0;

ALTER TABLE gather_unit_node_drops
    ADD COLUMN IF NOT EXISTS zone_name VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_gather_unit_node_drops_zone
    ON gather_unit_node_drops(node_id, zone_id);

WITH lookup AS (
    SELECT
        (SELECT id FROM item_types WHERE type_name = 'Consumable' LIMIT 1) AS consumable_type_id,
        (SELECT id FROM item_types WHERE type_name = 'Weapon' LIMIT 1) AS weapon_type_id,
        (SELECT id FROM item_rarities WHERE rarity_name = 'Common' LIMIT 1) AS common_rarity_id,
        (SELECT id FROM item_rarities WHERE rarity_name = 'Uncommon' LIMIT 1) AS uncommon_rarity_id,
        (SELECT id FROM item_rarities WHERE rarity_name = 'Rare' LIMIT 1) AS rare_rarity_id,
        (SELECT id FROM item_classes WHERE class_name = 'Consumable' LIMIT 1) AS consumable_class_id,
        (SELECT id FROM item_classes WHERE class_name = 'Main Hand Weapon' LIMIT 1) AS mainhand_class_id
),
fish_items (
    item_code, item_name, tier_min, tier_max, is_weapon, rarity_name, gold_cost, icon_path, model_path, wc3_abilities, attack_text
) AS (
    VALUES
        ('I6CU', 'Raw Brilliant Smallfish',      1,  5, FALSE, 'Common',    5, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6CV', 'Raw Slitherskin Mackerel',    1,  5, FALSE, 'Common',    5, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6CW', 'Sickly Looking Fish',          1,  6, FALSE, 'Common',    4, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6CX', 'Oily Blackmouth',              5, 12, FALSE, 'Common',   12, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6CY', 'Raw Longjaw Mud Snapper',      5, 10, FALSE, 'Common',   10, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6CZ', 'Raw Rainbow Fin Albacore',     5, 12, FALSE, 'Common',   12, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D0', 'Raw Bristle Whisker Catfish',  8, 14, FALSE, 'Common',   15, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D1', 'Raw Loch Frenzy',              8, 15, FALSE, 'Common',   16, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D2', 'Firefin Snapper',             10, 16, FALSE, 'Common',   20, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D3', 'Deviate Fish',                10, 18, FALSE, 'Uncommon', 35, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D4', 'Raw Sagefish',                10, 18, FALSE, 'Common',   22, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D5', 'Raw Greater Sagefish',        14, 22, FALSE, 'Uncommon', 40, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D6', 'Raw Rockscale Cod',           14, 20, FALSE, 'Common',   25, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D7', 'Raw Mithril Head Trout',      15, 22, FALSE, 'Common',   30, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D8', 'Raw Spotted Yellowtail',      15, 25, FALSE, 'Common',   32, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D9', 'Raw Glossy Mightfish',        18, 26, FALSE, 'Uncommon', 45, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DA', 'Raw Redgill',                 18, 26, FALSE, 'Common',   36, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DB', 'Nightfin Snapper',            20, 30, FALSE, 'Uncommon', 55, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DC', 'Sunscale Salmon',             20, 30, FALSE, 'Uncommon', 55, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DD', 'Stonescale Eel',              20, 30, FALSE, 'Uncommon', 65, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DE', 'Raw Whitescale Salmon',       22, 30, FALSE, 'Uncommon', 70, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DF', 'Darkclaw Lobster',            22, 30, FALSE, 'Uncommon', 75, 'ReplaceableTextures\CommandButtons\BTNSpinyCrab.blp',    'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DG', 'Winter Squid',                20, 30, FALSE, 'Uncommon', 60, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DH', 'Raw Summer Bass',             15, 25, FALSE, 'Common',   34, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DI', 'Raw Tigerseye Eel',           10, 20, FALSE, 'Common',   24, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DJ', 'Barbed Gill Trout',           12, 22, FALSE, 'Common',   28, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DK', 'Furious Crawdad',             20, 30, FALSE, 'Rare',    100, 'ReplaceableTextures\CommandButtons\BTNSpiderCrab.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DL', '10 Pound Mud Snapper',         1, 10, TRUE,  'Common',   15, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A07L', '+1 Damage'),
        ('I6DM', '12 Pound Mud Snapper',         1, 12, TRUE,  'Common',   18, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A07L', '+1 Damage'),
        ('I6DN', '15 Pound Mud Snapper',         5, 15, TRUE,  'Common',   22, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A07L', '+1 Damage'),
        ('I6DO', '17 Pound Catfish',             8, 18, TRUE,  'Common',   28, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A07M', '+2 Damage'),
        ('I6DP', '22 Pound Catfish',            10, 22, TRUE,  'Common',   35, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A07M', '+2 Damage'),
        ('I6DQ', '26 Pound Catfish',            15, 26, TRUE,  'Common',   42, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp', 'war3campImported\ITEMMonsterLure.mdl', 'A07M', '+2 Damage'),
        ('I6DR', 'Steelscale Crushfish',        15, 30, TRUE,  'Uncommon', 70, 'ReplaceableTextures\CommandButtons\BTNSteelMelee.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A07N', '+3 Damage'),
        ('I6DS', 'Rockhide Strongfish',         20, 30, TRUE,  'Uncommon', 85, 'ReplaceableTextures\CommandButtons\BTNSpinyCrab.blp',    'war3campImported\ITEMMonsterLure.mdl', 'A07N', '+3 Damage'),
        ('I6DT', 'Dark Herring',                20, 30, TRUE,  'Rare',    120, 'ReplaceableTextures\CommandButtons\BTNSteelMelee.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A07N', '+3 Damage'),
        ('I6DU', 'Broken Wine Bottle',          10, 25, TRUE,  'Common',   25, 'ReplaceableTextures\CommandButtons\BTNSteelMelee.blp',   NULL,                                     'A07L', '+1 Damage')
)
INSERT INTO items (
    item_code, item_name, base_id, type_id, rarity_id, class_id,
    item_level, required_level, max_charges, max_stack, gold_cost, lumber_cost,
    is_droppable, is_sellable, is_pawnable, is_powerup, drops_on_death,
    is_perishable, is_soulbound, is_unique, use_automatically, can_be_dropped_by_carrier,
    icon_path, model_path, tint_red, tint_green, tint_blue, tint_alpha, scale,
    tooltip, description, tooltip_extended, wc3_classification, actively_used, dropped_on_death,
    dinv_compatible, deq_compatible, equipment_slot, dual_wield_allowed,
    wc3_abilities, copy_base_abilities, specific_drop_only, notes
)
SELECT
    f.item_code,
    f.item_name,
    CASE WHEN f.is_weapon THEN 'bzbe' ELSE 'rej3' END,
    CASE WHEN f.is_weapon THEN l.weapon_type_id ELSE l.consumable_type_id END,
    CASE f.rarity_name
        WHEN 'Rare' THEN l.rare_rarity_id
        WHEN 'Uncommon' THEN l.uncommon_rarity_id
        ELSE l.common_rarity_id
    END,
    CASE WHEN f.is_weapon THEN l.mainhand_class_id ELSE l.consumable_class_id END,
    CASE WHEN f.is_weapon THEN 700 + ((f.tier_min + f.tier_max) / 2) ELSE f.tier_max END,
    1,
    CASE WHEN f.is_weapon THEN 1 ELSE 10 END,
    CASE WHEN f.is_weapon THEN 1 ELSE 10 END,
    f.gold_cost,
    0,
    TRUE, TRUE, TRUE, FALSE, TRUE,
    NOT f.is_weapon, FALSE, FALSE, FALSE, TRUE,
    f.icon_path,
    f.model_path,
    255, 255, 255, 255, 1.0,
    f.item_name,
    CASE WHEN f.is_weapon THEN 'A poor MainHand weapon caught while fishing.' ELSE 'Regenerates health.' END,
    CASE
        WHEN f.is_weapon THEN '[|c00A52A2AWeapon|r, |c00A9A9A9Fishing Trophy|r]|n|c00D3D3D3A trophy catch awkwardly gripped as a MainHand weapon.|r|n|c00FF6347' || f.attack_text || '|r'
        ELSE '|cff87ceebNon-Combat Consumable|r|nRegenerates 100 hit points of the Hero over 30 seconds when used.|nContains up to 10 fish.'
    END,
    CASE WHEN f.is_weapon THEN 'Permanent' ELSE 'Charged' END,
    NOT f.is_weapon,
    TRUE,
    TRUE,
    NOT f.is_weapon,
    CASE WHEN f.is_weapon THEN 'MainHand' ELSE NULL END,
    FALSE,
    f.wc3_abilities,
    FALSE,
    TRUE,
    'PotS fishing reward seed'
FROM fish_items f
CROSS JOIN lookup l
ON CONFLICT (item_code) DO UPDATE SET
    item_name = EXCLUDED.item_name,
    base_id = EXCLUDED.base_id,
    type_id = EXCLUDED.type_id,
    rarity_id = EXCLUDED.rarity_id,
    class_id = EXCLUDED.class_id,
    item_level = EXCLUDED.item_level,
    required_level = EXCLUDED.required_level,
    max_charges = EXCLUDED.max_charges,
    max_stack = EXCLUDED.max_stack,
    gold_cost = EXCLUDED.gold_cost,
    is_perishable = EXCLUDED.is_perishable,
    icon_path = EXCLUDED.icon_path,
    model_path = EXCLUDED.model_path,
    tooltip = EXCLUDED.tooltip,
    description = EXCLUDED.description,
    tooltip_extended = EXCLUDED.tooltip_extended,
    wc3_classification = EXCLUDED.wc3_classification,
    actively_used = EXCLUDED.actively_used,
    dinv_compatible = EXCLUDED.dinv_compatible,
    deq_compatible = EXCLUDED.deq_compatible,
    equipment_slot = EXCLUDED.equipment_slot,
    wc3_abilities = EXCLUDED.wc3_abilities,
    copy_base_abilities = EXCLUDED.copy_base_abilities,
    specific_drop_only = EXCLUDED.specific_drop_only,
    notes = EXCLUDED.notes,
    updated_at = CURRENT_TIMESTAMP;

WITH fish_node AS (
    SELECT id
    FROM gather_unit_nodes
    WHERE unit_code = 'n02N'
    ORDER BY id
    LIMIT 1
)
UPDATE gather_unit_nodes
SET node_name = 'Fish Pool',
    profession_id = 4,
    harvest_yield_min = 1,
    harvest_yield_max = 5,
    gather_success_chance_percent = 100,
    main_drop_group_chance_percent = 100,
    secondary_drop_group_chance_percent = 25,
    updated_at = CURRENT_TIMESTAMP
WHERE id IN (SELECT id FROM fish_node);

WITH fish_codes(item_code) AS (
    VALUES
        ('I6CU'), ('I6CV'), ('I6CW'), ('I6CX'), ('I6CY'), ('I6CZ'), ('I6D0'), ('I6D1'), ('I6D2'), ('I6D3'),
        ('I6D4'), ('I6D5'), ('I6D6'), ('I6D7'), ('I6D8'), ('I6D9'), ('I6DA'), ('I6DB'), ('I6DC'), ('I6DD'),
        ('I6DE'), ('I6DF'), ('I6DG'), ('I6DH'), ('I6DI'), ('I6DJ'), ('I6DK'), ('I6DL'), ('I6DM'), ('I6DN'),
        ('I6DO'), ('I6DP'), ('I6DQ'), ('I6DR'), ('I6DS'), ('I6DT'), ('I6DU')
),
fish_node AS (
    SELECT id
    FROM gather_unit_nodes
    WHERE unit_code = 'n02N'
    ORDER BY id
    LIMIT 1
)
DELETE FROM gather_unit_node_drops d
USING fish_codes c, fish_node n
WHERE d.node_id = n.id
  AND d.item_code = c.item_code;

WITH fish_items(item_code, item_name, tier_min, tier_max, is_weapon, base_weight) AS (
    VALUES
        ('I6CU', 'Raw Brilliant Smallfish',      1,  5, FALSE, 120),
        ('I6CV', 'Raw Slitherskin Mackerel',    1,  5, FALSE, 120),
        ('I6CW', 'Sickly Looking Fish',          1,  6, FALSE,  80),
        ('I6CX', 'Oily Blackmouth',              5, 12, FALSE,  70),
        ('I6CY', 'Raw Longjaw Mud Snapper',      5, 10, FALSE, 110),
        ('I6CZ', 'Raw Rainbow Fin Albacore',     5, 12, FALSE, 100),
        ('I6D0', 'Raw Bristle Whisker Catfish',  8, 14, FALSE,  95),
        ('I6D1', 'Raw Loch Frenzy',              8, 15, FALSE,  80),
        ('I6D2', 'Firefin Snapper',             10, 16, FALSE,  70),
        ('I6D3', 'Deviate Fish',                10, 18, FALSE,  35),
        ('I6D4', 'Raw Sagefish',                10, 18, FALSE,  90),
        ('I6D5', 'Raw Greater Sagefish',        14, 22, FALSE,  70),
        ('I6D6', 'Raw Rockscale Cod',           14, 20, FALSE,  95),
        ('I6D7', 'Raw Mithril Head Trout',      15, 22, FALSE,  95),
        ('I6D8', 'Raw Spotted Yellowtail',      15, 25, FALSE,  85),
        ('I6D9', 'Raw Glossy Mightfish',        18, 26, FALSE,  70),
        ('I6DA', 'Raw Redgill',                 18, 26, FALSE,  90),
        ('I6DB', 'Nightfin Snapper',            20, 30, FALSE,  65),
        ('I6DC', 'Sunscale Salmon',             20, 30, FALSE,  65),
        ('I6DD', 'Stonescale Eel',              20, 30, FALSE,  50),
        ('I6DE', 'Raw Whitescale Salmon',       22, 30, FALSE,  85),
        ('I6DF', 'Darkclaw Lobster',            22, 30, FALSE,  55),
        ('I6DG', 'Winter Squid',                20, 30, FALSE,  55),
        ('I6DH', 'Raw Summer Bass',             15, 25, FALSE,  70),
        ('I6DI', 'Raw Tigerseye Eel',           10, 20, FALSE,  60),
        ('I6DJ', 'Barbed Gill Trout',           12, 22, FALSE,  85),
        ('I6DK', 'Furious Crawdad',             20, 30, FALSE,  25),
        ('I6DL', '10 Pound Mud Snapper',         1, 10, TRUE,   70),
        ('I6DM', '12 Pound Mud Snapper',         1, 12, TRUE,   60),
        ('I6DN', '15 Pound Mud Snapper',         5, 15, TRUE,   55),
        ('I6DO', '17 Pound Catfish',             8, 18, TRUE,   55),
        ('I6DP', '22 Pound Catfish',            10, 22, TRUE,   45),
        ('I6DQ', '26 Pound Catfish',            15, 26, TRUE,   40),
        ('I6DR', 'Steelscale Crushfish',        15, 30, TRUE,   25),
        ('I6DS', 'Rockhide Strongfish',         20, 30, TRUE,   18),
        ('I6DT', 'Dark Herring',                20, 30, TRUE,   12),
        ('I6DU', 'Broken Wine Bottle',          10, 25, TRUE,   30)
),
fish_node AS (
    SELECT id
    FROM gather_unit_nodes
    WHERE unit_code = 'n02N'
    ORDER BY id
    LIMIT 1
),
zone_ranges AS (
    SELECT
        z.zone_id,
        z.zone_name,
        (regexp_match(COALESCE(NULLIF(z.level_range, ''), NULLIF(parent.level_range, '')), '^\s*([0-9]+)\s*-\s*([0-9]+)\s*$'))[1]::INT AS level_min,
        (regexp_match(COALESCE(NULLIF(z.level_range, ''), NULLIF(parent.level_range, '')), '^\s*([0-9]+)\s*-\s*([0-9]+)\s*$'))[2]::INT AS level_max
    FROM gather_zones z
    LEFT JOIN gather_zones parent ON parent.zone_id = z.parent_zone_id
    WHERE z.enabled = TRUE
      AND regexp_match(COALESCE(NULLIF(z.level_range, ''), NULLIF(parent.level_range, '')), '^\s*([0-9]+)\s*-\s*([0-9]+)\s*$') IS NOT NULL
),
default_rows AS (
    SELECT
        n.id AS node_id,
        0 AS zone_id,
        'Default / Unknown Zone' AS zone_name,
        CASE WHEN f.is_weapon THEN 'Secondary' ELSE 'Main' END AS group_name,
        f.item_code,
        f.item_name,
        CASE WHEN f.is_weapon THEN 20 ELSE 100 END AS drop_chance_percent,
        CASE WHEN f.is_weapon THEN f.base_weight ELSE f.base_weight END AS weight,
        1 AS min_quantity,
        CASE WHEN f.is_weapon THEN 1 ELSE 1 END AS max_quantity,
        TRUE AS enabled,
        CASE WHEN f.is_weapon THEN 5000 ELSE 1000 END + f.tier_min * 10 + ROW_NUMBER() OVER (ORDER BY f.is_weapon, f.tier_min, f.item_name) AS display_order,
        CASE WHEN f.is_weapon THEN 'PotS fishing seed: default trophy/weapon fallback.' ELSE 'PotS fishing seed: default fish fallback.' END AS notes
    FROM fish_node n
    CROSS JOIN fish_items f
),
zone_rows AS (
    SELECT
        n.id AS node_id,
        z.zone_id,
        z.zone_name,
        CASE WHEN f.is_weapon THEN 'Secondary' ELSE 'Main' END AS group_name,
        f.item_code,
        f.item_name,
        CASE WHEN f.is_weapon THEN 18 ELSE 100 END AS drop_chance_percent,
        f.base_weight AS weight,
        1 AS min_quantity,
        1 AS max_quantity,
        TRUE AS enabled,
        z.zone_id * 1000 + CASE WHEN f.is_weapon THEN 500 ELSE 100 END + f.tier_min * 10 + ROW_NUMBER() OVER (PARTITION BY z.zone_id, f.is_weapon ORDER BY f.tier_min, f.item_name) AS display_order,
        CASE WHEN f.is_weapon THEN 'PotS fishing seed: trophy/weapon reward from zone level range.' ELSE 'PotS fishing seed: main reward from zone level range.' END AS notes
    FROM fish_node n
    CROSS JOIN zone_ranges z
    JOIN fish_items f
      ON f.tier_min <= z.level_max
     AND f.tier_max >= z.level_min
)
INSERT INTO gather_unit_node_drops (
    node_id, zone_id, zone_name, group_name, item_code, item_name,
    drop_chance_percent, weight, min_quantity, max_quantity,
    enabled, display_order, notes
)
SELECT node_id, zone_id, zone_name, group_name, item_code, item_name,
       drop_chance_percent, weight, min_quantity, max_quantity, enabled, display_order, notes
FROM default_rows
UNION ALL
SELECT node_id, zone_id, zone_name, group_name, item_code, item_name,
       drop_chance_percent, weight, min_quantity, max_quantity, enabled, display_order, notes
FROM zone_rows;

COMMIT;
