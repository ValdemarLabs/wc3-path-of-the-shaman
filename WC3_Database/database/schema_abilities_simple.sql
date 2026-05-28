-- ====================================================================================================
-- WC3 ABILITIES SCHEMA - SIMPLIFIED
-- ====================================================================================================
-- Simplified schema for storing essential WC3 ability data for item reference
-- Stores only: ability_code, ability_name (anam), editor_suffix (ansf)
-- Author: Generated for PotS Project
-- Date: 2026-03-15
-- Version: 2.0.0 - Simplified for item reference only
-- ====================================================================================================

-- Drop existing table if present
DROP TABLE IF EXISTS wc3_abilities CASCADE;

-- Create simplified abilities table
CREATE TABLE wc3_abilities (
    id SERIAL PRIMARY KEY,
    ability_code CHAR(4) NOT NULL UNIQUE,          -- WC3 4-character ability ID (e.g., 'AHhb', 'A001')
    ability_name VARCHAR(255),                     -- Name/Title of ability (anam field)
    editor_suffix VARCHAR(255),                    -- Editor suffix (ansf field)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_ability_code UNIQUE (ability_code)
);

-- Create indexes for common queries
CREATE INDEX idx_abilities_code ON wc3_abilities(ability_code);
CREATE INDEX idx_abilities_name ON wc3_abilities(ability_name);

-- Add comments
COMMENT ON TABLE wc3_abilities IS 'Simplified WC3 abilities for item reference only';
COMMENT ON COLUMN wc3_abilities.ability_code IS 'WC3 4-character ability identifier';
COMMENT ON COLUMN wc3_abilities.ability_name IS 'Ability name (anam field)';
COMMENT ON COLUMN wc3_abilities.editor_suffix IS 'Editor suffix (ansf field)';

-- ====================================================================================================
-- TABLE: item_abilities (junction table for items and abilities)
-- ====================================================================================================
-- Note: This table may already exist. If so, just ensure the foreign key is correct.

-- Create item_abilities junction table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'item_abilities') THEN
        CREATE TABLE item_abilities (
            id SERIAL PRIMARY KEY,
            item_id INTEGER REFERENCES items(id) ON DELETE CASCADE,
            ability_id INTEGER REFERENCES wc3_abilities(id) ON DELETE CASCADE,
            ability_level INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(item_id, ability_id)
        );
        
        CREATE INDEX idx_item_abilities_item ON item_abilities(item_id);
        CREATE INDEX idx_item_abilities_ability ON item_abilities(ability_id);
        
        COMMENT ON TABLE item_abilities IS 'Links items to their abilities';
    ELSE
        -- Add ability_id foreign key if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'fk_item_abilities_wc3_abilities'
        ) THEN
            ALTER TABLE item_abilities
            ADD CONSTRAINT fk_item_abilities_wc3_abilities 
            FOREIGN KEY (ability_id) REFERENCES wc3_abilities(id) ON DELETE CASCADE;
            
            RAISE NOTICE 'Added ability_id foreign key to item_abilities table';
        END IF;
    END IF;
END $$;

COMMENT ON TABLE item_abilities IS 'Links items to their WC3 abilities';
