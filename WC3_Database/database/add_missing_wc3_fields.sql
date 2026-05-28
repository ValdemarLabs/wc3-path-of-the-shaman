-- Add missing WC3 fields to items table
-- Run this to enable full W3T export with all 40+ fields

-- Fields that DON'T exist in base schema (need to be added)
ALTER TABLE items ADD COLUMN IF NOT EXISTS base_id VARCHAR(4);  -- Base item for custom items
ALTER TABLE items ADD COLUMN IF NOT EXISTS hotkey VARCHAR(10);  -- uhot
ALTER TABLE items ADD COLUMN IF NOT EXISTS wc3_classification VARCHAR(50);  -- icla
ALTER TABLE items ADD COLUMN IF NOT EXISTS old_level INTEGER;  -- ilvo
ALTER TABLE items ADD COLUMN IF NOT EXISTS hit_points INTEGER DEFAULT 75;  -- ihtp
ALTER TABLE items ADD COLUMN IF NOT EXISTS actively_used BOOLEAN DEFAULT FALSE;  -- iusa (alternative to use_automatically)
ALTER TABLE items ADD COLUMN IF NOT EXISTS morph_target VARCHAR(4);  -- imor
ALTER TABLE items ADD COLUMN IF NOT EXISTS ignore_cooldown BOOLEAN DEFAULT FALSE;  -- iicd
ALTER TABLE items ADD COLUMN IF NOT EXISTS pick_random BOOLEAN DEFAULT FALSE;  -- iprn
ALTER TABLE items ADD COLUMN IF NOT EXISTS armor_type VARCHAR(50);  -- iamn
ALTER TABLE items ADD COLUMN IF NOT EXISTS wc3_abilities TEXT;  -- iabi (CRITICAL!)
ALTER TABLE items ADD COLUMN IF NOT EXISTS selection_size NUMERIC(10,4) DEFAULT 0.0;  -- issc
ALTER TABLE items ADD COLUMN IF NOT EXISTS button_pos_x INTEGER DEFAULT 0;  -- ubpx
ALTER TABLE items ADD COLUMN IF NOT EXISTS button_pos_y INTEGER DEFAULT 0;  -- ubpy
ALTER TABLE items ADD COLUMN IF NOT EXISTS stock_initial INTEGER DEFAULT 0;  -- isit
ALTER TABLE items ADD COLUMN IF NOT EXISTS stock_max INTEGER DEFAULT 0;  -- isto
ALTER TABLE items ADD COLUMN IF NOT EXISTS stock_replenish INTEGER DEFAULT 0;  -- istr
ALTER TABLE items ADD COLUMN IF NOT EXISTS stock_start_delay INTEGER DEFAULT 0;  -- isst
ALTER TABLE items ADD COLUMN IF NOT EXISTS wc3_requirements TEXT;  -- ureq
ALTER TABLE items ADD COLUMN IF NOT EXISTS wc3_requirements_amount TEXT;  -- urqa

-- Columns that ALREADY exist in base schema (no need to add):
-- item_name (unam)
-- tooltip (utip)
-- extended_tooltip (utub)
-- description (ides)
-- gold_cost (igol)
-- lumber_cost (ilum)
-- item_level (ilev)
-- max_charges (iuse)
-- max_stack (ista)
-- is_droppable (idro)
-- is_sellable (isel)
-- is_pawnable (ipaw)
-- is_powerup (ipow)
-- drops_on_death (idrp)
-- is_perishable (iper)
-- use_automatically (iusa)
-- icon_path (iico)
-- model_path (ifil)
-- scale (isca)
-- tint_red (iclr)
-- tint_green (iclg)
-- tint_blue (iclb)
-- cooldown_group (icid)
-- priority (ipri)
