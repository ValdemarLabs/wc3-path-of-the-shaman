-- ====================================================================================================
-- WC3 POTS DATABASE - STAT SYSTEM ENHANCEMENT
-- ====================================================================================================
-- This schema adds comprehensive support for the DEquipment stat system
-- Includes all 39 statids and ability codes from SharedDInvLib.j
--
-- Author: Enhanced for PotS Project
-- Date: 2026-03-10
-- Version: 2.0.0
-- ====================================================================================================

-- Drop existing enhanced tables if they exist
DROP TABLE IF EXISTS item_stat_bonuses CASCADE;
DROP TABLE IF EXISTS ability_codes CASCADE;
DROP TABLE IF EXISTS stat_definitions CASCADE;

-- ====================================================================================================
-- STAT DEFINITIONS TABLE (39 Stats from DEquipment)
-- ====================================================================================================

CREATE TABLE stat_definitions (
    statid INTEGER PRIMARY KEY,
    stat_name VARCHAR(100) NOT NULL UNIQUE,
    stat_display_name VARCHAR(100) NOT NULL, -- Display name in UI
    stat_short_name VARCHAR(50), -- Short name for UI (e.g., "STR", "AGI", "INT")
    display_as_percent BOOLEAN DEFAULT FALSE,
    application_method VARCHAR(50) NOT NULL, -- 'NATIVE', 'ABILITY', 'GLOBAL_VAR'
    ability_code CHAR(4), -- If application_method='ABILITY', this is the WC3 ability code
    ability_field VARCHAR(100), -- The ability field that stores the value (e.g., 'Oar1', 'Arm1')
    native_function VARCHAR(100), -- If application_method='NATIVE', this is the function name
    global_variable VARCHAR(100), -- If application_method='GLOBAL_VAR', this is the variable name
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert all 39 stats from DEquipment system
INSERT INTO stat_definitions (statid, stat_name, stat_display_name, stat_short_name, display_as_percent, application_method, ability_code, ability_field, native_function, global_variable, description) VALUES
-- Attributes & HP (1-5)
(1, 'Strength', 'Strength', 'STR', FALSE, 'NATIVE', NULL, NULL, 'SetHeroStr', NULL, 'Hero strength attribute'),
(2, 'Agility', 'Agility', 'AGI', FALSE, 'NATIVE', NULL, NULL, 'SetHeroAgi', NULL, 'Hero agility attribute'),
(3, 'Intelligence', 'Intelligence', 'INT', FALSE, 'NATIVE', NULL, NULL, 'SetHeroInt', NULL, 'Hero intelligence attribute'),
(4, 'Hitpoints', 'Hitpoints', 'HP', FALSE, 'NATIVE', NULL, NULL, 'BlzSetUnitMaxHP', NULL, 'Maximum hit points'),
(5, 'Hitpoint regeneration', 'Hitpoint Regeneration', 'HPS', FALSE, 'NATIVE', NULL, 'UNIT_RF_HIT_POINTS_REGENERATION_RATE', 'BlzSetUnitRealField', NULL, 'Hit points regenerated per second'),

-- Regen Percentages (6, 9)
(6, 'HP Pct Per Sec', 'HP% Per Second', 'HP%/sec', TRUE, 'ABILITY', 'DQLR', 'Oar1', NULL, NULL, 'HP regeneration as percentage of max HP per second'),
(7, 'Mana', 'Mana', 'Mana', FALSE, 'NATIVE', NULL, NULL, 'BlzSetUnitMaxMana', NULL, 'Maximum mana'),
(8, 'Mana regeneration', 'Mana Regeneration', 'MPS', FALSE, 'NATIVE', NULL, 'UNIT_RF_MANA_REGENERATION', 'BlzSetUnitRealField', NULL, 'Mana regenerated per second'),
(9, 'Mana Pct Per Sec', 'Mana% Per Second', 'Mana%/sec', TRUE, 'ABILITY', 'DQMR', 'Arm1', NULL, NULL, 'Mana regeneration as percentage of max mana per second'),

-- Critical Stats (10-11)
(10, 'Critical Chance', 'Critical Chance', 'Crit', TRUE, 'GLOBAL_VAR', NULL, NULL, NULL, 'udg_Stats_Crit', 'Chance to deal critical strike damage'),
(11, 'Critical Damage', 'Critical Damage', 'CritDMG', TRUE, 'ABILITY', 'DQCS', 'ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2', NULL, NULL, 'Critical strike damage multiplier (currently disabled in code)'),

-- Damage Stats (12-17)
(12, 'Damage', 'Damage', 'DMG', FALSE, 'NATIVE', NULL, NULL, 'BlzSetUnitBaseDamage', NULL, 'Base damage bonus for both weapon slots'),
(13, 'Damage Pct', 'Damage%', 'DMG%', TRUE, 'ABILITY', 'DQTM', 'Ear1', NULL, NULL, 'Percentage damage bonus for both melee and ranged (uses DQTM+DQTS abilities)'),
(14, 'Melee Damage', 'Melee Damage', 'MeleeDMG', FALSE, 'ABILITY', 'DQMF', 'Ear1', NULL, NULL, 'Flat damage bonus for melee attacks only'),
(15, 'Melee DMG Pct', 'Melee Damage%', 'MeleeDMG%', TRUE, 'ABILITY', 'DQTM', 'Ear1', NULL, NULL, 'Percentage damage bonus for melee attacks (stacks with statid 13)'),
(16, 'Ranged Damage', 'Ranged Damage', 'RangedDMG', FALSE, 'ABILITY', 'DQRF', 'Ear1', NULL, NULL, 'Flat damage bonus for ranged attacks only'),
(17, 'Ranged DMG Pct', 'Ranged Damage%', 'RangedDMG%', TRUE, 'ABILITY', 'DQTS', 'Ear1', NULL, NULL, 'Percentage damage bonus for ranged attacks (stacks with statid 13)'),

-- Cleave Stats (18-19)
(18, 'Cleave Pct', 'Cleave%', 'Cleave%', TRUE, 'ABILITY', 'DQCL', 'ABILITY_RLF_DISTRIBUTED_DAMAGE_FACTOR_NCA1', NULL, NULL, 'Percentage of damage dealt to nearby enemies'),
(19, 'Cleave Damage', 'Cleave Area', 'CleaveAOE', FALSE, 'ABILITY', 'DQCL', 'aare', NULL, NULL, 'Additional cleave area radius'),

-- Attack Stats (20-21)
(20, 'Attack Speed', 'Attack Speed', 'IAS', TRUE, 'ABILITY', 'DQAS', 'ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1', NULL, NULL, 'Attack speed percentage increase'),
(21, 'Attack Range', 'Attack Range', 'Range', FALSE, 'NATIVE', NULL, 'ua1r', 'BlzSetUnitWeaponRealField', NULL, 'Attack range bonus'),

-- Lifesteal & Thorns (22-24)
(22, 'Lifesteal Pct', 'Lifesteal%', 'Lifesteal', TRUE, 'ABILITY', 'DQLS', 'ABILITY_RLF_LIFE_STOLEN_PER_ATTACK', NULL, NULL, 'Percentage of damage returned as health'),
(23, 'Thorns', 'Thorns', 'Thorns', FALSE, 'ABILITY', 'DQTF', 'Eah1', NULL, NULL, 'Flat damage returned to attackers'),
(24, 'Thorns Pct', 'Thorns%', 'Thorns%', TRUE, 'ABILITY', 'DQSC', 'Uts1', NULL, NULL, 'Percentage of damage returned to attackers'),

-- Armor & Evasion (25-27)
(25, 'Armor', 'Armor', 'Armor', FALSE, 'NATIVE', NULL, NULL, 'BlzSetUnitArmor', NULL, 'Flat armor bonus'),
(26, 'Armor Pct', 'Armor%', 'Armor%', TRUE, 'NATIVE', NULL, NULL, 'BlzSetUnitArmor', NULL, 'Percentage armor bonus (calculated with flat armor)'),
(27, 'Dodge', 'Dodge', 'Evasion', TRUE, 'GLOBAL_VAR', NULL, NULL, NULL, 'udg_Stats_Dodge', 'Chance to dodge incoming attacks (ability DQEV disabled)'),

-- Damage Taken (28-30)
(28, 'Spell Damage Taken Pct', 'Spell DMG Taken%', 'SpellTaken%', TRUE, 'ABILITY', 'DQEG', 'ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5', NULL, NULL, 'Percentage modifier for spell damage taken'),
(29, 'Melee Damage Taken Pct', 'Melee DMG Taken%', 'MeleeTaken%', TRUE, 'ABILITY', 'DQSC', 'Uts2', NULL, NULL, 'Percentage modifier for melee damage taken'),
(30, 'Pierce Damage Taken Pct', 'Pierce DMG Taken%', 'PierceTaken%', TRUE, 'ABILITY', 'DQEG', 'ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1', NULL, NULL, 'Percentage modifier for pierce damage taken'),

-- Movement & Sight (31-33)
(31, 'Movement Speed', 'Movement Speed', 'MS', FALSE, 'ABILITY', 'DQMS', 'ABILITY_ILF_MOVEMENT_SPEED_BONUS', NULL, NULL, 'Flat movement speed bonus'),
(32, 'MoveSPD Pct', 'Movement Speed%', 'MS%', TRUE, 'ABILITY', 'DQHM', 'ABILITY_RLF_MOVEMENT_SPEED_INCREASE_PERCENT_UAU1', NULL, NULL, 'Percentage movement speed bonus'),
(33, 'Sight Range', 'Sight Range', 'Sight', FALSE, 'NATIVE', NULL, 'usir', 'BlzSetUnitRealField', NULL, 'Vision range bonus'),

-- Miscellaneous (34-36)
(34, 'Inventory Space', 'Inventory Space', 'InvSpace', FALSE, 'NATIVE', NULL, NULL, 'DInvDeltaAdditionalSlotsForUnit', NULL, 'Additional inventory slots'),
(35, 'Block Chance', 'Block Chance', 'Block', TRUE, 'GLOBAL_VAR', NULL, NULL, NULL, 'udg_Stats_Block', 'Chance to block incoming attacks'),
(36, 'Hit Chance', 'Hit Chance', 'Hit', TRUE, 'GLOBAL_VAR', NULL, NULL, NULL, 'udg_Stats_Hit', 'Chance for attacks to hit target'),

-- Spell Power (37-39)
(37, 'Spell Power Pct', 'Spell Power%', 'SpellPower%', TRUE, 'GLOBAL_VAR', NULL, NULL, NULL, 'udg_Stats_SpellPowerPct', 'Percentage spell power bonus'),
(38, 'Spell Power', 'Spell Power', 'SpellPower', TRUE, 'GLOBAL_VAR', NULL, NULL, NULL, 'udg_Stats_SpellPowerFlat', 'Flat spell power bonus'),
(39, 'Healing Power', 'Healing Power', 'HealPower', TRUE, 'GLOBAL_VAR', NULL, NULL, NULL, 'TBD', 'Healing effectiveness percentage');

COMMENT ON TABLE stat_definitions IS 'Comprehensive stat system definitions for DEquipment (39 stats total)';
COMMENT ON COLUMN stat_definitions.statid IS 'Stat ID from DEquipment system (1-39)';
COMMENT ON COLUMN stat_definitions.application_method IS 'How stat is applied: NATIVE (native function), ABILITY (WC3 ability), GLOBAL_VAR (global variable)';


-- ====================================================================================================
-- ABILITY CODES TABLE
-- ====================================================================================================

CREATE TABLE ability_codes (
    ability_code CHAR(4) PRIMARY KEY,
    ability_name VARCHAR(100) NOT NULL,
    ability_base VARCHAR(100), -- Base WC3 ability (e.g., 'Life Regeneration Aura', 'Mana Regeneration Aura')
    description TEXT,
    used_by_stats TEXT, -- Comma-separated list of statids that use this ability
    field_1_name VARCHAR(100), -- Primary ability field (e.g., 'Oar1', 'Arm1', 'Ear1')
    field_2_name VARCHAR(100), -- Secondary ability field if used
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert all ability codes used by the stat system
INSERT INTO ability_codes (ability_code, ability_name, ability_base, description, used_by_stats, field_1_name, field_2_name, notes) VALUES
('DQLR', 'HP Regeneration Percentage', 'Life Regeneration Aura', 'Regenerates percentage of max HP per second', '6', 'Oar1', NULL, 'Field Oar1 stores the HP% regen rate'),
('DQMR', 'Mana Regeneration Percentage', 'Mana Regeneration Aura', 'Regenerates percentage of max mana per second', '9', 'Arm1', NULL, 'Field Arm1 stores the Mana% regen rate'),
('DQTM', 'Melee Damage Percentage', 'Trueshot Aura (Melee)', 'Increases melee attack damage by percentage', '13,15', 'Ear1', NULL, 'Used for both general DMG% (13) and Melee DMG% (15)'),
('DQTS', 'Ranged Damage Percentage', 'Trueshot Aura (Ranged)', 'Increases ranged attack damage by percentage', '13,17', 'Ear1', NULL, 'Used for both general DMG% (13) and Ranged DMG% (17)'),
('DQMS', 'Movement Speed Flat', 'Movement Speed Bonus', 'Flat movement speed increase', '31', 'ABILITY_ILF_MOVEMENT_SPEED_BONUS', NULL, 'Integer level field for movement speed'),
('DQHM', 'Movement Speed Percentage', 'Slow Aura (Modified)', 'Percentage movement speed increase', '32', 'ABILITY_RLF_MOVEMENT_SPEED_INCREASE_PERCENT_UAU1', NULL, 'Field stores MS% increase. Buff BDQ0 is disabled.'),
('DQAS', 'Attack Speed', 'Attack Speed Increase', 'Attack speed percentage increase', '20', 'ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1', NULL, 'Field stores IAS increase'),
('DQEV', 'Evasion', 'Evasion', 'Chance to evade attacks', '27', 'ABILITY_RLF_CHANCE_TO_EVADE_EEV1', NULL, 'DISABLED IN CODE - Uses udg_Stats_Dodge instead'),
('DQLS', 'Lifesteal', 'Life Steal', 'Percentage of damage returned as HP', '22', 'ABILITY_RLF_LIFE_STOLEN_PER_ATTACK', NULL, 'Lifesteal percentage'),
('DQTF', 'Thorns Flat', 'Thorns Aura (Flat)', 'Returns flat damage to attacker', '23', 'Eah1', NULL, 'Returns fixed damage to attackers'),
('DQSC', 'Spiked Carapace', 'Spiked Carapace', 'Returns damage% and reduces melee DMG taken', '24,29', 'Uts1', 'Uts2', 'Field Uts1=Thorns%, Field Uts2=Melee DMG Taken%'),
('DQEG', 'Elegant Grace', 'Defensive Aura', 'Reduces spell and pierce damage taken', '28,30', 'ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5', 'ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1', 'Field DEF5=Spell DMG Taken%, Field DEF1=Pierce DMG Taken%'),
('DQMF', 'Melee Damage Flat', 'Trueshot Aura (Melee Flat)', 'Flat melee damage bonus', '14', 'Ear1', NULL, 'Adds flat melee damage'),
('DQRF', 'Ranged Damage Flat', 'Trueshot Aura (Ranged Flat)', 'Flat ranged damage bonus', '16', 'Ear1', NULL, 'Adds flat ranged damage'),
('DQCS', 'Critical Strike', 'Critical Strike', 'Critical strike chance and damage multiplier', '10,11', 'Ocr1', 'ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2', 'DISABLED IN CODE - Uses udg_Stats_Crit instead. Field Ocr1=Crit Chance, Field OCR2=Crit DMG multiplier'),
('DQCL', 'Cleaving Attack', 'Cleaving Attack', 'Splash damage to nearby enemies', '18,19', 'ABILITY_RLF_DISTRIBUTED_DAMAGE_FACTOR_NCA1', 'aare', 'Field NCA1=Cleave%, Field aare=Cleave Area');

COMMENT ON TABLE ability_codes IS 'WC3 ability codes used by DEquipment stat system';
COMMENT ON COLUMN ability_codes.used_by_stats IS 'Comma-separated list of statids (from stat_definitions) that use this ability';


-- ====================================================================================================
-- ITEM STAT BONUSES TABLE (Enhanced version)
-- ====================================================================================================

CREATE TABLE item_stat_bonuses (
    id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    statid INTEGER NOT NULL REFERENCES stat_definitions(statid),
    bonus_value DECIMAL(12,4) NOT NULL,
    bonus_value_percent BOOLEAN DEFAULT FALSE, -- TRUE if value should be displayed as percentage
    is_flat_bonus BOOLEAN DEFAULT TRUE, -- FALSE if percentage modifier
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(item_id, statid)
);

CREATE INDEX idx_item_stat_bonuses_item_id ON item_stat_bonuses(item_id);
CREATE INDEX idx_item_stat_bonuses_statid ON item_stat_bonuses(statid);

COMMENT ON TABLE item_stat_bonuses IS 'Item stat bonuses using DEquipment statid system';
COMMENT ON COLUMN item_stat_bonuses.bonus_value IS 'The numeric value of the bonus. Interpretation depends on stat type.';
COMMENT ON COLUMN item_stat_bonuses.bonus_value_percent IS 'If TRUE, display value as percentage in UI (value 0.15 = 15%)';
COMMENT ON COLUMN item_stat_bonuses.is_flat_bonus IS 'TRUE for flat bonuses (e.g., +50 HP), FALSE for multipliers (e.g., +10% HP)';


-- ====================================================================================================
-- VIEWS FOR EASY QUERYING
-- ====================================================================================================

-- View: Complete item stat information with stat names
CREATE OR REPLACE VIEW v_item_stats AS
SELECT 
    i.id AS item_id,
    i.item_code,
    i.item_name,
    isb.statid,
    sd.stat_name,
    sd.stat_display_name,
    sd.stat_short_name,
    isb.bonus_value,
    isb.bonus_value_percent,
    isb.is_flat_bonus,
    sd.display_as_percent,
    sd.application_method,
    sd.ability_code,
    sd.ability_field,
    isb.notes
FROM items i
JOIN item_stat_bonuses isb ON i.id = isb.item_id
JOIN stat_definitions sd ON isb.statid = sd.statid
WHERE sd.is_active = TRUE
ORDER BY i.id, isb.statid;

COMMENT ON VIEW v_item_stats IS 'Comprehensive view of all item stats with full stat definition details';


-- View: Items with ability-based stats
CREATE OR REPLACE VIEW v_item_ability_stats AS
SELECT 
    i.id AS item_id,
    i.item_code,
    i.item_name,
    sd.statid,
    sd.stat_display_name,
    isb.bonus_value,
    ac.ability_code,
    ac.ability_name,
    ac.field_1_name,
    ac.field_2_name
FROM items i
JOIN item_stat_bonuses isb ON i.id = isb.item_id
JOIN stat_definitions sd ON isb.statid = sd.statid
JOIN ability_codes ac ON sd.ability_code = ac.ability_code
WHERE sd.application_method = 'ABILITY'
ORDER BY i.id, sd.statid;

COMMENT ON VIEW v_item_ability_stats IS 'Items with ability-based stats (requires ability addition in-game)';


-- View: Stat summary by application method
CREATE OR REPLACE VIEW v_stat_application_summary AS
SELECT 
    application_method,
    COUNT(*) AS stat_count,
    STRING_AGG(stat_display_name, ', ' ORDER BY statid) AS stats
FROM stat_definitions
WHERE is_active = TRUE
GROUP BY application_method;

COMMENT ON VIEW v_stat_application_summary IS 'Summary of stats grouped by how they are applied (NATIVE, ABILITY, GLOBAL_VAR)';


-- ====================================================================================================
-- MIGRATION FUNCTIONS
-- ====================================================================================================

-- Function to migrate existing item_bonuses to item_stat_bonuses
-- This assumes you have existing data in item_bonuses table and want to map it to statids
CREATE OR REPLACE FUNCTION migrate_item_bonuses_to_statids()
RETURNS TABLE(migrated_count INTEGER, skipped_count INTEGER) AS $$
DECLARE
    migrated INTEGER := 0;
    skipped INTEGER := 0;
    bonus_rec RECORD;
    target_statid INTEGER;
BEGIN
    -- This is a template function - customize based on your existing data
    -- Example: Map bonus_type to statid
    
    FOR bonus_rec IN SELECT * FROM item_bonuses LOOP
        target_statid := NULL;
        
        -- Map bonus types to statids (customize this mapping)
        CASE bonus_rec.bonus_type
            WHEN 'strength' THEN target_statid := 1;
            WHEN 'agility' THEN target_statid := 2;
            WHEN 'intelligence' THEN target_statid := 3;
            WHEN 'hp' THEN target_statid := 4;
            WHEN 'mana' THEN target_statid := 7;
            WHEN 'armor' THEN target_statid := 25;
            WHEN 'damage' THEN target_statid := 12;
            WHEN 'attack_speed' THEN target_statid := 20;
            WHEN 'movement_speed' THEN target_statid := 31;
            ELSE target_statid := NULL;
        END CASE;
        
        IF target_statid IS NOT NULL THEN
            INSERT INTO item_stat_bonuses(item_id, statid, bonus_value, notes)
            VALUES (bonus_rec.item_id, target_statid, bonus_rec.bonus_value, 'Migrated from item_bonuses')
            ON CONFLICT (item_id, statid) DO NOTHING;
            migrated := migrated + 1;
        ELSE
            skipped := skipped + 1;
        END IF;
    END LOOP;
    
    RETURN QUERY SELECT migrated, skipped;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION migrate_item_bonuses_to_statids() IS 'Helper function to migrate existing item_bonuses to new statid-based system';


-- ====================================================================================================
-- SAMPLE QUERIES
-- ====================================================================================================

-- Sample: Find all items with critical strike stats
-- SELECT * FROM v_item_stats WHERE statid IN (10, 11);

-- Sample: Find items that use abilities
-- SELECT * FROM v_item_ability_stats;

-- Sample: Get all stats for a specific item
-- SELECT * FROM v_item_stats WHERE item_code = 'I000';

-- Sample: Find items with HP regeneration bonuses
-- SELECT * FROM v_item_stats WHERE statid IN (5, 6);


-- ====================================================================================================
-- END OF STAT SYSTEM ENHANCEMENT
-- ====================================================================================================
