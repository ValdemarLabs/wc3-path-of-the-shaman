-- Fix item_stats table to match JASS stat IDs
-- Based on SharedDInvLib.j stat ID mappings

-- First, clear existing data to avoid conflicts
TRUNCATE TABLE item_stat_values CASCADE;
DELETE FROM item_stats;

-- Reset the sequence to start from 1
ALTER SEQUENCE item_stats_id_seq RESTART WITH 1;

-- Insert stats with correct IDs matching JASS code
-- ID 1: STR
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (1, 'str', 'Strength', 'Increases damage and HP', '+{value}', '#FF0000', 1);

-- ID 2: AGI
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (2, 'agi', 'Agility', 'Increases attack speed and armor', '+{value}', '#00FF00', 2);

-- ID 3: INT
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (3, 'int', 'Intelligence', 'Increases mana and spell damage', '+{value}', '#0080FF', 3);

-- ID 4: HP
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (4, 'hp', 'Health', 'Maximum health points', '+{value}', '#C41E3A', 4);

-- ID 5: HPS (HP Regeneration)
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (5, 'hp_regen', 'HP Regen', 'Health regeneration per second', '+{value}', '#FF69B4', 5);

-- ID 6: HP Percent Per Sec
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (6, 'hp_regen_pct', 'HP Regen %', 'Health regeneration percent per second', '+{value}%', '#FF99CC', 6);

-- ID 7: Mana
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (7, 'mp', 'Mana', 'Maximum mana points', '+{value}', '#0070DD', 7);

-- ID 8: MPS (Mana Regeneration)
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (8, 'mp_regen', 'Mana Regen', 'Mana regeneration per second', '+{value}', '#9482C9', 8);

-- ID 9: Mana Percent Per Sec
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (9, 'mp_regen_pct', 'Mana Regen %', 'Mana regeneration percent per second', '+{value}%', '#B099DD', 9);

-- ID 10: Crit Chance
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (10, 'crit', 'Critical Chance', 'Chance to deal critical damage', '+{value}%', '#FF8C00', 10);

-- ID 11: Crit DMG
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (11, 'crit_dmg', 'Critical Damage', 'Critical hit damage multiplier', '+{value}%', '#FF4500', 11);

-- ID 12: Damage
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (12, 'dmg', 'Damage', 'Attack damage bonus', '+{value}', '#FFD700', 12);

-- ID 13: DMG Pct (General Damage Percent)
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (13, 'dmg_pct', 'Damage %', 'General damage percent bonus', '+{value}%', '#FFDD00', 13);

-- ID 14: Melee DMG Flat
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (14, 'melee_dmg', 'Melee Damage', 'Melee damage flat bonus', '+{value}', '#CC0000', 14);

-- ID 15: Melee DMG Percent
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (15, 'melee_dmg_pct', 'Melee Damage %', 'Melee damage percent bonus', '+{value}%', '#DD0000', 15);

-- ID 16: Ranged DMG Flat
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (16, 'ranged_dmg', 'Ranged Damage', 'Ranged damage flat bonus', '+{value}', '#00CC00', 16);

-- ID 17: Ranged DMG Percent
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (17, 'ranged_dmg_pct', 'Ranged Damage %', 'Ranged damage percent bonus', '+{value}%', '#00DD00', 17);

-- ID 18: Cleave Pct
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (18, 'cleave_pct', 'Cleave %', 'Cleave damage percent', '+{value}%', '#FFA500', 18);

-- ID 19: Cleave Area
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (19, 'cleave_area', 'Cleave Area', 'Cleave area of effect', '+{value}', '#FFB700', 19);

-- ID 20: IAS (Attack Speed)
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (20, 'aspd', 'Attack Speed', 'Attack speed bonus', '+{value}%', '#FFFF00', 20);

-- ID 21: Attack Range
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (21, 'attack_range', 'Attack Range', 'Attack range bonus', '+{value}', '#FFEE00', 21);

-- ID 22: Lifesteal Percent
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (22, 'lifesteal', 'Lifesteal', 'Heal from damage dealt', '+{value}%', '#8B0000', 22);

-- ID 23: Thorns Flat
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (23, 'thorns_flat', 'Thorns', 'Reflects flat damage when hit', '+{value}', '#CD853F', 23);

-- ID 24: Thorns Pct
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (24, 'thorns_pct', 'Thorns %', 'Reflects damage percent when hit', '+{value}%', '#D2691E', 24);

-- ID 25: Armor
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (25, 'armor', 'Armor', 'Physical damage reduction', '+{value}', '#C0C0C0', 25);

-- ID 26: Armor Percent
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (26, 'armor_pct', 'Armor %', 'Armor percent bonus', '+{value}%', '#D0D0D0', 26);

-- ID 27: Evasion
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (27, 'evasion', 'Evasion', 'Chance to evade attacks', '+{value}%', '#32CD32', 27);

-- ID 28: SpellDMG Taken Pct (Magic Damage Taken)
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (28, 'magic_dmg_taken', 'Magic Damage Taken', 'Magic damage taken modifier', '{value}%', '#9370DB', 28);

-- ID 29: Melee DMG Taken Pct
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (29, 'melee_dmg_taken', 'Melee Damage Taken', 'Melee damage taken modifier', '{value}%', '#DC143C', 29);

-- ID 30: Pierce DMG Taken Pct
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (30, 'pierce_dmg_taken', 'Pierce Damage Taken', 'Pierce damage taken modifier', '{value}%', '#228B22', 30);

-- ID 31: Movement Speed
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (31, 'ms', 'Movement Speed', 'Movement speed bonus', '+{value}', '#00FFFF', 31);

-- ID 32: Movement Speed Percent
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (32, 'ms_pct', 'Movement Speed %', 'Movement speed percent bonus', '+{value}%', '#00EEEE', 32);

-- ID 33: Sight Range
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
VALUES (33, 'sight_range', 'Sight Range', 'Vision range bonus', '+{value}', '#87CEEB', 33);

-- ID 34: Inventory Space
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order)
VALUES (34, 'inv_space', 'Inventory Space', 'Additional inventory slots', '+{value}', '#DAA520', 34);

-- ID 35: Block chance
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order)
VALUES (35, 'block', 'Block Chance', 'Chance to block incoming attacks', '+{value}%', '#4169E1', 35);

-- ID 36: Hit chance
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order)
VALUES (36, 'hit', 'Hit Chance', 'Increases accuracy and hit chance', '+{value}%', '#F0E68C', 36);

-- ID 37: Spell power Pct
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order)
VALUES (37, 'spell_power_pct', 'Spell Power %', 'Increases spell damage percent', '+{value}%', '#8A2BE2', 37);

-- ID 38: Spell power Flat
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order)
VALUES (38, 'spell_power', 'Spell Power', 'Flat spell damage bonus', '+{value}', '#9370DB', 38);

-- ID 39: Healing Power
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order)
VALUES (39, 'healing_power', 'Healing Power', 'Healing effectiveness percentage', '+{value}%', '#7CFC00', 39);

-- ID 40-48: Profession skills
INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order)
VALUES
(40, 'profession_mining', 'Mining', 'Mining profession skill bonus', '+{value}', '#B8860B', 40),
(41, 'profession_herbalism', 'Herbalism', 'Herbalism profession skill bonus', '+{value}', '#32CD32', 41),
(42, 'profession_skinning', 'Skinning', 'Skinning profession skill bonus', '+{value}', '#CD853F', 42),
(43, 'profession_fishing', 'Fishing', 'Fishing profession skill bonus', '+{value}', '#40C7EB', 43),
(44, 'profession_alchemy', 'Alchemy', 'Alchemy profession skill bonus', '+{value}', '#9370DB', 44),
(45, 'profession_blacksmithing', 'Blacksmithing', 'Blacksmithing profession skill bonus', '+{value}', '#708090', 45),
(46, 'profession_leatherworking', 'Leatherworking', 'Leatherworking profession skill bonus', '+{value}', '#8B4513', 46),
(47, 'profession_enchanting', 'Enchanting', 'Enchanting profession skill bonus', '+{value}', '#DA70D6', 47),
(48, 'profession_cooking', 'Cooking', 'Cooking profession skill bonus', '+{value}', '#FF8C00', 48);

-- Update the sequence to continue from 49
SELECT setval('item_stats_id_seq', 48, true);

-- Verification query
SELECT id, stat_code, stat_name FROM item_stats ORDER BY id;

PRINT 'Item stats IDs fixed to match JASS code!';
