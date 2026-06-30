-- ====================================================================================================
-- WC3 POTS POSTGRESQL DATABASE SCHEMA
-- ====================================================================================================
-- Database for managing Warcraft 3 items with import/export capabilities
-- Supports World Editor integration and DInventory/DEquipment subsystems
--
-- Author: Generated for PotS Project
-- Date: 2026-03-10
-- Version: 1.0.0
-- ====================================================================================================

-- Drop existing tables if they exist (for clean reinstall)
DROP TABLE IF EXISTS item_bonuses CASCADE;
DROP TABLE IF EXISTS item_requirements CASCADE;
DROP TABLE IF EXISTS item_abilities CASCADE;
DROP TABLE IF EXISTS item_set_bonuses CASCADE;
DROP TABLE IF EXISTS item_sets CASCADE;
DROP TABLE IF EXISTS items CASCADE;
DROP TABLE IF EXISTS item_classes CASCADE;
DROP TABLE IF EXISTS item_rarities CASCADE;
DROP TABLE IF EXISTS item_types CASCADE;
DROP TABLE IF EXISTS export_history CASCADE;
DROP TABLE IF EXISTS import_history CASCADE;

-- ====================================================================================================
-- ENUMERATION/LOOKUP TABLES
-- ====================================================================================================

-- Item Types (Weapon, Armor, Consumable, etc.)
CREATE TABLE item_types (
    id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Item Rarities (Common, Uncommon, Rare, Epic, Legendary, etc.)
CREATE TABLE item_rarities (
    id SERIAL PRIMARY KEY,
    rarity_name VARCHAR(50) UNIQUE NOT NULL,
    rarity_level INTEGER NOT NULL, -- 0=common, 1=uncommon, 2=rare, 3=epic, 4=legendary, etc.
    color_code VARCHAR(7), -- Hex color code for UI display (e.g., '#FF0000')
    gold_multiplier DECIMAL(5,2) DEFAULT 1.0,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_rarity_level UNIQUE(rarity_level)
);

-- Item Classes (Equipment Slot Types)
CREATE TABLE item_classes (
    id SERIAL PRIMARY KEY,
    class_name VARCHAR(50) UNIQUE NOT NULL,
    slot_type VARCHAR(50), -- 'HEAD', 'CHEST', 'LEGS', 'WEAPON', 'OFFHAND', 'RING', 'TRINKET', etc.
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Item Sets
CREATE TABLE item_sets (
    id SERIAL PRIMARY KEY,
    set_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    set_bonus_2pc TEXT,
    set_bonus_3pc TEXT,
    set_bonus_4pc TEXT,
    set_bonus_5pc TEXT,
    set_bonus_6pc TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ====================================================================================================
-- MAIN ITEMS TABLE
-- ====================================================================================================

CREATE TABLE items (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    
    -- WC3 Identifiers
    item_code CHAR(4) UNIQUE NOT NULL, -- WC3 4-character item ID (e.g., 'I000')
    item_name VARCHAR(255) NOT NULL,
    
    -- Foreign Keys
    type_id INTEGER REFERENCES item_types(id) ON DELETE SET NULL,
    rarity_id INTEGER REFERENCES item_rarities(id) ON DELETE SET NULL,
    class_id INTEGER REFERENCES item_classes(id) ON DELETE SET NULL,
    set_id INTEGER REFERENCES item_sets(id) ON DELETE SET NULL,
    
    -- Base Properties
    item_level INTEGER DEFAULT 1,
    required_level INTEGER DEFAULT 1,
    max_charges INTEGER DEFAULT 0,
    max_stack INTEGER DEFAULT 1,
    
    -- Cost & Value
    gold_cost INTEGER DEFAULT 0,
    lumber_cost INTEGER DEFAULT 0,
    sell_value INTEGER,
    
    -- Combat Stats - Offensive
    damage_min INTEGER DEFAULT 0,
    damage_max INTEGER DEFAULT 0,
    attack_speed DECIMAL(6,2) DEFAULT 0,
    critical_chance DECIMAL(5,2) DEFAULT 0,
    critical_damage DECIMAL(5,2) DEFAULT 0,
    
    -- Combat Stats - Defensive
    armor INTEGER DEFAULT 0,
    block_chance DECIMAL(5,2) DEFAULT 0,
    dodge_chance DECIMAL(5,2) DEFAULT 0,
    
    -- Attributes
    strength_bonus INTEGER DEFAULT 0,
    agility_bonus INTEGER DEFAULT 0,
    intelligence_bonus INTEGER DEFAULT 0,
    
    -- Derived Stats
    health_bonus INTEGER DEFAULT 0,
    mana_bonus INTEGER DEFAULT 0,
    health_regen DECIMAL(6,2) DEFAULT 0,
    mana_regen DECIMAL(6,2) DEFAULT 0,
    movement_speed INTEGER DEFAULT 0,
    
    -- Resistances
    fire_resistance INTEGER DEFAULT 0,
    cold_resistance INTEGER DEFAULT 0,
    lightning_resistance INTEGER DEFAULT 0,
    poison_resistance INTEGER DEFAULT 0,
    
    -- Item Flags
    is_droppable BOOLEAN DEFAULT TRUE,
    is_sellable BOOLEAN DEFAULT TRUE,
    is_pawnable BOOLEAN DEFAULT TRUE,
    is_powerup BOOLEAN DEFAULT FALSE,
    drops_on_death BOOLEAN DEFAULT TRUE,
    is_perishable BOOLEAN DEFAULT FALSE,
    is_soulbound BOOLEAN DEFAULT FALSE,
    is_unique BOOLEAN DEFAULT FALSE,
    use_automatically BOOLEAN DEFAULT FALSE,
    can_be_dropped_by_carrier BOOLEAN DEFAULT TRUE,
    
    -- Visual Properties
    icon_path VARCHAR(255),
    model_path VARCHAR(255),
    tint_red INTEGER DEFAULT 255,
    tint_green INTEGER DEFAULT 255,
    tint_blue INTEGER DEFAULT 255,
    tint_alpha INTEGER DEFAULT 255,
    scale DECIMAL(5,2) DEFAULT 1.0,
    
    -- Tooltips & Description
    tooltip TEXT,
    extended_tooltip TEXT,
    description TEXT,
    lore TEXT,
    
    -- Cooldown Properties
    cooldown_group INTEGER DEFAULT 0,
    cooldown_duration INTEGER DEFAULT 0,
    
    -- WC3 Object Editor Fields
    priority INTEGER DEFAULT 0,
    
    -- DInventory/DEquip Integration
    dinv_compatible BOOLEAN DEFAULT TRUE,
    deq_compatible BOOLEAN DEFAULT TRUE,
    equipment_slot VARCHAR(50), -- for DEquipment system
    dual_wield_allowed BOOLEAN DEFAULT FALSE,
    
    -- Growth Item Properties (for DEqGrowthItem module)
    is_growth_item BOOLEAN DEFAULT FALSE,
    growth_formula TEXT,
    max_growth_level INTEGER DEFAULT 0,
    
    -- Named Item Properties (for DEqNamedItem module)
    is_named_item BOOLEAN DEFAULT FALSE,
    named_item_pool VARCHAR(100),
    
    -- Custom Fields (JSON for flexibility)
    custom_data JSONB DEFAULT '{}',
    
    -- Metadata
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    
    -- Indexes for performance
    CONSTRAINT check_item_level CHECK (item_level >= 0 AND item_level <= 1000),
    CONSTRAINT check_required_level CHECK (required_level >= 0 AND required_level <= 1000),
    CONSTRAINT check_max_charges CHECK (max_charges >= 0),
    CONSTRAINT check_max_stack CHECK (max_stack >= 1)
);

-- ====================================================================================================
-- ITEM BONUSES TABLE (for multiple stat bonuses)
-- ====================================================================================================

CREATE TABLE item_bonuses (
    id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    bonus_type VARCHAR(100) NOT NULL, -- 'STAT', 'RESISTANCE', 'EFFECT', 'PROC', etc.
    bonus_name VARCHAR(100) NOT NULL,
    bonus_value DECIMAL(10,2) NOT NULL,
    bonus_formula TEXT, -- For dynamic bonuses
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ====================================================================================================
-- ITEM REQUIREMENTS TABLE
-- ====================================================================================================

CREATE TABLE item_requirements (
    id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    requirement_type VARCHAR(50) NOT NULL, -- 'LEVEL', 'CLASS', 'RACE', 'QUEST', 'REPUTATION', etc.
    requirement_value VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ====================================================================================================
-- ITEM ABILITIES TABLE (WC3 abilities granted by item)
-- ====================================================================================================

CREATE TABLE item_abilities (
    id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    ability_code CHAR(4) NOT NULL, -- WC3 4-character ability ID
    ability_name VARCHAR(255),
    ability_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ====================================================================================================
-- ITEM SET BONUSES TABLE (detailed set bonuses)
-- ====================================================================================================

CREATE TABLE item_set_bonuses (
    id SERIAL PRIMARY KEY,
    set_id INTEGER NOT NULL REFERENCES item_sets(id) ON DELETE CASCADE,
    pieces_required INTEGER NOT NULL,
    bonus_type VARCHAR(100) NOT NULL,
    bonus_value DECIMAL(10,2) NOT NULL,
    bonus_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_pieces_required CHECK (pieces_required >= 2 AND pieces_required <= 10)
);

-- ====================================================================================================
-- IMPORT/EXPORT HISTORY TABLES
-- ====================================================================================================

CREATE TABLE import_history (
    id SERIAL PRIMARY KEY,
    import_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file VARCHAR(255),
    items_imported INTEGER,
    items_updated INTEGER,
    items_failed INTEGER,
    import_format VARCHAR(50), -- 'WC3_TXT', 'WC3_SLK', 'CSV', 'JSON', etc.
    notes TEXT
);

CREATE TABLE export_history (
    id SERIAL PRIMARY KEY,
    export_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    destination_file VARCHAR(255),
    items_exported INTEGER,
    export_format VARCHAR(50), -- 'JASS', 'DEQIP', 'CSV', 'JSON', etc.
    export_type VARCHAR(50), -- 'SINGLE', 'SELECTION', 'ALL'
    item_codes TEXT[], -- Array of exported item codes
    notes TEXT
);

-- ====================================================================================================
-- INDEXES FOR PERFORMANCE
-- ====================================================================================================

CREATE INDEX idx_items_item_code ON items(item_code);
CREATE INDEX idx_items_item_name ON items(item_name);
CREATE INDEX idx_items_type_id ON items(type_id);
CREATE INDEX idx_items_rarity_id ON items(rarity_id);
CREATE INDEX idx_items_class_id ON items(class_id);
CREATE INDEX idx_items_set_id ON items(set_id);
CREATE INDEX idx_items_item_level ON items(item_level);
CREATE INDEX idx_items_required_level ON items(required_level);
CREATE INDEX idx_items_is_soulbound ON items(is_soulbound);
CREATE INDEX idx_items_is_unique ON items(is_unique);
CREATE INDEX idx_items_dinv_compatible ON items(dinv_compatible);
CREATE INDEX idx_items_deq_compatible ON items(deq_compatible);

CREATE INDEX idx_item_bonuses_item_id ON item_bonuses(item_id);
CREATE INDEX idx_item_bonuses_bonus_type ON item_bonuses(bonus_type);

CREATE INDEX idx_item_requirements_item_id ON item_requirements(item_id);
CREATE INDEX idx_item_requirements_type ON item_requirements(requirement_type);

CREATE INDEX idx_item_abilities_item_id ON item_abilities(item_id);
CREATE INDEX idx_item_abilities_ability_code ON item_abilities(ability_code);

CREATE INDEX idx_item_set_bonuses_set_id ON item_set_bonuses(set_id);

-- ====================================================================================================
-- TRIGGERS FOR AUTO-UPDATE TIMESTAMPS
-- ====================================================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_items_updated_at BEFORE UPDATE ON items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_item_sets_updated_at BEFORE UPDATE ON item_sets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ====================================================================================================
-- VIEWS FOR COMMON QUERIES
-- ====================================================================================================

-- Complete Item View (with all related data)
CREATE OR REPLACE VIEW v_items_complete AS
SELECT 
    i.*,
    t.type_name,
    r.rarity_name,
    r.rarity_level,
    r.color_code as rarity_color,
    c.class_name,
    c.slot_type,
    s.set_name,
    s.description as set_description
FROM items i
LEFT JOIN item_types t ON i.type_id = t.id
LEFT JOIN item_rarities r ON i.rarity_id = r.id
LEFT JOIN item_classes c ON i.class_id = c.id
LEFT JOIN item_sets s ON i.set_id = s.id;

-- DEquipment Compatible Items View
CREATE OR REPLACE VIEW v_deq_items AS
SELECT * FROM v_items_complete
WHERE deq_compatible = TRUE;

-- DInventory Compatible Items View
CREATE OR REPLACE VIEW v_dinv_items AS
SELECT * FROM v_items_complete
WHERE dinv_compatible = TRUE;

-- Items by Rarity View
CREATE OR REPLACE VIEW v_items_by_rarity AS
SELECT 
    r.rarity_name,
    r.rarity_level,
    COUNT(i.id) as item_count,
    AVG(i.gold_cost) as avg_gold_cost
FROM item_rarities r
LEFT JOIN items i ON r.id = i.rarity_id
GROUP BY r.id, r.rarity_name, r.rarity_level
ORDER BY r.rarity_level;

-- ====================================================================================================
-- SEED DATA (Default values)
-- ====================================================================================================

-- Insert default item types
INSERT INTO item_types (type_name, description) VALUES
('Weapon', 'Weapons for dealing damage'),
('Armor', 'Armor pieces for protection'),
('Accessory', 'Rings, amulets, trinkets'),
('Consumable', 'Potions, scrolls, food'),
('Quest', 'Quest-related items'),
('Material', 'Crafting materials'),
('Other', 'Miscellaneous items');

-- Insert default rarities
INSERT INTO item_rarities (rarity_name, rarity_level, color_code, gold_multiplier, description) VALUES
('Common', 0, '#9D9D9D', 1.0, 'Common quality items'),
('Uncommon', 1, '#1EFF00', 1.5, 'Uncommon quality items'),
('Rare', 2, '#0070DD', 2.0, 'Rare quality items'),
('Epic', 3, '#A335EE', 3.0, 'Epic quality items'),
('Legendary', 4, '#FF8000', 5.0, 'Legendary quality items'),
('Artifact', 5, '#E6CC80', 10.0, 'Artifact quality items');

-- Insert default item classes (equipment slots)
INSERT INTO item_classes (class_name, slot_type, description) VALUES
('Head Armor', 'HEAD', 'Helmets, hats, circlets'),
('Chest Armor', 'CHEST', 'Chest pieces, robes'),
('Leg Armor', 'LEGS', 'Pants, leg armor'),
('Foot Armor', 'FEET', 'Boots, shoes'),
('Hand Armor', 'HANDS', 'Gloves, gauntlets'),
('Main Hand Weapon', 'WEAPON', 'Primary weapon'),
('Off Hand Weapon', 'OFFHAND', 'Secondary weapon, shields'),
('Two-Hand Weapon', 'TWOHAND', 'Two-handed weapons'),
('Ring', 'RING', 'Rings'),
('Amulet', 'AMULET', 'Amulets, necklaces'),
('Trinket', 'TRINKET', 'Trinkets, charms'),
('Back', 'BACK', 'Cloaks, capes'),
('Ability', 'ABILITY', 'Ability-granting item slot/class'),
('Skill', 'SKILL', 'Skill-granting item slot/class');

-- ====================================================================================================
-- UTILITY FUNCTIONS
-- ====================================================================================================

-- Function to calculate item sell value (if not explicitly set)
CREATE OR REPLACE FUNCTION calculate_sell_value(p_item_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_gold_cost INTEGER;
    v_rarity_mult DECIMAL;
    v_sell_value INTEGER;
BEGIN
    SELECT i.gold_cost, COALESCE(r.gold_multiplier, 1.0)
    INTO v_gold_cost, v_rarity_mult
    FROM items i
    LEFT JOIN item_rarities r ON i.rarity_id = r.id
    WHERE i.id = p_item_id;
    
    -- Default sell value is 0.5 * gold_cost * rarity_multiplier
    v_sell_value := FLOOR(v_gold_cost * v_rarity_mult * 0.5);
    
    RETURN v_sell_value;
END;
$$ LANGUAGE plpgsql;

-- Function to get item by code
CREATE OR REPLACE FUNCTION get_item_by_code(p_item_code CHAR(4))
RETURNS TABLE (
    item_json JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT row_to_json(v.*)::JSONB
    FROM v_items_complete v
    WHERE v.item_code = p_item_code;
END;
$$ LANGUAGE plpgsql;

-- Function to search items
CREATE OR REPLACE FUNCTION search_items(
    p_search_term VARCHAR,
    p_type_id INTEGER DEFAULT NULL,
    p_rarity_id INTEGER DEFAULT NULL,
    p_min_level INTEGER DEFAULT 0,
    p_max_level INTEGER DEFAULT 1000
)
RETURNS TABLE (
    item_code CHAR(4),
    item_name VARCHAR,
    type_name VARCHAR,
    rarity_name VARCHAR,
    item_level INTEGER,
    gold_cost INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.item_code,
        v.item_name,
        v.type_name,
        v.rarity_name,
        v.item_level,
        v.gold_cost
    FROM v_items_complete v
    WHERE 
        (p_search_term IS NULL OR 
         v.item_name ILIKE '%' || p_search_term || '%' OR 
         v.description ILIKE '%' || p_search_term || '%')
        AND (p_type_id IS NULL OR v.type_id = p_type_id)
        AND (p_rarity_id IS NULL OR v.rarity_id = p_rarity_id)
        AND v.item_level BETWEEN p_min_level AND p_max_level
    ORDER BY v.item_level DESC, v.item_name;
END;
$$ LANGUAGE plpgsql;

-- ====================================================================================================
-- COMMENTS ON TABLES
-- ====================================================================================================

COMMENT ON TABLE items IS 'Main table storing all WC3 item data with support for DInventory and DEquipment subsystems';
COMMENT ON TABLE item_bonuses IS 'Additional bonuses and effects for items';
COMMENT ON TABLE item_requirements IS 'Requirements for equipping or using items';
COMMENT ON TABLE item_abilities IS 'WC3 abilities granted by items';
COMMENT ON TABLE item_sets IS 'Item set definitions';
COMMENT ON TABLE item_set_bonuses IS 'Set bonuses when wearing multiple pieces';
COMMENT ON TABLE import_history IS 'History of imports from WC3 World Editor';
COMMENT ON TABLE export_history IS 'History of exports to JASS or other formats';

-- ====================================================================================================
-- END OF SCHEMA
-- ====================================================================================================

-- Grant permissions (adjust username as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wc3_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO wc3_user;

VACUUM ANALYZE;
