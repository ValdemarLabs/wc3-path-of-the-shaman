-- Update gather_zones table with zones from ZonesCore.j (replaces old Zones.j data)
-- Run this migration to update to the correct zone definitions

-- Clear old zone data
TRUNCATE TABLE gather_zones;

-- Reset sequence
ALTER SEQUENCE gather_zones_id_seq RESTART WITH 1;

-- =========================================
-- MAIN ZONES
-- =========================================
INSERT INTO gather_zones (zone_id, zone_name, environment_type, is_dungeon, level_range, parent_zone_id, enabled) VALUES
(1, 'Twilight Grove', 'Ancient Forest', false, '3-8', NULL, true),
(2, 'Sereneglade', 'Forest', false, '1-9', NULL, true),
(3, 'Emberpeak Highlands', 'Burned Forest, Mountainous', false, '10-15', NULL, true),
(4, 'Dragonfire Peaks', 'Volcanic, Mountainous', false, '20-30', NULL, true),
(6, 'Thornwoods', 'Forest', false, '1-10', NULL, true),
(7, 'Havenwoods', 'Forest', false, '5-15', NULL, true),
(8, 'Bonecrush Stronghold', 'Forest', false, '10-15', NULL, true),
(9, 'Vanguard Vale', 'Magical, Forest', false, '10-20', NULL, true),
(10, 'Riverbane', 'Riverine, Forest, Seaside', false, '8-12', NULL, true),
(11, 'Deadwoods', 'Haunted Forest', false, '8-14', NULL, true),
(12, 'Felfire Bastion', 'Fel Imbused, Mountainous', false, '12-15', NULL, true),
(13, 'Stormhaven', 'Cityscape', false, '12-18', NULL, true),
(14, 'Sirensong', 'Jungle, Seaside', false, '10-15', NULL, true),
(15, 'Zul''Gurak', 'Jungle, Ancient Ruins', false, '15-20', NULL, true),
(17, 'Verdant Plains', 'Swamp, Forest, Mountainous', false, '15-20', NULL, true),
(18, 'Coliseum of Ages', 'Arena', false, NULL, NULL, true),
(19, 'Ghostwalk Ridge', 'Eerie Forest', false, '5-10', NULL, true),
(20, 'Dawnhold', 'Haunted Ruins', false, '15-18', NULL, true);

-- =========================================
-- SUB-ZONES (parent zones)
-- =========================================
INSERT INTO gather_zones (zone_id, zone_name, environment_type, is_dungeon, level_range, parent_zone_id, enabled) VALUES
(601, 'Stonetooth Camp', 'Forest', false, '1-10', 6, true),
(602, 'Bloodtusk Tribe', 'Forest', false, '1-10', 6, true),
(1201, 'Felfire Citadel', 'Fel Imbused, Mountainous', false, '12-15', 12, true),
(1401, 'Mok''natha', 'Jungle, Seaside', false, NULL, 14, true),
(1402, 'Ruins of Zul''Garok', 'Jungle, Seaside, Ancient Ruins', false, '10-15', 14, true),
(1403, 'Urgmar', 'Jungle, Seaside', false, '10-15', 14, true),
(1404, 'Serpentshore', 'Jungle, Seaside', false, '10-15', 14, true),
(1701, 'Chimairo''s Roost', 'Swamp, Forest, Mountainous', false, '15-20', 17, true),
(1702, 'The Weeping Hollow', 'Swamp, Forest, Mountainous', false, '15-20', 17, true),
(1703, 'Redwind Pass', 'Mountainous', false, '15-20', 17, true),
(1704, 'xxxSettlement', 'Magical, Forest', false, '10-20', 17, true),
(1705, 'Vael''Anorath', 'Magical, Forest', false, '10-20', 17, true),
(1901, 'Ironspine Post', 'Eerie Forest', false, NULL, 19, true);

-- =========================================
-- SPECIAL ZONES
-- =========================================
INSERT INTO gather_zones (zone_id, zone_name, environment_type, is_dungeon, level_range, parent_zone_id, enabled) VALUES
(8810, 'Horde Scout Base', 'Orcish settlement', false, NULL, NULL, true);

-- =========================================
-- DUNGEONS
-- =========================================
INSERT INTO gather_zones (zone_id, zone_name, environment_type, is_dungeon, level_range, parent_zone_id, enabled) VALUES
(101, 'Gnoll Hideout', 'Underground', true, '5-12', NULL, true),
(102, 'The Crypt', 'Underground', true, '8-20', NULL, true),
(103, 'Wyrmhold Sanctum', 'Underground', true, '20-25', NULL, true),
(104, 'Boom Mine', 'Underground', true, '10-15', NULL, true),
(105, 'Firelands', 'Elemental Place', true, '20-30', NULL, true),
(106, 'Dreadforge', 'Underground', true, NULL, NULL, true);

-- =========================================
-- INTERIORS / CAVES  
-- =========================================
INSERT INTO gather_zones (zone_id, zone_name, environment_type, is_dungeon, level_range, parent_zone_id, enabled) VALUES
(12010, 'Riverbane Inn', 'Interior', true, NULL, 10, true),
(12020, 'Havenwoods Inn', 'Interior', true, NULL, 7, true),
(12030, 'Stormhaven Inn', 'Interior', true, NULL, 13, true),
(12110, 'Cinderfall', 'Underground', true, NULL, 3, true),
(12111, 'Wolf Den', 'Underground', true, NULL, 2, true),
(12112, 'Shadowmaw Cave', 'Underground', true, NULL, 14, true),
(12113, 'Kobold Mine', 'Underground', true, NULL, 2, true),
(12114, 'Blazehollow', 'Underground', true, NULL, 4, true);

-- Verify count (should be 44 zones)
SELECT COUNT(*) AS zone_count FROM gather_zones;

-- Show all zones organized by type
SELECT 
    CASE 
        WHEN is_dungeon AND parent_zone_id IS NOT NULL THEN 'Interior/Cave'
        WHEN is_dungeon THEN 'Dungeon'
        WHEN parent_zone_id IS NOT NULL THEN 'Sub-zone'
        ELSE 'Main Zone'
    END AS zone_type,
    zone_id, 
    zone_name, 
    environment_type,
    level_range
FROM gather_zones 
ORDER BY 
    CASE 
        WHEN is_dungeon AND parent_zone_id IS NOT NULL THEN 4
        WHEN is_dungeon THEN 3
        WHEN parent_zone_id IS NOT NULL THEN 2
        ELSE 1
    END,
    zone_id;
