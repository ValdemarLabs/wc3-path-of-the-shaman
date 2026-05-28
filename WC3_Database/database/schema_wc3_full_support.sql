-- WC3 .w3t Full Field Support Enhancement
-- Adds missing WC3-specific fields to prevent data loss during import/export
-- Run this AFTER the base schema.sql

-- Add missing WC3 fields to items table
ALTER TABLE items ADD COLUMN IF NOT EXISTS base_id VARCHAR(4);  -- Original item ID (for custom items)
ALTER TABLE items ADD COLUMN IF NOT EXISTS tooltip_extended TEXT;  -- utub - Extended tooltip (Ubertip)
ALTER TABLE items ADD COLUMN IF NOT EXISTS hotkey VARCHAR(10);  -- uhot - Hotkey
ALTER TABLE items ADD COLUMN IF NOT EXISTS wc3_classification VARCHAR(50);  -- icla - WC3 Classification (Permanent/Charged/etc)
ALTER TABLE items ADD COLUMN IF NOT EXISTS old_level INTEGER;  -- ilvo - Old level field
ALTER TABLE items ADD COLUMN IF NOT EXISTS hit_points INTEGER;  -- ihtp - Hit points
ALTER TABLE items ADD COLUMN IF NOT EXISTS actively_used BOOLEAN;  -- iusa - Actively used
ALTER TABLE items ADD COLUMN IF NOT EXISTS dropped_on_death BOOLEAN;  -- idnp - Dropped when carrier dies
ALTER TABLE items ADD COLUMN IF NOT EXISTS morph_target VARCHAR(4);  -- imor - Morph target
ALTER TABLE items ADD COLUMN IF NOT EXISTS ignore_cooldown BOOLEAN;  -- iicd - Ignore cooldown
ALTER TABLE items ADD COLUMN IF NOT EXISTS pick_random BOOLEAN;  -- iprn - Pick random
ALTER TABLE items ADD COLUMN IF NOT EXISTS armor_type VARCHAR(50);  -- iarm - Armor type
ALTER TABLE items ADD COLUMN IF NOT EXISTS wc3_abilities TEXT;  -- iabi - Abilities as comma-separated raw codes
ALTER TABLE items ADD COLUMN IF NOT EXISTS scale NUMERIC(10,4);  -- isca - Scaling value
ALTER TABLE items ADD COLUMN IF NOT EXISTS selection_size NUMERIC(10,4);  -- issc - Selection size
ALTER TABLE items ADD COLUMN IF NOT EXISTS button_pos_x INTEGER;  -- ubpx - Button position X
ALTER TABLE items ADD COLUMN IF NOT EXISTS button_pos_y INTEGER;  -- ubpy - Button position Y
ALTER TABLE items ADD COLUMN IF NOT EXISTS stock_initial INTEGER;  -- isit - Stock initial
ALTER TABLE items ADD COLUMN IF NOT EXISTS stock_max INTEGER;  -- isto - Stock max
ALTER TABLE items ADD COLUMN IF NOT EXISTS stock_replenish INTEGER;  -- isrr - Stock replenish interval
ALTER TABLE items ADD COLUMN IF NOT EXISTS stock_start_delay INTEGER;  -- isst - Stock start delay
ALTER TABLE items ADD COLUMN IF NOT EXISTS wc3_requirements TEXT;  -- ureq - Requirements
ALTER TABLE items ADD COLUMN IF NOT EXISTS wc3_requirements_amount TEXT;  -- urqa - Requirements amount

-- CRITICAL: Store all original modifications for perfect round-trip
ALTER TABLE items ADD COLUMN IF NOT EXISTS original_modifications JSONB;  -- All WC3 modifications as JSON

-- Add comments
COMMENT ON COLUMN items.base_id IS 'Original item code this custom item is based on (for custom items only)';
COMMENT ON COLUMN items.tooltip_extended IS 'WC3 Extended Tooltip (Ubertip) - utub field';
COMMENT ON COLUMN items.hotkey IS 'WC3 Hotkey - uhot field';
COMMENT ON COLUMN items.wc3_classification IS 'WC3 Classification: Permanent, Charged, Powerup, Artifact, Campaign, Misc - icla field';
COMMENT ON COLUMN items.wc3_abilities IS 'WC3 Abilities as comma-separated raw codes (e.g., "AIs6,AId1") - iabi field';
COMMENT ON COLUMN items.original_modifications IS 'Complete WC3 modification data for perfect round-trip export (JSONB format)';

-- Create index on base_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_items_base_id ON items(base_id);

-- Create GIN index on original_modifications for JSON queries
CREATE INDEX IF NOT EXISTS idx_items_original_mods ON items USING GIN (original_modifications);

-- Schema enhancements complete

