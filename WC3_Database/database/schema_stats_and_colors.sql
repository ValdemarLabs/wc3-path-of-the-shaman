-- WC3 Item Manager - Stats and Color System
-- Adds stats, bonuses, and color customization to item manager

-- Stats/Attributes table
CREATE TABLE IF NOT EXISTS item_stats (
    id SERIAL PRIMARY KEY,
    stat_code VARCHAR(50) UNIQUE NOT NULL,
    stat_name VARCHAR(100) NOT NULL,
    stat_description TEXT,
    display_format VARCHAR(50) DEFAULT '{value}',  -- e.g., '+{value}', '{value}%'
    color_hex VARCHAR(7) DEFAULT '#FFFFFF',
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Item-Stats relationship (many-to-many)
CREATE TABLE IF NOT EXISTS item_stat_values (
    id SERIAL PRIMARY KEY,
    item_id INTEGER REFERENCES items(id) ON DELETE CASCADE,
    stat_id INTEGER REFERENCES item_stats(id) ON DELETE CASCADE,
    stat_value NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(item_id, stat_id)
);

-- Color scheme for UI elements
CREATE TABLE IF NOT EXISTS ui_color_scheme (
    id SERIAL PRIMARY KEY,
    element_type VARCHAR(50) NOT NULL,  -- 'rarity', 'class', 'stat', 'type'
    element_name VARCHAR(100) NOT NULL,
    color_hex VARCHAR(7) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(element_type, element_name)
);

-- Tooltip templates
CREATE TABLE IF NOT EXISTS tooltip_templates (
    id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) UNIQUE NOT NULL,
    template_type VARCHAR(50) NOT NULL,  -- 'tooltip_extended', 'description'
    template_text TEXT NOT NULL,
    description TEXT,
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default stats
INSERT INTO item_stats (stat_code, stat_name, stat_description, display_format, color_hex, display_order) VALUES
('str', 'Strength', 'Increases damage and HP', '+{value}', '#FF0000', 1),
('agi', 'Agility', 'Increases attack speed and armor', '+{value}', '#00FF00', 2),
('int', 'Intelligence', 'Increases mana and spell damage', '+{value}', '#0080FF', 3),
('hp', 'Health', 'Maximum health points', '+{value}', '#C41E3A', 4),
('mp', 'Mana', 'Maximum mana points', '+{value}', '#0070DD', 5),
('hp_regen', 'HP Regen', 'Health regeneration per second', '+{value}', '#FF69B4', 6),
('mp_regen', 'Mana Regen', 'Mana regeneration per second', '+{value}', '#9482C9', 7),
('dmg', 'Damage', 'Attack damage bonus', '+{value}', '#FFD700', 8),
('armor', 'Armor', 'Physical damage reduction', '+{value}', '#C0C0C0', 9),
('aspd', 'Attack Speed', 'Attack speed bonus', '+{value}%', '#FFFF00', 10),
('ms', 'Movement Speed', 'Movement speed bonus', '+{value}', '#00FFFF', 11),
('crit', 'Critical Chance', 'Chance to deal critical damage', '+{value}%', '#FF8C00', 12),
('critdmg', 'Critical Damage', 'Critical hit damage multiplier', '+{value}%', '#FF4500', 13),
('dodge', 'Dodge', 'Chance to dodge attacks', '+{value}%', '#32CD32', 14),
('block', 'Block', 'Chance to block attacks', '+{value}%', '#4682B4', 15),
('lifesteal', 'Lifesteal', 'Heal from damage dealt', '+{value}%', '#8B0000', 16),
('spell_power', 'Spell Power', 'Increases spell damage', '+{value}', '#9370DB', 17),
('fire_res', 'Fire Resistance', 'Reduces fire damage taken', '+{value}', '#FF4500', 18),
('cold_res', 'Cold Resistance', 'Reduces cold damage taken', '+{value}', '#00CED1', 19),
('lightning_res', 'Lightning Resistance', 'Reduces lightning damage taken', '+{value}', '#FFD700', 20),
('poison_res', 'Poison Resistance', 'Reduces poison damage taken', '+{value}', '#228B22', 21)
ON CONFLICT (stat_code) DO NOTHING;

-- Insert default color schemes for rarities
INSERT INTO ui_color_scheme (element_type, element_name, color_hex, description) VALUES
('rarity', 'Common', '#A9A9A9', 'Common item color (Gray)'),
('rarity', 'Uncommon', '#90EE90', 'Uncommon item color (Green)'),
('rarity', 'Rare', '#0080FF', 'Rare item color (Blue)'),
('rarity', 'Epic', '#800080', 'Epic item color (Purple)'),
('rarity', 'Legendary', '#FFB400', 'Legendary item color (Orange)'),
('class', 'Ability', '#00CED1', 'Ability items'),
('class', 'Skill', '#1E90FF', 'Skill items'),
('class', 'Quest', '#FFFF00', 'Quest items'),
('class', 'Miscellaneous', '#D3D3D3', 'Miscellaneous items'),
('class', 'Other', '#D3D3D3', 'Other items'),
('class', 'Head Armor', '#C0C0C0', 'Head armor items'),
('class', 'Chest Armor', '#B0C4DE', 'Chest armor items'),
('class', 'Leg Armor', '#A9B7C6', 'Leg armor items'),
('class', 'Foot Armor', '#CD853F', 'Foot armor items'),
('class', 'Hand Armor', '#DEB887', 'Hand armor items'),
('class', 'Main Hand Weapon', '#A52A2A', 'Main-hand weapon items'),
('class', 'Off Hand Weapon', '#8B4513', 'Off-hand weapon items'),
('class', 'Two-Hand Weapon', '#B22222', 'Two-hand weapon items'),
('class', 'Ring', '#FFD700', 'Ring items'),
('class', 'Amulet', '#40E0D0', 'Amulet items'),
('class', 'Trinket', '#DA70D6', 'Trinket items'),
('class', 'Back', '#708090', 'Back items'),
('class', 'MISC', '#CCCCCC', 'Miscellaneous items'),
('class', 'CONSUMABLE', '#90EE90', 'Consumable items'),
('class', 'ARTIFACT', '#FFB400', 'Artifact items'),
('class', 'QUEST', '#FFFF00', 'Quest items'),
('type', 'Weapon', '#FF6347', 'Weapon type items'),
('type', 'Armor', '#4682B4', 'Armor type items'),
('type', 'Accessory', '#9370DB', 'Accessory type items'),
('stat', 'positive', '#00FF00', 'Positive stat bonus'),
('stat', 'negative', '#FF0000', 'Negative stat penalty'),
('stat', 'neutral', '#FFFF00', 'Neutral stat')
ON CONFLICT (element_type, element_name) DO NOTHING;

-- Insert default tooltip templates
INSERT INTO tooltip_templates (template_name, template_type, template_text, is_default) VALUES
('default_extended', 'tooltip_extended', 
'|cFFFFD700{item_name}|r
|n|cFF808080Level {item_level}|r
|n
|n{stats_section}
|n
|n{special_abilities}',
true),
('default_description', 'description',
'{item_class} item from the {source_location}.
|n
|n{lore_text}
|n
|n|cFF808080"{flavor_text}"|r',
true)
ON CONFLICT (template_name) DO NOTHING;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_item_stat_values_item ON item_stat_values(item_id);
CREATE INDEX IF NOT EXISTS idx_item_stat_values_stat ON item_stat_values(stat_id);
CREATE INDEX IF NOT EXISTS idx_ui_color_scheme_type ON ui_color_scheme(element_type);

-- Add comments
COMMENT ON TABLE item_stats IS 'Available stats/attributes that can be assigned to items';
COMMENT ON TABLE item_stat_values IS 'Many-to-many relationship between items and stats';
COMMENT ON TABLE ui_color_scheme IS 'Hex color codes for UI elements (rarities, classes, stats, types)';
COMMENT ON TABLE tooltip_templates IS 'Templates for auto-generating tooltips and descriptions';

PRINT 'Stats and color system schema created successfully!';
