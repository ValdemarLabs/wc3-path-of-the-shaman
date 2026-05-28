-- Migration: 004_create_unit_specific_drops
-- Description: Create junction table for boss/specific unit drops
-- Date: 2026-04-11

-- Unit Specific Drops - for units with loot_mode = 'specific' or 'both'
-- Most units (90%+) use generic tier-based drops and won't have entries here
CREATE TABLE IF NOT EXISTS unit_specific_drops (
    id SERIAL PRIMARY KEY,
    unit_code VARCHAR(4) NOT NULL,
    item_code VARCHAR(4) NOT NULL,
    
    -- Drop configuration
    drop_chance DECIMAL(5,2) DEFAULT 100.00,     -- 0.00 - 100.00
    min_quantity INTEGER DEFAULT 1,
    max_quantity INTEGER DEFAULT 1,
    is_guaranteed BOOLEAN DEFAULT FALSE,          -- Always drops (ignores chance)
    weight INTEGER DEFAULT 100,                   -- For weighted random selection
    
    enabled BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign keys
    CONSTRAINT fk_usd_unit FOREIGN KEY (unit_code) REFERENCES unit_types(unit_code)
        ON DELETE CASCADE,
    CONSTRAINT fk_usd_item FOREIGN KEY (item_code) REFERENCES items(item_code)
        ON DELETE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_drop_chance CHECK (drop_chance >= 0 AND drop_chance <= 100),
    CONSTRAINT chk_quantity CHECK (min_quantity >= 1 AND max_quantity >= min_quantity),
    CONSTRAINT chk_weight CHECK (weight >= 0)
);

-- Unique constraint: one entry per unit+item combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_unit_specific_unique 
    ON unit_specific_drops(unit_code, item_code);

-- Index for lookups
CREATE INDEX IF NOT EXISTS idx_usd_unit_code ON unit_specific_drops(unit_code);
CREATE INDEX IF NOT EXISTS idx_usd_enabled ON unit_specific_drops(enabled);

COMMENT ON TABLE unit_specific_drops IS 'Explicit item drops for boss/unique units (loot_mode = specific or both)';
COMMENT ON COLUMN unit_specific_drops.is_guaranteed IS 'If true, always drops regardless of drop_chance';
COMMENT ON COLUMN unit_specific_drops.weight IS 'Relative weight for weighted random when multiple items available';
