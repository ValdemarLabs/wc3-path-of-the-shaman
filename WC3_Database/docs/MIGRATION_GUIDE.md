# Migration Guide: Upgrade to StatID System

This guide helps you upgrade your existing WC3 POTS database to use the new enhanced stat system with full DEquipment support.

---

## Prerequisites

✅ PostgreSQL 12+ installed  
✅ Existing `wc3_pots` database (or similar)  
✅ Python 3.7+ with psycopg2 installed  
✅ Backup of your current database  

---

## Step 1: Backup Your Existing Database

**IMPORTANT: Always backup before applying schema changes!**

```powershell
# Open PowerShell in the WC3_Database directory
cd h:\Pelit\PotS_JASS\WC3_Database

# Backup your database
$env:PGPASSWORD="your_password"
pg_dump -U postgres -h localhost -p 5432 wc3_pots > backup_before_statid_$(Get-Date -Format "yyyyMMdd_HHmmss").sql

# Verify backup was created
dir backup_*.sql
```

---

## Step 2: Configure Database Connection

If you don't have `database.ini`, create it from the example:

```powershell
# Copy the example file
Copy-Item database.ini.example database.ini

# Edit with your credentials
notepad database.ini
```

**database.ini** should look like:

```ini
[postgresql]
host = localhost
port = 5432
database = wc3_pots
user = postgres
password = your_password_here
```

---

## Step 3: Check Current Database State

Let's see what you currently have:

```powershell
# Connect to your database
$env:PGPASSWORD="your_password"
psql -U postgres -h localhost -p 5432 -d wc3_pots
```

```sql
-- Check existing tables
\dt

-- Check if you have items
SELECT COUNT(*) FROM items;

-- Check if you have old item_bonuses table (if exists)
SELECT COUNT(*) FROM item_bonuses;

-- Exit psql
\q
```

---

## Step 4: Apply the Enhanced Schema

The enhancement schema can be applied **without dropping your existing tables**.

```powershell
# Apply the stat system enhancement
$env:PGPASSWORD="your_password"
psql -U postgres -h localhost -p 5432 -d wc3_pots -f schema_stats_enhancement.sql
```

This creates:
- ✅ `stat_definitions` table (39 stats)
- ✅ `ability_codes` table (16 abilities)
- ✅ `item_stat_bonuses` table (new, won't conflict with old data)
- ✅ Helper views (`v_item_stats`, etc.)

**The script will NOT delete your existing `items` or `item_bonuses` tables.**

---

## Step 5: Verify Installation

```powershell
psql -U postgres -h localhost -p 5432 -d wc3_pots
```

```sql
-- Check new tables exist
\dt stat_definitions
\dt ability_codes
\dt item_stat_bonuses

-- Verify stat definitions are loaded
SELECT COUNT(*) FROM stat_definitions;
-- Should return 39

-- Verify ability codes are loaded
SELECT COUNT(*) FROM ability_codes;
-- Should return 16

-- View some stats
SELECT statid, stat_name, stat_short_name, application_method, ability_code 
FROM stat_definitions 
ORDER BY statid 
LIMIT 10;

-- View some abilities
SELECT ability_code, ability_name, used_by_stats 
FROM ability_codes 
ORDER BY ability_code;
```

---

## Step 6: Migrate Existing Item Data (Optional)

### Option A: If you have generic `item_bonuses` table

If your old database has an `item_bonuses` table with `bonus_type` as text:

```sql
-- See what bonus types you have
SELECT DISTINCT bonus_type FROM item_bonuses;

-- Map old bonus types to statids
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, notes)
SELECT 
    item_id,
    CASE bonus_type
        WHEN 'strength' THEN 1
        WHEN 'agility' THEN 2
        WHEN 'intelligence' THEN 3
        WHEN 'hp' THEN 4
        WHEN 'hp_regen' THEN 5
        WHEN 'mana' THEN 7
        WHEN 'mana_regen' THEN 8
        WHEN 'damage' THEN 12
        WHEN 'attack_speed' THEN 20
        WHEN 'armor' THEN 25
        WHEN 'movement_speed' THEN 31
        -- Add more mappings based on your bonus types
        ELSE NULL
    END AS statid,
    bonus_value,
    'Migrated from item_bonuses table'
FROM item_bonuses
WHERE bonus_type IN ('strength', 'agility', 'intelligence', 'hp', 'hp_regen', 'mana', 'mana_regen', 'damage', 'attack_speed', 'armor', 'movement_speed')
AND EXISTS (SELECT 1 FROM items WHERE items.id = item_bonuses.item_id)
ON CONFLICT (item_id, statid) DO NOTHING;

-- Check migration results
SELECT COUNT(*) FROM item_stat_bonuses;
```

### Option B: If you have hardcoded stat columns in `items`

If your items table has columns like `strength_bonus`, `agility_bonus`, etc:

```sql
-- Migrate strength bonuses
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, notes)
SELECT 
    id,
    1,  -- StatID for Strength
    strength_bonus,
    'Migrated from items.strength_bonus'
FROM items
WHERE strength_bonus IS NOT NULL AND strength_bonus != 0
ON CONFLICT (item_id, statid) DO NOTHING;

-- Migrate agility bonuses
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, notes)
SELECT 
    id,
    2,  -- StatID for Agility
    agility_bonus,
    'Migrated from items.agility_bonus'
FROM items
WHERE agility_bonus IS NOT NULL AND agility_bonus != 0
ON CONFLICT (item_id, statid) DO NOTHING;

-- Migrate intelligence bonuses
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, notes)
SELECT 
    id,
    3,  -- StatID for Intelligence
    intelligence_bonus,
    'Migrated from items.intelligence_bonus'
FROM items
WHERE intelligence_bonus IS NOT NULL AND intelligence_bonus != 0
ON CONFLICT (item_id, statid) DO NOTHING;

-- Migrate armor (if you have it)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, notes)
SELECT 
    id,
    25,  -- StatID for Armor
    armor,
    'Migrated from items.armor'
FROM items
WHERE armor IS NOT NULL AND armor != 0
ON CONFLICT (item_id, statid) DO NOTHING;

-- Check migration results
SELECT COUNT(*) FROM item_stat_bonuses;
```

### Verify Migration

```sql
-- View migrated stats
SELECT 
    i.item_code,
    i.item_name,
    sd.stat_short_name,
    isb.bonus_value,
    isb.notes
FROM items i
JOIN item_stat_bonuses isb ON i.id = isb.item_id
JOIN stat_definitions sd ON isb.statid = sd.statid
ORDER BY i.item_code, sd.statid;
```

---

## Step 7: Add New Stats (Enhanced Features)

Now you can add advanced stats that weren't available before:

```sql
-- Example: Add percentage-based stats to an item
-- Get an item ID first
SELECT id, item_code, item_name FROM items LIMIT 5;

-- Let's say you want to add stats to item 'I000'
-- Add +2% HP regeneration per second (ability-based)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    6,     -- HP Pct Per Sec
    0.02,  -- 2%
    TRUE   -- Display as percentage
);

-- Add +25% Attack Speed (ability-based)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    20,    -- Attack Speed
    0.25,  -- 25%
    TRUE
);

-- Add +15% Critical Chance (global variable)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    10,    -- Critical Chance
    0.15,  -- 15%
    TRUE
);

-- Add +20% Lifesteal (ability-based)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    22,    -- Lifesteal Pct
    0.20,  -- 20%
    TRUE
);

-- View all stats for this item
SELECT * FROM v_item_stats WHERE item_code = 'I000';
```

---

## Step 8: Test the Enhanced Exporter

```powershell
# Export a single item for testing
python wc3_exporter_enhanced.py --output test_export.j --format deq_enhanced --items I000

# View the generated file
notepad test_export.j
```

**Expected output:**

```jass
library DEquipmentItemsEnhanced initializer InitDEqItems requires SharedDInvLib

globals
    constant integer STATID_STR = 1   // Strength
    constant integer STATID_AGI = 2   // Agility
    constant integer STATID_INT = 3   // Intelligence
    constant integer STATID_HP = 4    // Hitpoints
    // ... (all 39 stats)
endglobals

//===========================================================================
// Your Item Name ('I000')
//===========================================================================
function DEqSetup_I000 takes nothing returns nothing
    local integer iid = 'I000'
    
    // Native stats
    call DEqSetStatBonus(iid, 1, 50)  // STR: 50
    call DEqSetStatBonus(iid, 25, 10)  // Armor: 10
    
    // Ability-based stats
    call DEqSetStatBonus(iid, 6, 0.02)  // HP%/sec: 2.0% (ability 'DQLR')
    call DEqSetStatBonus(iid, 20, 0.25)  // IAS: 25.0% (ability 'DQAS')
    call DEqSetStatBonus(iid, 22, 0.20)  // Lifesteal: 20.0% (ability 'DQLS')
    
    // Global variable stats
    call DEqSetStatBonus(iid, 10, 0.15)  // Crit: 15.0% (uses udg_Stats_Crit)
    
endfunction

function InitDEqItems takes nothing returns nothing
    call DEqSetup_I000()
endfunction

endlibrary
```

---

## Step 9: Export All Items

Once you've verified the test export works:

```powershell
# Export all items with full statid support
python wc3_exporter_enhanced.py --output exports\items_deq_all.j --format deq_enhanced

# Or export specific items
python wc3_exporter_enhanced.py --output exports\legendary_items.j --format deq_enhanced --items I000 I001 I002
```

---

## Troubleshooting

### Problem: "relation 'stat_definitions' does not exist"

**Solution:** The enhancement schema wasn't applied correctly.

```powershell
# Re-apply the enhancement
psql -U postgres -d wc3_pots -f schema_stats_enhancement.sql
```

### Problem: "column 'item_id' does not exist in item_bonuses"

**Solution:** Your old `item_bonuses` table has different column names.

```sql
-- Check the structure
\d item_bonuses

-- Adjust the migration queries based on your actual column names
```

### Problem: Migration inserts fail with "duplicate key value"

**Solution:** Data already exists. Use `DO NOTHING` clause or update the script.

```sql
-- This is safe to re-run
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value)
SELECT id, 1, strength_bonus FROM items WHERE strength_bonus != 0
ON CONFLICT (item_id, statid) DO NOTHING;
```

### Problem: Python script says "module 'psycopg2' not found"

**Solution:** Install required packages

```powershell
pip install -r requirements.txt
```

### Problem: Export generates empty files

**Solution:** Check database connection and verify items exist

```sql
SELECT COUNT(*) FROM items;
SELECT COUNT(*) FROM item_stat_bonuses;
SELECT * FROM v_item_stats LIMIT 5;
```

---

## Quick Reference: StatID Lookup

Most commonly used stats:

| StatID | Short Name | Display As % | Type |
|--------|------------|--------------|------|
| 1 | STR | No | Flat |
| 2 | AGI | No | Flat |
| 3 | INT | No | Flat |
| 4 | HP | No | Flat |
| 6 | HP%/sec | Yes | % |
| 12 | DMG | No | Flat |
| 20 | IAS | Yes | % |
| 22 | Lifesteal | Yes | % |
| 25 | Armor | No | Flat |
| 31 | MS | No | Flat |

**See [STAT_SYSTEM_REFERENCE.md](STAT_SYSTEM_REFERENCE.md) for complete list of all 39 stats.**

---

## Rollback (If Needed)

If something goes wrong and you need to rollback:

```powershell
# Restore from backup
$env:PGPASSWORD="your_password"
psql -U postgres -d wc3_pots < backup_before_statid_20260310_143000.sql
```

---

## Next Steps

After successful migration:

1. ✅ Add more stat bonuses to your items using statids
2. ✅ Use views like `v_item_stats` for easy querying
3. ✅ Export to JASS with `wc3_exporter_enhanced.py`
4. ✅ Integrate exported JASS into your WC3 map
5. ✅ Test in-game with DEquipment system

---

## Support Files

- **Complete Stat Reference:** [STAT_SYSTEM_REFERENCE.md](STAT_SYSTEM_REFERENCE.md)
- **Quick Overview:** [ENHANCEMENT_SUMMARY.md](ENHANCEMENT_SUMMARY.md)
- **Database Schema:** [schema_stats_enhancement.sql](schema_stats_enhancement.sql)
- **Enhanced Exporter:** [wc3_exporter_enhanced.py](wc3_exporter_enhanced.py)

---

## Summary Checklist

- [ ] Backup current database
- [ ] Configure database.ini with credentials
- [ ] Apply schema_stats_enhancement.sql
- [ ] Verify stat_definitions has 39 rows
- [ ] Verify ability_codes has 16 rows
- [ ] Migrate existing item stats (if any)
- [ ] Add new enhanced stats to items
- [ ] Test export with single item
- [ ] Export all items
- [ ] Integrate JASS into map
- [ ] Test in-game

**You're ready to use the full 39-stat DEquipment system! 🎉**
