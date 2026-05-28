# WC3 POTS Database - StatID System Enhancement Summary

## Overview

✅ **Database schema now covers ALL stats from SharedDInvLib.j**  
✅ **All 39 statids from DEquipment system are defined**  
✅ **16 ability raw codes ('DQLR', 'DQMR', etc.) are documented**  
✅ **3 stat application methods are supported (NATIVE, ABILITY, GLOBAL_VAR)**  
✅ **Enhanced exporter with full statid support created**

---

## What Was Created

### 1. Enhanced Database Schema
**File:** [schema_stats_enhancement.sql](schema_stats_enhancement.sql)

Three new tables added:

#### `stat_definitions` (39 rows)
- Complete definition of all statids 1-39
- Includes stat names, display names, short names
- Tracks application method (NATIVE/ABILITY/GLOBAL_VAR)
- Stores ability codes and field names
- Stores native function names or global variable names

#### `ability_codes` (16 rows)
- All WC3 ability codes used by stat system
- Field parameters (e.g., 'Oar1', 'Arm1', 'Ear1')
- Documentation of which stats use which abilities
- Notes about multi-field abilities

#### `item_stat_bonuses` (replacement for generic item_bonuses)
- Links items to statids
- Stores bonus values with proper typing
- Supports both flat and percentage bonuses
- Foreign key to stat_definitions ensures data integrity

### 2. Enhanced Exporter
**File:** [wc3_exporter_enhanced.py](wc3_exporter_enhanced.py)

New features:
- Loads stat_definitions and ability_codes into cache on connect
- Generates JASS code with proper statid constants
- Groups stats by application method in comments
- Exports with full stat details (name, value, ability code, field)
- Creates DEqSetup functions with all stat bonuses

### 3. Complete Documentation
**File:** [STAT_SYSTEM_REFERENCE.md](STAT_SYSTEM_REFERENCE.md)

Includes:
- Complete 39-stat reference table with all details
- Application method explanations with code examples
- Ability codes reference with field mappings
- Database schema documentation
- SQL usage examples
- Export guide with Python examples
- Migration guide from old system
- Quick reference tables

---

## Complete Stat Coverage Verification

### All 39 Stats from SharedDInvLib.j

| Category | StatIDs | Status |
|----------|---------|--------|
| Attributes & HP | 1-5 | ✅ COVERED |
| Regen Percentages | 6, 7-9 | ✅ COVERED |
| Critical Stats | 10-11 | ✅ COVERED |
| Damage Stats | 12-17 | ✅ COVERED |
| Cleave Stats | 18-19 | ✅ COVERED |
| Attack Stats | 20-21 | ✅ COVERED |
| Lifesteal & Thorns | 22-24 | ✅ COVERED |
| Armor & Evasion | 25-27 | ✅ COVERED |
| Damage Taken | 28-30 | ✅ COVERED |
| Movement & Sight | 31-33 | ✅ COVERED |
| Miscellaneous | 34-36 | ✅ COVERED |
| Spell Power | 37-39 | ✅ COVERED |

### All Ability Codes from DEqSubtractSetStats

| Ability Code | Field(s) | Status |
|--------------|----------|--------|
| DQLR | Oar1 | ✅ DOCUMENTED |
| DQMR | Arm1 | ✅ DOCUMENTED |
| DQTM | Ear1 | ✅ DOCUMENTED |
| DQTS | Ear1 | ✅ DOCUMENTED |
| DQMS | ABILITY_ILF_MOVEMENT_SPEED_BONUS | ✅ DOCUMENTED |
| DQHM | ABILITY_RLF_MOVEMENT_SPEED_INCREASE_PERCENT_UAU1 | ✅ DOCUMENTED |
| DQAS | ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1 | ✅ DOCUMENTED |
| DQEV | ABILITY_RLF_CHANCE_TO_EVADE_EEV1 | ✅ DOCUMENTED (disabled) |
| DQLS | ABILITY_RLF_LIFE_STOLEN_PER_ATTACK | ✅ DOCUMENTED |
| DQTF | Eah1 | ✅ DOCUMENTED |
| DQSC | Uts1, Uts2 | ✅ DOCUMENTED |
| DQEG | ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5, ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1 | ✅ DOCUMENTED |
| DQMF | Ear1 | ✅ DOCUMENTED |
| DQRF | Ear1 | ✅ DOCUMENTED |
| DQCS | Ocr1, ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2 | ✅ DOCUMENTED (disabled) |
| DQCL | ABILITY_RLF_DISTRIBUTED_DAMAGE_FACTOR_NCA1, aare | ✅ DOCUMENTED |

---

## Usage Examples

### 1. Install Enhanced Schema

```bash
cd WC3_Database
psql -U postgres -d wc3_pots -f schema_stats_enhancement.sql
```

This will create:
- `stat_definitions` table with 39 stats
- `ability_codes` table with 16 abilities
- `item_stat_bonuses` table
- Helper views (`v_item_stats`, `v_item_ability_stats`, `v_stat_application_summary`)
- Migration function

### 2. Add Stats to Items

```sql
-- Add +50 Strength to an item
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    1,  -- StatID for Strength
    50
);

-- Add +2% HP regen per second (ability-based)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    6,  -- StatID for HP Pct Per Sec (uses ability DQLR)
    0.02,  -- 2%
    TRUE
);

-- Add +25% Attack Speed (ability-based)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    20,  -- StatID for Attack Speed (uses ability DQAS)
    0.25,  -- 25%
    TRUE
);
```

### 3. Query Item Stats

```sql
-- View all stats for an item
SELECT * FROM v_item_stats WHERE item_code = 'I000';

-- Find items with ability-based stats
SELECT * FROM v_item_ability_stats WHERE item_code = 'I000';

-- Get stat application summary
SELECT * FROM v_stat_application_summary;
```

### 4. Export to JASS

```bash
python wc3_exporter_enhanced.py --output exports/items_deq.j --format deq_enhanced
```

Generated JASS will look like:

```jass
library DEquipmentItemsEnhanced initializer InitDEqItems requires SharedDInvLib

globals
    constant integer STATID_STR = 1   // Strength
    constant integer STATID_AGI = 2   // Agility
    constant integer STATID_INT = 3   // Intelligence
    constant integer STATID_HP = 4    // Hitpoints
    // ... all 39 stats
endglobals

function DEqSetup_I000 takes nothing returns nothing
    local integer iid = 'I000'
    
    // Native stats
    call DEqSetStatBonus(iid, 1, 50)  // STR: 50
    
    // Ability-based stats
    call DEqSetStatBonus(iid, 6, 0.02)  // HP%/sec: 2.0% (ability 'DQLR')
    call DEqSetStatBonus(iid, 20, 0.25)  // IAS: 25.0% (ability 'DQAS')
endfunction

function InitDEqItems takes nothing returns nothing
    call DEqSetup_I000()
endfunction

endlibrary
```

---

## Key Features

### 1. Complete Stat Coverage
All 39 statids from SharedDInvLib.j are defined and ready to use.

### 2. Ability Code Mapping
Every ability code ('DQLR', 'DQMR', etc.) is documented with:
- Field names ('Oar1', 'Arm1', 'Ear1', etc.)
- Which statids use that ability
- Whether the ability is active or disabled in code

### 3. Application Method Tracking
Stats are categorized by how they're applied:
- **NATIVE:** 13 stats using WC3 native functions
- **ABILITY:** 16 stats using custom WC3 abilities
- **GLOBAL_VAR:** 10 stats using global arrays (DamageEngine/custom systems)

### 4. Proper Value Handling
- Flat bonuses (e.g., +50 HP, +10 Armor)
- Percentage bonuses (e.g., +25% IAS, +2% HP/sec)
- Display formatting (whether to show as %)

### 5. Data Integrity
- Foreign keys ensure valid statids
- Unique constraints prevent duplicate stat bonuses per item
- Active/inactive flags for stats and abilities

### 6. Helper Views
- `v_item_stats`: Complete item stat information
- `v_item_ability_stats`: Items with ability-based stats only
- `v_stat_application_summary`: Stats grouped by application method

---

## Differences from Original Database

### OLD System:
❌ Generic `item_bonuses` table with `bonus_type` VARCHAR  
❌ No statid enforcement  
❌ Hardcoded stat names in exporter  
❌ Limited stat types  
❌ No ability code tracking  

### NEW System:
✅ `item_stat_bonuses` table with `statid` INTEGER foreign key  
✅ All 39 statids enforced via stat_definitions  
✅ Dynamic stat lookup in exporter  
✅ Complete 39-stat system  
✅ ability_codes table with field mappings  

---

## Files Created/Modified

### New Files:
1. **schema_stats_enhancement.sql** (525 lines)
   - stat_definitions table with 39 inserts
   - ability_codes table with 16 inserts
   - item_stat_bonuses table
   - Views and helper functions

2. **wc3_exporter_enhanced.py** (450 lines)
   - Enhanced exporter with statid support
   - Loads stat definitions on connect
   - Generates proper JASS with stat constants
   - Groups stats by application method

3. **STAT_SYSTEM_REFERENCE.md** (900+ lines)
   - Complete stat reference tables
   - Application method documentation
   - Ability codes reference
   - Usage examples and migration guide

### Existing Files (Unchanged):
- Original schema.sql still exists for reference
- Original wc3_exporter.py still exists for basic exports
- All other database files remain functional

---

## Next Steps

### 1. Install the Enhanced Schema

```bash
cd WC3_Database
psql -U postgres -d wc3_pots -f schema_stats_enhancement.sql
```

### 2. Migrate Existing Data (Optional)

If you have existing items with generic bonuses in `item_bonuses`:

```sql
-- Map old bonus_type to statids
-- Customize this based on your data
SELECT * FROM migrate_item_bonuses_to_statids();
```

### 3. Start Using StatIDs

```sql
-- Add some stats to a test item
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
SELECT id, 1, 50, FALSE FROM items WHERE item_code = 'I000'  -- +50 STR
UNION ALL
SELECT id, 20, 0.25, TRUE FROM items WHERE item_code = 'I000';  -- +25% IAS
```

### 4. Export and Test

```bash
python wc3_exporter_enhanced.py --output test_export.j --format deq_enhanced --items I000
```

Review the generated JASS code to verify correct stat export.

### 5. Integrate with Your Map

Copy the generated JASS code into your map and ensure:
- SharedDInvLib.j is included
- All ability codes exist in your Object Editor
- DEquipment system is initialized

---

## Support

**Reference Documentation:** See [STAT_SYSTEM_REFERENCE.md](STAT_SYSTEM_REFERENCE.md)  
**Schema File:** See [schema_stats_enhancement.sql](schema_stats_enhancement.sql)  
**Enhanced Exporter:** See [wc3_exporter_enhanced.py](wc3_exporter_enhanced.py)  
**Original System:** See SharedDInvLib.j lines 860-920 (stat definitions) and 2600-3100 (stat application)

---

## Verification Checklist

✅ All 39 statids from DEquipment system are defined in stat_definitions table  
✅ All 16 ability codes are defined in ability_codes table  
✅ Every ability code has field parameters documented  
✅ item_stat_bonuses table links items to statids with foreign key  
✅ Enhanced exporter properly uses statid system  
✅ Documentation covers all stats with examples  
✅ Views created for easy querying  
✅ Migration function provided for existing data  

**Status: ✅ COMPLETE - Database now fully supports DEquipment stat system**
