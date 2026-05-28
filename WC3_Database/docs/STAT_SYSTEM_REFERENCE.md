# WC3 POTS Database - Stat System Complete Reference
## DEquipment StatID System Documentation

**Version:** 2.0.0  
**Last Updated:** 2026-03-10  
**Database Enhancement:** Full 39-stat DEquipment system integration

---

## Table of Contents

1. [Overview](#overview)
2. [Complete Stat List](#complete-stat-list)
3. [Application Methods](#application-methods)
4. [Ability Codes Reference](#ability-codes-reference)
5. [Database Schema](#database-schema)
6. [Usage Examples](#usage-examples)
7. [Export Guide](#export-guide)

---

## Overview

The WC3 POTS database has been enhanced to support the complete DEquipment stat system from SharedDInvLib.j. This includes:

- **39 distinct statids** (numbered 1-39)
- **16 custom ability codes** for dynamic stat application
- **3 application methods**: NATIVE, ABILITY, GLOBAL_VAR
- **Full integration** with item_stat_bonuses table

### Key Features

✅ All 39 stats from DEquipment system  
✅ Ability codes with field parameters  
✅ Application method tracking  
✅ Enhanced exporter with statid support  
✅ View-based queries for easy access  
✅ Migration functions for existing data  

---

## Complete Stat List

### Attributes & HP (StatID 1-5)

| StatID | Name | Short | Display% | Method | Function/Ability | Description |
|--------|------|-------|----------|--------|------------------|-------------|
| 1 | Strength | STR | No | NATIVE | SetHeroStr | Hero strength attribute |
| 2 | Agility | AGI | No | NATIVE | SetHeroAgi | Hero agility attribute |
| 3 | Intelligence | INT | No | NATIVE | SetHeroInt | Hero intelligence attribute |
| 4 | Hitpoints | HP | No | NATIVE | BlzSetUnitMaxHP | Maximum hit points |
| 5 | Hitpoint regeneration | HPS | No | NATIVE | BlzSetUnitRealField (UNIT_RF_HIT_POINTS_REGENERATION_RATE) | HP regen per second |

### Regeneration Percentages (StatID 6, 9)

| StatID | Name | Short | Display% | Method | Ability | Field | Description |
|--------|------|-------|----------|--------|---------|-------|-------------|
| 6 | HP Pct Per Sec | HP%/sec | Yes | ABILITY | DQLR | Oar1 | HP regen as % of max HP/sec |
| 7 | Mana | Mana | No | NATIVE | BlzSetUnitMaxMana | Maximum mana |
| 8 | Mana regeneration | MPS | No | NATIVE | BlzSetUnitRealField (UNIT_RF_MANA_REGENERATION) | Mana regen per second |
| 9 | Mana Pct Per Sec | Mana%/sec | Yes | ABILITY | DQMR | Arm1 | Mana regen as % of max mana/sec |

### Critical Stats (StatID 10-11)

| StatID | Name | Short | Display% | Method | Global Variable | Description |
|--------|------|-------|----------|--------|-----------------|-------------|
| 10 | Critical Chance | Crit | Yes | GLOBAL_VAR | udg_Stats_Crit | Chance to deal critical damage |
| 11 | Critical Damage | CritDMG | Yes | ABILITY | udg_Stats_Crit (field: ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2 - disabled) | Critical strike damage multiplier |

### Damage Stats (StatID 12-17)

| StatID | Name | Short | Display% | Method | Ability/Function | Field | Description |
|--------|------|-------|----------|--------|------------------|-------|-------------|
| 12 | Damage | DMG | No | NATIVE | BlzSetUnitBaseDamage | Base damage for both weapons |
| 13 | Damage Pct | DMG% | Yes | ABILITY | DQTM + DQTS | Ear1 | % damage for melee+ranged |
| 14 | Melee Damage | MeleeDMG | No | ABILITY | DQMF | Ear1 | Flat melee damage only |
| 15 | Melee DMG Pct | MeleeDMG% | Yes | ABILITY | DQTM | Ear1 | % melee damage (stacks with 13) |
| 16 | Ranged Damage | RangedDMG | No | ABILITY | DQRF | Ear1 | Flat ranged damage only |
| 17 | Ranged DMG Pct | RangedDMG% | Yes | ABILITY | DQTS | Ear1 | % ranged damage (stacks with 13) |

### Cleave Stats (StatID 18-19)

| StatID | Name | Short | Display% | Method | Ability | Field | Description |
|--------|------|-------|----------|--------|---------|-------|-------------|
| 18 | Cleave Pct | Cleave% | Yes | ABILITY | DQCL | ABILITY_RLF_DISTRIBUTED_DAMAGE_FACTOR_NCA1 | % damage to nearby enemies |
| 19 | Cleave Damage | CleaveAOE | No | ABILITY | DQCL | aare | Cleave area radius bonus |

### Attack Stats (StatID 20-21)

| StatID | Name | Short | Display% | Method | Ability/Field | Field | Description |
|--------|------|-------|----------|--------|---------------|-------|-------------|
| 20 | Attack Speed | IAS | Yes | ABILITY | DQAS | ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1 | Attack speed % increase |
| 21 | Attack Range | Range | No | NATIVE | BlzSetUnitWeaponRealField | ua1r | Attack range bonus |

### Lifesteal & Thorns (StatID 22-24)

| StatID | Name | Short | Display% | Method | Ability | Field | Description |
|--------|------|-------|----------|--------|---------|-------|-------------|
| 22 | Lifesteal Pct | Lifesteal | Yes | ABILITY | DQLS | ABILITY_RLF_LIFE_STOLEN_PER_ATTACK | % damage returned as HP |
| 23 | Thorns | Thorns | No | ABILITY | DQTF | Eah1 | Flat damage to attackers |
| 24 | Thorns Pct | Thorns% | Yes | ABILITY | DQSC | Uts1 | % damage to attackers |

### Armor & Evasion (StatID 25-27)

| StatID | Name | Short | Display% | Method | Function/Variable | Description |
|--------|------|-------|----------|--------|-------------------|-------------|
| 25 | Armor | Armor | No | NATIVE | BlzSetUnitArmor | Flat armor bonus |
| 26 | Armor Pct | Armor% | Yes | NATIVE | BlzSetUnitArmor (calculated) | % armor bonus |
| 27 | Dodge | Evasion | Yes | GLOBAL_VAR | udg_Stats_Dodge | Dodge/evasion chance |

### Damage Taken (StatID 28-30)

| StatID | Name | Short | Display% | Method | Ability | Field | Description |
|--------|------|-------|----------|--------|---------|-------|-------------|
| 28 | Spell Damage Taken Pct | SpellTaken% | Yes | ABILITY | DQEG | ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5 | Spell damage taken modifier |
| 29 | Melee Damage Taken Pct | MeleeTaken% | Yes | ABILITY | DQSC | Uts2 | Melee damage taken modifier |
| 30 | Pierce Damage Taken Pct | PierceTaken% | Yes | ABILITY | DQEG | ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1 | Pierce damage taken modifier |

### Movement & Sight (StatID 31-33)

| StatID | Name | Short | Display% | Method | Ability/Field | Field | Description |
|--------|------|-------|----------|--------|---------------|-------|-------------|
| 31 | Movement Speed | MS | No | ABILITY | DQMS | ABILITY_ILF_MOVEMENT_SPEED_BONUS | Flat movement speed |
| 32 | MoveSPD Pct | MS% | Yes | ABILITY | DQHM | ABILITY_RLF_MOVEMENT_SPEED_INCREASE_PERCENT_UAU1 | % movement speed |
| 33 | Sight Range | Sight | No | NATIVE | BlzSetUnitRealField | usir | Vision range bonus |

### Miscellaneous (StatID 34-36)

| StatID | Name | Short | Display% | Method | Function/Variable | Description |
|--------|------|-------|----------|--------|-------------------|-------------|
| 34 | Inventory Space | InvSpace | No | NATIVE | DInvDeltaAdditionalSlotsForUnit | Additional inventory slots |
| 35 | Block Chance | Block | Yes | GLOBAL_VAR | udg_Stats_Block | Chance to block attacks |
| 36 | Hit Chance | Hit | Yes | GLOBAL_VAR | udg_Stats_Hit | Chance for attacks to hit |

### Spell Power (StatID 37-39)

| StatID | Name | Short | Display% | Method | Variable | Description |
|--------|------|-------|----------|--------|----------|-------------|
| 37 | Spell Power Pct | SpellPower% | Yes | GLOBAL_VAR | udg_Stats_SpellPowerPct | % spell power |
| 38 | Spell Power | SpellPower | Yes | GLOBAL_VAR | udg_Stats_SpellPowerFlat | Flat spell power |
| 39 | Healing Power | HealPower | Yes | GLOBAL_VAR | TBD | Healing effectiveness % |

---

## Application Methods

### NATIVE (Direct WC3 Functions)

**Description:** Stats applied through native WC3 functions like `SetHeroStr`, `BlzSetUnitMaxHP`, etc.

**Stats:** 1, 2, 3, 4, 5, 7, 8, 12, 21, 25, 26, 33, 34

**Example:**
```jass
// StatID 1: Strength
call SetHeroStr(u, GetHeroStr(u, FALSE) + 10, TRUE)

// StatID 4: Max HP
call BlzSetUnitMaxHP(u, GetUnitState(u, UNIT_STATE_MAX_LIFE) + 500)

// StatID 25: Armor
call BlzSetUnitArmor(u, BlzGetUnitArmor(u) + 5.0)
```

**Database Storage:** Store value directly in `item_stat_bonuses.bonus_value`

### ABILITY (WC3 Abilities)

**Description:** Stats applied by adding custom WC3 abilities to units and modifying ability fields.

**Stats:** 6, 9, 13, 14, 15, 16, 17, 18, 19, 20, 22, 23, 24, 28, 29, 30, 31, 32

**Example:**
```jass
// StatID 6: HP% Per Second (ability DQLR)
if GetUnitAbilityLevel(u, 'DQLR') < 1 then
    call UnitAddAbility(u, 'DQLR')
endif
set a = BlzGetUnitAbility(u, 'DQLR')
call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Oar1'), 0, 0.02)  // 2% HP/sec
call IncUnitAbilityLevel(u, 'DQLR')
call DecUnitAbilityLevel(u, 'DQLR')

// StatID 20: Attack Speed (ability DQAS)
call UnitAddAbility(u, 'DQAS')
set a = BlzGetUnitAbility(u, 'DQAS')
call BlzSetAbilityRealLevelField(a, ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1, 0, 0.25)  // 25% IAS
call IncUnitAbilityLevel(u, 'DQAS')
call DecUnitAbilityLevel(u, 'DQAS')
```

**Database Storage:** Store value in `item_stat_bonuses.bonus_value`, ability code in `stat_definitions.ability_code`

### GLOBAL_VAR (Global Variables)

**Description:** Stats stored in global arrays, typically handled by DamageEngine or custom combat systems.

**Stats:** 10, 27, 35, 36, 37, 38, 39

**Example:**
```jass
// StatID 10: Critical Chance
set udg_Stats_Crit[GetUnitUserData(u)] = udg_Stats_Crit[GetUnitUserData(u)] + 15  // +15% crit

// StatID 27: Dodge/Evasion
set udg_Stats_Dodge[GetUnitUserData(u)] = udg_Stats_Dodge[GetUnitUserData(u)] + 10  // +10% dodge

// StatID 37: Spell Power%
set udg_Stats_SpellPowerPct[GetUnitUserData(u)] = udg_Stats_SpellPowerPct[GetUnitUserData(u)] + 20  // +20%
```

**Database Storage:** Store value in `item_stat_bonuses.bonus_value`, variable name in `stat_definitions.global_variable`

---

## Ability Codes Reference

### Complete List

| Code | Name | Base Ability | Field 1 | Field 2 | Used By Stats | Notes |
|------|------|--------------|---------|---------|---------------|-------|
| DQLR | HP Regen % | Life Regeneration Aura | Oar1 | - | 6 | HP% regen per second |
| DQMR | Mana Regen % | Mana Regeneration Aura | Arm1 | - | 9 | Mana% regen per second |
| DQTM | Melee DMG % | Trueshot Aura (Melee) | Ear1 | - | 13, 15 | Melee damage% increase |
| DQTS | Ranged DMG % | Trueshot Aura (Ranged) | Ear1 | - | 13, 17 | Ranged damage% increase |
| DQMS | Move Speed Flat | Movement Speed | ABILITY_ILF_MOVEMENT_SPEED_BONUS | - | 31 | Flat MS bonus |
| DQHM | Move Speed % | Slow Aura (Modified) | ABILITY_RLF_MOVEMENT_SPEED_INCREASE_PERCENT_UAU1 | - | 32 | MS% increase |
| DQAS | Attack Speed | Attack Speed | ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1 | - | 20 | IAS% increase |
| DQEV | Evasion | Evasion | ABILITY_RLF_CHANCE_TO_EVADE_EEV1 | - | 27 | DISABLED - uses udg_Stats_Dodge |
| DQLS | Lifesteal | Life Steal | ABILITY_RLF_LIFE_STOLEN_PER_ATTACK | - | 22 | Lifesteal % |
| DQTF | Thorns Flat | Thorns Aura | Eah1 | - | 23 | Returns flat damage |
| DQSC | Spiked Carapace | Spiked Carapace | Uts1 | Uts2 | 24, 29 | Thorns% + Melee DMG Taken% |
| DQEG | Elegant Grace | Defensive Aura | ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5 | ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1 | 28, 30 | Spell + Pierce DMG Taken% |
| DQMF | Melee DMG Flat | Trueshot (Melee Flat) | Ear1 | - | 14 | Flat melee damage |
| DQRF | Ranged DMG Flat | Trueshot (Ranged Flat) | Ear1 | - | 16 | Flat ranged damage |
| DQCS | Critical Strike | Critical Strike | Ocr1 | ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2 | 10, 11 | DISABLED - uses udg_Stats_Crit |
| DQCL | Cleaving Attack | Cleaving Attack | ABILITY_RLF_DISTRIBUTED_DAMAGE_FACTOR_NCA1 | aare | 18, 19 | Cleave% + Area |

### Multi-Field Abilities

Some abilities use multiple fields for different stats:

**DQSC (Spiked Carapace):**
- Field `Uts1`: Thorns % (StatID 24)
- Field `Uts2`: Melee Damage Taken % (StatID 29)

**DQEG (Elegant Grace):**
- Field `ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5`: Spell Damage Taken % (StatID 28)
- Field `ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1`: Pierce Damage Taken % (StatID 30)

**DQCL (Cleaving Attack):**
- Field `ABILITY_RLF_DISTRIBUTED_DAMAGE_FACTOR_NCA1`: Cleave % (StatID 18)
- Field `aare`: Cleave Area bonus (StatID 19)

---

## Database Schema

### stat_definitions

Primary table defining all 39 stats:

```sql
CREATE TABLE stat_definitions (
    statid INTEGER PRIMARY KEY,
    stat_name VARCHAR(100) NOT NULL UNIQUE,
    stat_display_name VARCHAR(100) NOT NULL,
    stat_short_name VARCHAR(50),
    display_as_percent BOOLEAN DEFAULT FALSE,
    application_method VARCHAR(50) NOT NULL,  -- 'NATIVE', 'ABILITY', 'GLOBAL_VAR'
    ability_code CHAR(4),
    ability_field VARCHAR(100),
    native_function VARCHAR(100),
    global_variable VARCHAR(100),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### ability_codes

Lookup table for WC3 ability codes:

```sql
CREATE TABLE ability_codes (
    ability_code CHAR(4) PRIMARY KEY,
    ability_name VARCHAR(100) NOT NULL,
    ability_base VARCHAR(100),
    description TEXT,
    used_by_stats TEXT,  -- Comma-separated statids
    field_1_name VARCHAR(100),
    field_2_name VARCHAR(100),
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### item_stat_bonuses

Links items to their stat bonuses:

```sql
CREATE TABLE item_stat_bonuses (
    id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    statid INTEGER NOT NULL REFERENCES stat_definitions(statid),
    bonus_value DECIMAL(12,4) NOT NULL,
    bonus_value_percent BOOLEAN DEFAULT FALSE,
    is_flat_bonus BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(item_id, statid)
);
```

---

## Usage Examples

### 1. Add Stats to an Item

```sql
-- Add +50 Strength (StatID 1) to item
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    1,  -- Strength
    50
);

-- Add +2% HP per second (StatID 6, ability-based)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    6,  -- HP Pct Per Sec
    0.02,  -- Store as decimal (2%)
    TRUE   -- Display as percentage
);

-- Add +25% Attack Speed (StatID 20, ability-based)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    20,  -- Attack Speed
    0.25,  -- Store as decimal (25%)
    TRUE
);
```

### 2. Query Items with Specific Stats

```sql
-- Find all items with Strength bonuses
SELECT 
    i.item_code,
    i.item_name,
    isb.bonus_value,
    sd.stat_display_name
FROM items i
JOIN item_stat_bonuses isb ON i.id = isb.item_id
JOIN stat_definitions sd ON isb.statid = sd.statid
WHERE sd.statid = 1
ORDER BY isb.bonus_value DESC;

-- Find all items that use abilities (requires UnitAddAbility)
SELECT DISTINCT
    i.item_code,
    i.item_name,
    sd.ability_code,
    ac.ability_name
FROM items i
JOIN item_stat_bonuses isb ON i.id = isb.item_id
JOIN stat_definitions sd ON isb.statid = sd.statid
JOIN ability_codes ac ON sd.ability_code = ac.ability_code
WHERE sd.application_method = 'ABILITY'
ORDER BY i.item_code;

-- Find items with critical strike (global var stats)
SELECT 
    i.item_code,
    i.item_name,
    isb.bonus_value,
    sd.stat_display_name
FROM items i
JOIN item_stat_bonuses isb ON i.id = isb.item_id
JOIN stat_definitions sd ON isb.statid = sd.statid
WHERE sd.statid IN (10, 11)  -- Crit chance & crit damage
ORDER BY isb.statid, isb.bonus_value DESC;
```

### 3. Export Items to JASS

```bash
# Export all items with full statid support
python wc3_exporter_enhanced.py --output exports/items_deq.j --format deq_enhanced

# Export specific items only
python wc3_exporter_enhanced.py --output exports/legendary_items.j --format deq_enhanced --items I000 I001 I002
```

### 4. View Item Stats Summary

```sql
-- Using the v_item_stats view
SELECT 
    item_code,
    item_name,
    stat_short_name,
    bonus_value,
    application_method,
    ability_code
FROM v_item_stats
WHERE item_code = 'I000'
ORDER BY statid;
```

---

## Export Guide

### Using wc3_exporter_enhanced.py

The enhanced exporter generates proper JASS code with statid support:

```python
from wc3_exporter_enhanced import WC3ItemExporterEnhanced

db_config = {
    'host': 'localhost',
    'port': '5432',
    'database': 'wc3_pots',
    'user': 'postgres',
    'password': 'your_password'
}

exporter = WC3ItemExporterEnhanced(db_config)
exporter.connect()

# Export all items
exporter.export_to_deq_config('output/items_deq.j')

# Export specific items
exporter.export_to_deq_config('output/special_items.j', item_codes=['I000', 'I001'])

exporter.disconnect()
```

### Generated JASS Output

```jass
library DEquipmentItemsEnhanced initializer InitDEqItems requires SharedDInvLib

globals
    constant integer STATID_STR = 1   // Strength
    constant integer STATID_AGI = 2   // Agility
    constant integer STATID_INT = 3   // Intelligence
    //... (all 39 stats)
endglobals

//===========================================================================
// Sword of Legends ('I000')
//===========================================================================
function DEqSetup_I000 takes nothing returns nothing
    local integer iid = 'I000'
    
    // Native stats (applied via SetHeroStr, BlzSetUnitMaxHP, etc.)
    call DEqSetStatBonus(iid, 1, 50)  // STR: 50
    call DEqSetStatBonus(iid, 12, 100)  // DMG: 100
    
    // Ability-based stats (applied via WC3 abilities)
    // Note: Items with these stats will add abilities to units when equipped
    call DEqSetStatBonus(iid, 6, 0.02)  // HP%/sec: 2.0% (ability 'DQLR')
    call DEqSetStatBonus(iid, 20, 0.25)  // IAS: 25.0% (ability 'DQAS')
    
endfunction

function InitDEqItems takes nothing returns nothing
    call DEqSetup_I000()
endfunction

endlibrary
```

---

## Migration from Old System

### Step 1: Install Enhanced Schema

```bash
psql -U postgres -d wc3_pots -f schema_stats_enhancement.sql
```

### Step 2: Migrate Existing Data

```sql
-- Map old item_bonuses to new statid system
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value)
SELECT 
    item_id,
    CASE bonus_type
        WHEN 'strength' THEN 1
        WHEN 'agility' THEN 2
        WHEN 'intelligence' THEN 3
        WHEN 'hp' THEN 4
        WHEN 'armor' THEN 25
        WHEN 'damage' THEN 12
        WHEN 'attack_speed' THEN 20
        WHEN 'movement_speed' THEN 31
    END,
    bonus_value
FROM item_bonuses
WHERE bonus_type IN ('strength', 'agility', 'intelligence', 'hp', 'armor', 'damage', 'attack_speed', 'movement_speed')
ON CONFLICT (item_id, statid) DO NOTHING;
```

### Step 3: Verify Migration

```sql
SELECT COUNT(*) FROM item_stat_bonuses;
SELECT * FROM v_item_stats LIMIT 10;
```

---

## Quick Reference

### Most Common Stats

| StatID | Short Name | Type | Common Use |
|--------|------------|------|------------|
| 1 | STR | Flat | Hero attribute |
| 2 | AGI | Flat | Hero attribute |
| 3 | INT | Flat | Hero attribute |
| 4 | HP | Flat | Bonus hitpoints |
| 12 | DMG | Flat | Weapon damage |
| 20 | IAS | % | Attack speed |
| 25 | Armor | Flat | Armor value |
| 31 | MS | Flat | Movement speed |

### Percentage-Based Stats

- StatID 6, 9: HP%/sec, Mana%/sec
- StatID 10, 11: Critical chance & damage
- StatID 13, 15, 17: Damage %
- StatID 18: Cleave %
- StatID 20: Attack speed
- StatID 22: Lifesteal
- StatID 24: Thorns %
- StatID 27: Evasion
- StatID 28, 29, 30: Damage taken %
- StatID 32: Movement speed %
- StatID 35, 36: Block & Hit chance
- StatID 37, 38, 39: Spell & Healing power

---

## Support & Further Information

**Database Schema:** See `schema_stats_enhancement.sql`  
**Exporter:** See `wc3_exporter_enhanced.py`  
**Example Queries:** See `WC3_Database/example_queries.sql`  
**SharedDInvLib.j:** Original stat system implementation  

**Questions?** Check the code comments in SharedDInvLib.j for detailed implementation logic.
