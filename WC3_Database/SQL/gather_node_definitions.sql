-- ============================================================
-- GatherNodes Definitions & Spawn Points Data
-- Predefined herbs, veins, crystals for easy selection in Item Manager
-- ============================================================

-- ============================================================
-- Herb/Item Definitions - Template library for item-based nodes
-- ============================================================
CREATE TABLE IF NOT EXISTS gather_herb_definitions (
    id SERIAL PRIMARY KEY,
    item_code VARCHAR(4) NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) DEFAULT 'Herbs',
    description TEXT,
    suggested_respawn_min REAL DEFAULT 120.0,
    suggested_respawn_max REAL DEFAULT 300.0,
    suggested_skill INT DEFAULT 0,
    tier_level INT DEFAULT 1,
    display_order INT DEFAULT 0,
    UNIQUE(item_code)
);

-- ============================================================
-- Vein/Unit Definitions - Template library for unit-based nodes
-- ============================================================
CREATE TABLE IF NOT EXISTS gather_vein_definitions (
    id SERIAL PRIMARY KEY,
    unit_code VARCHAR(4) NOT NULL,
    unit_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) DEFAULT 'Ore Veins',
    description TEXT,
    suggested_glow_r INT DEFAULT 255,
    suggested_glow_g INT DEFAULT 200,
    suggested_glow_b INT DEFAULT 0,
    suggested_respawn_min REAL DEFAULT 180.0,
    suggested_respawn_max REAL DEFAULT 400.0,
    suggested_skill INT DEFAULT 0,
    tier_level INT DEFAULT 1,
    display_order INT DEFAULT 0,
    UNIQUE(unit_code)
);

-- ============================================================
-- Insert Predefined Herb/Item Definitions
-- ============================================================
INSERT INTO gather_herb_definitions (item_code, item_name, category, tier_level, display_order, description) VALUES
    -- Common Herbs (Tier 1) - Zones 1-10
    ('I0AA', 'Agave', 'Herbs', 1, 1, 'Common desert succulent'),
    ('I0AB', 'Earth Roots', 'Herbs', 1, 2, 'Basic herb found near trees'),
    ('I0AC', 'Forest Flower', 'Flowers', 1, 3, 'Common wildflower'),
    ('I0AD', 'Wild Mint', 'Herbs', 1, 4, 'Aromatic herb'),
    ('I0AE', 'Silverleaf', 'Herbs', 1, 5, 'Silver-tinged herb'),
    ('I0AF', 'Peacebloom', 'Herbs', 1, 6, 'Calming white flower'),
    ('I0AG', 'Earthroot', 'Herbs', 1, 7, 'Root herb'),
    ('I0AH', 'Mageroyal', 'Herbs', 2, 8, 'Magical purple herb'),
    
    -- Uncommon Herbs (Tier 2) - Zones 8-15
    ('I0BA', 'Briarthorn', 'Herbs', 2, 10, 'Thorny herb'),
    ('I0BB', 'Stranglekelp', 'Herbs', 2, 11, 'Aquatic herb'),
    ('I0BC', 'Bruiseweed', 'Herbs', 2, 12, 'Purple medicinal herb'),
    ('I0BD', 'Wild Steelbloom', 'Herbs', 2, 13, 'Metallic petaled flower'),
    ('I0BE', 'Grave Moss', 'Herbs', 2, 14, 'Found in graveyards'),
    ('I0BF', 'Kingsblood', 'Flowers', 2, 15, 'Royal crimson flower'),
    
    -- Rare Herbs (Tier 3) - Zones 15-25
    ('I0CA', 'Liferoot', 'Rare Herbs', 3, 20, 'Near water sources'),
    ('I0CB', 'Fadeleaf', 'Rare Herbs', 3, 21, 'Shadow-touched herb'),
    ('I0CC', 'Goldthorn', 'Rare Herbs', 3, 22, 'Golden thorned plant'),
    ('I0CD', 'Khadgars Whisker', 'Rare Herbs', 3, 23, 'Magical energized herb'),
    ('I0CE', 'Wintersbite', 'Rare Herbs', 3, 24, 'Cold climate herb'),
    ('I0CF', 'Firebloom', 'Rare Herbs', 3, 25, 'Volcanic region herb'),
    
    -- Epic Herbs (Tier 4) - Zones 25-35
    ('I0DA', 'Sungrass', 'Rare Herbs', 4, 30, 'Sun-infused herb'),
    ('I0DB', 'Blindweed', 'Rare Herbs', 4, 31, 'Found in darkness'),
    ('I0DC', 'Ghost Mushroom', 'Mushrooms', 4, 32, 'Rare luminescent fungus'),
    ('I0DD', 'Gromsblood', 'Rare Herbs', 4, 33, 'Blood-red powerful herb'),
    ('I0DE', 'Purple Lotus', 'Flowers', 4, 34, 'Exotic purple flower'),
    ('I0DF', 'Arthas Tears', 'Flowers', 4, 35, 'Frozen tear-shaped flower'),
    
    -- Common Mushrooms (Tier 1-2)
    ('I0MA', 'Common Mushroom', 'Mushrooms', 1, 40, 'Basic edible mushroom'),
    ('I0MB', 'Brown Cap', 'Mushrooms', 1, 41, 'Forest floor mushroom'),
    ('I0MC', 'Shimmercap', 'Mushrooms', 2, 42, 'Glowing cave mushroom'),
    ('I0MD', 'Nightcap', 'Mushrooms', 2, 43, 'Dark environment mushroom'),
    
    -- Reagents
    ('I0RA', 'Crystal Shard', 'Reagents', 2, 50, 'Magical crafting reagent'),
    ('I0RB', 'Elemental Dust', 'Reagents', 2, 51, 'Elemental residue'),
    ('I0RC', 'Arcane Crystal', 'Reagents', 3, 52, 'High-power reagent'),
    ('I0RD', 'Dragon Scale Fragment', 'Reagents', 4, 53, 'Rare dragon material')
ON CONFLICT (item_code) DO NOTHING;

-- ============================================================
-- Insert Predefined Vein/Unit Definitions
-- From GatherNodes_oldGUI.txt
-- ============================================================
INSERT INTO gather_vein_definitions (unit_code, unit_name, category, tier_level, display_order, description, suggested_glow_r, suggested_glow_g, suggested_glow_b) VALUES
    -- Copper Ore (Tier 1) - Zones 1-10
    ('n001', 'Copper Vein', 'Ore Veins', 1, 1, 'Basic copper ore node', 184, 115, 51),
    ('n002', 'Copper Vein 2', 'Ore Veins', 1, 2, 'Copper ore variant', 184, 115, 51),
    ('n003', 'Copper Deposit', 'Ore Veins', 1, 3, 'Large copper deposit', 184, 115, 51),
    
    -- Tin Ore (Tier 1) - Zones 1-10
    ('n004', 'Tin Vein', 'Ore Veins', 1, 4, 'Basic tin ore node', 200, 200, 200),
    ('n005', 'Tin Vein 2', 'Ore Veins', 1, 5, 'Tin ore variant', 200, 200, 200),
    ('n006', 'Tin Deposit', 'Ore Veins', 1, 6, 'Large tin deposit', 200, 200, 200),
    
    -- Silver Ore (Tier 2) - Zones 5-15
    ('n007', 'Silver Vein', 'Ore Veins', 2, 7, 'Silver ore node', 192, 192, 192),
    ('n008', 'Silver Vein 2', 'Ore Veins', 2, 8, 'Silver ore variant', 192, 192, 192),
    ('n009', 'Silver Deposit', 'Rich Veins', 2, 9, 'Rich silver deposit', 220, 220, 220),
    
    -- Iron Ore (Tier 2) - Zones 8-18
    ('n010', 'Iron Vein', 'Ore Veins', 2, 10, 'Iron ore node', 139, 90, 43),
    ('n011', 'Iron Vein 2', 'Ore Veins', 2, 11, 'Iron ore variant', 139, 90, 43),
    ('n012', 'Iron Deposit', 'Rich Veins', 2, 12, 'Rich iron deposit', 160, 100, 50),
    
    -- Gold Ore (Tier 3) - Zones 10-20
    ('n013', 'Gold Vein', 'Ore Veins', 3, 13, 'Gold ore node', 255, 215, 0),
    ('n014', 'Gold Vein 2', 'Ore Veins', 3, 14, 'Gold ore variant', 255, 215, 0),
    ('n015', 'Gold Deposit', 'Rich Veins', 3, 15, 'Rich gold deposit', 255, 230, 50),
    
    -- Mithril Ore (Tier 3) - Zones 15-25
    ('n016', 'Mithril Vein', 'Ore Veins', 3, 16, 'Mithril ore node', 100, 149, 237),
    ('n017', 'Mithril Vein 2', 'Ore Veins', 3, 17, 'Mithril ore variant', 100, 149, 237),
    ('n018', 'Mithril Deposit', 'Rich Veins', 3, 18, 'Rich mithril deposit', 120, 170, 255),
    
    -- Thorium Ore (Tier 4) - Zones 20-30
    ('n019', 'Thorium Vein', 'Ore Veins', 4, 19, 'Thorium ore node', 50, 50, 50),
    ('n020', 'Thorium Vein 2', 'Ore Veins', 4, 20, 'Thorium ore variant', 50, 50, 50),
    ('n021', 'Rich Thorium Vein', 'Rich Veins', 4, 21, 'Rich thorium deposit', 80, 80, 80),
    
    -- Truesilver Ore (Tier 4) - Zones 20-30
    ('n022', 'Truesilver Vein', 'Ore Veins', 4, 22, 'Truesilver ore node', 176, 196, 222),
    ('n023', 'Truesilver Deposit', 'Rich Veins', 4, 23, 'Rich truesilver', 200, 220, 255),
    
    -- Adamantite Ore (Tier 5) - Zones 25-35
    ('n024', 'Adamantite Vein', 'Ore Veins', 5, 24, 'Adamantite ore node', 0, 100, 0),
    ('n025', 'Rich Adamantite', 'Rich Veins', 5, 25, 'Rich adamantite', 0, 150, 0),
    
    -- Red Crystals
    ('n030', 'Red Crystal', 'Crystal Veins', 2, 30, 'Red crystal formation', 255, 50, 50),
    ('n031', 'Red Crystal Cluster', 'Crystal Veins', 2, 31, 'Large red crystals', 255, 80, 80),
    ('n032', 'Blood Crystal', 'Crystal Veins', 3, 32, 'Dark red crystal', 180, 0, 0),
    
    -- Blue Crystals  
    ('n033', 'Blue Crystal', 'Crystal Veins', 2, 33, 'Blue crystal formation', 50, 100, 255),
    ('n034', 'Blue Crystal Cluster', 'Crystal Veins', 2, 34, 'Large blue crystals', 80, 130, 255),
    ('n035', 'Azure Crystal', 'Crystal Veins', 3, 35, 'Azure magical crystal', 0, 80, 220),
    
    -- Green Crystals
    ('n036', 'Green Crystal', 'Crystal Veins', 2, 36, 'Green crystal formation', 50, 255, 100),
    ('n037', 'Green Crystal Cluster', 'Crystal Veins', 2, 37, 'Large green crystals', 80, 255, 130),
    ('n038', 'Emerald Crystal', 'Crystal Veins', 3, 38, 'Deep emerald crystal', 0, 180, 80),
    
    -- Yellow/Orange Crystals
    ('n039', 'Yellow Crystal', 'Crystal Veins', 2, 39, 'Yellow crystal formation', 255, 255, 50),
    ('n040', 'Orange Crystal', 'Crystal Veins', 2, 40, 'Orange crystal cluster', 255, 150, 50),
    ('n041', 'Amber Crystal', 'Crystal Veins', 3, 41, 'Ancient amber crystal', 255, 180, 0),
    
    -- Purple/Arcane Crystals
    ('n042', 'Purple Crystal', 'Crystal Veins', 3, 42, 'Purple magical crystal', 150, 50, 255),
    ('n043', 'Arcane Crystal', 'Crystal Veins', 4, 43, 'High arcane crystal', 200, 100, 255),
    ('n044', 'Void Crystal', 'Crystal Veins', 5, 44, 'Void-touched crystal', 100, 0, 150),
    
    -- Fish Pools
    ('n050', 'Fish Pool', 'Fish Pools', 1, 50, 'Common fishing spot', 0, 150, 255),
    ('n051', 'Deep Pool', 'Fish Pools', 2, 51, 'Deep water fishing', 0, 100, 200),
    ('n052', 'Rare Fish School', 'Fish Pools', 3, 52, 'Rare fish location', 0, 200, 200),
    ('n053', 'Salmon Pool', 'Fish Pools', 2, 53, 'Salmon fishing spot', 255, 100, 100),
    ('n054', 'Lobster Trap', 'Fish Pools', 3, 54, 'Coastal lobster area', 255, 80, 50),
    
    -- Treasure Chests
    ('n060', 'Wooden Chest', 'Treasure Chests', 1, 60, 'Basic wooden chest', 139, 90, 43),
    ('n061', 'Iron Chest', 'Treasure Chests', 2, 61, 'Reinforced iron chest', 105, 105, 105),
    ('n062', 'Golden Chest', 'Treasure Chests', 3, 62, 'Valuable gold chest', 255, 215, 0),
    ('n063', 'Ancient Chest', 'Treasure Chests', 4, 63, 'Ancient treasure', 100, 80, 60),
    ('n064', 'Locked Strongbox', 'Treasure Chests', 3, 64, 'Requires lockpicking', 80, 80, 80),
    
    -- Rare Spawns
    ('n070', 'Rare Herb Node', 'Rare Spawns', 3, 70, 'Very rare herb spawn', 255, 255, 150),
    ('n071', 'Rich Mineral Vein', 'Rare Spawns', 4, 71, 'Rich multi-mineral', 200, 200, 255),
    ('n072', 'Magical Essence', 'Rare Spawns', 4, 72, 'Pure magical energy', 255, 100, 255),
    ('n073', 'Dragon Hoard', 'Rare Spawns', 5, 73, 'Rare dragon treasure', 255, 200, 50)
ON CONFLICT (unit_code) DO NOTHING;

-- ============================================================
-- Insert Spawn Points from Old GUI (Ore Regions by Zone)
-- ============================================================

-- Zone 1: Twilight Grove - Regions 1-12
INSERT INTO gather_spawn_points (zone_id, zone_name, point_name, region_variable, node_type, spawn_point_index) VALUES
    (1, 'Twilight Grove', 'Ore Vein 0001', 'gg_rct_OreVeins0001', 'unit', 1),
    (1, 'Twilight Grove', 'Ore Vein 0002', 'gg_rct_OreVeins0002', 'unit', 2),
    (1, 'Twilight Grove', 'Ore Vein 0003', 'gg_rct_OreVeins0003', 'unit', 3),
    (1, 'Twilight Grove', 'Ore Vein 0004', 'gg_rct_OreVeins0004', 'unit', 4),
    (1, 'Twilight Grove', 'Ore Vein 0005', 'gg_rct_OreVeins0005', 'unit', 5),
    (1, 'Twilight Grove', 'Ore Vein 0006', 'gg_rct_OreVeins0006', 'unit', 6),
    (1, 'Twilight Grove', 'Ore Vein 0007', 'gg_rct_OreVeins0007', 'unit', 7),
    (1, 'Twilight Grove', 'Ore Vein 0008', 'gg_rct_OreVeins0008', 'unit', 8),
    (1, 'Twilight Grove', 'Ore Vein 0009', 'gg_rct_OreVeins0009', 'unit', 9),
    (1, 'Twilight Grove', 'Ore Vein 0010', 'gg_rct_OreVeins0010', 'unit', 10),
    (1, 'Twilight Grove', 'Ore Vein 0011', 'gg_rct_OreVeins0011', 'unit', 11),
    (1, 'Twilight Grove', 'Ore Vein 0012', 'gg_rct_OreVeins0012', 'unit', 12)
ON CONFLICT (region_variable) DO NOTHING;

-- Zone 2: Sereneglade - Regions 13-50  
INSERT INTO gather_spawn_points (zone_id, zone_name, point_name, region_variable, node_type, spawn_point_index) VALUES
    (2, 'Sereneglade', 'Ore Vein 0013', 'gg_rct_OreVeins0013', 'unit', 13),
    (2, 'Sereneglade', 'Ore Vein 0014', 'gg_rct_OreVeins0014', 'unit', 14),
    (2, 'Sereneglade', 'Ore Vein 0015', 'gg_rct_OreVeins0015', 'unit', 15),
    (2, 'Sereneglade', 'Ore Vein 0016', 'gg_rct_OreVeins0016', 'unit', 16),
    (2, 'Sereneglade', 'Ore Vein 0017', 'gg_rct_OreVeins0017', 'unit', 17),
    (2, 'Sereneglade', 'Ore Vein 0018', 'gg_rct_OreVeins0018', 'unit', 18),
    (2, 'Sereneglade', 'Ore Vein 0019', 'gg_rct_OreVeins0019', 'unit', 19),
    (2, 'Sereneglade', 'Ore Vein 0020', 'gg_rct_OreVeins0020', 'unit', 20),
    (2, 'Sereneglade', 'Ore Vein 0021', 'gg_rct_OreVeins0021', 'unit', 21),
    (2, 'Sereneglade', 'Ore Vein 0022', 'gg_rct_OreVeins0022', 'unit', 22),
    (2, 'Sereneglade', 'Ore Vein 0023', 'gg_rct_OreVeins0023', 'unit', 23),
    (2, 'Sereneglade', 'Ore Vein 0024', 'gg_rct_OreVeins0024', 'unit', 24),
    (2, 'Sereneglade', 'Ore Vein 0025', 'gg_rct_OreVeins0025', 'unit', 25),
    (2, 'Sereneglade', 'Ore Vein 0026', 'gg_rct_OreVeins0026', 'unit', 26),
    (2, 'Sereneglade', 'Ore Vein 0027', 'gg_rct_OreVeins0027', 'unit', 27),
    (2, 'Sereneglade', 'Ore Vein 0028', 'gg_rct_OreVeins0028', 'unit', 28),
    (2, 'Sereneglade', 'Ore Vein 0029', 'gg_rct_OreVeins0029', 'unit', 29),
    (2, 'Sereneglade', 'Ore Vein 0030', 'gg_rct_OreVeins0030', 'unit', 30),
    (2, 'Sereneglade', 'Ore Vein 0031', 'gg_rct_OreVeins0031', 'unit', 31),
    (2, 'Sereneglade', 'Ore Vein 0032', 'gg_rct_OreVeins0032', 'unit', 32),
    (2, 'Sereneglade', 'Ore Vein 0033', 'gg_rct_OreVeins0033', 'unit', 33),
    (2, 'Sereneglade', 'Ore Vein 0034', 'gg_rct_OreVeins0034', 'unit', 34),
    (2, 'Sereneglade', 'Ore Vein 0035', 'gg_rct_OreVeins0035', 'unit', 35),
    (2, 'Sereneglade', 'Ore Vein 0036', 'gg_rct_OreVeins0036', 'unit', 36),
    (2, 'Sereneglade', 'Ore Vein 0037', 'gg_rct_OreVeins0037', 'unit', 37),
    (2, 'Sereneglade', 'Ore Vein 0038', 'gg_rct_OreVeins0038', 'unit', 38),
    (2, 'Sereneglade', 'Ore Vein 0039', 'gg_rct_OreVeins0039', 'unit', 39),
    (2, 'Sereneglade', 'Ore Vein 0040', 'gg_rct_OreVeins0040', 'unit', 40),
    (2, 'Sereneglade', 'Ore Vein 0041', 'gg_rct_OreVeins0041', 'unit', 41),
    (2, 'Sereneglade', 'Ore Vein 0042', 'gg_rct_OreVeins0042', 'unit', 42),
    (2, 'Sereneglade', 'Ore Vein 0043', 'gg_rct_OreVeins0043', 'unit', 43),
    (2, 'Sereneglade', 'Ore Vein 0045', 'gg_rct_OreVeins0045', 'unit', 44),
    (2, 'Sereneglade', 'Ore Vein 0046', 'gg_rct_OreVeins0046', 'unit', 45),
    (2, 'Sereneglade', 'Ore Vein 0047', 'gg_rct_OreVeins0047', 'unit', 46),
    (2, 'Sereneglade', 'Ore Vein 0048', 'gg_rct_OreVeins0048', 'unit', 47),
    (2, 'Sereneglade', 'Ore Vein 0049', 'gg_rct_OreVeins0049', 'unit', 48),
    (2, 'Sereneglade', 'Ore Vein 0050', 'gg_rct_OreVeins0050', 'unit', 49),
    (2, 'Sereneglade', 'Ore Vein 0051', 'gg_rct_OreVeins0051', 'unit', 50)
ON CONFLICT (region_variable) DO NOTHING;

-- Zone 4: Thornwoods - Regions 101-133
INSERT INTO gather_spawn_points (zone_id, zone_name, point_name, region_variable, node_type, spawn_point_index) VALUES
    (4, 'Thornwoods', 'Ore Vein 0101', 'gg_rct_OreVeins0101', 'unit', 101),
    (4, 'Thornwoods', 'Ore Vein 0102', 'gg_rct_OreVeins0102', 'unit', 102),
    (4, 'Thornwoods', 'Ore Vein 0103', 'gg_rct_OreVeins0103', 'unit', 103),
    (4, 'Thornwoods', 'Ore Vein 0104', 'gg_rct_OreVeins0104', 'unit', 104),
    (4, 'Thornwoods', 'Ore Vein 0105', 'gg_rct_OreVeins0105', 'unit', 105),
    (4, 'Thornwoods', 'Ore Vein 0106', 'gg_rct_OreVeins0106', 'unit', 106),
    (4, 'Thornwoods', 'Ore Vein 0107', 'gg_rct_OreVeins0107', 'unit', 107),
    (4, 'Thornwoods', 'Ore Vein 0108', 'gg_rct_OreVeins0108', 'unit', 108),
    (4, 'Thornwoods', 'Ore Vein 0109', 'gg_rct_OreVeins0109', 'unit', 109),
    (4, 'Thornwoods', 'Ore Vein 0110', 'gg_rct_OreVeins0110', 'unit', 110),
    (4, 'Thornwoods', 'Ore Vein 0111', 'gg_rct_OreVeins0111', 'unit', 111),
    (4, 'Thornwoods', 'Ore Vein 0112', 'gg_rct_OreVeins0112', 'unit', 112),
    (4, 'Thornwoods', 'Ore Vein 0113', 'gg_rct_OreVeins0113', 'unit', 113),
    (4, 'Thornwoods', 'Ore Vein 0114', 'gg_rct_OreVeins0114', 'unit', 114),
    (4, 'Thornwoods', 'Ore Vein 0115', 'gg_rct_OreVeins0115', 'unit', 115),
    (4, 'Thornwoods', 'Ore Vein 0116', 'gg_rct_OreVeins0116', 'unit', 116),
    (4, 'Thornwoods', 'Ore Vein 0117', 'gg_rct_OreVeins0117', 'unit', 117),
    (4, 'Thornwoods', 'Ore Vein 0118', 'gg_rct_OreVeins0118', 'unit', 118),
    (4, 'Thornwoods', 'Ore Vein 0119', 'gg_rct_OreVeins0119', 'unit', 119),
    (4, 'Thornwoods', 'Ore Vein 0120', 'gg_rct_OreVeins0120', 'unit', 120),
    (4, 'Thornwoods', 'Ore Vein 0121', 'gg_rct_OreVeins0121', 'unit', 121),
    (4, 'Thornwoods', 'Ore Vein 0122', 'gg_rct_OreVeins0122', 'unit', 122),
    (4, 'Thornwoods', 'Ore Vein 0123', 'gg_rct_OreVeins0123', 'unit', 123),
    (4, 'Thornwoods', 'Ore Vein 0124', 'gg_rct_OreVeins0124', 'unit', 124),
    (4, 'Thornwoods', 'Ore Vein 0125', 'gg_rct_OreVeins0125', 'unit', 125),
    (4, 'Thornwoods', 'Ore Vein 0126', 'gg_rct_OreVeins0126', 'unit', 126),
    (4, 'Thornwoods', 'Ore Vein 0127', 'gg_rct_OreVeins0127', 'unit', 127),
    (4, 'Thornwoods', 'Ore Vein 0128', 'gg_rct_OreVeins0128', 'unit', 128),
    (4, 'Thornwoods', 'Ore Vein 0129', 'gg_rct_OreVeins0129', 'unit', 129),
    (4, 'Thornwoods', 'Ore Vein 0130', 'gg_rct_OreVeins0130', 'unit', 130),
    (4, 'Thornwoods', 'Ore Vein 0131', 'gg_rct_OreVeins0131', 'unit', 131),
    (4, 'Thornwoods', 'Ore Vein 0132', 'gg_rct_OreVeins0132', 'unit', 132),
    (4, 'Thornwoods', 'Ore Vein 0133', 'gg_rct_OreVeins0133', 'unit', 133)
ON CONFLICT (region_variable) DO NOTHING;

-- Zone 3: Emberpeak Highlands - Regions 201-231
INSERT INTO gather_spawn_points (zone_id, zone_name, point_name, region_variable, node_type, spawn_point_index) VALUES
    (3, 'Emberpeak Highlands', 'Ore Vein 0201', 'gg_rct_OreVeins0201', 'unit', 201),
    (3, 'Emberpeak Highlands', 'Ore Vein 0202', 'gg_rct_OreVeins0202', 'unit', 202),
    (3, 'Emberpeak Highlands', 'Ore Vein 0203', 'gg_rct_OreVeins0203', 'unit', 203),
    (3, 'Emberpeak Highlands', 'Ore Vein 0204', 'gg_rct_OreVeins0204', 'unit', 204),
    (3, 'Emberpeak Highlands', 'Ore Vein 0205', 'gg_rct_OreVeins0205', 'unit', 205),
    (3, 'Emberpeak Highlands', 'Ore Vein 0206', 'gg_rct_OreVeins0206', 'unit', 206),
    (3, 'Emberpeak Highlands', 'Ore Vein 0207', 'gg_rct_OreVeins0207', 'unit', 207),
    (3, 'Emberpeak Highlands', 'Ore Vein 0208', 'gg_rct_OreVeins0208', 'unit', 208),
    (3, 'Emberpeak Highlands', 'Ore Vein 0209', 'gg_rct_OreVeins0209', 'unit', 209),
    (3, 'Emberpeak Highlands', 'Ore Vein 0210', 'gg_rct_OreVeins0210', 'unit', 210),
    (3, 'Emberpeak Highlands', 'Ore Vein 0211', 'gg_rct_OreVeins0211', 'unit', 211),
    (3, 'Emberpeak Highlands', 'Ore Vein 0212', 'gg_rct_OreVeins0212', 'unit', 212),
    (3, 'Emberpeak Highlands', 'Ore Vein 0213', 'gg_rct_OreVeins0213', 'unit', 213),
    (3, 'Emberpeak Highlands', 'Ore Vein 0214', 'gg_rct_OreVeins0214', 'unit', 214),
    (3, 'Emberpeak Highlands', 'Ore Vein 0215', 'gg_rct_OreVeins0215', 'unit', 215),
    (3, 'Emberpeak Highlands', 'Ore Vein 0216', 'gg_rct_OreVeins0216', 'unit', 216),
    (3, 'Emberpeak Highlands', 'Ore Vein 0217', 'gg_rct_OreVeins0217', 'unit', 217),
    (3, 'Emberpeak Highlands', 'Ore Vein 0218', 'gg_rct_OreVeins0218', 'unit', 218),
    (3, 'Emberpeak Highlands', 'Ore Vein 0219', 'gg_rct_OreVeins0219', 'unit', 219),
    (3, 'Emberpeak Highlands', 'Ore Vein 0220', 'gg_rct_OreVeins0220', 'unit', 220),
    (3, 'Emberpeak Highlands', 'Ore Vein 0221', 'gg_rct_OreVeins0221', 'unit', 221),
    (3, 'Emberpeak Highlands', 'Ore Vein 0222', 'gg_rct_OreVeins0222', 'unit', 222),
    (3, 'Emberpeak Highlands', 'Ore Vein 0223', 'gg_rct_OreVeins0223', 'unit', 223),
    (3, 'Emberpeak Highlands', 'Ore Vein 0224', 'gg_rct_OreVeins0224', 'unit', 224),
    (3, 'Emberpeak Highlands', 'Ore Vein 0225', 'gg_rct_OreVeins0225', 'unit', 225),
    (3, 'Emberpeak Highlands', 'Ore Vein 0226', 'gg_rct_OreVeins0226', 'unit', 226),
    (3, 'Emberpeak Highlands', 'Ore Vein 0227', 'gg_rct_OreVeins0227', 'unit', 227),
    (3, 'Emberpeak Highlands', 'Ore Vein 0228', 'gg_rct_OreVeins0228', 'unit', 228),
    (3, 'Emberpeak Highlands', 'Ore Vein 0229', 'gg_rct_OreVeins0229', 'unit', 229),
    (3, 'Emberpeak Highlands', 'Ore Vein 0230', 'gg_rct_OreVeins0230', 'unit', 230),
    (3, 'Emberpeak Highlands', 'Ore Vein 0231', 'gg_rct_OreVeins0231', 'unit', 231)
ON CONFLICT (region_variable) DO NOTHING;

-- Zone 10: Riverbane - Regions 232-285
INSERT INTO gather_spawn_points (zone_id, zone_name, point_name, region_variable, node_type, spawn_point_index) VALUES
    (10, 'Riverbane', 'Ore Vein 0232', 'gg_rct_OreVeins0232', 'unit', 232),
    (10, 'Riverbane', 'Ore Vein 0233', 'gg_rct_OreVeins0233', 'unit', 233),
    (10, 'Riverbane', 'Ore Vein 0234', 'gg_rct_OreVeins0234', 'unit', 234),
    (10, 'Riverbane', 'Ore Vein 0235', 'gg_rct_OreVeins0235', 'unit', 235),
    (10, 'Riverbane', 'Ore Vein 0236', 'gg_rct_OreVeins0236', 'unit', 236),
    (10, 'Riverbane', 'Ore Vein 0237', 'gg_rct_OreVeins0237', 'unit', 237),
    (10, 'Riverbane', 'Ore Vein 0238', 'gg_rct_OreVeins0238', 'unit', 238),
    (10, 'Riverbane', 'Ore Vein 0239', 'gg_rct_OreVeins0239', 'unit', 239),
    (10, 'Riverbane', 'Ore Vein 0240', 'gg_rct_OreVeins0240', 'unit', 240),
    (10, 'Riverbane', 'Ore Vein 0241', 'gg_rct_OreVeins0241', 'unit', 241),
    (10, 'Riverbane', 'Ore Vein 0242', 'gg_rct_OreVeins0242', 'unit', 242),
    (10, 'Riverbane', 'Ore Vein 0243', 'gg_rct_OreVeins0243', 'unit', 243),
    (10, 'Riverbane', 'Ore Vein 0244', 'gg_rct_OreVeins0244', 'unit', 244),
    (10, 'Riverbane', 'Ore Vein 0245', 'gg_rct_OreVeins0245', 'unit', 245),
    (10, 'Riverbane', 'Ore Vein 0246', 'gg_rct_OreVeins0246', 'unit', 246),
    (10, 'Riverbane', 'Ore Vein 0247', 'gg_rct_OreVeins0247', 'unit', 247),
    (10, 'Riverbane', 'Ore Vein 0248', 'gg_rct_OreVeins0248', 'unit', 248),
    (10, 'Riverbane', 'Ore Vein 0249', 'gg_rct_OreVeins0249', 'unit', 249),
    (10, 'Riverbane', 'Ore Vein 0250', 'gg_rct_OreVeins0250', 'unit', 250),
    (10, 'Riverbane', 'Ore Vein 0251', 'gg_rct_OreVeins0251', 'unit', 251),
    (10, 'Riverbane', 'Ore Vein 0252', 'gg_rct_OreVeins0252', 'unit', 252),
    (10, 'Riverbane', 'Ore Vein 0253', 'gg_rct_OreVeins0253', 'unit', 253),
    (10, 'Riverbane', 'Ore Vein 0254', 'gg_rct_OreVeins0254', 'unit', 254),
    (10, 'Riverbane', 'Ore Vein 0255', 'gg_rct_OreVeins0255', 'unit', 255),
    (10, 'Riverbane', 'Ore Vein 0256', 'gg_rct_OreVeins0256', 'unit', 256),
    (10, 'Riverbane', 'Ore Vein 0257', 'gg_rct_OreVeins0257', 'unit', 257),
    (10, 'Riverbane', 'Ore Vein 0258', 'gg_rct_OreVeins0258', 'unit', 258),
    (10, 'Riverbane', 'Ore Vein 0259', 'gg_rct_OreVeins0259', 'unit', 259),
    (10, 'Riverbane', 'Ore Vein 0260', 'gg_rct_OreVeins0260', 'unit', 260),
    (10, 'Riverbane', 'Ore Vein 0261', 'gg_rct_OreVeins0261', 'unit', 261),
    (10, 'Riverbane', 'Ore Vein 0262', 'gg_rct_OreVeins0262', 'unit', 262),
    (10, 'Riverbane', 'Ore Vein 0263', 'gg_rct_OreVeins0263', 'unit', 263),
    (10, 'Riverbane', 'Ore Vein 0264', 'gg_rct_OreVeins0264', 'unit', 264),
    (10, 'Riverbane', 'Ore Vein 0265', 'gg_rct_OreVeins0265', 'unit', 265),
    (10, 'Riverbane', 'Ore Vein 0266', 'gg_rct_OreVeins0266', 'unit', 266),
    (10, 'Riverbane', 'Ore Vein 0267', 'gg_rct_OreVeins0267', 'unit', 267),
    (10, 'Riverbane', 'Ore Vein 0268', 'gg_rct_OreVeins0268', 'unit', 268),
    (10, 'Riverbane', 'Ore Vein 0269', 'gg_rct_OreVeins0269', 'unit', 269),
    (10, 'Riverbane', 'Ore Vein 0270', 'gg_rct_OreVeins0270', 'unit', 270),
    (10, 'Riverbane', 'Ore Vein 0271', 'gg_rct_OreVeins0271', 'unit', 271),
    (10, 'Riverbane', 'Ore Vein 0272', 'gg_rct_OreVeins0272', 'unit', 272),
    (10, 'Riverbane', 'Ore Vein 0273', 'gg_rct_OreVeins0273', 'unit', 273),
    (10, 'Riverbane', 'Ore Vein 0274', 'gg_rct_OreVeins0274', 'unit', 274),
    (10, 'Riverbane', 'Ore Vein 0275', 'gg_rct_OreVeins0275', 'unit', 275),
    (10, 'Riverbane', 'Ore Vein 0276', 'gg_rct_OreVeins0276', 'unit', 276),
    (10, 'Riverbane', 'Ore Vein 0277', 'gg_rct_OreVeins0277', 'unit', 277),
    (10, 'Riverbane', 'Ore Vein 0278', 'gg_rct_OreVeins0278', 'unit', 278),
    (10, 'Riverbane', 'Ore Vein 0279', 'gg_rct_OreVeins0279', 'unit', 279),
    (10, 'Riverbane', 'Ore Vein 0280', 'gg_rct_OreVeins0280', 'unit', 280),
    (10, 'Riverbane', 'Ore Vein 0281', 'gg_rct_OreVeins0281', 'unit', 281),
    (10, 'Riverbane', 'Ore Vein 0282', 'gg_rct_OreVeins0282', 'unit', 282),
    (10, 'Riverbane', 'Ore Vein 0283', 'gg_rct_OreVeins0283', 'unit', 283),
    (10, 'Riverbane', 'Ore Vein 0284', 'gg_rct_OreVeins0284', 'unit', 284),
    (10, 'Riverbane', 'Ore Vein 0285', 'gg_rct_OreVeins0285', 'unit', 285)
ON CONFLICT (region_variable) DO NOTHING;

-- Zone 11: Deadwoods / Zone 19: Ghostwalk Ridge - Regions 286-318
INSERT INTO gather_spawn_points (zone_id, zone_name, point_name, region_variable, node_type, spawn_point_index) VALUES
    (11, 'Deadwoods', 'Ore Vein 0286', 'gg_rct_OreVeins0286', 'unit', 286),
    (11, 'Deadwoods', 'Ore Vein 0287', 'gg_rct_OreVeins0287', 'unit', 287),
    (11, 'Deadwoods', 'Ore Vein 0288', 'gg_rct_OreVeins0288', 'unit', 288),
    (11, 'Deadwoods', 'Ore Vein 0289', 'gg_rct_OreVeins0289', 'unit', 289),
    (11, 'Deadwoods', 'Ore Vein 0290', 'gg_rct_OreVeins0290', 'unit', 290),
    (11, 'Deadwoods', 'Ore Vein 0291', 'gg_rct_OreVeins0291', 'unit', 291),
    (11, 'Deadwoods', 'Ore Vein 0292', 'gg_rct_OreVeins0292', 'unit', 292),
    (11, 'Deadwoods', 'Ore Vein 0293', 'gg_rct_OreVeins0293', 'unit', 293),
    (11, 'Deadwoods', 'Ore Vein 0294', 'gg_rct_OreVeins0294', 'unit', 294),
    (11, 'Deadwoods', 'Ore Vein 0295', 'gg_rct_OreVeins0295', 'unit', 295),
    (11, 'Deadwoods', 'Ore Vein 0296', 'gg_rct_OreVeins0296', 'unit', 296),
    (11, 'Deadwoods', 'Ore Vein 0297', 'gg_rct_OreVeins0297', 'unit', 297),
    (11, 'Deadwoods', 'Ore Vein 0298', 'gg_rct_OreVeins0298', 'unit', 298),
    (11, 'Deadwoods', 'Ore Vein 0299', 'gg_rct_OreVeins0299', 'unit', 299),
    (11, 'Deadwoods', 'Ore Vein 0300', 'gg_rct_OreVeins0300', 'unit', 300),
    (11, 'Deadwoods', 'Ore Vein 0301', 'gg_rct_OreVeins0301', 'unit', 301),
    (11, 'Deadwoods', 'Ore Vein 0302', 'gg_rct_OreVeins0302', 'unit', 302),
    (11, 'Deadwoods', 'Ore Vein 0303', 'gg_rct_OreVeins0303', 'unit', 303),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0304', 'gg_rct_OreVeins0304', 'unit', 304),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0305', 'gg_rct_OreVeins0305', 'unit', 305),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0306', 'gg_rct_OreVeins0306', 'unit', 306),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0307', 'gg_rct_OreVeins0307', 'unit', 307),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0308', 'gg_rct_OreVeins0308', 'unit', 308),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0309', 'gg_rct_OreVeins0309', 'unit', 309),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0310', 'gg_rct_OreVeins0310', 'unit', 310),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0311', 'gg_rct_OreVeins0311', 'unit', 311),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0312', 'gg_rct_OreVeins0312', 'unit', 312),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0313', 'gg_rct_OreVeins0313', 'unit', 313),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0314', 'gg_rct_OreVeins0314', 'unit', 314),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0315', 'gg_rct_OreVeins0315', 'unit', 315),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0316', 'gg_rct_OreVeins0316', 'unit', 316),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0317', 'gg_rct_OreVeins0317', 'unit', 317),
    (19, 'Ghostwalk Ridge', 'Ore Vein 0318', 'gg_rct_OreVeins0318', 'unit', 318)
ON CONFLICT (region_variable) DO NOTHING;

-- ============================================================
-- Crystal Spawn Regions
-- ============================================================

-- Red Crystal spawn regions
INSERT INTO gather_spawn_points (zone_id, zone_name, point_name, region_variable, node_type, spawn_point_index) VALUES
    (3, 'Emberpeak Highlands', 'Red Crystal 0001', 'gg_rct_CrystalsRed0001', 'unit', 401),
    (3, 'Emberpeak Highlands', 'Red Crystal 0002', 'gg_rct_CrystalsRed0002', 'unit', 402),
    (3, 'Emberpeak Highlands', 'Red Crystal 0003', 'gg_rct_CrystalsRed0003', 'unit', 403),
    (3, 'Emberpeak Highlands', 'Red Crystal 0004', 'gg_rct_CrystalsRed0004', 'unit', 404),
    (3, 'Emberpeak Highlands', 'Red Crystal 0005', 'gg_rct_CrystalsRed0005', 'unit', 405),
    (3, 'Emberpeak Highlands', 'Red Crystal 0006', 'gg_rct_CrystalsRed0006', 'unit', 406),
    (3, 'Emberpeak Highlands', 'Red Crystal 0007', 'gg_rct_CrystalsRed0007', 'unit', 407),
    (3, 'Emberpeak Highlands', 'Red Crystal 0008', 'gg_rct_CrystalsRed0008', 'unit', 408),
    (3, 'Emberpeak Highlands', 'Red Crystal 0009', 'gg_rct_CrystalsRed0009', 'unit', 409),
    (3, 'Emberpeak Highlands', 'Red Crystal 0010', 'gg_rct_CrystalsRed0010', 'unit', 410),
    (3, 'Emberpeak Highlands', 'Red Crystal 0011', 'gg_rct_CrystalsRed0011', 'unit', 411),
    (3, 'Emberpeak Highlands', 'Red Crystal 0012', 'gg_rct_CrystalsRed0012', 'unit', 412),
    (3, 'Emberpeak Highlands', 'Red Crystal 0013', 'gg_rct_CrystalsRed0013', 'unit', 413),
    (3, 'Emberpeak Highlands', 'Red Crystal 0014', 'gg_rct_CrystalsRed0014', 'unit', 414),
    (3, 'Emberpeak Highlands', 'Red Crystal 0015', 'gg_rct_CrystalsRed0015', 'unit', 415),
    (3, 'Emberpeak Highlands', 'Red Crystal 0016', 'gg_rct_CrystalsRed0016', 'unit', 416),
    (3, 'Emberpeak Highlands', 'Red Crystal 0017', 'gg_rct_CrystalsRed0017', 'unit', 417),
    (3, 'Emberpeak Highlands', 'Red Crystal 0018', 'gg_rct_CrystalsRed0018', 'unit', 418),
    (3, 'Emberpeak Highlands', 'Red Crystal 0019', 'gg_rct_CrystalsRed0019', 'unit', 419),
    (3, 'Emberpeak Highlands', 'Red Crystal 0020', 'gg_rct_CrystalsRed0020', 'unit', 420)
ON CONFLICT (region_variable) DO NOTHING;

-- Any Crystal spawn regions (multi-zone)
INSERT INTO gather_spawn_points (zone_id, zone_name, point_name, region_variable, node_type, spawn_point_index) VALUES
    (0, 'Any Zone', 'Any Crystal 0001', 'gg_rct_CrystalsAny0001', 'unit', 501),
    (0, 'Any Zone', 'Any Crystal 0002', 'gg_rct_CrystalsAny0002', 'unit', 502),
    (0, 'Any Zone', 'Any Crystal 0003', 'gg_rct_CrystalsAny0003', 'unit', 503),
    (0, 'Any Zone', 'Any Crystal 0004', 'gg_rct_CrystalsAny0004', 'unit', 504),
    (0, 'Any Zone', 'Any Crystal 0005', 'gg_rct_CrystalsAny0005', 'unit', 505),
    (0, 'Any Zone', 'Any Crystal 0006', 'gg_rct_CrystalsAny0006', 'unit', 506)
ON CONFLICT (region_variable) DO NOTHING;

-- ============================================================
-- Comments
-- ============================================================
COMMENT ON TABLE gather_herb_definitions IS 'Predefined herb/item templates for quick selection in Gather Node form';
COMMENT ON TABLE gather_vein_definitions IS 'Predefined vein/unit templates for quick selection in Gather Node form';
