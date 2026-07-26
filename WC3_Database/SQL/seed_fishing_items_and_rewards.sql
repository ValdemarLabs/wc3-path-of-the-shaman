-- ============================================================
-- PotS Fishing Item Rewards and Pool Variants
-- Adds fish items, special pool loot, gather-node fish pools,
-- zone placements, and zone-filtered fishing rewards.
-- ============================================================

BEGIN;

ALTER TABLE gather_unit_node_drops
    ADD COLUMN IF NOT EXISTS zone_id INT NOT NULL DEFAULT 0;

ALTER TABLE gather_unit_node_drops
    ADD COLUMN IF NOT EXISTS zone_name VARCHAR(100);

ALTER TABLE gather_node_zones
    ADD COLUMN IF NOT EXISTS shared_max_override INT NULL;

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
        ('I6CU', 'Raw Brilliant Smallfish',      1,  5, FALSE, 'Common',    5, 'ReplaceableTextures\CommandButtons\BTNFish_08.blp',       'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6CV', 'Raw Slitherskin Mackerel',    1,  5, FALSE, 'Common',    5, 'ReplaceableTextures\CommandButtons\BTNFish_24.blp',       'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6CW', 'Sickly Looking Fish',          1,  6, FALSE, 'Common',    4, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6CX', 'Oily Blackmouth',              5, 12, FALSE, 'Common',   12, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6CY', 'Raw Longjaw Mud Snapper',      5, 10, FALSE, 'Common',   10, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6CZ', 'Raw Rainbow Fin Albacore',     5, 12, FALSE, 'Common',   12, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D0', 'Raw Bristle Whisker Catfish',  8, 14, FALSE, 'Common',   15, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D1', 'Raw Loch Frenzy',              8, 15, FALSE, 'Common',   16, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D2', 'Firefin Snapper',             10, 16, FALSE, 'Common',   20, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D3', 'Deviate Fish',                10, 18, FALSE, 'Uncommon', 35, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D4', 'Raw Sagefish',                10, 18, FALSE, 'Common',   22, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D5', 'Raw Greater Sagefish',        14, 22, FALSE, 'Uncommon', 40, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D6', 'Raw Rockscale Cod',           14, 20, FALSE, 'Common',   25, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D7', 'Raw Mithril Head Trout',      15, 22, FALSE, 'Common',   30, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D8', 'Raw Spotted Yellowtail',      15, 25, FALSE, 'Common',   32, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6D9', 'Raw Glossy Mightfish',        18, 26, FALSE, 'Uncommon', 45, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DA', 'Raw Redgill',                 18, 26, FALSE, 'Common',   36, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DB', 'Nightfin Snapper',            20, 30, FALSE, 'Uncommon', 55, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DC', 'Sunscale Salmon',             20, 30, FALSE, 'Uncommon', 55, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DD', 'Stonescale Eel',              20, 30, FALSE, 'Uncommon', 65, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DE', 'Raw Whitescale Salmon',       22, 30, FALSE, 'Uncommon', 70, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DF', 'Darkclaw Lobster',            22, 30, FALSE, 'Uncommon', 75, 'ReplaceableTextures\CommandButtons\BTNSpinyCrab.blp',      'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DG', 'Winter Squid',                20, 30, FALSE, 'Uncommon', 60, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DH', 'Raw Summer Bass',             15, 25, FALSE, 'Common',   34, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DI', 'Raw Tigerseye Eel',           10, 20, FALSE, 'Common',   24, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DJ', 'Barbed Gill Trout',           12, 22, FALSE, 'Common',   28, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DK', 'Furious Crawdad',             20, 30, FALSE, 'Rare',    100, 'ReplaceableTextures\CommandButtons\BTNSpiderCrab.blp',     'war3campImported\ITEMMonsterLure.mdl', 'A60V', NULL),
        ('I6DL', '10 Pound Mud Snapper',         1, 10, TRUE,  'Common',   15, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A07L', '+1 Damage'),
        ('I6DM', '12 Pound Mud Snapper',         1, 12, TRUE,  'Common',   18, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A07L', '+1 Damage'),
        ('I6DN', '15 Pound Mud Snapper',         5, 15, TRUE,  'Common',   22, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A07L', '+1 Damage'),
        ('I6DO', '17 Pound Catfish',             8, 18, TRUE,  'Common',   28, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A07M', '+2 Damage'),
        ('I6DP', '22 Pound Catfish',            10, 22, TRUE,  'Common',   35, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A07M', '+2 Damage'),
        ('I6DQ', '26 Pound Catfish',            15, 26, TRUE,  'Common',   42, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',   'war3campImported\ITEMMonsterLure.mdl', 'A07M', '+2 Damage'),
        ('I6DR', 'Steelscale Crushfish',        15, 30, TRUE,  'Uncommon', 70, 'ReplaceableTextures\CommandButtons\BTNSteelMelee.blp',     'war3campImported\ITEMMonsterLure.mdl', 'A07N', '+3 Damage'),
        ('I6DS', 'Rockhide Strongfish',         20, 30, TRUE,  'Uncommon', 85, 'ReplaceableTextures\CommandButtons\BTNSpinyCrab.blp',      'war3campImported\ITEMMonsterLure.mdl', 'A07N', '+3 Damage'),
        ('I6DT', 'Dark Herring',                20, 30, TRUE,  'Rare',    120, 'ReplaceableTextures\CommandButtons\BTNSteelMelee.blp',     'war3campImported\ITEMMonsterLure.mdl', 'A07N', '+3 Damage'),
        ('I6DU', 'Broken Wine Bottle',          10, 25, TRUE,  'Common',   25, 'ReplaceableTextures\CommandButtons\BTNSteelMelee.blp',     NULL,                                     'A07L', '+1 Damage')
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

WITH lookup AS (
    SELECT
        (SELECT id FROM item_types WHERE type_name = 'Consumable' LIMIT 1) AS consumable_type_id,
        (SELECT id FROM item_types WHERE type_name = 'Material' LIMIT 1) AS material_type_id,
        (SELECT id FROM item_types WHERE type_name = 'Other' LIMIT 1) AS other_type_id,
        (SELECT id FROM item_rarities WHERE rarity_name = 'Common' LIMIT 1) AS common_rarity_id,
        (SELECT id FROM item_rarities WHERE rarity_name = 'Uncommon' LIMIT 1) AS uncommon_rarity_id,
        (SELECT id FROM item_rarities WHERE rarity_name = 'Rare' LIMIT 1) AS rare_rarity_id,
        (SELECT id FROM item_classes WHERE class_name = 'Consumable' LIMIT 1) AS consumable_class_id,
        (SELECT id FROM item_classes WHERE class_name = 'Material' LIMIT 1) AS material_class_id,
        (SELECT id FROM item_classes WHERE class_name = 'Other' LIMIT 1) AS other_class_id,
        (SELECT id FROM item_classes WHERE class_name = 'MISC' LIMIT 1) AS misc_class_id
),
pool_loot_items (
    item_code, item_name, item_kind, tier_min, tier_max, rarity_name, gold_cost, icon_path, model_path, max_stack, tooltip_hint
) AS (
    VALUES
        ('I6DV', 'Firefin Oil',             'material',   8, 18, 'Common',    24, 'ReplaceableTextures\CommandButtons\BTNSpell_fire_volcano.blp',       NULL, 20, 'A warm alchemical oil skimmed from a fiery pool.'),
        ('I6DW', 'Elemental Fire',          'material',  10, 30, 'Uncommon',  45, 'ReplaceableTextures\CommandButtons\BTNSpell_fire_volcano.blp',       NULL, 20, 'Condensed elemental flame pulled from boiling water.'),
        ('I6DX', 'Volcanic Scale',          'material',  10, 30, 'Common',    30, 'ReplaceableTextures\CommandButtons\BTNReinforcedHides.blp',          NULL, 20, 'A heat-blackened scale with a molten edge.'),
        ('I6DY', 'Smoldering Pearl',        'material',  18, 30, 'Rare',      90, 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Gem_Ruby_01.blp',     NULL, 20, 'A pearl that glows beneath a layer of soot.'),
        ('I6DZ', 'Lavafin Snapper',         'consumable',12, 24, 'Uncommon',  42, 'ReplaceableTextures\CommandButtons\BTNFish_24.blp',                 'war3campImported\ITEMMonsterLure.mdl', 10, 'A hot-blooded fish caught from lava-warmed water.'),
        ('I6E0', 'Elemental Water',         'material',   8, 30, 'Uncommon',  45, 'ReplaceableTextures\CommandButtons\BTNSpell_nature_acid_01.blp',     NULL, 20, 'Living water gathered from an elemental pool.'),
        ('I6E1', 'Pure Water Globule',      'material',   5, 18, 'Common',    22, 'ReplaceableTextures\CommandButtons\BTNINV_SpringWater.blp',          NULL, 20, 'A clear globule of fresh magical water.'),
        ('I6E2', 'Tidal Pearl',             'material',  14, 30, 'Rare',      86, 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Gem_Opal_01.blp',     NULL, 20, 'A pearl polished smooth by restless currents.'),
        ('I6E3', 'Enchanted Seaweed',       'material',   5, 22, 'Common',    20, 'ReplaceableTextures\CommandButtons\BTNInv_Misc_Herb_15.blp',         NULL, 20, 'Kelp threaded with a faint blue shimmer.'),
        ('I6E4', 'Azurefin Minnow',         'consumable', 5, 16, 'Common',    24, 'ReplaceableTextures\CommandButtons\BTNFish_08.blp',                 'war3campImported\ITEMMonsterLure.mdl', 10, 'A small fish that glitters in clear water.'),
        ('I6E5', 'Fel-Touched Fish',        'consumable',12, 30, 'Uncommon',  48, 'ReplaceableTextures\CommandButtons\BTNFelHound.blp',                'war3campImported\ITEMMonsterLure.mdl', 10, 'A sickly fish warped by fel seepage.'),
        ('I6E6', 'Black Ichor',             'material',  12, 30, 'Common',    28, 'ReplaceableTextures\PassiveButtons\PASBTNSlowPoison.blp',          NULL, 20, 'A tar-thick fluid that clings to glass.'),
        ('I6E7', 'Demonic Scale',           'material',  14, 30, 'Uncommon',  52, 'ReplaceableTextures\CommandButtons\BTNReinforcedHides.blp',          NULL, 20, 'A jagged scale with a fel-green sheen.'),
        ('I6E8', 'Corrupted Pearl',         'material',  16, 30, 'Rare',      96, 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Gem_Emerald_01.blp',  NULL, 20, 'A pearl with a dark core and green surface glow.'),
        ('I6E9', 'Abyssal Eye',             'material',  18, 30, 'Rare',     110, 'ReplaceableTextures\CommandButtons\BTNWandOfShadowSight.blp',        NULL, 20, 'An unblinking relic from something below.'),
        ('I6EA', 'Nightscale Eel',          'consumable',12, 26, 'Uncommon',  44, 'ReplaceableTextures\CommandButtons\BTNMonsterLure.blp',             'war3campImported\ITEMMonsterLure.mdl', 10, 'An eel with a midnight-blue hide.'),
        ('I6EB', 'Moonlit Pearl',           'material',  10, 28, 'Uncommon',  60, 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Gem_Crystal_01.blp',  NULL, 20, 'A pale pearl that catches moonlight easily.'),
        ('I6EC', 'Darkwater Clam',          'material',  10, 24, 'Common',    26, 'ReplaceableTextures\CommandButtons\BTNSpinyCrab.blp',               NULL, 20, 'A heavy clam from cold, still water.'),
        ('I6ED', 'Shadowfin',               'consumable',14, 30, 'Uncommon',  46, 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Gem_Amethyst_01.blp', 'war3campImported\ITEMMonsterLure.mdl', 10, 'A dark fish that nearly vanishes in deep water.'),
        ('I6EE', 'Oily Black Pearl',        'material',  12, 30, 'Rare',      84, 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Gem_Stone_01.blp',    NULL, 20, 'A black pearl coated in slick oil.'),
        ('I6EF', 'Barnacled Crate',         'other',    10, 30, 'Common',    65, 'ReplaceableTextures\CommandButtons\BTNBox.blp',                    'war3campImported\ITEMBox.mdl', 1, 'A sealed crate dragged out of wreckage.'),
        ('I6EG', 'Waterlogged Lockbox',     'other',    14, 30, 'Rare',     130, 'ReplaceableTextures\CommandButtons\BTNChestOfGold.blp',            'Objects\InventoryItems\TreasureChest\treasurechest.mdl', 1, 'A locked box swollen by seawater.'),
        ('I6EH', 'Sailor''s Coinpurse',     'other',    10, 30, 'Common',    70, 'ReplaceableTextures\CommandButtons\BTNChestOfGold.blp',            'Objects\InventoryItems\TreasureChest\treasurechest.mdl', 1, 'A small purse with damp coins inside.'),
        ('I6EI', 'Ancient Compass',         'other',    16, 30, 'Rare',     145, 'ReplaceableTextures\CommandButtons\BTNGem.blp',                    NULL, 1, 'A tarnished compass that still points somewhere.'),
        ('I6EJ', 'Tarnished Goblet',        'other',    10, 30, 'Common',    52, 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Gem_Topaz_01.blp',   NULL, 1, 'A dented goblet from a sunken cabin.'),
        ('I6EK', 'Sealed Message Bottle',   'other',    12, 30, 'Uncommon',  76, 'ReplaceableTextures\CommandButtons\BTNINV_Wine_02.blp',            NULL, 1, 'A corked bottle with a salt-stained note inside.'),
        ('I6EL', 'Shipwreck Debris',        'material', 10, 30, 'Common',    18, 'ReplaceableTextures\CommandButtons\BTNHumanMissileUpThree.blp',    NULL, 20, 'Usable scrap recovered from a wreck.'),
        ('I6EM', 'Polished Pearl',          'material',  8, 30, 'Uncommon',  58, 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Gem_Diamond_01.blp', NULL, 20, 'A clean pearl with a fine luster.'),
        ('I6EN', 'Stranglekelp Clump',      'material',  5, 20, 'Common',    18, 'ReplaceableTextures\CommandButtons\BTNInv_Misc_Herb_15.blp',         NULL, 20, 'A tangled clump of waterweed.'),
        ('I6EO', 'Broken Fishing Hook',     'other',     1, 20, 'Common',    10, 'ReplaceableTextures\CommandButtons\BTNSteelMelee.blp',             NULL, 1, 'An old hook from another fisher.'),
        ('I6EP', 'Rusted Anchor Fragment',  'material', 10, 30, 'Common',    22, 'ReplaceableTextures\CommandButtons\BTNSteelMelee.blp',             NULL, 20, 'A jagged piece of rusted anchor.'),
        ('I6EQ', 'Glowing Fish Scale',      'material',  6, 24, 'Uncommon',  34, 'ReplaceableTextures\CommandButtons\BTNEnchantedGemstone.blp',       NULL, 20, 'A small scale with a steady inner glow.'),
        ('I6ER', 'Prismatic Shell',         'material', 16, 30, 'Rare',      94, 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Gem_Variety_02.blp', NULL, 20, 'A shell that shifts color in the hand.'),
        ('I6ES', 'Driftwood Bundle',        'material',  1, 16, 'Common',    14, 'ReplaceableTextures\CommandButtons\BTNNatureTouchGrow.blp',        NULL, 20, 'Salt-stained wood gathered from the waterline.'),
        ('I6ET', 'Sunken Silver Ring',      'other',    12, 30, 'Uncommon',  88, 'ReplaceableTextures\CommandButtons\BTNRingGreen.blp',              NULL, 1, 'A plain ring recovered from the bottom.'),
        ('I6EU', 'Drowned Sapphire',        'material', 18, 30, 'Rare',     120, 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Gem_Sapphire_01.blp', NULL, 20, 'A cold blue gem rolled smooth by the sea.'),
        ('I6EV', 'Noxious Fin',             'material', 12, 30, 'Common',    30, 'ReplaceableTextures\PassiveButtons\PASBTNSlowPoison.blp',          NULL, 20, 'A fin slick with noxious residue.'),
        ('I6EW', 'Felweed Bundle',          'material', 12, 30, 'Common',    32, 'ReplaceableTextures\CommandButtons\BTNFelHound.blp',                NULL, 20, 'Felweed tied together with wet cord.'),
        ('I6EX', 'Searing Eel',             'consumable',15, 30, 'Uncommon',  56, 'ReplaceableTextures\CommandButtons\BTNFish_24.blp',                 'war3campImported\ITEMMonsterLure.mdl', 10, 'An eel that writhes with lingering heat.'),
        ('I6EY', 'Magma Clam',              'material', 16, 30, 'Uncommon',  64, 'ReplaceableTextures\CommandButtons\BTNSpinyCrab.blp',               NULL, 20, 'A clam shell fused with cooled magma.'),
        ('I6EZ', 'Arcane Pearl',            'material', 18, 30, 'Rare',     118, 'ReplaceableTextures\CommandButtons\BTNEnchantedGemstone.blp',       NULL, 20, 'A pearl humming with stored magic.')
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
    p.item_code,
    p.item_name,
    CASE WHEN p.item_kind = 'consumable' THEN 'rej3' ELSE 'bzbe' END,
    CASE
        WHEN p.item_kind = 'consumable' THEN l.consumable_type_id
        WHEN p.item_kind = 'material' THEN l.material_type_id
        ELSE l.other_type_id
    END,
    CASE p.rarity_name
        WHEN 'Rare' THEN l.rare_rarity_id
        WHEN 'Uncommon' THEN l.uncommon_rarity_id
        ELSE l.common_rarity_id
    END,
    CASE
        WHEN p.item_kind = 'consumable' THEN l.consumable_class_id
        WHEN p.item_kind = 'material' THEN COALESCE(l.material_class_id, l.misc_class_id)
        ELSE COALESCE(l.other_class_id, l.misc_class_id)
    END,
    p.tier_max,
    1,
    CASE WHEN p.item_kind = 'consumable' THEN 10 ELSE 1 END,
    p.max_stack,
    p.gold_cost,
    0,
    TRUE, TRUE, TRUE, FALSE, TRUE,
    p.item_kind = 'consumable', FALSE, FALSE, FALSE, TRUE,
    p.icon_path,
    p.model_path,
    255, 255, 255, 255, 1.0,
    p.item_name,
    CASE
        WHEN p.item_kind = 'consumable' THEN 'Regenerates health.'
        WHEN p.item_kind = 'material' THEN 'A fishing material recovered from a special pool.'
        ELSE 'A fishing treasure recovered from a special pool.'
    END,
    CASE
        WHEN p.item_kind = 'consumable' THEN '|cff87ceebNon-Combat Consumable|r|nRegenerates 100 hit points of the Hero over 30 seconds when used.|nContains up to 10 fish.|n|cffd3d3d3' || p.tooltip_hint || '|r'
        WHEN p.item_kind = 'material' THEN '[|c00CCCCCCMaterial|r, |c00A9A9A9Fishing|r]|n|c00D3D3D3' || p.tooltip_hint || '|r'
        ELSE '[|c00CCCCCCOther|r, |c00A9A9A9Fishing|r]|n|c00D3D3D3' || p.tooltip_hint || '|r'
    END,
    CASE WHEN p.item_kind = 'consumable' THEN 'Charged' ELSE 'Permanent' END,
    p.item_kind = 'consumable',
    TRUE,
    TRUE,
    FALSE,
    NULL,
    FALSE,
    CASE WHEN p.item_kind = 'consumable' THEN 'A60V' ELSE NULL END,
    FALSE,
    TRUE,
    'PotS fishing special pool reward seed'
FROM pool_loot_items p
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

WITH fish_pool_codes(unit_code) AS (
    VALUES
        ('n02N'), ('n02O'), ('n02P'), ('n02Q'), ('n02R'), ('n02S'),
        ('n02T'), ('n02U'), ('n02V'), ('n02W'), ('n02X')
)
UPDATE unit_types u
SET loot_mode = 'none',
    loot_tier_id = NULL,
    loot_table_id = NULL,
    drop_count_min = 0,
    drop_count_max = 0,
    notes = CASE
        WHEN COALESCE(u.notes, '') ILIKE '%PotS fishing gather pool:%' THEN u.notes
        ELSE CONCAT_WS(' ', NULLIF(u.notes, ''), 'PotS fishing gather pool: rewards handled by GatherNodes.')
    END,
    updated_at = CURRENT_TIMESTAMP
FROM fish_pool_codes f
WHERE u.unit_code = f.unit_code;

WITH fish_cat AS (
    SELECT id
    FROM gather_node_categories
    WHERE category_name = 'Fish Pools'
    LIMIT 1
),
pool_defs (
    unit_code, node_name, tier_min, tier_max, spawn_weight, max_per_zone,
    skill_required, harvest_yield_min, harvest_yield_max, secondary_chance,
    glow_r, glow_g, glow_b, is_rare, notes, display_order
) AS (
    VALUES
        ('n02N', 'Fish Pool',                 1, 30,  70, 3,   0, 1, 5, 25,  80, 170, 255, FALSE, 'Generic fish pool. Rewards are filtered by zone level.', 7010),
        ('n02O', 'Coastal Fish School',       1, 12, 100, 3,   0, 1, 5, 20,  80, 200, 255, FALSE, 'Low-level coastal and river fish school.', 7020),
        ('n02P', 'Verdant Fish School',       5, 18,  85, 3,  20, 1, 5, 25,  60, 225, 120, FALSE, 'Mid-level green fish school for forest and river zones.', 7030),
        ('n02Q', 'Elemental Water Pool',      5, 18,  45, 2,  25, 1, 4, 40,  60, 140, 255, TRUE,  'Elemental water pool with reagent rewards.', 7040),
        ('n02R', 'Eel School',                8, 25,  65, 2,  40, 1, 5, 30, 170, 170,  70, FALSE, 'Eel-focused fish school for darker waters.', 7050),
        ('n02S', 'Elemental Fire Pool',      10, 30,  45, 2,  50, 1, 4, 45, 255,  90,  20, TRUE,  'Elemental fire pool; does not use normal fish rewards.', 7060),
        ('n02T', 'Deep Elemental Water Pool',10, 30,  40, 2,  50, 1, 4, 45,  70, 220, 255, TRUE,  'Higher-level elemental water pool with reagent rewards.', 7070),
        ('n02U', 'Fel Pool',                 12, 30,  35, 1,  70, 1, 4, 50,  70, 255,  90, TRUE,  'Fel-tainted pool with sinister rewards.', 7080),
        ('n02V', 'Lava Pool',                15, 30,  45, 2,  75, 1, 4, 40, 255,  80,  10, TRUE,  'Lava-warmed pool with fire and lava catches.', 7090),
        ('n02W', 'Searing Lava Pool',        20, 30,  35, 1, 100, 1, 4, 55, 255,  40,   0, TRUE,  'High-level lava pool with rare fiery rewards.', 7100),
        ('n02X', 'Ship Wreck',               10, 30,  30, 1,  50, 1, 4, 65, 190, 170, 110, TRUE,  'Wreckage pool with treasure and occasional fish.', 7110)
)
INSERT INTO gather_unit_nodes (
    unit_code, node_name, category_id, spawn_weight,
    respawn_time_min, respawn_time_max, max_per_zone, skill_required,
    owner_player, glow_effect, glow_color_r, glow_color_g, glow_color_b,
    glow_alpha, glow_scale, glow_height, is_rare, enabled, notes,
    profession_id, harvest_yield_min, harvest_yield_max, gather_success_chance_percent,
    special_behavior_id, special_behavior_chance_percent,
    main_drop_group_chance_percent, secondary_drop_group_chance_percent,
    prevent_water_spawn, display_order
)
SELECT
    p.unit_code,
    p.node_name,
    c.id,
    p.spawn_weight,
    180.0,
    420.0,
    p.max_per_zone,
    p.skill_required,
    24,
    TRUE,
    p.glow_r,
    p.glow_g,
    p.glow_b,
    185,
    1.4,
    55.0,
    p.is_rare,
    TRUE,
    p.notes,
    4,
    p.harvest_yield_min,
    p.harvest_yield_max,
    100,
    0,
    0,
    100,
    p.secondary_chance,
    FALSE,
    p.display_order
FROM pool_defs p
CROSS JOIN fish_cat c
ON CONFLICT (unit_code) DO UPDATE SET
    node_name = EXCLUDED.node_name,
    category_id = EXCLUDED.category_id,
    spawn_weight = EXCLUDED.spawn_weight,
    respawn_time_min = EXCLUDED.respawn_time_min,
    respawn_time_max = EXCLUDED.respawn_time_max,
    max_per_zone = EXCLUDED.max_per_zone,
    skill_required = EXCLUDED.skill_required,
    owner_player = EXCLUDED.owner_player,
    glow_effect = EXCLUDED.glow_effect,
    glow_color_r = EXCLUDED.glow_color_r,
    glow_color_g = EXCLUDED.glow_color_g,
    glow_color_b = EXCLUDED.glow_color_b,
    glow_alpha = EXCLUDED.glow_alpha,
    glow_scale = EXCLUDED.glow_scale,
    glow_height = EXCLUDED.glow_height,
    is_rare = EXCLUDED.is_rare,
    enabled = EXCLUDED.enabled,
    notes = EXCLUDED.notes,
    profession_id = EXCLUDED.profession_id,
    harvest_yield_min = EXCLUDED.harvest_yield_min,
    harvest_yield_max = EXCLUDED.harvest_yield_max,
    gather_success_chance_percent = EXCLUDED.gather_success_chance_percent,
    special_behavior_id = EXCLUDED.special_behavior_id,
    special_behavior_chance_percent = EXCLUDED.special_behavior_chance_percent,
    main_drop_group_chance_percent = EXCLUDED.main_drop_group_chance_percent,
    secondary_drop_group_chance_percent = EXCLUDED.secondary_drop_group_chance_percent,
    prevent_water_spawn = EXCLUDED.prevent_water_spawn,
    display_order = EXCLUDED.display_order,
    updated_at = CURRENT_TIMESTAMP;

WITH pool_nodes AS (
    SELECT id
    FROM gather_unit_nodes
    WHERE unit_code IN ('n02N', 'n02O', 'n02P', 'n02Q', 'n02R', 'n02S', 'n02T', 'n02U', 'n02V', 'n02W', 'n02X')
)
DELETE FROM gather_node_zones z
USING pool_nodes p
WHERE z.node_type = 'unit'
  AND z.node_id = p.id;

WITH pool_defs (
    unit_code, tier_min, tier_max, spawn_weight, max_override
) AS (
    VALUES
        ('n02N',  1, 30,  70, 3),
        ('n02O',  1, 12, 100, 3),
        ('n02P',  5, 18,  85, 3),
        ('n02Q',  5, 18,  45, 2),
        ('n02R',  8, 25,  65, 2),
        ('n02S', 10, 30,  45, 2),
        ('n02T', 10, 30,  40, 2),
        ('n02U', 12, 30,  35, 1),
        ('n02V', 15, 30,  45, 2),
        ('n02W', 20, 30,  35, 1),
        ('n02X', 10, 30,  30, 1)
),
pool_tags(unit_code, tag) AS (
    VALUES
        ('n02N', 'any'),
        ('n02O', 'fresh'), ('n02O', 'river'), ('n02O', 'coast'),
        ('n02P', 'fresh'), ('n02P', 'river'), ('n02P', 'coast'),
        ('n02Q', 'water'), ('n02Q', 'river'), ('n02Q', 'coast'),
        ('n02R', 'river'), ('n02R', 'coast'), ('n02R', 'shadow'),
        ('n02S', 'fire'),
        ('n02T', 'water'), ('n02T', 'river'), ('n02T', 'coast'),
        ('n02U', 'fel'), ('n02U', 'shadow'),
        ('n02V', 'fire'), ('n02V', 'lava'),
        ('n02W', 'lava'),
        ('n02X', 'wreck')
),
zone_source AS (
    SELECT
        z.zone_id,
        z.zone_name,
        z.parent_zone_id,
        COALESCE(NULLIF(z.level_range, ''), NULLIF(parent.level_range, '')) AS effective_level_range
    FROM gather_zones z
    LEFT JOIN gather_zones parent ON parent.zone_id = z.parent_zone_id
    WHERE z.enabled = TRUE
),
zone_ranges AS (
    SELECT
        zs.zone_id,
        zs.zone_name,
        (m.match)[1]::INT AS level_min,
        (m.match)[2]::INT AS level_max,
        lower(zs.zone_name) AS zone_key
    FROM zone_source zs
    CROSS JOIN LATERAL regexp_match(zs.effective_level_range, '^\s*([0-9]+)\s*-\s*([0-9]+)\s*$') AS m(match)
),
zone_tags AS (
    SELECT
        z.zone_id,
        z.zone_name,
        z.level_min,
        z.level_max,
        ARRAY_REMOVE(ARRAY[
            'any'::TEXT,
            CASE WHEN z.zone_key ~ '(serene|haven|thorn|twilight|verdant|weeping|redwind|vanguard)' THEN 'fresh' END,
            CASE WHEN z.zone_key ~ '(river|haven|serene|thorn|twilight|verdant|weeping)' THEN 'river' END,
            CASE WHEN z.zone_key ~ '(siren|serpent|stormhaven|riverbane|havenwoods|verdant|twilight|sereneglade)' THEN 'coast' END,
            CASE WHEN z.zone_key ~ '(siren|serpent|stormhaven|riverbane|havenwoods|verdant|twilight|sereneglade|thornwoods)' THEN 'water' END,
            CASE WHEN z.zone_key ~ '(siren|serpent|stormhaven|riverbane)' THEN 'wreck' END,
            CASE WHEN z.zone_key ~ '(ember|dragonfire|firelands|blaze|cinder|felfire)' THEN 'fire' END,
            CASE WHEN z.zone_key ~ '(dragonfire|firelands|blaze|cinder)' THEN 'lava' END,
            CASE WHEN z.zone_key ~ '(fel|dreadforge)' THEN 'fel' END,
            CASE WHEN z.zone_key ~ '(deadwoods|crypt|ghost|shadow|zul|dreadforge)' THEN 'shadow' END
        ], NULL) AS tags
    FROM zone_ranges z
),
eligible_assignments AS (
    SELECT
        n.id AS node_id,
        p.unit_code,
        z.zone_id,
        z.zone_name,
        p.spawn_weight,
        p.max_override,
        CASE
            WHEN z.level_max <= 8 THEN 2
            WHEN z.level_max <= 18 THEN 3
            ELSE 4
        END AS shared_max_override
    FROM pool_defs p
    JOIN gather_unit_nodes n ON n.unit_code = p.unit_code
    JOIN zone_tags z
      ON p.tier_min <= z.level_max
     AND p.tier_max >= z.level_min
    WHERE EXISTS (
        SELECT 1
        FROM pool_tags pt
        WHERE pt.unit_code = p.unit_code
          AND pt.tag = ANY(z.tags)
    )
)
INSERT INTO gather_node_zones (
    node_type, node_id, zone_id, zone_name, spawn_mode, spawn_group_id,
    weight_override, max_override, shared_max_override, enabled
)
SELECT
    'unit',
    e.node_id,
    e.zone_id,
    e.zone_name,
    'random',
    NULL,
    e.spawn_weight,
    e.max_override,
    e.shared_max_override,
    TRUE
FROM eligible_assignments e
ON CONFLICT (node_type, node_id, zone_id) DO UPDATE SET
    zone_name = EXCLUDED.zone_name,
    spawn_mode = EXCLUDED.spawn_mode,
    spawn_group_id = EXCLUDED.spawn_group_id,
    weight_override = EXCLUDED.weight_override,
    max_override = EXCLUDED.max_override,
    shared_max_override = EXCLUDED.shared_max_override,
    enabled = EXCLUDED.enabled;

WITH pool_nodes AS (
    SELECT id
    FROM gather_unit_nodes
    WHERE unit_code IN ('n02N', 'n02O', 'n02P', 'n02Q', 'n02R', 'n02S', 'n02T', 'n02U', 'n02V', 'n02W', 'n02X')
)
DELETE FROM gather_unit_node_drops d
USING pool_nodes p
WHERE d.node_id = p.id;

WITH reward_defs (
    unit_code, item_code, item_name, tier_min, tier_max, group_name,
    weight, min_quantity, max_quantity, reward_order
) AS (
    VALUES
        ('n02N', 'I6CU', 'Raw Brilliant Smallfish',      1,  5, 'Main',      120, 1, 1, 101),
        ('n02N', 'I6CV', 'Raw Slitherskin Mackerel',    1,  5, 'Main',      120, 1, 1, 102),
        ('n02N', 'I6CW', 'Sickly Looking Fish',          1,  6, 'Main',       70, 1, 1, 103),
        ('n02N', 'I6CY', 'Raw Longjaw Mud Snapper',      5, 10, 'Main',      110, 1, 1, 104),
        ('n02N', 'I6CZ', 'Raw Rainbow Fin Albacore',     5, 12, 'Main',      100, 1, 1, 105),
        ('n02N', 'I6D0', 'Raw Bristle Whisker Catfish',  8, 14, 'Main',       95, 1, 1, 106),
        ('n02N', 'I6D1', 'Raw Loch Frenzy',              8, 15, 'Main',       80, 1, 1, 107),
        ('n02N', 'I6D4', 'Raw Sagefish',                10, 18, 'Main',       80, 1, 1, 108),
        ('n02N', 'I6D6', 'Raw Rockscale Cod',           14, 20, 'Main',       95, 1, 1, 109),
        ('n02N', 'I6D7', 'Raw Mithril Head Trout',      15, 22, 'Main',       90, 1, 1, 110),
        ('n02N', 'I6D8', 'Raw Spotted Yellowtail',      15, 25, 'Main',       85, 1, 1, 111),
        ('n02N', 'I6DA', 'Raw Redgill',                 18, 26, 'Main',       90, 1, 1, 112),
        ('n02N', 'I6DE', 'Raw Whitescale Salmon',       22, 30, 'Main',       85, 1, 1, 113),
        ('n02N', 'I6DF', 'Darkclaw Lobster',            22, 30, 'Main',       55, 1, 1, 114),
        ('n02N', 'I6DK', 'Furious Crawdad',             20, 30, 'Main',       25, 1, 1, 115),
        ('n02N', 'I6DL', '10 Pound Mud Snapper',         1, 10, 'Secondary',  70, 1, 1, 501),
        ('n02N', 'I6DM', '12 Pound Mud Snapper',         1, 12, 'Secondary',  60, 1, 1, 502),
        ('n02N', 'I6DN', '15 Pound Mud Snapper',         5, 15, 'Secondary',  55, 1, 1, 503),
        ('n02N', 'I6DO', '17 Pound Catfish',             8, 18, 'Secondary',  55, 1, 1, 504),
        ('n02N', 'I6DP', '22 Pound Catfish',            10, 22, 'Secondary',  45, 1, 1, 505),
        ('n02N', 'I6DQ', '26 Pound Catfish',            15, 26, 'Secondary',  40, 1, 1, 506),
        ('n02N', 'I6DR', 'Steelscale Crushfish',        15, 30, 'Secondary',  25, 1, 1, 507),
        ('n02N', 'I6DS', 'Rockhide Strongfish',         20, 30, 'Secondary',  18, 1, 1, 508),
        ('n02N', 'I6DT', 'Dark Herring',                20, 30, 'Secondary',  12, 1, 1, 509),
        ('n02N', 'I6DU', 'Broken Wine Bottle',          10, 25, 'Secondary',  30, 1, 1, 510),

        ('n02O', 'I6CU', 'Raw Brilliant Smallfish',      1,  5, 'Main',      100, 1, 1, 101),
        ('n02O', 'I6CV', 'Raw Slitherskin Mackerel',    1,  5, 'Main',      120, 1, 1, 102),
        ('n02O', 'I6CY', 'Raw Longjaw Mud Snapper',      5, 10, 'Main',      105, 1, 1, 103),
        ('n02O', 'I6CZ', 'Raw Rainbow Fin Albacore',     5, 12, 'Main',      110, 1, 1, 104),
        ('n02O', 'I6CX', 'Oily Blackmouth',              5, 12, 'Main',       65, 1, 1, 105),
        ('n02O', 'I6E4', 'Azurefin Minnow',              5, 16, 'Main',       80, 1, 1, 106),
        ('n02O', 'I6EN', 'Stranglekelp Clump',           5, 20, 'Secondary',  70, 1, 2, 501),
        ('n02O', 'I6EO', 'Broken Fishing Hook',          1, 20, 'Secondary',  35, 1, 1, 502),
        ('n02O', 'I6DL', '10 Pound Mud Snapper',         1, 10, 'Secondary',  40, 1, 1, 503),
        ('n02O', 'I6DM', '12 Pound Mud Snapper',         1, 12, 'Secondary',  30, 1, 1, 504),

        ('n02P', 'I6D0', 'Raw Bristle Whisker Catfish',  8, 14, 'Main',      100, 1, 1, 101),
        ('n02P', 'I6D1', 'Raw Loch Frenzy',              8, 15, 'Main',       85, 1, 1, 102),
        ('n02P', 'I6D3', 'Deviate Fish',                10, 18, 'Main',       45, 1, 1, 103),
        ('n02P', 'I6D4', 'Raw Sagefish',                10, 18, 'Main',      100, 1, 1, 104),
        ('n02P', 'I6D5', 'Raw Greater Sagefish',        14, 22, 'Main',       70, 1, 1, 105),
        ('n02P', 'I6D6', 'Raw Rockscale Cod',           14, 20, 'Main',       90, 1, 1, 106),
        ('n02P', 'I6DJ', 'Barbed Gill Trout',           12, 22, 'Main',       95, 1, 1, 107),
        ('n02P', 'I6EQ', 'Glowing Fish Scale',           6, 24, 'Secondary',  55, 1, 2, 501),
        ('n02P', 'I6EM', 'Polished Pearl',               8, 30, 'Secondary',  35, 1, 1, 502),
        ('n02P', 'I6DN', '15 Pound Mud Snapper',         5, 15, 'Secondary',  35, 1, 1, 503),
        ('n02P', 'I6DO', '17 Pound Catfish',             8, 18, 'Secondary',  30, 1, 1, 504),

        ('n02Q', 'I6E1', 'Pure Water Globule',           5, 18, 'Main',      110, 1, 2, 101),
        ('n02Q', 'I6E0', 'Elemental Water',              8, 30, 'Main',       80, 1, 1, 102),
        ('n02Q', 'I6C6', 'Essence of Water',             8, 30, 'Main',       65, 1, 1, 103),
        ('n02Q', 'I003', 'Water Crystal',                8, 30, 'Main',       45, 1, 1, 104),
        ('n02Q', 'I6E2', 'Tidal Pearl',                 14, 30, 'Main',       28, 1, 1, 105),
        ('n02Q', 'I6E3', 'Enchanted Seaweed',            5, 22, 'Secondary',  75, 1, 2, 501),
        ('n02Q', 'I6EM', 'Polished Pearl',               8, 30, 'Secondary',  45, 1, 1, 502),
        ('n02Q', 'I6EZ', 'Arcane Pearl',                18, 30, 'Secondary',  18, 1, 1, 503),

        ('n02R', 'I6DI', 'Raw Tigerseye Eel',           10, 20, 'Main',      100, 1, 1, 101),
        ('n02R', 'I6EA', 'Nightscale Eel',              12, 26, 'Main',       90, 1, 1, 102),
        ('n02R', 'I6ED', 'Shadowfin',                   14, 30, 'Main',       70, 1, 1, 103),
        ('n02R', 'I6DD', 'Stonescale Eel',              20, 30, 'Main',       65, 1, 1, 104),
        ('n02R', 'I6DB', 'Nightfin Snapper',            20, 30, 'Main',       60, 1, 1, 105),
        ('n02R', 'I6EC', 'Darkwater Clam',              10, 24, 'Secondary',  65, 1, 2, 501),
        ('n02R', 'I6EE', 'Oily Black Pearl',            12, 30, 'Secondary',  28, 1, 1, 502),
        ('n02R', 'I67Y', 'Shadowgem',                   18, 30, 'Secondary',  18, 1, 1, 503),

        ('n02S', 'I6DW', 'Elemental Fire',              10, 30, 'Main',      100, 1, 1, 101),
        ('n02S', 'I6C5', 'Essence of Fire',             10, 30, 'Main',       80, 1, 1, 102),
        ('n02S', 'I002', 'Fire Crystal',                10, 30, 'Main',       55, 1, 1, 103),
        ('n02S', 'I6DV', 'Firefin Oil',                  8, 18, 'Main',       75, 1, 2, 104),
        ('n02S', 'I6DX', 'Volcanic Scale',              10, 30, 'Main',       70, 1, 2, 105),
        ('n02S', 'I6DY', 'Smoldering Pearl',            18, 30, 'Secondary',  35, 1, 1, 501),
        ('n02S', 'i1d5', 'Firebloom',                   10, 30, 'Secondary',  45, 1, 1, 502),
        ('n02S', 'i1d6', 'Fireweed',                    10, 30, 'Secondary',  50, 1, 2, 503),

        ('n02T', 'I6E0', 'Elemental Water',             10, 30, 'Main',      100, 1, 1, 101),
        ('n02T', 'I6C6', 'Essence of Water',            10, 30, 'Main',       85, 1, 1, 102),
        ('n02T', 'I003', 'Water Crystal',               10, 30, 'Main',       60, 1, 1, 103),
        ('n02T', 'I6E2', 'Tidal Pearl',                 14, 30, 'Main',       45, 1, 1, 104),
        ('n02T', 'I6ER', 'Prismatic Shell',             16, 30, 'Secondary',  35, 1, 1, 501),
        ('n02T', 'I6EZ', 'Arcane Pearl',                18, 30, 'Secondary',  28, 1, 1, 502),
        ('n02T', 'I6E3', 'Enchanted Seaweed',            5, 22, 'Secondary',  60, 1, 2, 503),

        ('n02U', 'I6E6', 'Black Ichor',                 12, 30, 'Main',      100, 1, 2, 101),
        ('n02U', 'I6E5', 'Fel-Touched Fish',            12, 30, 'Main',       75, 1, 1, 102),
        ('n02U', 'I6EV', 'Noxious Fin',                 12, 30, 'Main',       70, 1, 2, 103),
        ('n02U', 'I6E7', 'Demonic Scale',               14, 30, 'Main',       55, 1, 1, 104),
        ('n02U', 'I6E8', 'Corrupted Pearl',             16, 30, 'Main',       28, 1, 1, 105),
        ('n02U', 'I6E9', 'Abyssal Eye',                 18, 30, 'Secondary',  25, 1, 1, 501),
        ('n02U', 'I67Y', 'Shadowgem',                   18, 30, 'Secondary',  22, 1, 1, 502),
        ('n02U', 'i1d4', 'Felweed',                     12, 30, 'Secondary',  45, 1, 1, 503),
        ('n02U', 'i1e6', 'Fel Cap',                     12, 30, 'Secondary',  35, 1, 1, 504),
        ('n02U', 'i1e9', 'Nightmare Vine',              14, 30, 'Secondary',  25, 1, 1, 505),

        ('n02V', 'I6DZ', 'Lavafin Snapper',             12, 24, 'Main',       90, 1, 1, 101),
        ('n02V', 'I6EX', 'Searing Eel',                 15, 30, 'Main',       80, 1, 1, 102),
        ('n02V', 'I6EY', 'Magma Clam',                  16, 30, 'Main',       70, 1, 1, 103),
        ('n02V', 'I6DV', 'Firefin Oil',                  8, 18, 'Main',       65, 1, 2, 104),
        ('n02V', 'I6DX', 'Volcanic Scale',              10, 30, 'Main',       65, 1, 2, 105),
        ('n02V', 'I6DW', 'Elemental Fire',              10, 30, 'Secondary',  42, 1, 1, 501),
        ('n02V', 'I6C5', 'Essence of Fire',             10, 30, 'Secondary',  36, 1, 1, 502),
        ('n02V', 'I6DY', 'Smoldering Pearl',            18, 30, 'Secondary',  24, 1, 1, 503),

        ('n02W', 'I6DW', 'Elemental Fire',              20, 30, 'Main',      100, 1, 1, 101),
        ('n02W', 'I6EX', 'Searing Eel',                 15, 30, 'Main',       70, 1, 1, 102),
        ('n02W', 'I6EY', 'Magma Clam',                  16, 30, 'Main',       75, 1, 1, 103),
        ('n02W', 'I6DY', 'Smoldering Pearl',            18, 30, 'Main',       45, 1, 1, 104),
        ('n02W', 'I002', 'Fire Crystal',                20, 30, 'Secondary',  35, 1, 1, 501),
        ('n02W', 'I6C5', 'Essence of Fire',             20, 30, 'Secondary',  45, 1, 1, 502),
        ('n02W', 'i1d7', 'Flame Cap',                   20, 30, 'Secondary',  30, 1, 1, 503),

        ('n02X', 'I6EF', 'Barnacled Crate',             10, 30, 'Main',      100, 1, 1, 101),
        ('n02X', 'I6EH', 'Sailor''s Coinpurse',         10, 30, 'Main',       85, 1, 1, 102),
        ('n02X', 'I6EL', 'Shipwreck Debris',            10, 30, 'Main',       80, 1, 2, 103),
        ('n02X', 'I6EK', 'Sealed Message Bottle',       12, 30, 'Main',       60, 1, 1, 104),
        ('n02X', 'I6EG', 'Waterlogged Lockbox',         14, 30, 'Main',       30, 1, 1, 105),
        ('n02X', 'I6EI', 'Ancient Compass',             16, 30, 'Main',       24, 1, 1, 106),
        ('n02X', 'I6EJ', 'Tarnished Goblet',            10, 30, 'Main',       65, 1, 1, 107),
        ('n02X', 'I6EM', 'Polished Pearl',               8, 30, 'Secondary',  55, 1, 1, 501),
        ('n02X', 'I6ET', 'Sunken Silver Ring',          12, 30, 'Secondary',  35, 1, 1, 502),
        ('n02X', 'I6EU', 'Drowned Sapphire',            18, 30, 'Secondary',  25, 1, 1, 503),
        ('n02X', 'I6D8', 'Raw Spotted Yellowtail',      15, 25, 'Secondary',  45, 1, 1, 504),
        ('n02X', 'I6DB', 'Nightfin Snapper',            20, 30, 'Secondary',  30, 1, 1, 505)
),
zone_source AS (
    SELECT
        z.zone_id,
        z.zone_name,
        COALESCE(NULLIF(z.level_range, ''), NULLIF(parent.level_range, '')) AS effective_level_range
    FROM gather_zones z
    LEFT JOIN gather_zones parent ON parent.zone_id = z.parent_zone_id
    WHERE z.enabled = TRUE
),
zone_ranges AS (
    SELECT
        zs.zone_id,
        zs.zone_name,
        (m.match)[1]::INT AS level_min,
        (m.match)[2]::INT AS level_max,
        (((m.match)[1]::INT + (m.match)[2]::INT) / 2.0) AS level_mid
    FROM zone_source zs
    CROSS JOIN LATERAL regexp_match(zs.effective_level_range, '^\s*([0-9]+)\s*-\s*([0-9]+)\s*$') AS m(match)
),
assigned_pool_zones AS (
    SELECT
        n.unit_code,
        n.id AS node_id,
        z.zone_id,
        z.zone_name,
        z.level_min,
        z.level_max,
        z.level_mid
    FROM gather_node_zones a
    JOIN gather_unit_nodes n ON a.node_type = 'unit' AND n.id = a.node_id
    JOIN zone_ranges z ON z.zone_id = a.zone_id
    WHERE n.unit_code IN ('n02N', 'n02O', 'n02P', 'n02Q', 'n02R', 'n02S', 'n02T', 'n02U', 'n02V', 'n02W', 'n02X')
      AND a.enabled = TRUE
),
default_rows AS (
    SELECT
        n.id AS node_id,
        0 AS zone_id,
        'Default / Unknown Zone' AS zone_name,
        r.group_name,
        r.item_code,
        r.item_name,
        100 AS drop_chance_percent,
        r.weight,
        r.min_quantity,
        r.max_quantity,
        TRUE AS enabled,
        CASE WHEN r.group_name = 'Secondary' THEN 5000 ELSE 1000 END + r.reward_order AS display_order,
        'PotS fishing seed: default fallback for ' || n.node_name || '.' AS notes
    FROM reward_defs r
    JOIN gather_unit_nodes n ON n.unit_code = r.unit_code
),
ranked_zone_rows AS (
    SELECT
        z.node_id,
        z.zone_id,
        z.zone_name,
        r.group_name,
        r.item_code,
        r.item_name,
        100 AS drop_chance_percent,
        r.weight,
        r.min_quantity,
        r.max_quantity,
        TRUE AS enabled,
        z.zone_id * 1000 + CASE WHEN r.group_name = 'Secondary' THEN 500 ELSE 100 END + r.reward_order AS display_order,
        'PotS fishing seed: ' || r.group_name || ' reward filtered by pool type and zone level.' AS notes,
        ROW_NUMBER() OVER (
            PARTITION BY z.node_id, z.zone_id, r.group_name
            ORDER BY ABS(((r.tier_min + r.tier_max) / 2.0) - z.level_mid), r.reward_order
        ) AS reward_rank
    FROM assigned_pool_zones z
    JOIN reward_defs r
      ON r.unit_code = z.unit_code
     AND r.tier_min <= z.level_max
     AND r.tier_max >= z.level_min
)
INSERT INTO gather_unit_node_drops (
    node_id, zone_id, zone_name, group_name, item_code, item_name,
    drop_chance_percent, weight, min_quantity, max_quantity,
    enabled, display_order, notes
)
SELECT
    node_id, zone_id, zone_name, group_name, item_code, item_name,
    drop_chance_percent, weight, min_quantity, max_quantity, enabled, display_order, notes
FROM default_rows
UNION ALL
SELECT
    node_id, zone_id, zone_name, group_name, item_code, item_name,
    drop_chance_percent, weight, min_quantity, max_quantity, enabled, display_order, notes
FROM ranked_zone_rows
WHERE reward_rank <= CASE WHEN group_name = 'Main' THEN 6 ELSE 3 END;

COMMIT;
