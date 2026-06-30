-- ====================================================================================================
-- WC3 ABILITIES SCHEMA
-- ====================================================================================================
-- Schema for storing complete WC3 ability data from .w3a files
-- Supports full round-trip import/export with zero data loss
-- Author: Generated for PotS Project
-- Date: 2026-03-11
-- Version: 1.0.0
-- ====================================================================================================

-- ====================================================================================================
-- WC3 ABILITIES TABLE (Main abilities storage)
-- ====================================================================================================

CREATE TABLE IF NOT EXISTS wc3_abilities (
    id SERIAL PRIMARY KEY,
    
    -- Core identification
    ability_code CHAR(4) NOT NULL UNIQUE,          -- WC3 4-character ability ID (e.g., 'AHhb', 'A001')
    ability_name VARCHAR(255),                     -- Name/Title of ability (anam)
    base_id CHAR(4),                               -- Base ability this was modified from
    
    -- Classification
    ability_type VARCHAR(50),                      -- Type: Hero, Unit, Item, etc.
    race VARCHAR(50),                              -- Race: Human, Orc, Undead, NightElf, Neutral
    
    -- Text descriptions
    tooltip_normal TEXT,                           -- Tooltip - Normal (atp1 level 1)
    tooltip TEXT,                                  -- Tooltip - Basic (atp1-5)
    tooltip_extended TEXT,                         -- Tooltip - Extended/Ubertip (aub1-5)
    research_tooltip TEXT,                         -- Research Tooltip (aret)
    research_tooltip_extended TEXT,                -- Research Ubertip (arut)
    hotkey VARCHAR(10),                            -- Hotkey (ahky)
    unhotkey VARCHAR(10),                          -- Un-Hotkey (auho)
    research_hotkey VARCHAR(10),                   -- Research Hotkey (arhk)
    
    -- Levels & Requirements
    levels INTEGER DEFAULT 1,                      -- Number of Levels (alev)
    required_level INTEGER,                        -- Required Hero Level (arlv)
    level_skip INTEGER,                            -- Level Skip Requirement (alsk)
    
    -- Costs
    mana_cost INTEGER,                             -- Mana Cost (amcs for level 1)
    gold_cost INTEGER,                             -- Gold Cost Research (agar)
    lumber_cost INTEGER,                           -- Lumber Cost Research (alar)
    
    -- Cooldown & Timers
    cooldown DECIMAL(10,2),                        -- Cooldown (acdn for level 1)
    cast_time DECIMAL(10,2),                       -- Cast Time (acas for level 1)
    duration DECIMAL(10,2),                        -- Duration (adur for level 1 or ادur)
    hero_duration DECIMAL(10,2),                   -- Hero Duration (ahdu for level 1)
    
    -- Ranges & Areas
    cast_range DECIMAL(10,2),                      -- Cast Range (aran for level 1)
    area_of_effect DECIMAL(10,2),                  -- Area of Effect (aare for level 1)
    
    -- Effects & Damage
    damage_per_second DECIMAL(10,2),               -- Damage per Second (adps)
    damage_amount DECIMAL(10,2),                   -- Damage Amount (ahdu or specific field)
    attack_speed_increase DECIMAL(10,2),           -- Attack Speed Increase (Oae1/Isx1)
    movement_speed_modifier DECIMAL(10,2),         -- Movement Speed Modifier (Slo1/Uau1)
    
    -- Stats & Multipliers
    strength_bonus INTEGER,                        -- Strength Bonus (Istr)
    agility_bonus INTEGER,                         -- Agility Bonus (Iagi)
    intelligence_bonus INTEGER,                    -- Intelligence Bonus (Iint)
    damage_bonus INTEGER,                          -- Damage Bonus (Iatt)
    armor_bonus INTEGER,                           -- Armor Bonus (Idef)
    
    -- Flags & Booleans
    is_hero_ability BOOLEAN DEFAULT FALSE,         -- Hero Ability (aher)
    is_item_ability BOOLEAN DEFAULT FALSE,         -- Item Ability (aite)
    checkdep BOOLEAN DEFAULT TRUE,                 -- Check Dependencies (achd)
    visible BOOLEAN DEFAULT TRUE,                  -- Visible (avis)
    
    -- Targeting
    targets_allowed TEXT,                          -- Targets Allowed (atar)
    
    -- Visual/Art fields
    icon_path VARCHAR(255),                        -- Icon - Normal (aart)
    icon_research VARCHAR(255),                    -- Icon - Research (arar)
    button_pos_x INTEGER,                          -- Button Position X (abpx)
    button_pos_y INTEGER,                          -- Button Position Y (abpy)
    button_pos_research_x INTEGER,                 -- Research Button X (arbx)
    button_pos_research_y INTEGER,                 -- Research Button Y (arby)
    
    effect_art VARCHAR(255),                       -- Art - Effect (aeat)
    effect_target VARCHAR(255),                    -- Art - Target (atat)
    effect_caster VARCHAR(255),                    -- Art - Caster (acat)
    effect_special VARCHAR(255),                   -- Art - Special (asat)
    missile_art VARCHAR(255),                      -- Art - Missile (amat)
    missile_speed INTEGER,                         -- Missile Speed (amsp)
    missile_arc DECIMAL(10,2),                     -- Missile Arc (amar)
    missile_homing BOOLEAN DEFAULT FALSE,          -- Missile Homing Enabled (amho)
    
    -- Sound effects
    effect_sound VARCHAR(255),                     -- Sound - Effect (aefs)
    
    -- Requirements & Techtree
    requirements TEXT,                             -- Requirements (areq)
    requirements_levels TEXT,                      -- Requirements - Levels (arqa)
    
    -- Data fields (ability-specific parameters stored as JSON)
    -- WC3 abilities have many level-dependent data fields (ادur1-5, ahdu1-5, etc.)
    data_fields JSONB,                             -- Level-dependent fields as JSON
    
    -- ===== CRITICAL: ZERO DATA LOSS =====
    -- Store original parsed modifications as JSON for perfect round-trip export
    original_modifications JSONB,                  -- All modifications from .w3a file
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes
    CONSTRAINT unique_ability_code UNIQUE (ability_code)
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_abilities_name ON wc3_abilities(ability_name);
CREATE INDEX IF NOT EXISTS idx_abilities_base_id ON wc3_abilities(base_id);
CREATE INDEX IF NOT EXISTS idx_abilities_type ON wc3_abilities(ability_type);
CREATE INDEX IF NOT EXISTS idx_abilities_race ON wc3_abilities(race);
CREATE INDEX IF NOT EXISTS idx_abilities_hero ON wc3_abilities(is_hero_ability);
CREATE INDEX IF NOT EXISTS idx_abilities_item ON wc3_abilities(is_item_ability);
CREATE INDEX IF NOT EXISTS idx_abilities_data_fields ON wc3_abilities USING GIN (data_fields);
CREATE INDEX IF NOT EXISTS idx_abilities_original_mods ON wc3_abilities USING GIN (original_modifications);

COMMENT ON TABLE wc3_abilities IS 'Complete WC3 ability data from .w3a files with zero data loss';
COMMENT ON COLUMN wc3_abilities.ability_code IS 'WC3 4-character ability identifier';
COMMENT ON COLUMN wc3_abilities.base_id IS 'Original WC3 ability this was modified from';
COMMENT ON COLUMN wc3_abilities.tooltip_normal IS 'Ability normal tooltip (atp1 level 1)';
COMMENT ON COLUMN wc3_abilities.data_fields IS 'Level-dependent ability fields (JSON array indexed by level)';
COMMENT ON COLUMN wc3_abilities.original_modifications IS 'Raw WC3 modifications for perfect export round-trip';

-- ====================================================================================================
-- ABILITY IMPORT HISTORY
-- ====================================================================================================

CREATE TABLE IF NOT EXISTS ability_import_history (
    id SERIAL PRIMARY KEY,
    import_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file VARCHAR(255) NOT NULL,
    abilities_imported INTEGER DEFAULT 0,
    abilities_updated INTEGER DEFAULT 0,
    abilities_failed INTEGER DEFAULT 0,
    fields_stored INTEGER DEFAULT 0,
    import_format VARCHAR(50) DEFAULT 'W3A',
    notes TEXT
);

COMMENT ON TABLE ability_import_history IS 'Track .w3a file imports for auditing';

-- ====================================================================================================
-- ABILITY TO ITEM LINKING (Enhanced)
-- ====================================================================================================

-- Enhance existing item_abilities table with foreign key to wc3_abilities
DO $$
BEGIN
    -- Add foreign key if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_item_abilities_wc3_abilities' 
        AND table_name = 'item_abilities'
    ) THEN
        -- Add ability_id column if not exists
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'item_abilities' AND column_name = 'ability_id'
        ) THEN
            ALTER TABLE item_abilities ADD COLUMN ability_id INTEGER;
        END IF;
        
        -- Add foreign key constraint
        ALTER TABLE item_abilities 
        ADD CONSTRAINT fk_item_abilities_wc3_abilities 
        FOREIGN KEY (ability_id) REFERENCES wc3_abilities(id) ON DELETE SET NULL;
        
        -- Create index for joins
        CREATE INDEX IF NOT EXISTS idx_item_abilities_ability_id ON item_abilities(ability_id);
        
        RAISE NOTICE 'Added ability_id foreign key to item_abilities table';
    END IF;
END $$;

COMMENT ON COLUMN item_abilities.ability_id IS 'Links to wc3_abilities table for full ability data';
