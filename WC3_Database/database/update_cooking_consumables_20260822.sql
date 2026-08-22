-- One-time development migration for cooking consumables.
-- Run explicitly against the development database; the Item Manager does not run this file.

CREATE TEMP TABLE cooking_consumable_update (
    item_code VARCHAR(4) PRIMARY KEY,
    buff_name TEXT NOT NULL,
    effect_text TEXT NOT NULL,
    drunk_value NUMERIC(10, 2)
) ON COMMIT DROP;

INSERT INTO cooking_consumable_update (item_code, buff_name, effect_text, drunk_value)
VALUES
    ('j0c6', 'Well Fed', '+1 Agility, +1 hit point regeneration for 15 minutes.', NULL),
    ('j2b0', 'Well Fed', '+1 hit point regeneration and +25 maximum hit points for 15 minutes.', NULL),
    ('j0c7', 'Well Fed', '+1 Strength and +50 maximum hit points for 15 minutes.', NULL),
    ('j2b1', 'Well Fed', '+35 maximum mana and +1 mana regeneration for 15 minutes.', NULL),
    ('j0d0', 'Well Fed', '+2 Agility and +1 Critical Chance for 15 minutes.', NULL),
    ('j0c8', 'Well Fed', '+2 Strength, +100 maximum hit points, and +1 hit point regeneration for 15 minutes.', NULL),
    ('j2b2', 'Well Fed', '+75 maximum hit points and +1 Dodge for 15 minutes.', NULL),
    ('j0c9', 'Well Fed', '+2 Intelligence, +60 maximum mana, and +1 mana regeneration for 15 minutes.', NULL),
    ('j0d1', 'Well Fed', '+1 Armor, +1 Block, and +1 hit point regeneration for 15 minutes.', NULL),
    ('j2a0', 'Well Fed', '+3 Strength and +3 Damage for 15 minutes.', NULL),
    ('j2a1', 'Well Fed', '+2 hit point regeneration, +1 Dodge, and +40 maximum mana for 15 minutes.', NULL),
    ('j2a2', 'Well Fed', '+3 Agility, +1 Hit, and +4 Damage for 15 minutes.', NULL),
    ('j2b3', 'Well Fed', '+2 Agility, +2 Hit, and +1 mana regeneration for 15 minutes.', NULL),
    ('j2a3', 'Well Fed', '+2 Armor, +2 Block, and +150 maximum hit points for 15 minutes.', NULL),
    ('j2b4', 'Well Fed', '+125 maximum hit points, +2 hit point regeneration, and +1 Armor for 15 minutes.', NULL),
    ('j2a4', 'Well Fed', '+3 Intelligence, +90 maximum mana, and +1 Spell Power for 15 minutes.', NULL),
    ('j2b5', 'Well Fed', '+2 Critical Chance, +2 Hit, and +4 Damage for 15 minutes.', NULL),
    ('j2a5', 'Well Fed', '+3 Strength, +5 Damage, and +1 Critical Chance for 15 minutes.', NULL),
    ('j2b6', 'Well Fed', '+5 Spell Power, +2 Critical Chance, and -1 Armor for 15 minutes.', NULL),
    ('j2a6', 'Well Fed', '+5 Agility, +2 Critical Chance, and +7 Damage for 15 minutes.', NULL),
    ('j2b7', 'Well Fed', '+4 Intelligence, +2 mana regeneration, and +5 Spell Power for 15 minutes.', NULL),
    ('j2a7', 'Well Fed', '+5 Agility, +2 Dodge, and +12 movement speed for 15 minutes.', NULL),
    ('j2b9', 'Well Fed', '+3 Armor, +2 Block, and +100 maximum hit points for 15 minutes.', NULL),
    ('j2a8', 'Well Fed', '+5 Strength, +8 Damage, +3 Critical Chance, and -1 Hit for 15 minutes.', NULL),
    ('j2c0', 'Well Fed', '+3 Block, +2 Armor, and +3 Hit for 15 minutes.', NULL),
    ('j2a9', 'Well Fed', '+4 Strength, +250 maximum hit points, and +2 hit point regeneration for 15 minutes.', NULL),
    ('j2c1', 'Well Fed', '+4 Agility, +3 Hit, and +10 movement speed for 15 minutes.', NULL),
    ('j2d2', 'Well Fed', '+4 Agility, +3 Dodge, -2 Intelligence, and +30 sight range for 15 minutes.', NULL),
    ('j2c2', 'Well Fed', '+7 Strength, +12 Damage, and +4 Critical Chance for 15 minutes.', NULL),
    ('j2c3', 'Well Fed', '+4 Critical Chance, +5 Hit, and +6 Damage for 15 minutes.', NULL),
    ('j2c4', 'Well Fed', '+3 mana regeneration, +10 Spell Power, and +180 maximum mana for 15 minutes.', NULL),
    ('j2c5', 'Well Fed', '+4 hit point regeneration, +300 maximum hit points, and +2 Armor for 15 minutes.', NULL),
    ('j2c6', 'Well Fed', '+4 Armor, +5 Block, and -8 movement speed for 15 minutes.', NULL),
    ('j2c7', 'Well Fed', '+5% Spell Power, +250 maximum mana, and +4 Hit for 15 minutes.', NULL),
    ('j2c8', 'Well Fed', '+8 Strength, +300 maximum hit points, and +4 Armor for 15 minutes.', NULL),
    ('j2c9', 'Well Fed', '+8 Agility, +5 Critical Chance, and +6 Dodge for 15 minutes.', NULL),
    ('j2d0', 'Well Fed', '+20 movement speed, +5 Hit, and +5 Dodge for 15 minutes.', NULL),
    ('j2d1', 'Well Fed', '+25 Spell Power, +5 Dodge, and +5% Spell Power for 15 minutes.', NULL),
    ('j2d3', 'Well Fed', '+20 Damage, +5% Spell Power, +5 Critical Chance, and -2 Armor for 15 minutes.', NULL),
    ('j2d4', 'Well Fed', '+8 Critical Chance, +8 Spell Power, +40 sight range, and -2 hit point regeneration for 15 minutes.', NULL),
    -- Alcoholic servings use 6-30 Drunk, keeping one item below the 45 pass-out threshold.
    ('j3a0', 'Well Hydrated', '+25 maximum mana and +1 mana regeneration for 10 minutes.', NULL),
    ('j3a1', 'Well Hydrated', '+50 maximum hit points and -1 Intelligence for 10 minutes.', NULL),
    ('j3a2', 'Well Hydrated', '+1 Strength, -2 Intelligence, and -1 Armor for 10 minutes.', 6),
    ('j3a3', 'Well Hydrated', '+3 Strength, -2 Intelligence, and -1 Armor for 10 minutes.', 8),
    ('j3a4', 'Well Hydrated', '+1 mana regeneration, +60 maximum mana, and -1 Armor for 10 minutes.', NULL),
    ('j3a5', 'Well Hydrated', '+5 Damage, -2 Hit, and -3 Intelligence for 10 minutes.', 10),
    ('j3a6', 'Well Hydrated', '+3 Critical Chance, +6 Damage, -4 Intelligence, and -2 Armor for 10 minutes.', 14),
    ('j3a7', 'Well Hydrated', '+4 Intelligence, +1 mana regeneration, and -1 Armor for 10 minutes.', NULL),
    ('j3a8', 'Well Hydrated', '+5 Dodge, -5 Hit, +20 sight range, and -4 Intelligence for 10 minutes.', 16),
    ('j3a9', 'Well Hydrated', '+15 Spell Power, -20 movement speed, and -2 Armor for 10 minutes.', 10),
    ('j3b0', 'Well Hydrated', '+4 Armor, +4 Block, and -4 Agility for 10 minutes.', 12),
    ('j3b1', 'Well Hydrated', '+200 maximum hit points, +2 hit point regeneration, and -3 Intelligence for 10 minutes.', NULL),
    ('j3b2', 'Well Hydrated', '+20 Damage, +5 Critical Chance, -5 Intelligence, and -4 Armor for 10 minutes.', 20),
    ('j3b3', 'Well Hydrated', '+10% Spell Power, +10 Spell Power, -5 Hit, and -6 Intelligence for 10 minutes.', 25),
    ('j3b4', 'Well Hydrated', '+10 Critical Chance, +10 Damage, -10 Intelligence, -5 Dodge, and -5 Armor for 10 minutes.', 30);

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM cooking_consumable_update) <> 55 THEN
        RAISE EXCEPTION 'Expected 55 cooking consumable definitions';
    END IF;

    IF (SELECT COUNT(*) FROM items i JOIN cooking_consumable_update u ON u.item_code = i.item_code) <> 55 THEN
        RAISE EXCEPTION 'The database does not contain all 55 cooking consumables';
    END IF;
END $$;

INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order, is_active)
VALUES (49, 'drunk', 'Drunk', 'Intoxication added when consumed', '+{value}', '#DDA0DD', 49, TRUE)
ON CONFLICT DO NOTHING;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM item_stats WHERE stat_code = 'drunk') THEN
        RAISE EXCEPTION 'Could not create or find the Drunk item stat';
    END IF;
END $$;

SELECT setval(
    pg_get_serial_sequence('item_stats', 'id'),
    GREATEST((SELECT COALESCE(MAX(id), 1) FROM item_stats), 49),
    TRUE
);

UPDATE items i
SET tooltip_extended = CASE
        WHEN strpos(COALESCE(i.tooltip_extended, ''), '|cffffcc00Use:|r') > 0 THEN
            split_part(i.tooltip_extended, '|cffffcc00Use:|r', 1)
            || '|cffffcc00Use:|r '
            || u.buff_name || '; ' || u.effect_text
        ELSE u.buff_name || '; ' || u.effect_text
    END,
    description = CASE
        WHEN strpos(COALESCE(i.description, ''), '|cffffcc00Use:|r') > 0 THEN
            split_part(i.description, '|cffffcc00Use:|r', 1)
            || '|cffffcc00Use:|r '
            || u.buff_name || '; ' || u.effect_text
        ELSE u.buff_name || '; ' || u.effect_text
    END,
    wc3_abilities = 'A0F5',
    manual_abilities_data = jsonb_build_array(jsonb_build_object(
        'Code', 'A0F5',
        'Type', 'Use',
        'Description', u.buff_name || '; ' || u.effect_text,
        'TooltipNormal', 'Eat/Drink',
        'TooltipSource', 'Custom',
        'TooltipExtended', u.buff_name || '; ' || u.effect_text
    )),
    copy_base_abilities = FALSE,
    actively_used = TRUE,
    cooldown_group = 'Alxk',
    ignore_cooldown = TRUE,
    updated_at = CURRENT_TIMESTAMP
FROM cooking_consumable_update u
WHERE i.item_code = u.item_code;

UPDATE wc3_abilities
SET ability_name = 'Eat/Drink',
    tooltip_normal = 'Eat/Drink',
    tooltip_extended = 'Consumes one charge and applies the item''s Well Fed effect for 15 minutes or Well Hydrated effect for 10 minutes.',
    updated_at = CURRENT_TIMESTAMP
WHERE ability_code = 'A0F5';

DELETE FROM item_stat_values v
USING items i, cooking_consumable_update u, item_stats s
WHERE v.item_id = i.id
  AND i.item_code = u.item_code
  AND v.stat_id = s.id
  AND s.stat_code = 'drunk';

INSERT INTO item_stat_values (item_id, stat_id, stat_value)
SELECT i.id, s.id, u.drunk_value
FROM cooking_consumable_update u
JOIN items i ON i.item_code = u.item_code
CROSS JOIN item_stats s
WHERE s.stat_code = 'drunk'
  AND u.drunk_value IS NOT NULL;

DO $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM items i
        JOIN cooking_consumable_update u ON u.item_code = i.item_code
        WHERE i.cooldown_group = 'Alxk'
          AND i.ignore_cooldown = TRUE
          AND i.manual_abilities_data->0->>'Description' = u.buff_name || '; ' || u.effect_text
    ) <> 55 THEN
        RAISE EXCEPTION 'Cooking consumable text or cooldown configuration verification failed';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM item_stat_values v
        JOIN items i ON i.id = v.item_id
        JOIN item_stats s ON s.id = v.stat_id
        JOIN cooking_consumable_update u ON u.item_code = i.item_code
        WHERE s.stat_code = 'drunk'
          AND v.stat_value = u.drunk_value
    ) <> 10 THEN
        RAISE EXCEPTION 'Expected 10 alcoholic drinks with matching Drunk stat values';
    END IF;
END $$;

SELECT u.buff_name,
       COUNT(*) AS item_count,
       COUNT(*) FILTER (WHERE i.cooldown_group = 'Alxk' AND i.ignore_cooldown) AS no_cooldown_count
FROM cooking_consumable_update u
JOIN items i ON i.item_code = u.item_code
GROUP BY u.buff_name
ORDER BY u.buff_name;
