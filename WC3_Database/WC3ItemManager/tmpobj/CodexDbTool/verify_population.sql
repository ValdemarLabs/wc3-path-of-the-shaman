SELECT r.rarity_name, c.class_name, COUNT(*) AS item_count
FROM items i
JOIN item_rarities r ON r.id = i.rarity_id
JOIN item_classes c ON c.id = i.class_id
WHERE i.item_code >= 'j0a0' AND i.item_code <= 'j1d1'
GROUP BY r.rarity_name, c.class_name
ORDER BY r.rarity_name, c.class_name;

SELECT armor_type, c.class_name, COUNT(*) AS item_count,
       MIN(item_level_unclassified) AS min_drop_level,
       MAX(item_level_unclassified) AS max_drop_level
FROM items i
JOIN item_classes c ON c.id = i.class_id
WHERE i.item_code BETWEEN 'j1a0' AND 'j1d1'
GROUP BY armor_type, c.class_name
ORDER BY armor_type, c.class_name;

SELECT i.item_code, i.item_name, COUNT(isv.id) AS stat_rows,
       i.item_level, i.item_level_unclassified, i.wc3_abilities,
       left(i.tooltip_extended, 160) AS tooltip_preview
FROM items i
LEFT JOIN item_stat_values isv ON isv.item_id = i.id
WHERE i.item_code BETWEEN 'j1a0' AND 'j1d1'
GROUP BY i.item_code, i.item_name, i.item_level, i.item_level_unclassified,
         i.wc3_abilities, i.tooltip_extended
ORDER BY i.item_code
LIMIT 40;

SELECT lt.name, COUNT(lti.id) AS item_count
FROM loot_tables lt
JOIN loot_table_items lti ON lti.loot_table_id = lt.id
WHERE lti.item_code IN (
    SELECT item_code FROM items WHERE item_code BETWEEN 'j0a0' AND 'j1d1'
    UNION
    SELECT item_code FROM items WHERE item_code IN (
        'I61O','I61P','I61Q','I61R','I61T','I61Y','I61Z','I620','I621',
        'I6AR','I614','I6AS','I6AB','I622','I6AE','I00S','I00X','I00V',
        'I00W','I66P','I6A4'
    )
)
GROUP BY lt.name, lt.category, lt.min_level
ORDER BY lt.category, lt.min_level, lt.name;

SELECT category, COUNT(DISTINCT unit_code) AS units
FROM (
    SELECT usd.unit_code,
           CASE
               WHEN usd.notes ILIKE '%wolf%' THEN 'wolf'
               WHEN usd.notes ILIKE '%bear%' THEN 'bear'
               WHEN usd.notes ILIKE '%stag%' THEN 'stag'
               WHEN usd.notes ILIKE '%boar%' THEN 'boar'
               WHEN usd.notes ILIKE '%crawler%' THEN 'crawler'
               WHEN usd.notes ILIKE '%frog%' THEN 'frog'
               WHEN usd.notes ILIKE '%snake%' THEN 'snake'
               WHEN usd.notes ILIKE '%murloc%' THEN 'murloc'
               WHEN usd.notes ILIKE '%makrura%' THEN 'makrura'
               WHEN usd.notes ILIKE '%lizard%' THEN 'lizard'
               WHEN usd.notes ILIKE '%dragon%' OR usd.notes ILIKE '%whelp%' THEN 'dragon'
               WHEN usd.notes ILIKE '%gnoll%' THEN 'gnoll'
               WHEN usd.notes ILIKE '%undead%' OR usd.notes ILIKE '%rotten%' THEN 'undead'
               WHEN usd.notes ILIKE '%boss%' THEN 'boss'
               ELSE 'other'
           END AS category
    FROM unit_specific_drops usd
    WHERE usd.notes ILIKE '%OldGUI%'
       OR usd.notes ILIKE '%New %'
       OR usd.notes ILIKE '%Boss %'
       OR usd.item_code BETWEEN 'j0a0' AND 'j1d1'
) s
GROUP BY category
ORDER BY category;

SELECT ut.unit_name, ut.editor_suffix, ut.unit_code, i.item_name, usd.item_code,
       usd.drop_chance, usd.is_guaranteed, usd.weight, usd.notes
FROM unit_specific_drops usd
JOIN unit_types ut ON ut.unit_code = usd.unit_code
JOIN items i ON i.item_code = usd.item_code
WHERE usd.notes ILIKE '%OldGUI%'
   OR usd.notes ILIKE '%New %'
   OR usd.notes ILIKE '%Boss %'
   OR usd.item_code BETWEEN 'j0a0' AND 'j1d1'
ORDER BY ut.unit_name, ut.editor_suffix, i.item_name
LIMIT 80;

SELECT unit_code, item_code, COUNT(*) AS duplicate_rows
FROM unit_specific_drops
GROUP BY unit_code, item_code
HAVING COUNT(*) > 1
ORDER BY duplicate_rows DESC, unit_code, item_code
LIMIT 20;

SELECT lti.loot_table_id, lt.name, lti.item_code, COUNT(*) AS duplicate_rows
FROM loot_table_items lti
JOIN loot_tables lt ON lt.id = lti.loot_table_id
GROUP BY lti.loot_table_id, lt.name, lti.item_code
HAVING COUNT(*) > 1
ORDER BY duplicate_rows DESC, lt.name, lti.item_code
LIMIT 20;
