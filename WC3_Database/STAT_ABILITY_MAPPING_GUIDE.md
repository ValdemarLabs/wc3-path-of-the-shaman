# Stat Ability Mapping System Guide

## Overview

The Stat Ability Mapping System automatically generates WC3 ability codes based on item stats. These abilities provide the mechanical bonuses in-game but remain **invisible to players** - only the stat values from the database are shown in tooltips.

## How It Works

### 1. **Item Stats Database**
Items have stats stored in several ways:
- Individual columns in the `items` table (e.g., `critical_chance`, `block_chance`, `dodge_chance`)
- Linked stats through the `item_stats` junction table
- Both store numeric values (e.g., 25 for 25% crit)

### 2. **Ability Database**
The `wc3_abilities` table contains 857 imported abilities, including stat abilities:
- **Hit**: 18 abilities (1%, 2%, 3%, 4%, 5%, 10%, 15%, 20%, 25%, 30%, 35%, 40%, 50%, 60%, 75%, 90%, 100%)
- **Crit**: 13 abilities (5%, 10%, 15%, 20%, 25%, 30%, 35%, 40%, 50%, 60%, 75%, 90%, 100%)
- **Block**: 13 abilities (5% - 100%)
- **Dodge**: 13 abilities (5% - 100%)
- **Spell**: 13 abilities (5% - 100%)
- **Strength**: 4 abilities (+2, +8, +10, +15)
- **Agility**: 2 abilities (+2, +8)
- **Intelligence**: 4 abilities (+2, +8, +15, +20)
- **Mana**: 4 abilities (+50, +150, +250, +500)

### 3. **StatAbilityMapper.cs**
Core mapping engine with:
- **StatMap Dictionary**: Maps stat types to available ability codes and values
- **FindAbilityCombination()**: Greedy algorithm to find optimal ability combination
- **ParseStatAndGetAbilities()**: Parses stat strings and returns ability codes

### 4. **GUI Integration**
In the Item Edit Form:
- **Stats Picker**: User adds stats (e.g., "Critical Strike Chance: 25")
- **Auto-Generate Button**: Click "🔄 Auto-Generate from Stats"
- **Abilities Field**: Automatically populated with comma-separated ability codes

## Usage Example

### Scenario: Item with 25% Hit Chance

1. **Add Stat**: In Stats Picker, add "Hit Chance" with value 25
2. **Click Auto-Generate**: System finds ability combination
3. **Result**: `A04L` (Stats_Hit 25%) is added to abilities field
4. **Tooltip**: Item displays "Hit Chance: +25%" (from stats, NOT from ability name)

### Scenario: Item with 23% Crit (needs combination)

1. **Add Stat**: Critical Strike Chance: 23
2. **Auto-Generate Finds**: 
   - `A04I` (20%) + `A01G` (3%) - NO! (Crit only has 5% min)
   - Cannot build 23% exactly with available abilities
3. **Solution**: User adjusts to 20% or 25%

### Scenario: Item with Multiple Stats

```
Stats:
- Hit Chance: 20
- Crit Chance: 15
- Strength: 10

Generated Abilities: A04K, A01H, A6D7
- A04K = Stats_Hit (20%)
- A01H = Stats_Crit (15%)
- A6D7 = Strength (+10)
```

## Ability Selection Algorithm

**Greedy Approach** (picks largest values first):

```csharp
// For Hit 25%:
Available: [100, 90, 75, 60, 50, 40, 35, 30, 25, 20, 15, 10, 5, 4, 3, 2, 1]
Target: 25
Selected: A04L (25%) ← Exact match!

// For Hit 48%:  Available: [100, 90, 75, 60, 50, 40, 35, 30, 25, 20, 15, 10, 5, 4, 3, 2, 1]
Target: 48
Selected: A04O (40%) + A04I (10%) - Wait, that's 50! Try again:
Selected: A04O (40%) + A04H (5%) + A64C (3%) = 48% ✓
```

## Important Notes

### Visibility
- **Abilities ARE applied**: Items get mechanical bonuses from abilities
- **Abilities HIDDEN**: Player doesn't see ability names in tooltip
- **Stats DISPLAYED**: Only stat values from database appear in tooltip

### Limitations
- Not all values can be built exactly (e.g., 23% crit impossible)
- System warns when values cannot be mapped
- User should adjust stat values to match available ability combinations

### Stat Type Mapping

The system recognizes these stat name variations:

| Stat Name Variants | Maps To |
|-------------------|---------|
| Critical Strike Chance, Critical Chance, Crit, Crit Chance | **Crit** |
| Hit Chance, Hit, Accuracy | **Hit** |
| Block Chance, Block | **Block** |
| Dodge Chance, Dodge, Evasion | **Dodge** |
| Spell Resistance, Spell, Magic Resistance | **Spell** |
| Strength, STR | **Strength** |
| Agility, AGI | **Agility** |
| Intelligence, INT | **Intelligence** |
| Mana, Mana Bonus | **Mana** |

## Workflow

```
┌─────────────────────┐
│  User Adds Stats    │
│  (Stats Picker)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────┐
│ Click "Auto-Generate"       │
│ from Stats Button           │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ StatAbilityMapper           │
│ • Maps stat names           │
│ • Finds ability combos      │
│ • Returns ability codes     │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ txtAbilities Field          │
│ Populated with:             │
│ "A04K, A01H, A6D7"          │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Save Item to Database       │
│ (wc3_abilities column)      │
└─────────────────────────────┘
```

## Testing Example

1. **Open Item Editor**
2. **Create New Item** (Code: test, Name: Test Sword)
3. **Add Stats in Stats Picker**:
   - Hit Chance: 20
   - Critical Strike Chance: 15
   - Strength: 10
4. **Click "Auto-Generate from Stats"**
5. **Result**: Abilities field shows `A04K, A01H, A6D7`
6. **Save Item**
7. **Export to .w3t**: Item will have those abilities applied
8. **In-Game**: Player sees "Hit Chance: +20%" in tooltip (NOT "Stats_Hit (20%)")

## Troubleshooting

### "Cannot build exact value"
**Problem**: Stat value cannot be created with available abilities  
**Solution**: Adjust stat value to match available combinations

### "Unknown stat type"
**Problem**: Stat name not recognized by mapping system  
**Solution**: Rename stat or add mapping to `statTypeMap` dictionary in `BtnAutoGenAbilities_Click()`

### "No stats defined"
**Problem**: No stats added to item yet  
**Solution**: Use Stats Picker to add stats before clicking auto-generate

## Advanced: Adding New Stat Types

To support new stat types:

1. **Import abilities** with new stat bonuses from WC3
2. **Add to StatAbilityMapper.cs**:
   ```csharp
   ["NewStat"] = new List<AbilityValue>
   {
       new AbilityValue("A999", 10),
       new AbilityValue("A998", 20),
   }
   ```
3. **Add to statTypeMap** in ItemEditForm.cs:
   ```csharp
   {"New Stat Name", "NewStat"},
   ```
4. **Done!** Auto-generation will now support the new stat

## Files Modified

- `StatAbilityMapper.cs` - Core mapping logic  - `ItemEditForm.cs` - GUI integration + auto-generate button
- `wc3_w3a_parser.py` - Fixed Reforged v3 format parsing
- `wc3_w3a_importer.py` - Simplified importer for 3-field ability data

## Database Schema

```sql
-- Abilities table (simplified for item reference)
CREATE TABLE wc3_abilities (
    ability_code CHAR(4) NOT NULL UNIQUE,  -- e.g., 'A04L'
    ability_name VARCHAR(255),              -- e.g., 'Stats_Hit'
    editor_suffix VARCHAR(255)              -- e.g., '(25 %)'
);

-- Items table (stores ability codes)
ALTER TABLE items ADD COLUMN wc3_abilities TEXT;  -- e.g., 'A04K, A01H, A6D7'
```

## Performance

- **Instant**: Algorithm processes stats in milliseconds
- **Memory**: StatMap dictionary loaded once at class initialization
- **Database**: No queries during ability generation (all in-memory)

## Future Enhancements

1. **Smart Suggestions**: When exact value impossible, suggest closest achievable value
2. **Ability Optimizer**: Find most efficient combination (fewest abilities)
3. **Conflict Detection**: Warn if abilities might conflict
4. **Custom Ability Support**: Allow users to define custom ability mappings
5. **Bulk Operation**: Auto-generate abilities for all items in database
