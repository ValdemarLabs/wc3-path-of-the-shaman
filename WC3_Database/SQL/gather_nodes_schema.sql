-- ============================================================
-- GatherNodes System Database Schema
-- For WC3 Item Manager - Herb/Vein/Fish Pool/Treasure spawning
-- ============================================================

-- ============================================================
-- Node Categories - Organize nodes into groups
-- ============================================================
CREATE TABLE IF NOT EXISTS gather_node_categories (
    id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    node_type VARCHAR(10) NOT NULL CHECK (node_type IN ('item', 'unit')),
    description TEXT,
    display_order INT DEFAULT 0,
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default categories
INSERT INTO gather_node_categories (category_name, node_type, description, display_order) VALUES
    ('Herbs', 'item', 'Common herb plants', 1),
    ('Flowers', 'item', 'Decorative and reagent flowers', 2),
    ('Mushrooms', 'item', 'Fungi and mushrooms', 3),
    ('Rare Herbs', 'item', 'Rare and valuable herbs', 4),
    ('Reagents', 'item', 'Crafting reagents that spawn in world', 5),
    ('Ore Veins', 'unit', 'Common ore mining nodes', 10),
    ('Crystal Veins', 'unit', 'Crystal and gem nodes', 11),
    ('Rich Veins', 'unit', 'High-yield mining nodes', 12),
    ('Fish Pools', 'unit', 'Fishing spots', 13),
    ('Treasure Chests', 'unit', 'Random treasure containers', 14),
    ('Rare Spawns', 'unit', 'Rare and special spawn points', 15)
ON CONFLICT (category_name) DO NOTHING;

-- ============================================================
-- Gather Item Nodes - Items that spawn as gatherable (Herbs)
-- ============================================================
CREATE TABLE IF NOT EXISTS gather_item_nodes (
    id SERIAL PRIMARY KEY,
    item_code VARCHAR(4) NOT NULL,
    node_name VARCHAR(100) NOT NULL,
    category_id INT REFERENCES gather_node_categories(id),
    spawn_weight INT DEFAULT 100,
    respawn_time_min REAL DEFAULT 60.0,
    respawn_time_max REAL DEFAULT 180.0,
    max_per_zone INT DEFAULT 5,
    skill_required INT DEFAULT 0,
    glow_effect BOOLEAN DEFAULT FALSE,
    glow_color_r INT DEFAULT 0,
    glow_color_g INT DEFAULT 255,
    glow_color_b INT DEFAULT 0,
    glow_alpha INT DEFAULT 200,
    is_rare BOOLEAN DEFAULT FALSE,
    enabled BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(item_code)
);

-- ============================================================
-- Gather Unit Nodes - Units that spawn as gatherable (Veins, Fish, Chests)
-- ============================================================
CREATE TABLE IF NOT EXISTS gather_unit_nodes (
    id SERIAL PRIMARY KEY,
    unit_code VARCHAR(4) NOT NULL,
    node_name VARCHAR(100) NOT NULL,
    category_id INT REFERENCES gather_node_categories(id),
    spawn_weight INT DEFAULT 100,
    respawn_time_min REAL DEFAULT 120.0,
    respawn_time_max REAL DEFAULT 360.0,
    max_per_zone INT DEFAULT 3,
    skill_required INT DEFAULT 0,
    owner_player INT DEFAULT 24,
    glow_effect BOOLEAN DEFAULT TRUE,
    glow_color_r INT DEFAULT 255,
    glow_color_g INT DEFAULT 200,
    glow_color_b INT DEFAULT 0,
    glow_alpha INT DEFAULT 200,
    glow_scale REAL DEFAULT 1.5,
    is_rare BOOLEAN DEFAULT FALSE,
    enabled BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(unit_code)
);

-- ============================================================
-- Gather Node Zones - Link nodes to zones (many-to-many)
-- ============================================================
CREATE TABLE IF NOT EXISTS gather_node_zones (
    id SERIAL PRIMARY KEY,
    node_type VARCHAR(10) NOT NULL CHECK (node_type IN ('item', 'unit')),
    node_id INT NOT NULL,
    zone_id INT NOT NULL,
    zone_name VARCHAR(100),
    spawn_mode VARCHAR(20) DEFAULT 'random' CHECK (spawn_mode IN ('random', 'fixed', 'both')),
    spawn_group_id INT,
    weight_override INT,
    max_override INT,
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(node_type, node_id, zone_id)
);

-- ============================================================
-- Gather Spawn Point Groups - logical placement groups per zone
-- ============================================================
CREATE TABLE IF NOT EXISTS gather_spawn_point_groups (
    id SERIAL PRIMARY KEY,
    zone_id INT NOT NULL,
    zone_name VARCHAR(100),
    group_name VARCHAR(100) NOT NULL,
    node_type VARCHAR(10) DEFAULT 'both' CHECK (node_type IN ('item', 'unit', 'both')),
    enabled BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(zone_id, group_name, node_type)
);

-- ============================================================
-- Gather Spawn Points - Specific spawn regions within zones
-- ============================================================
CREATE TABLE IF NOT EXISTS gather_spawn_points (
    id SERIAL PRIMARY KEY,
    zone_id INT NOT NULL,
    zone_name VARCHAR(100),
    point_name VARCHAR(100) NOT NULL,
    region_variable VARCHAR(100) NOT NULL,
    node_type VARCHAR(10) DEFAULT 'both' CHECK (node_type IN ('item', 'unit', 'both')),
    spawn_group_id INT,
    spawn_point_index INT,
    enabled BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(region_variable)
);

-- ============================================================
-- Indexes for performance
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_gather_item_nodes_category ON gather_item_nodes(category_id);
CREATE INDEX IF NOT EXISTS idx_gather_item_nodes_enabled ON gather_item_nodes(enabled);
CREATE INDEX IF NOT EXISTS idx_gather_unit_nodes_category ON gather_unit_nodes(category_id);
CREATE INDEX IF NOT EXISTS idx_gather_unit_nodes_enabled ON gather_unit_nodes(enabled);
CREATE INDEX IF NOT EXISTS idx_gather_node_zones_node ON gather_node_zones(node_type, node_id);
CREATE INDEX IF NOT EXISTS idx_gather_node_zones_zone ON gather_node_zones(zone_id);
CREATE INDEX IF NOT EXISTS idx_gather_node_zones_group ON gather_node_zones(spawn_group_id);
CREATE INDEX IF NOT EXISTS idx_gather_spawn_point_groups_zone ON gather_spawn_point_groups(zone_id);
CREATE INDEX IF NOT EXISTS idx_gather_spawn_points_zone ON gather_spawn_points(zone_id);
CREATE INDEX IF NOT EXISTS idx_gather_spawn_points_group ON gather_spawn_points(spawn_group_id);

-- ============================================================
-- Views for easy querying
-- ============================================================

-- Item nodes with category name
CREATE OR REPLACE VIEW v_gather_item_nodes AS
SELECT 
    gin.id,
    gin.item_code,
    gin.node_name,
    gin.category_id,
    COALESCE(gnc.category_name, 'Uncategorized') as category_name,
    gin.spawn_weight,
    gin.respawn_time_min,
    gin.respawn_time_max,
    gin.max_per_zone,
    gin.skill_required,
    gin.glow_effect,
    gin.glow_color_r,
    gin.glow_color_g,
    gin.glow_color_b,
    gin.glow_alpha,
    gin.is_rare,
    gin.enabled,
    gin.notes
FROM gather_item_nodes gin
LEFT JOIN gather_node_categories gnc ON gin.category_id = gnc.id;

-- Unit nodes with category name
CREATE OR REPLACE VIEW v_gather_unit_nodes AS
SELECT 
    gun.id,
    gun.unit_code,
    gun.node_name,
    gun.category_id,
    COALESCE(gnc.category_name, 'Uncategorized') as category_name,
    gun.spawn_weight,
    gun.respawn_time_min,
    gun.respawn_time_max,
    gun.max_per_zone,
    gun.skill_required,
    gun.owner_player,
    gun.glow_effect,
    gun.glow_color_r,
    gun.glow_color_g,
    gun.glow_color_b,
    gun.glow_alpha,
    gun.glow_scale,
    gun.is_rare,
    gun.enabled,
    gun.notes
FROM gather_unit_nodes gun
LEFT JOIN gather_node_categories gnc ON gun.category_id = gnc.id;

-- Zone assignments with node details
CREATE OR REPLACE VIEW v_gather_node_zone_assignments AS
SELECT 
    gnz.id,
    gnz.node_type,
    gnz.node_id,
    gnz.zone_id,
    gnz.zone_name,
    gnz.spawn_mode,
    gnz.spawn_group_id,
    gspg.group_name as spawn_group_name,
    gnz.weight_override,
    gnz.max_override,
    gnz.enabled,
    CASE 
        WHEN gnz.node_type = 'item' THEN gin.node_name
        WHEN gnz.node_type = 'unit' THEN gun.node_name
    END as node_name,
    CASE 
        WHEN gnz.node_type = 'item' THEN gin.item_code
        WHEN gnz.node_type = 'unit' THEN gun.unit_code
    END as node_code
FROM gather_node_zones gnz
LEFT JOIN gather_item_nodes gin ON gnz.node_type = 'item' AND gnz.node_id = gin.id
LEFT JOIN gather_unit_nodes gun ON gnz.node_type = 'unit' AND gnz.node_id = gun.id;
LEFT JOIN gather_spawn_point_groups gspg ON gnz.spawn_group_id = gspg.id;

-- ============================================================
-- Sample Data (Optional - can be removed or modified)
-- ============================================================

-- Sample herbs
-- INSERT INTO gather_item_nodes (item_code, node_name, category_id, spawn_weight, is_rare) 
-- SELECT 'herb', 'Agave', id, 100, false FROM gather_node_categories WHERE category_name = 'Herbs';

-- Sample veins (uncomment and modify as needed)
-- INSERT INTO gather_unit_nodes (unit_code, node_name, category_id, spawn_weight, glow_effect)
-- SELECT 'h001', 'Copper Vein', id, 60, true FROM gather_node_categories WHERE category_name = 'Ore Veins';

COMMENT ON TABLE gather_item_nodes IS 'Gatherable item nodes (herbs, flowers, mushrooms)';
COMMENT ON TABLE gather_unit_nodes IS 'Gatherable unit nodes (ore veins, crystal veins, fish pools, treasure chests)';
COMMENT ON TABLE gather_node_zones IS 'Zone placements for gather nodes: random in zone or targeted spawn group';
COMMENT ON TABLE gather_spawn_point_groups IS 'Named groups of spawn point rects for targeted gather-node placement';
COMMENT ON TABLE gather_spawn_points IS 'Specific spawn point regions within zones, optionally assigned to groups';
COMMENT ON TABLE gather_node_categories IS 'Categories for organizing gather nodes';
