-- Normalize cooked consumable tooltips and assign themed custom icons.
-- This is an explicit one-time migration; it is not run by ItemManager startup.
WITH food_data(item_code, effect_text, icon_path) AS (
    VALUES
        ('j0c6', '+1 Agility, +1 hit point regeneration.', 'ReplaceableTextures\CommandButtons\BTNFood_132_Meat.blp'),
        ('j0c7', '+1 Strength, +50 maximum hit points.', 'ReplaceableTextures\CommandButtons\BTNFood_107_Venison.blp'),
        ('j0c8', '+2 Strength, +100 maximum hit points, +1 hit point regeneration.', 'ReplaceableTextures\CommandButtons\BTNFood_150_Cookie.blp'),
        ('j0c9', '+2 Intelligence, +60 maximum mana, +1 mana regeneration.', 'ReplaceableTextures\CommandButtons\BTNFood_126_ClamMeat.blp'),
        ('j0d0', '+2 Agility, +1 Critical Chance.', 'ReplaceableTextures\CommandButtons\BTNFood_124_Skewer.blp'),
        ('j0d1', '+1 Armor, +1 Block, +1 hit point regeneration.', 'ReplaceableTextures\CommandButtons\BTNFood_144_CakeSlice.blp'),
        ('j2b0', '+1 hit point regeneration, +25 maximum hit points.', 'ReplaceableTextures\CommandButtons\BTNFood_127_Fish.blp'),
        ('j2b1', '+35 maximum mana, +1 mana regeneration.', 'ReplaceableTextures\CommandButtons\BTNFood_128_Fish.blp'),
        ('j2a0', '+3 Strength, +3 Damage.', 'ReplaceableTextures\CommandButtons\BTNFood_133_Meat.blp'),
        ('j2b2', '+75 maximum hit points, +1 Dodge.', 'ReplaceableTextures\CommandButtons\BTNFood_146_CakeSlice.blp'),
        ('j2a1', '+2 hit point regeneration, +1 Dodge, +40 maximum mana.', 'ReplaceableTextures\CommandButtons\BTNFood_115_CondorSoup.blp'),
        ('j2a2', '+3 Agility, +1 Hit, +4 Damage.', 'ReplaceableTextures\CommandButtons\BTNFood_124_Skewer.blp'),
        ('j2b3', '+2 Agility, +2 Hit, +1 mana regeneration.', 'ReplaceableTextures\CommandButtons\BTNFood_129_Fish.blp'),
        ('j2a3', '+2 Armor, +2 Block, +150 maximum hit points.', 'ReplaceableTextures\CommandButtons\BTNFood_117_HeartySoup.blp'),
        ('j2b4', '+125 maximum hit points, +2 hit point regeneration, +1 Armor.', 'ReplaceableTextures\CommandButtons\BTNFood_115_CondorSoup.blp'),
        ('j2a4', '+3 Intelligence, +90 maximum mana, +1 Spell Power.', 'ReplaceableTextures\CommandButtons\BTNFood_117_HeartySoup.blp'),
        ('j2b5', '+2 Critical Chance, +2 Hit, +4 Damage.', 'ReplaceableTextures\CommandButtons\BTNFood_130_Fish.blp'),
        ('j2a5', '+3 Strength, +5 Damage, +1 Critical Chance.', 'ReplaceableTextures\CommandButtons\BTNFood_123_Roast.blp'),
        ('j2b6', '+5 Spell Power, +2 Critical Chance, -1 Armor.', 'ReplaceableTextures\CommandButtons\BTNFood_115_CondorSoup.blp'),
        ('j2a6', '+5 Agility, +2 Critical Chance, +7 Damage.', 'ReplaceableTextures\CommandButtons\BTNFood_122_Steak.blp'),
        ('j2b7', '+4 Intelligence, +2 mana regeneration, +5 Spell Power.', 'ReplaceableTextures\CommandButtons\BTNFood_117_HeartySoup.blp'),
        ('j2a7', '+5 Agility, +2 Dodge, +12 movement speed.', 'ReplaceableTextures\CommandButtons\BTNFood_121_ButterMeat.blp'),
        ('j2b9', '+3 Armor, +2 Block, +100 maximum hit points.', 'ReplaceableTextures\CommandButtons\BTNFood_131_Fish.blp'),
        ('j2a8', '+5 Strength, +8 Damage, +3 Critical Chance, -1 Hit.', 'ReplaceableTextures\CommandButtons\BTNFood_115_CondorSoup.blp'),
        ('j2c0', '+3 Block, +2 Armor, +3 Hit.', 'ReplaceableTextures\CommandButtons\BTNFood_136_Fish.blp'),
        ('j2a9', '+4 Strength, +250 maximum hit points, +2 hit point regeneration.', 'ReplaceableTextures\CommandButtons\BTNFood_123_Roast.blp'),
        ('j2c1', '+4 Agility, +3 Hit, +10 movement speed.', 'ReplaceableTextures\CommandButtons\BTNFood_138_Fish.blp'),
        ('j2d2', '+4 Agility, +3 Dodge, -2 Intelligence, +30 sight range.', 'ReplaceableTextures\CommandButtons\BTNFood_139_Fish.blp'),
        ('j2c2', '+7 Strength, +12 Damage, +4 Critical Chance.', 'ReplaceableTextures\CommandButtons\BTNFood_125_FishChunk.blp'),
        ('j2c3', '+4 Critical Chance, +5 Hit, +6 Damage.', 'ReplaceableTextures\CommandButtons\BTNFood_140_Fish.blp'),
        ('j2c4', '+3 mana regeneration, +10 Spell Power, +180 maximum mana.', 'ReplaceableTextures\CommandButtons\BTNFood_115_CondorSoup.blp'),
        ('j2c5', '+4 hit point regeneration, +300 maximum hit points, +2 Armor.', 'ReplaceableTextures\CommandButtons\BTNFood_111_IcefinFillet.blp'),
        ('j2c6', '+4 Armor, +5 Block, -8 movement speed.', 'ReplaceableTextures\CommandButtons\BTNFood_141_Fish.blp'),
        ('j2c7', '+5% Spell Power, +250 maximum mana, +4 Hit.', 'ReplaceableTextures\CommandButtons\BTNFood_142_Fish.blp'),
        ('j2c8', '+8 Strength, +300 maximum hit points, +4 Armor.', 'ReplaceableTextures\CommandButtons\BTNFood_117_HeartySoup.blp'),
        ('j2c9', '+8 Agility, +5 Critical Chance, +6 Dodge.', 'ReplaceableTextures\CommandButtons\BTNFood_143_Fish.blp'),
        ('j2d0', '+20 movement speed, +5 Hit, +5 Dodge.', 'ReplaceableTextures\CommandButtons\BTNFood_110_EmperorSalmon.blp'),
        ('j2d1', '+25 Spell Power, +5 Dodge, +5% Spell Power.', 'ReplaceableTextures\CommandButtons\BTNFood_141_Fish.blp'),
        ('j2d3', '+20 Damage, +5% Spell Power, +5 Critical Chance, -2 Armor.', 'ReplaceableTextures\CommandButtons\BTNFood_123_Roast.blp'),
        ('j2d4', '+8 Critical Chance, +8 Spell Power, +40 sight range, -2 hit point regeneration.', 'ReplaceableTextures\CommandButtons\BTNFood_149_CupCake.blp')
), food_updates AS (
    SELECT i.id, f.effect_text, f.icon_path,
           format('[|cFFD2B48CFood|r, %s%s|r]|n|n|cff00ff00Abilities:|r|n|cffffcc00Use:|r %s',
               CASE r.rarity_name WHEN 'Uncommon' THEN '|cFF90EE90' WHEN 'Rare' THEN '|cFF0080FF' ELSE '|cFFFFFFFF' END,
               r.rarity_name, f.effect_text) AS extended_text
    FROM items i
    JOIN food_data f ON f.item_code = i.item_code
    JOIN item_rarities r ON r.id = i.rarity_id
)
UPDATE items i
SET icon_path = u.icon_path,
    tooltip_extended = u.extended_text,
    description = u.extended_text,
    manual_abilities_data = jsonb_build_array(jsonb_build_object(
        'Code', 'A0F5', 'Type', 'Use', 'Description', u.effect_text,
        'TooltipNormal', 'Eat/Drink', 'TooltipSource', 'Custom',
        'TooltipExtended', 'Cooking applies the configured timed effect.')),
    updated_at = CURRENT_TIMESTAMP
FROM food_updates u
WHERE i.id = u.id;

WITH drink_data(item_code, icon_path) AS (
    VALUES
        ('j3a0', 'ReplaceableTextures\CommandButtons\BTN25_HoneyTea.blp'),
        ('j3a1', 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Milk_01.blp'),
        ('j3a2', 'ReplaceableTextures\CommandButtons\BTNBeer_01.blp'),
        ('j3a3', 'ReplaceableTextures\CommandButtons\BTNINV_Wine_04.blp'),
        ('j3a4', 'ReplaceableTextures\CommandButtons\BTN27_BlueSoup.blp'),
        ('j3a5', 'ReplaceableTextures\CommandButtons\BTNBeer_04.blp'),
        ('j3a6', 'ReplaceableTextures\CommandButtons\BTNINV_Wine_02.blp'),
        ('j3a7', 'ReplaceableTextures\CommandButtons\BTNElixir_01.blp'),
        ('j3a8', 'ReplaceableTextures\CommandButtons\BTNINV_Wine_03.blp'),
        ('j3a9', 'ReplaceableTextures\CommandButtons\BTNINV_Wine_01.blp'),
        ('j3b0', 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Mug.blp'),
        ('j3b1', 'ReplaceableTextures\CommandButtons\BTNINV_Misc_Mug.blp'),
        ('j3b2', 'ReplaceableTextures\CommandButtons\BTNElixir_04.blp'),
        ('j3b3', 'ReplaceableTextures\CommandButtons\BTNINV_Wine_01.blp'),
        ('j3b4', 'ReplaceableTextures\CommandButtons\BTNBeer_09.blp')
), drink_updates AS (
    SELECT i.id, d.icon_path,
           format('[|cFF87CEEBDrink|r, %s%s|r]|n|n|cff00ff00Abilities:|r|n|cffffcc00Use:|r Consumes one food or beverage charge.',
               CASE r.rarity_name WHEN 'Uncommon' THEN '|cFF90EE90' WHEN 'Rare' THEN '|cFF0080FF' ELSE '|cFFFFFFFF' END,
               r.rarity_name) AS extended_text
    FROM items i
    JOIN drink_data d ON d.item_code = i.item_code
    JOIN item_rarities r ON r.id = i.rarity_id
)
UPDATE items i
SET icon_path = u.icon_path,
    tooltip_extended = u.extended_text,
    description = u.extended_text,
    manual_abilities_data = jsonb_build_array(jsonb_build_object(
        'Code', 'A0F5', 'Type', 'Use', 'Description', 'Consumes one food or beverage charge.',
        'TooltipNormal', 'Eat/Drink', 'TooltipSource', 'Custom',
        'TooltipExtended', 'Cooking applies the configured timed effect.')),
    updated_at = CURRENT_TIMESTAMP
FROM drink_updates u
WHERE i.id = u.id;

DO $$
DECLARE
    normalized_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO normalized_count
    FROM items i
    JOIN item_classes c ON c.id = i.class_id
    WHERE c.class_name IN ('Food', 'Drink')
      AND i.tooltip_extended LIKE '[%Abilities:%Use:%';

    IF normalized_count <> 55 THEN
        RAISE EXCEPTION 'Expected 55 normalized Food/Drink items, found %', normalized_count;
    END IF;
END $$;
