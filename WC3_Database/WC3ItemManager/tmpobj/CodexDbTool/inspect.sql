SELECT current_database() AS database_name, current_user AS user_name;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'items', 'item_classes', 'item_rarities', 'item_types', 'item_stats',
      'item_stat_values', 'loot_tables', 'loot_table_items',
      'unit_types', 'unit_specific_drops'
  )
ORDER BY table_name;

SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('item_types', 'loot_tables', 'loot_table_items', 'unit_types', 'unit_specific_drops')
ORDER BY table_name, ordinal_position;

SELECT id, class_name, slot_type, description
FROM item_classes
ORDER BY id;

SELECT id, rarity_name, rarity_level, color_code
FROM item_rarities
ORDER BY id;

SELECT id, type_name, description
FROM item_types
ORDER BY id;

SELECT id, stat_code, stat_name, display_format, color_hex, display_order
FROM item_stats
WHERE is_active = true
ORDER BY display_order, id;

SELECT item_code, item_name, item_level, item_level_unclassified, rarity_id, class_id,
       base_id, icon_path, model_path, wc3_abilities, armor_type, equipment_slot,
       specific_drop_only
FROM items
WHERE item_name ILIKE ANY (ARRAY[
    '%Copper%', '%Cloth%', '%Leather%', '%Mail%', '%Plate%',
    '%Wolf%', '%Stag%', '%Gnoll%', '%Whelp%', '%Murloc%', '%Makrura%',
    '%Bear%', '%Crawler%', '%Crab%', '%Boar%', '%Snake%', '%Frog%',
    '%Lizard%', '%Zombie%'
])
ORDER BY item_code
LIMIT 250;

SELECT item_code
FROM items
WHERE item_code ~ '^[a-z][0-9][a-z][0-9]$'
ORDER BY item_code DESC
LIMIT 80;

SELECT id, name, description, drop_chance, drop_count_min, drop_count_max,
       min_level, max_level, category, enabled
FROM loot_tables
ORDER BY category, min_level, name;

SELECT lt.name, COUNT(lti.id) AS item_count
FROM loot_tables lt
LEFT JOIN loot_table_items lti ON lti.loot_table_id = lt.id
GROUP BY lt.id, lt.name, lt.category, lt.min_level
ORDER BY lt.category, lt.min_level, lt.name;

SELECT unit_code, unit_name, editor_suffix, unit_level, is_boss, loot_mode, loot_table_id,
       drop_count_min, drop_count_max
FROM unit_types
WHERE unit_name ILIKE ANY (ARRAY[
    '%Wolf%', '%Stag%', '%Gnoll%', '%Whelp%', '%Murloc%', '%Mur''gal%', '%Margul%',
    '%Makrura%', '%Bear%', '%Crab%', '%Boar%', '%Pig%', '%Snake%', '%Frog%',
    '%Lizard%', '%Zombie%', '%Dragon%', '%Colossus%', '%Gollum%', '%Sargoth%',
    '%Rol%', '%Velaria%', '%Unknown Entity%', '%Mordrax%'
])
ORDER BY unit_level, unit_name, editor_suffix
LIMIT 300;

SELECT ut.unit_name, ut.editor_suffix, usd.unit_code, i.item_name, usd.item_code,
       usd.drop_chance, usd.is_guaranteed, usd.weight, usd.notes
FROM unit_specific_drops usd
JOIN unit_types ut ON ut.unit_code = usd.unit_code
JOIN items i ON i.item_code = usd.item_code
ORDER BY ut.unit_name, i.item_name
LIMIT 300;
