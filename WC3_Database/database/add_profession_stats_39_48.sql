-- Add Healing Power and profession stats to match DEquipment stat IDs 39-48.

INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order)
VALUES
    (39, 'healing_power', 'Healing Power', 'Healing effectiveness percentage', '+{value}%', '#7CFC00', 39),
    (40, 'profession_mining', 'Mining', 'Mining profession skill bonus', '+{value}', '#B8860B', 40),
    (41, 'profession_herbalism', 'Herbalism', 'Herbalism profession skill bonus', '+{value}', '#32CD32', 41),
    (42, 'profession_skinning', 'Skinning', 'Skinning profession skill bonus', '+{value}', '#CD853F', 42),
    (43, 'profession_fishing', 'Fishing', 'Fishing profession skill bonus', '+{value}', '#40C7EB', 43),
    (44, 'profession_alchemy', 'Alchemy', 'Alchemy profession skill bonus', '+{value}', '#9370DB', 44),
    (45, 'profession_blacksmithing', 'Blacksmithing', 'Blacksmithing profession skill bonus', '+{value}', '#708090', 45),
    (46, 'profession_leatherworking', 'Leatherworking', 'Leatherworking profession skill bonus', '+{value}', '#8B4513', 46),
    (47, 'profession_enchanting', 'Enchanting', 'Enchanting profession skill bonus', '+{value}', '#DA70D6', 47),
    (48, 'profession_cooking', 'Cooking', 'Cooking profession skill bonus', '+{value}', '#FF8C00', 48)
ON CONFLICT (id) DO UPDATE SET
    stat_code = EXCLUDED.stat_code,
    stat_name = EXCLUDED.stat_name,
    stat_description = EXCLUDED.stat_description,
    display_format = EXCLUDED.display_format,
    color_hex = EXCLUDED.color_hex,
    display_order = EXCLUDED.display_order;

SELECT setval('item_stats_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM item_stats), 48), true);

SELECT id, stat_code, stat_name, display_format, color_hex
FROM item_stats
WHERE id BETWEEN 39 AND 48
ORDER BY id;
