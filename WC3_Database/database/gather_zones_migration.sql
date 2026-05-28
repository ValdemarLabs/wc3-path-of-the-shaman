-- ============================================================
-- Gather Zones Migration
-- Creates zones table from Zones.j definitions
-- ============================================================

-- Create the zones table
CREATE TABLE IF NOT EXISTS gather_zones (
    id SERIAL PRIMARY KEY,
    zone_id INTEGER UNIQUE NOT NULL,           -- The zone ID from Zones.j (e.g., 1, 2, 101)
    zone_name VARCHAR(64) NOT NULL,            -- Zone name (e.g., "Twilight Grove")
    environment_type VARCHAR(64),              -- Environment type (e.g., "Forest", "Dungeon")
    is_dungeon BOOLEAN DEFAULT FALSE,          -- Whether this is a dungeon zone
    level_range VARCHAR(16),                   -- Recommended level range (e.g., "1-10")
    parent_zone_id INTEGER REFERENCES gather_zones(zone_id), -- Parent zone for sub-zones
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert all zones from Zones.j
INSERT INTO gather_zones (zone_id, zone_name, environment_type, is_dungeon, level_range, parent_zone_id) VALUES
-- Main zones
(1, 'Twilight Grove', 'Ancient Forest', false, '3-8', NULL),
(2, 'Sereneglade', 'Forest', false, '1-9', NULL),
(3, 'Emberpeak Highlands', 'Mountainous', false, '10-15', NULL),
(4, 'Dragonfire Peaks', 'Volcanic, Mountainous', false, '20-30', NULL),
(6, 'Thornwoods', 'Forest', false, '1-10', NULL),
(7, 'Havenwoods', 'Forest', false, '5-15', NULL),
(8, 'Bonecrush Stronghold', 'Forest', false, '10-15', NULL),
(9, 'Vanguard Vale', 'Magical, Forest', false, '10-20', NULL),
(10, 'Riverbane', 'Riverine, Forest, Seaside', false, '8-12', NULL),
(11, 'Deadwoods', 'Haunted Forest', false, '8-14', NULL),
(12, 'Felfire Bastion', 'Fel Imbused, Mountainous', false, '12-15', NULL),
(13, 'Stormhaven', 'Cityscape', false, '12-18', NULL),
(14, 'Sirensong', 'Jungle, Seaside', false, '10-15', NULL),
(15, 'Zul''Gurak', 'Jungle, Ancient Ruins', false, '15-20', NULL),
(17, 'Verdant Plains', 'Swamp, Forest, Mountainous', false, '15-20', NULL),
(18, 'Coliseum of Ages', 'Arena', false, NULL, NULL),
(19, 'Ghostwalk Ridge', 'Eerie Forest', false, '5-10', NULL),
(20, 'Dawnhold', 'Haunted Ruins', false, '15-18', NULL),

-- Sub-zones (Thornwoods)
(601, 'Stonetooth Camp', 'Forest', false, '1-10', 6),
(602, 'Bloodtusk Tribe', 'Forest', false, '1-10', 6),

-- Sub-zones (Felfire)
(1201, 'Felfire Citadel', 'Fel Imbused, Mountainous', false, '12-15', 12),

-- Sub-zones (Sirensong)
(1401, 'Mok''natha', 'Jungle, Seaside', false, NULL, 14),
(1402, 'Ruins of Zul''Garok', 'Jungle, Seaside, Ancient Ruins', false, '10-15', 14),
(1403, 'Urgmar', 'Jungle, Seaside', false, '10-15', 14),
(1404, 'Serpentshore', 'Jungle, Seaside', false, '10-15', 14),

-- Sub-zones (Verdant Plains)
(1701, 'Chimairo''s Roost', 'Swamp, Forest, Mountainous', false, '15-20', 17),
(1702, 'The Weeping Hollow', 'Swamp, Forest, Mountainous', false, '15-20', 17),
(1703, 'Redwind Pass', 'Mountainous', false, '15-20', 17),
(1704, 'xxxSettlement', 'Magical, Forest', false, '10-20', 17),
(1705, 'Vael''Anorath', 'Magical, Forest', false, '10-20', 17),

-- Sub-zones (Ghostwalk)
(1901, 'Ironspine Post', 'Eerie Forest', false, NULL, 19),

-- Special zones
(8810, 'Horde Scout Base', 'Orcish settlement', false, NULL, NULL),

-- Dungeons
(101, 'Gnoll Hideout', 'Underground', true, '5-12', NULL),
(102, 'The Crypt', 'Underground', true, '8-20', NULL),
(103, 'Wyrmhold Sanctum', 'Underground', true, '20-25', NULL),
(104, 'Boom Mine', 'Underground', true, '10-15', NULL),
(105, 'Firelands', 'Elemental Place', true, '20-30', NULL)
ON CONFLICT (zone_id) DO UPDATE SET
    zone_name = EXCLUDED.zone_name,
    environment_type = EXCLUDED.environment_type,
    is_dungeon = EXCLUDED.is_dungeon,
    level_range = EXCLUDED.level_range,
    parent_zone_id = EXCLUDED.parent_zone_id;

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_gather_zones_name ON gather_zones(zone_name);
CREATE INDEX IF NOT EXISTS idx_gather_zones_is_dungeon ON gather_zones(is_dungeon);

-- Update spawn points to reference zone table
-- (Optional: you can add a foreign key constraint if desired)
-- ALTER TABLE gather_spawn_points ADD CONSTRAINT fk_spawn_point_zone
--     FOREIGN KEY (zone_id) REFERENCES gather_zones(zone_id);

COMMENT ON TABLE gather_zones IS 'Zone definitions imported from Zones.j';
