-- Migration: 002_create_loot_tiers
-- Description: Create loot_tiers table for level-based generic drops
-- Date: 2026-04-11

-- Loot Tiers define level ranges and per-rarity item levels/weights
CREATE TABLE IF NOT EXISTS loot_tiers (
    id SERIAL PRIMARY KEY,
    tier_name VARCHAR(50) UNIQUE NOT NULL,
    min_unit_level INTEGER NOT NULL,
    max_unit_level INTEGER NOT NULL,
    description TEXT,
    drop_chance_base DECIMAL(5,2) DEFAULT 10.00,
    
    -- Per-rarity item levels (NULL = rarity unavailable at this tier)
    common_item_level INTEGER,
    uncommon_item_level INTEGER,
    rare_item_level INTEGER,
    epic_item_level INTEGER,
    legendary_item_level INTEGER,
    artifact_item_level INTEGER,
    
    -- Per-rarity weights (0 = disabled)
    common_weight INTEGER DEFAULT 60,
    uncommon_weight INTEGER DEFAULT 25,
    rare_weight INTEGER DEFAULT 12,
    epic_weight INTEGER DEFAULT 3,
    legendary_weight INTEGER DEFAULT 0,
    artifact_weight INTEGER DEFAULT 0,
    
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure level ranges don't overlap
    CONSTRAINT chk_level_range CHECK (min_unit_level <= max_unit_level),
    CONSTRAINT chk_level_positive CHECK (min_unit_level >= 1)
);

-- Index for level lookups
CREATE INDEX IF NOT EXISTS idx_loot_tiers_levels ON loot_tiers(min_unit_level, max_unit_level);
CREATE INDEX IF NOT EXISTS idx_loot_tiers_enabled ON loot_tiers(enabled);

-- Now add FK constraint to unit_types
ALTER TABLE unit_types 
    ADD CONSTRAINT fk_unit_loot_tier 
    FOREIGN KEY (loot_tier_id) REFERENCES loot_tiers(id)
    ON DELETE SET NULL;

COMMENT ON TABLE loot_tiers IS 'Defines level-based loot tiers with per-rarity item levels and weights';
COMMENT ON COLUMN loot_tiers.drop_chance_base IS 'Base drop chance percentage (0-100)';
COMMENT ON COLUMN loot_tiers.common_item_level IS 'Item level for Common rarity drops in this tier';
