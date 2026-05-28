-- Migration: 006_seed_loot_tiers
-- Description: Seed default loot tiers with rarity configuration
-- Date: 2026-04-11

-- Seed 7 default loot tiers
-- Rarity IDs: 0=Common, 1=Uncommon, 2=Rare, 3=Epic, 4=Legendary, 5=Artifact
INSERT INTO loot_tiers (
    tier_name, min_unit_level, max_unit_level, description, drop_chance_base,
    common_item_level, uncommon_item_level, rare_item_level, epic_item_level, legendary_item_level, artifact_item_level,
    common_weight, uncommon_weight, rare_weight, epic_weight, legendary_weight, artifact_weight
)
VALUES 
    -- Tier 1: Starting area (levels 1-5)
    -- Common/Uncommon/Rare only, no Epic+
    ('TIER_1_5', 1, 5, 'Starting area mobs', 15.00, 
     5, 10, 15, NULL, NULL, NULL, 
     60, 25, 15, 0, 0, 0),
    
    -- Tier 2: Early game (levels 6-10)
    -- Common/Uncommon/Rare + rare Epic
    ('TIER_6_10', 6, 10, 'Early game mobs', 12.00, 
     10, 15, 20, 25, NULL, NULL, 
     55, 28, 14, 3, 0, 0),
    
    -- Tier 3: Mid-early game (levels 11-15)
    -- All rarities except Artifact
    ('TIER_11_15', 11, 15, 'Mid-early game', 10.00, 
     15, 20, 25, 30, 35, NULL, 
     50, 28, 15, 5, 2, 0),
    
    -- Tier 4: Mid game (levels 16-20)
    ('TIER_16_20', 16, 20, 'Mid game', 8.00, 
     20, 25, 30, 35, 40, 45, 
     45, 30, 16, 6, 3, 0),
    
    -- Tier 5: Mid-late game (levels 21-25)
    ('TIER_21_25', 21, 25, 'Mid-late game', 6.00, 
     25, 30, 35, 40, 45, 50, 
     40, 30, 18, 8, 3, 1),
    
    -- Tier 6: Late game (levels 26-30)
    ('TIER_26_30', 26, 30, 'Late game', 5.00, 
     30, 35, 40, 45, 50, 55, 
     35, 30, 20, 10, 4, 1),
    
    -- Tier 7: End game / Elite (levels 31+)
    ('TIER_31_PLUS', 31, 99, 'End game / elite', 4.00, 
     35, 40, 45, 50, 55, 60, 
     30, 28, 22, 12, 6, 2)

ON CONFLICT (tier_name) DO UPDATE SET
    min_unit_level = EXCLUDED.min_unit_level,
    max_unit_level = EXCLUDED.max_unit_level,
    description = EXCLUDED.description,
    drop_chance_base = EXCLUDED.drop_chance_base,
    common_item_level = EXCLUDED.common_item_level,
    uncommon_item_level = EXCLUDED.uncommon_item_level,
    rare_item_level = EXCLUDED.rare_item_level,
    epic_item_level = EXCLUDED.epic_item_level,
    legendary_item_level = EXCLUDED.legendary_item_level,
    artifact_item_level = EXCLUDED.artifact_item_level,
    common_weight = EXCLUDED.common_weight,
    uncommon_weight = EXCLUDED.uncommon_weight,
    rare_weight = EXCLUDED.rare_weight,
    epic_weight = EXCLUDED.epic_weight,
    legendary_weight = EXCLUDED.legendary_weight,
    artifact_weight = EXCLUDED.artifact_weight;
