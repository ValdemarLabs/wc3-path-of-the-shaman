-- Add missing stats 35-38 to match SharedDInvLib.j
-- These stats are referenced in the JASS code but missing from the database

-- ID 35: Block chance
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (35, 'block', 'Block Chance', 'Chance to block incoming attacks', '+{value}%', '#4169E1', 35)
ON CONFLICT (id) DO UPDATE SET
    stat_code = EXCLUDED.stat_code,
    stat_name = EXCLUDED.stat_name,
    stat_description = EXCLUDED.stat_description,
    display_format = EXCLUDED.display_format,
    color_hex = EXCLUDED.color_hex,
    display_order = EXCLUDED.display_order;

-- ID 36: Hit chance
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (36, 'hit', 'Hit Chance', 'Increases accuracy and hit chance', '+{value}%', '#F0E68C', 36)
ON CONFLICT (id) DO UPDATE SET
    stat_code = EXCLUDED.stat_code,
    stat_name = EXCLUDED.stat_name,
    stat_description = EXCLUDED.stat_description,
    display_format = EXCLUDED.display_format,
    color_hex = EXCLUDED.color_hex,
    display_order = EXCLUDED.display_order;

-- ID 37: Spell power Pct
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (37, 'spell_power_pct', 'Spell Power %', 'Increases spell damage percent', '+{value}%', '#8A2BE2', 37)
ON CONFLICT (id) DO UPDATE SET
    stat_code = EXCLUDED.stat_code,
    stat_name = EXCLUDED.stat_name,
    stat_description = EXCLUDED.stat_description,
    display_format = EXCLUDED.display_format,
    color_hex = EXCLUDED.color_hex,
    display_order = EXCLUDED.display_order;

-- ID 38: Spell power Flat
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (38, 'spell_power', 'Spell Power', 'Flat spell damage bonus', '+{value}', '#9370DB', 38)
ON CONFLICT (id) DO UPDATE SET
    stat_code = EXCLUDED.stat_code,
    stat_name = EXCLUDED.stat_name,
    stat_description = EXCLUDED.stat_description,
    display_format = EXCLUDED.display_format,
    color_hex = EXCLUDED.color_hex,
    display_order = EXCLUDED.display_order;

-- Update the sequence to continue from 38
SELECT setval('item_stats_id_seq', 38, true);

-- Verification query
SELECT id, stat_code, stat_name, display_format, color_hex FROM item_stats WHERE id >= 35 ORDER BY id;
