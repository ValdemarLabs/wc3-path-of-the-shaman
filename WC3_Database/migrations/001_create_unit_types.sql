-- Migration: 001_create_unit_types
-- Description: Create unit_types table for ItemLootSystem
-- Date: 2026-04-11

-- Unit Types table stores WC3 unit type data for loot configuration
CREATE TABLE IF NOT EXISTS unit_types (
    id SERIAL PRIMARY KEY,
    
    -- WC3-imported columns (from .w3u files)
    unit_code VARCHAR(4) NOT NULL UNIQUE,
    base_id VARCHAR(4),                          -- Base unit ID for custom units
    unit_name VARCHAR(255) NOT NULL,             -- unam field
    editor_suffix VARCHAR(100),                  -- unsf field
    icon_path VARCHAR(255),                      -- uico field
    
    -- Loot configuration columns
    unit_level INTEGER DEFAULT 1,                -- For generic drop tier matching
    is_boss BOOLEAN DEFAULT FALSE,               -- Boss unit flag
    loot_mode VARCHAR(20) DEFAULT 'generic'      -- generic, specific, both, none
        CHECK (loot_mode IN ('generic', 'specific', 'both', 'none')),
    loot_tier_id INTEGER,                        -- FK to loot_tiers (added after that table)
    drop_count_min INTEGER DEFAULT 1,
    drop_count_max INTEGER DEFAULT 1,
    
    -- Metadata
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_unit_types_unit_code ON unit_types(unit_code);
CREATE INDEX IF NOT EXISTS idx_unit_types_is_boss ON unit_types(is_boss);
CREATE INDEX IF NOT EXISTS idx_unit_types_loot_mode ON unit_types(loot_mode);
CREATE INDEX IF NOT EXISTS idx_unit_types_unit_level ON unit_types(unit_level);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_unit_types_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_unit_types_updated_at ON unit_types;
CREATE TRIGGER trigger_unit_types_updated_at
    BEFORE UPDATE ON unit_types
    FOR EACH ROW
    EXECUTE FUNCTION update_unit_types_timestamp();

COMMENT ON TABLE unit_types IS 'WC3 unit type definitions for loot system configuration';
COMMENT ON COLUMN unit_types.unit_code IS '4-character WC3 unit type ID (e.g., hfoo, Hpal)';
COMMENT ON COLUMN unit_types.loot_mode IS 'generic=level-based pool, specific=explicit drops, both=combined, none=no drops';
