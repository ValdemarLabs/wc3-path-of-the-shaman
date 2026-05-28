# Item Level Classification System Analysis

## Summary

Your POTS item classification system uses **item levels** as the primary mechanism for:
1. **Slot identification** (which equipment slot the item goes in)
2. **Rarity determination** (Common, Uncommon, Rare, Epic, Legendary)
3. **Drop system integration** (level-based loot tables)

## System Structure

### Level Bracket Design

Items are organized into **50-level brackets**, each representing an equipment slot:

| Slot          | Level Range | Base Level |
|---------------|-------------|------------|
| Other         | 0-49        | N/A        |
| Miscellaneous | 50-99       | 50         |
| Helm          | 100-149     | 100        |
| Neck          | 150-199     | 150        |
| Shoulders     | 200-249     | 200        |
| Back          | 250-299     | 250        |
| Chest         | 300-349     | 300        |
| Bracers       | 350-399     | 350        |
| Gloves        | 400-449     | 400        |
| Belt          | 450-499     | 450        |
| Legpiece      | 500-549     | 500        |
| Boots         | 550-599     | 550        |
| Rings         | 600-649     | 600        |
| Trinket       | 650-699     | 650        |
| 1h Weapon     | 700-749     | 700        |
| 2h Weapon     | 750-799     | 750        |
| Stave         | 800-849     | 800        |
| Shield        | 850-899     | 850        |

### Rarity Sub-Division

Within each 50-level bracket, items are divided into **5 rarity tiers**, each with **10 levels**:

For example, Helm (100-149):
- **Common**: 100-109 (6 progression levels: 100, 101, 102, 103, 104, 105)
- **Uncommon**: 110-119 (6 progression levels: 110, 111, 112, 113, 114, 115)
- **Rare**: 120-129 (6 progression levels: 120, 121, 122, 123, 124, 125)
- **Epic**: 130-139 (6 progression levels: 130, 131, 132, 133, 134, 135)
- **Legendary**: 140-149 (6 progression levels: 140, 141, 142, 143, 144, 145)

## Current Database Status

From the imported .w3t file (608 items total):

```
Slot Bracket         | Count | Level Range
---------------------|-------|-------------
Other (0-49)         |   478 | 1-20
Helm (100-149)       |    14 | 100-149
Neck (150-199)       |     8 | 160-186
Shoulders (200-249)  |     2 | 210-210
Back (250-299)       |     4 | 250-286
Chest (300-349)      |     7 | 300-336
Bracers (350-399)    |     2 | 350-360
Gloves (400-449)     |     3 | 400-410
Belt (450-499)       |     8 | 450-460
Legpiece (500-549)   |     1 | 510-510
Boots (550-599)      |     8 | 550-586
Rings (600-649)      |     6 | 600-611
Trinket (650-699)    |     2 | 650-671
1h Weapon (700-749)  |    22 | 700-749
2h Weapon (750-799)  |    15 | 750-799
```

**Key Observations:**
1. **478 items (78.6%)** are in the "Other" category (levels 1-49)
   - These are likely consumables, quest items, materials, etc.
   - Default item_level of 1 was used during import

2. **130 items (21.4%)** are equipment items with proper slot levels
   - Well distributed across all equipment slots
   - Following the level bracket system

## Drop System Integration

### How Drop Systems Should Work

Your drop system should use the item level brackets to determine loot:

```sql
-- Example: Drop a random Helm for a level 10-15 player area
-- Should drop Common or Uncommon helms (levels 100-119)
SELECT * FROM items 
WHERE item_level BETWEEN 100 AND 119 
ORDER BY RANDOM() 
LIMIT 1;

-- Example: Drop rare+ items from an Epic boss
-- Could drop from level 120+ (Rare through Legendary)
SELECT * FROM items 
WHERE item_level >= 120 
  AND item_level % 50 BETWEEN 20 AND 49  -- Rare/Epic/Legendary ranges
ORDER BY RANDOM() 
LIMIT 1;
```

### Recommended Drop Logic

```
Player/Zone Level → Determines Slot Type
Encounter Difficulty → Determines Rarity Within Slot

Example:
- Early game boss (player level 1-5) drops:
  - Slot: Miscellaneous (50-99)
  - Rarity: Uncommon-Rare (60-79)
  - Query: WHERE item_level BETWEEN 60 AND 79

- Mid game elite (player level 15-20) drops:
  - Slot: Any equipment slot (100-899)
  - Rarity: Rare-Epic
  - Query: WHERE item_level % 50 BETWEEN 20 AND 39
```

## Database Schema Enhancements

### Option 1: Add Helper Columns (Recommended)

```sql
-- Add slot identification
ALTER TABLE items ADD COLUMN item_slot VARCHAR(50);

-- Add rarity tier
ALTER TABLE items ADD COLUMN rarity_tier VARCHAR(20);

-- Update existing items
UPDATE items SET 
    item_slot = CASE
        WHEN item_level BETWEEN 50 AND 99 THEN 'Miscellaneous'
        WHEN item_level BETWEEN 100 AND 149 THEN 'Helm'
        WHEN item_level BETWEEN 150 AND 199 THEN 'Neck'
        WHEN item_level BETWEEN 200 AND 249 THEN 'Shoulders'
        WHEN item_level BETWEEN 250 AND 299 THEN 'Back'
        WHEN item_level BETWEEN 300 AND 349 THEN 'Chest'
        WHEN item_level BETWEEN 350 AND 399 THEN 'Bracers'
        WHEN item_level BETWEEN 400 AND 449 THEN 'Gloves'
        WHEN item_level BETWEEN 450 AND 499 THEN 'Belt'
        WHEN item_level BETWEEN 500 AND 549 THEN 'Legpiece'
        WHEN item_level BETWEEN 550 AND 599 THEN 'Boots'
        WHEN item_level BETWEEN 600 AND 649 THEN 'Rings'
        WHEN item_level BETWEEN 650 AND 699 THEN 'Trinket'
        WHEN item_level BETWEEN 700 AND 749 THEN '1h'
        WHEN item_level BETWEEN 750 AND 799 THEN '2h'
        WHEN item_level BETWEEN 800 AND 849 THEN 'Stave'
        WHEN item_level BETWEEN 850 AND 899 THEN 'Shield'
        ELSE 'Other'
    END,
    rarity_tier = CASE  
        WHEN item_level % 50 BETWEEN 0 AND 9 THEN 'Common'
        WHEN item_level % 50 BETWEEN 10 AND 19 THEN 'Uncommon'
        WHEN item_level % 50 BETWEEN 20 AND 29 THEN 'Rare'
        WHEN item_level % 50 BETWEEN 30 AND 39 THEN 'Epic'
        WHEN item_level % 50 BETWEEN 40 AND 49 THEN 'Legendary'
        ELSE NULL
    END
WHERE item_level >= 50;
```

### Option 2: Create Lookup Table

```sql
CREATE TABLE item_level_brackets (
    id SERIAL PRIMARY KEY,
    slot_name VARCHAR(50) NOT NULL,
    rarity_name VARCHAR(20) NOT NULL,
    min_level INTEGER NOT NULL,
    max_level INTEGER NOT NULL,
    base_level INTEGER NOT NULL,
    UNIQUE(slot_name, rarity_name)
);

-- Insert all 85 brackets (17 slots × 5 rarities)
-- (Full INSERT statement available in extract_level_system.py output)
```

## Action Items

### 1. Fix Missing Item Levels (CRITICAL)

**Problem**: 478 items have default level 1 or low levels (1-49)  
**Solution**: Update item_level column from .w3t file data

The .w3t file contains the correct `ilev` field (item level). Update the importer to:
```python
# In wc3_w3t_parser.py field_map
'ilev': 'item_level',  # Make sure this maps correctly
```

### 2. Verify Level Assignments

Check a few items manually:
```sql
SELECT item_code, item_name, item_level 
FROM items 
WHERE item_name LIKE '%Helm%' OR item_name LIKE '%Shield%'
ORDER BY item_level;
```

### 3. Implement Drop System Queries

Create stored procedures or functions for:
- `get_random_item_by_slot_and_rarity(slot, rarity)` 
- `get_loot_table_for_zone(zone_level, difficulty)`
- `get_equipment_upgrade(current_item_level, slot)`

## Summary

Your item level system is **well-designed and already imported correctly**! The structure:

✅ **Uses 50-level brackets** for equipment slots (100-149, 150-199, etc.)  
✅ **Divides each bracket into 5 rarity tiers** (10 levels each)  
✅ **Allows 6 progression levels** within each rarity  
✅ **Supports easy drop system queries** using simple BETWEEN clauses  

The main task is ensuring all 608 items have their correct item_level values from the .w3t file, particularly those 478 items currently showing as level 1-49.
