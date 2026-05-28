# Item Stats ID Mapping Reference

This document defines the canonical stat ID mappings between the database and JASS code (SharedDInvLib.j).

## Stat ID Mappings

| ID | Stat Code | Stat Name | Description | JASS Reference |
|----|-----------|-----------|-------------|----------------|
| 1 | str | Strength | Increases damage and HP | `statid == 1` |
| 2 | agi | Agility | Increases attack speed and armor | `statid == 2` |
| 3 | int | Intelligence | Increases mana and spell damage | `statid == 3` |
| 4 | hp | Health | Maximum health points | `statid == 4` |
| 5 | hp_regen | HP Regen | Health regeneration per second (HPS) | `statid == 5` |
| 6 | hp_regen_pct | HP Regen % | Health regeneration percent per second | `statid == 6` |
| 7 | mp | Mana | Maximum mana points | `statid == 7` |
| 8 | mp_regen | Mana Regen | Mana regeneration per second (MPS) | `statid == 8` |
| 9 | mp_regen_pct | Mana Regen % | Mana regeneration percent per second | `statid == 9` |
| 10 | crit | Critical Chance | Chance to deal critical damage | `statid == 10` |
| 11 | crit_dmg | Critical Damage | Critical hit damage multiplier | `statid == 11` |
| 12 | dmg | Damage | Attack damage bonus | `statid == 12` |
| 13 | dmg_pct | Damage % | General damage percent bonus | `statid == 13` |
| 14 | melee_dmg | Melee Damage | Melee damage flat bonus | `statid == 14` |
| 15 | melee_dmg_pct | Melee Damage % | Melee damage percent bonus | `statid == 15` |
| 16 | ranged_dmg | Ranged Damage | Ranged damage flat bonus | `statid == 16` |
| 17 | ranged_dmg_pct | Ranged Damage % | Ranged damage percent bonus | `statid == 17` |
| 18 | cleave_pct | Cleave % | Cleave damage percent | `statid == 18` |
| 19 | cleave_area | Cleave Area | Cleave area of effect | `statid == 19` |
| 20 | aspd | Attack Speed | Attack speed bonus (IAS) | `statid == 20` |
| 21 | attack_range | Attack Range | Attack range bonus | `statid == 21` |
| 22 | lifesteal | Lifesteal | Heal from damage dealt (percent) | `statid == 22` |
| 23 | thorns_flat | Thorns | Reflects flat damage when hit | `statid == 23` |
| 24 | thorns_pct | Thorns % | Reflects damage percent when hit | `statid == 24` |
| 25 | armor | Armor | Physical damage reduction | `statid == 25` |
| 26 | armor_pct | Armor % | Armor percent bonus | `statid == 26` |
| 27 | evasion | Evasion | Chance to evade attacks | `statid == 27` |
| 28 | magic_dmg_taken | Magic Damage Taken | Magic damage taken modifier | `statid == 28` |
| 29 | melee_dmg_taken | Melee Damage Taken | Melee damage taken modifier | `statid == 29` |
| 30 | pierce_dmg_taken | Pierce Damage Taken | Pierce damage taken modifier | `statid == 30` |
| 31 | ms | Movement Speed | Movement speed bonus | `statid == 31` |
| 32 | ms_pct | Movement Speed % | Movement speed percent bonus | `statid == 32` |
| 33 | sight_range | Sight Range | Vision range bonus | `statid == 33` |
| 34 | inv_space | Inventory Space | Additional inventory slots | `statid == 34` |

## Important Notes

### Database Schema
- The `item_stats` table uses explicit ID values (1-34) to match JASS code
- The sequence `item_stats_id_seq` is set to start from 35 for any future additions
- Stat IDs are **hardcoded** and should **never change**

### JASS Implementation
- Stats are referenced in `SharedDInvLib.j` in functions:
  - `DEqGrantSetStats()` - Grants stats when equipped
  - `DEqSubtractSetStats()` - Removes stats when unequipped
  - `AddDEqStatsOfItemToUnit()` - Adds item stats to unit
  - `RemoveDEqStatsOfItemFromUnit()` - Removes item stats from unit

### Data Types
- **Flat values**: STR, AGI, INT, HP, Mana, Damage, etc.
- **Percent values**: All stats ending in `_pct` or with `%` in display format
- **Special**: Damage taken modifiers (28-30) can be negative for resistance

### Migration Files
- SQL: `database/fix_item_stats_ids.sql`
- Python: `fix_item_stats_migration.py`

## Usage in Code

### Database Queries
```sql
-- Get all strength bonuses for an item
SELECT isv.stat_value 
FROM item_stat_values isv
WHERE isv.item_id = ? AND isv.stat_id = 1;

-- Add a new stat to an item
INSERT INTO item_stat_values (item_id, stat_id, stat_value)
VALUES (?, 12, 50.0);  -- +50 Damage
```

### C# Code
```csharp
// Reference stat by ID
const int STAT_ID_STRENGTH = 1;
const int STAT_ID_DAMAGE = 12;
const int STAT_ID_CRIT_CHANCE = 10;
```

## History
- **2026-03-12**: Initial migration to fix stat ID mappings
  - Cleared old auto-increment IDs
  - Set explicit IDs 1-34 to match JASS code
  - Added missing stats (hp_regen_pct, melee/ranged variants, etc.)

## Stat Categories

### Primary Attributes (1-3)
- Strength, Agility, Intelligence

### Health & Resources (4-9)
- HP, HP Regen, HP Regen %, Mana, Mana Regen, Mana Regen %

### Offensive Stats (10-22)
- Crit, Crit Damage, Damage, Damage %, Melee/Ranged variants, Cleave, Attack Speed, Attack Range, Lifesteal

### Defensive Stats (23-30)
- Thorns, Armor, Evasion, Damage Taken modifiers

### Utility Stats (31-34)
- Movement Speed, Sight Range, Inventory Space
