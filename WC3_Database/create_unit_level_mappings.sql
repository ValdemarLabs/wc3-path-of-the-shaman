-- Create table for unit level -> item level mappings
BEGIN;

CREATE TABLE IF NOT EXISTS unit_level_mappings (
    id SERIAL PRIMARY KEY,
    item_class_name VARCHAR(50) NOT NULL,
    rarity_name VARCHAR(50) NOT NULL,
    unit_level_range VARCHAR(20) NOT NULL, -- e.g., "Levels 1-5"
    item_level INTEGER NOT NULL,
    UNIQUE(item_class_name, rarity_name, unit_level_range)
);

CREATE INDEX IF NOT EXISTS idx_unit_level_mappings_lookup 
ON unit_level_mappings(item_class_name, rarity_name);

COMMIT;

SELECT 'Created unit_level_mappings table' as message;
