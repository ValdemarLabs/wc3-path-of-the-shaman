-- Zul'kis begins with modest Darkspear travel gear. These items are excluded
-- from generic loot because they exist to establish his prologue loadout.
WITH starter_items (
    item_code, item_name, class_name, item_level, icon_path, tooltip,
    description, wc3_abilities
) AS (
    VALUES
        ('j4c3', '|cFFFFFFFFWorn Hexer''s Hood|r', 'Head Armor', 110,
         'ReplaceableTextures\CommandButtons\BTNHelmet_30.blp', 'Worn Hexer''s Hood',
         '[|cFFC0C0C0Head Armor|r, |cFF9D9D9DCommon|r]|n|c00D3D3D3A faded cloth hood marked with simple Darkspear dye.|r', NULL),
        ('j4c4', '|cFFFFFFFFSalt-Stained Ritual Vest|r', 'Chest Armor', 310,
         'ReplaceableTextures\CommandButtons\BTNChest_Cloth_14.blp', 'Salt-Stained Ritual Vest',
         '[|cFFB0C4DEChest Armor|r, |cFF9D9D9DCommon|r]|n|c00D3D3D3Salt-stiffened cloth tied for travel, not ceremony.|r|n|cff0080FF+1 Intelligence|r', 'A074'),
        ('j4c5', '|cFFFFFFFFFrayed Handwraps|r', 'Hand Armor', 410,
         'ReplaceableTextures\CommandButtons\BTNWartornScrap_Leather.blp', 'Frayed Handwraps',
         '[|cFFDEB887Hand Armor|r, |cFF9D9D9DCommon|r]|n|c00D3D3D3Frayed wraps that keep river spray from slicking the hands.|r', NULL),
        ('j4c6', '|cFFFFFFFFFetish-Keeper''s Cord|r', 'Belt', 460,
         'ReplaceableTextures\CommandButtons\BTNBelt_12.blp', 'Fetish-Keeper''s Cord',
         '[|cFF8B5A2BBelt|r, |cFF9D9D9DCommon|r]|n|c00D3D3D3A knotted cord holding a few humble ritual tokens.|r|n|cff0070DD+5 Mana|r', 'A07C'),
        ('j4c7', '|cFFFFFFFFRiverworn Kilt|r', 'Leg Armor', 510,
         'ReplaceableTextures\CommandButtons\BTNArmorKit_03.blp', 'Riverworn Kilt',
         '[|cFFA9B7C6Leg Armor|r, |cFF9D9D9DCommon|r]|n|c00D3D3D3A patched kilt worn thin by the voyage upriver.|r', NULL),
        ('j4c8', '|cFFFFFFFFReedbound Sandals|r', 'Foot Armor', 560,
         'ReplaceableTextures\CommandButtons\BTNBoots_05.blp', 'Reedbound Sandals',
         '[|cFFCD853FFoot Armor|r, |cFF9D9D9DCommon|r]|n|c00D3D3D3Reed-bound sandals repaired more than once.|r', NULL),
        ('j4c9', '|cFFFFFFFFDarkspear Bone Beads|r', 'Neck', 160,
         'ReplaceableTextures\CommandButtons\BTNINV_Jewelry_Necklace_04.blp', 'Darkspear Bone Beads',
         '[|cFF40E0D0Neck|r, |cFF9D9D9DCommon|r]|n|c00D3D3D3Small bone beads used for focus during simple rites.|r|n|cff9370DB+1 Spell Power|r', 'A090'),
        ('j4d0', '|cFFFFFFFFFaded Mojo Charm|r', 'Trinket', 660,
         'ReplaceableTextures\CommandButtons\BTNArmorKit_24.blp', 'Faded Mojo Charm',
         '[|cFFDA70D6Trinket|r, |cFF9D9D9DCommon|r]|n|c00D3D3D3A faded charm carrying only a trace of old mojo.|r', NULL)
)
INSERT INTO items (
    item_code, item_name, base_id, rarity_id, class_id, type_id, item_level,
    required_level, gold_cost, lumber_cost, max_charges, max_stack, tooltip,
    tooltip_extended, description, icon_path, model_path, wc3_abilities,
    wc3_classification, is_powerup, use_automatically, is_droppable,
    is_sellable, is_pawnable, actively_used, is_perishable,
    dropped_on_death, dinv_compatible, deq_compatible, specific_drop_only,
    created_by, notes
)
SELECT
    s.item_code, s.item_name, 'rat9', 1, c.id, 8, s.item_level,
    1, 0, 0, 0, 1, s.tooltip, s.description, s.description, s.icon_path,
    'Objects\InventoryItems\TreasureChest\treasurechest.mdl',
    s.wc3_abilities, 'Permanent', FALSE, FALSE, TRUE, TRUE, TRUE, FALSE,
    FALSE, TRUE, TRUE, TRUE, TRUE, 'Codex',
    'Zul''kis prologue starter equipment.'
FROM starter_items s
JOIN item_classes c ON c.class_name = s.class_name
ON CONFLICT (item_code) DO UPDATE SET
    item_name = EXCLUDED.item_name,
    base_id = EXCLUDED.base_id,
    rarity_id = EXCLUDED.rarity_id,
    class_id = EXCLUDED.class_id,
    type_id = EXCLUDED.type_id,
    item_level = EXCLUDED.item_level,
    required_level = EXCLUDED.required_level,
    gold_cost = EXCLUDED.gold_cost,
    lumber_cost = EXCLUDED.lumber_cost,
    max_charges = EXCLUDED.max_charges,
    max_stack = EXCLUDED.max_stack,
    tooltip = EXCLUDED.tooltip,
    tooltip_extended = EXCLUDED.tooltip_extended,
    description = EXCLUDED.description,
    icon_path = EXCLUDED.icon_path,
    model_path = EXCLUDED.model_path,
    wc3_abilities = EXCLUDED.wc3_abilities,
    wc3_classification = EXCLUDED.wc3_classification,
    is_powerup = EXCLUDED.is_powerup,
    use_automatically = EXCLUDED.use_automatically,
    is_droppable = EXCLUDED.is_droppable,
    is_sellable = EXCLUDED.is_sellable,
    is_pawnable = EXCLUDED.is_pawnable,
    actively_used = EXCLUDED.actively_used,
    is_perishable = EXCLUDED.is_perishable,
    dropped_on_death = EXCLUDED.dropped_on_death,
    dinv_compatible = EXCLUDED.dinv_compatible,
    deq_compatible = EXCLUDED.deq_compatible,
    specific_drop_only = EXCLUDED.specific_drop_only,
    notes = EXCLUDED.notes,
    updated_at = CURRENT_TIMESTAMP;

-- The existing scepter was still classified as miscellaneous in the manager,
-- which prevented current DEquipment exports from defining it as a staff.
UPDATE items
SET class_id = (SELECT id FROM item_classes WHERE class_name = 'Stave'),
    tooltip = '|c0090EE90Shadowcaster''s Scepter|r',
    tooltip_extended = '[|cFF6A5ACDStave|r, |cFF1EFF00Uncommon|r]|n|cff0080FF+3 Intelligence|r|n|cff00FF00+2 Agility|r',
    description = '[|cFF6A5ACDStave|r, |cFF1EFF00Uncommon|r]|n|cff0080FF+3 Intelligence|r|n|cff00FF00+2 Agility|r',
    updated_at = CURRENT_TIMESTAMP
WHERE item_code = 'I68B';

DELETE FROM item_stat_values
WHERE item_id IN (
    SELECT id
    FROM items
    WHERE item_code IN ('j4c3', 'j4c4', 'j4c5', 'j4c6', 'j4c7', 'j4c8', 'j4c9', 'j4d0')
);

INSERT INTO item_stat_values (item_id, stat_id, stat_value, sort_order)
SELECT i.id, s.id, v.stat_value, v.sort_order
FROM (VALUES
    ('j4c4', 'int', 1.00, 0),
    ('j4c6', 'mp', 5.00, 0),
    ('j4c9', 'spell_power', 1.00, 0)
) AS v(item_code, stat_code, stat_value, sort_order)
JOIN items i ON i.item_code = v.item_code
JOIN item_stats s ON s.stat_code = v.stat_code;

DO $$
DECLARE
    starter_count INTEGER;
    starter_stat_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO starter_count
    FROM items
    WHERE item_code IN ('j4c3', 'j4c4', 'j4c5', 'j4c6', 'j4c7', 'j4c8', 'j4c9', 'j4d0');

    SELECT COUNT(*) INTO starter_stat_count
    FROM item_stat_values v
    JOIN items i ON i.id = v.item_id
    WHERE i.item_code IN ('j4c3', 'j4c4', 'j4c5', 'j4c6', 'j4c7', 'j4c8', 'j4c9', 'j4d0');

    IF starter_count <> 8 OR starter_stat_count <> 3 THEN
        RAISE EXCEPTION 'Expected 8 Zul''kis starter items and 3 stat rows, found % items and % stats.', starter_count, starter_stat_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM items i
        JOIN item_classes c ON c.id = i.class_id
        WHERE i.item_code = 'I68B' AND c.class_name = 'Stave'
    ) THEN
        RAISE EXCEPTION 'Shadowcaster''s Scepter was not classified as a staff.';
    END IF;
END $$;

SELECT i.item_code, i.item_name, c.class_name, i.item_level,
       COALESCE(string_agg(s.stat_code || '=' || v.stat_value, ', ' ORDER BY v.sort_order), 'flavor-only') AS stats
FROM items i
JOIN item_classes c ON c.id = i.class_id
LEFT JOIN item_stat_values v ON v.item_id = i.id
LEFT JOIN item_stats s ON s.id = v.stat_id
WHERE i.item_code IN ('I68B', 'j4c3', 'j4c4', 'j4c5', 'j4c6', 'j4c7', 'j4c8', 'j4c9', 'j4d0')
GROUP BY i.item_code, i.item_name, c.class_name, i.item_level
ORDER BY i.item_code;
