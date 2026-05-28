-- ====================================================================================================
-- WC3 BASE ITEMS TABLE
-- ====================================================================================================
-- Table containing vanilla Warcraft 3 base item IDs for reference
-- Used as dropdown selection when creating custom items

DROP TABLE IF EXISTS wc3_base_items CASCADE;

CREATE TABLE wc3_base_items (
    id SERIAL PRIMARY KEY,
    item_code VARCHAR(4) UNIQUE NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    item_type VARCHAR(50), -- 'Permanent', 'Charged', 'Powerup', 'Artifact', 'Purchasable', 'Campaign', 'Miscellaneous'
    description TEXT,
    is_common BOOLEAN DEFAULT false, -- Mark commonly used base items
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert common WC3 base items (most frequently used for custom items)
INSERT INTO wc3_base_items (item_code, item_name, item_type, is_common, description) VALUES
-- Artifacts (Permanent items)
('afac', 'Claws of Attack +15', 'Permanent', true, 'Common base for weapons'),
('rat3', 'Claws of Attack +3', 'Permanent', true, 'Low-level weapon base'),
('rat6', 'Claws of Attack +6', 'Permanent', true, 'Mid-level weapon base'),
('rat9', 'Claws of Attack +9', 'Permanent', true, 'High-level weapon base'),
('rhe1', 'Crown of Kings +5', 'Permanent', true, 'Common base for helmets'),
('rhe2', 'Crown of Kings +5', 'Permanent', false, 'Helmet base variant'),
('rhe3', 'Crown of Kings +5', 'Permanent', false, 'Helmet base variant'),
('rag1', 'Slippers of Agility +3', 'Permanent', true, 'Boots/footwear base'),
('rin1', 'Mantle of Intelligence +3', 'Permanent', true, 'Cloak/mantle base'),
('rspd', 'Boots of Speed', 'Permanent', true, 'Common boots base'),
('pghe', 'Periapt of Vitality', 'Permanent', true, 'Amulet/necklace base'),
('pnvu', 'Pendant of Energy', 'Permanent', true, 'Pendant base'),
('gold', 'Gold Coins', 'Permanent', true, 'Currency/gold base'),
('lmbr', 'Bundle of Lumber', 'Permanent', true, 'Currency/lumber base'),

-- Charged Items
('sres', 'Staff of Resurrection', 'Charged', true, 'Charged staff base'),
('sman', 'Staff of Sanctuary', 'Charged', true, 'Charged staff base'),
('ssil', 'Staff of Silence', 'Charged', false, 'Charged staff base'),
('stel', 'Staff of Teleportation', 'Charged', true, 'Teleport scroll base'),
('wtlg', 'Wand of Lightning Shield', 'Charged', false, 'Charged wand base'),

-- Consumables
('rej1', 'Lesser Clarity Potion', 'Charged', true, 'Mana potion base'),
('rej2', 'Clarity Potion', 'Charged', true, 'Mana potion base'),
('rej3', 'Greater Clarity Potion', 'Charged', true, 'Mana potion base'),
('rej4', 'Lesser Rejuvenation Potion', 'Charged', true, 'Health/Mana potion base'),
('rej5', 'Rejuvenation Potion', 'Charged', true, 'Health/Mana potion base'),
('rej6', 'Greater Rejuvenation Potion', 'Charged', true, 'Health/Mana potion base'),
('phea', 'Potion of Healing', 'Charged', true, 'Health potion base'),
('phe1', 'Lesser Healing Potion', 'Charged', true, 'Health potion base'),
('phe2', 'Potion of Greater Healing', 'Charged', true, 'Health potion base'),
('pinv', 'Potion of Invisibility', 'Charged', true, 'Invisibility potion base'),
('pspd', 'Potion of Speed', 'Charged', true, 'Speed potion base'),
('pmna', 'Potion of Mana', 'Charged', true, 'Mana potion base'),

-- Powerups (Temporary buffs)
('sor1', 'Scroll of Regeneration', 'Powerup', true, 'Regen scroll base'),
('sor2', 'Scroll of the Beast', 'Powerup', false, 'Buff scroll base'),
('sor3', 'Scroll of Speed', 'Powerup', false, 'Speed scroll base'),
('sor4', 'Scroll of Restoration', 'Powerup', false, 'Restoration scroll base'),
('sor5', 'Scroll of Healing', 'Powerup', true, 'Healing scroll base'),
('sor6', 'Scroll of Mana', 'Powerup', false, 'Mana scroll base'),
('sor7', 'Scroll of Protection', 'Powerup', true, 'Protection scroll base'),
('sora', 'Scroll of Town Portal', 'Powerup', true, 'Town portal base'),
('stwp', 'Scroll of Town Portal', 'Powerup', true, 'Town portal base (alternate)'),

-- Tomes (Stat books)
('tstr', 'Tome of Strength', 'Charged', true, 'Strength tome base'),
('tint', 'Tome of Intelligence', 'Charged', true, 'Intelligence tome base'),
('tagi', 'Tome of Agility', 'Charged', true, 'Agility tome base'),
('tkno', 'Tome of Knowledge', 'Charged', true, 'Experience tome base'),
('tpow', 'Tome of Power', 'Charged', false, 'Power tome base'),

-- Runes (Instant effects)
('rune', 'Rune of Healing', 'Powerup', true, 'Healing rune base'),
('rnsp', 'Rune of Speed', 'Powerup', false, 'Speed rune base'),
('rnsu', 'Rune of Lesser Healing', 'Powerup', false, 'Lesser healing rune base'),

-- Special/Quest items
('kybl', 'Key of Three Moons', 'Campaign', false, 'Quest key base'),
('ckng', 'Cheese', 'Campaign', false, 'Quest food base'),
('glsk', 'Gloves of Haste', 'Permanent', true, 'Gloves base'),
('gcel', 'Gem of True Seeing', 'Permanent', false, 'Gem/trinket base'),

-- Miscellaneous
('moon', 'Moonstone', 'Miscellaneous', false, 'Special stone base'),
('rnec', 'Necklace of Spell Immunity', 'Permanent', true, 'Immunity item base'),
('belv', 'Boots of Quel''Thalas +6', 'Permanent', false, 'Epic boots base'),
('desc', 'Kelen''s Dagger of Escape', 'Permanent', false, 'Mobility item base'),
('bspd', 'Boots of Speed', 'Permanent', true, 'Basic boots base'),
('ward', 'Warsong Battle Drums', 'Charged', false, 'Drums base'),

-- Common empties for custom items
('wolg', 'Wirt''s Other Leg', 'Permanent', false, 'Fun item base'),
('ches', 'Cheese', 'Charged', false, 'Food base'),
('very', 'Very Rare Item', 'Permanent', false, 'Generic rare base');

-- Create index for faster lookups
CREATE INDEX idx_base_items_common ON wc3_base_items(is_common);
CREATE INDEX idx_base_items_type ON wc3_base_items(item_type);
