# ItemDropSystem Documentation

## Overview

The **ItemDropSystem** is a modular, maintainable item drop system for Warcraft 3 maps. It handles drops from units, bosses, and destructibles based on level ranges, rarity tiers, and unit-specific loot tables.

## Library Structure

The system is divided into 6 modular libraries:

### 1. **ItemDropConfig.j** (Data/Configuration)
- Contains all item arrays and loot tables
- Player group configuration
- Item IDs organized by level range and rarity
- **No logic** - purely data storage
- **Easy to maintain**: All item IDs in one place

### 2. **ItemDropCore.j** (Core Logic)
- Generic level-based drop algorithms
- Rarity rolling system (Common → Legendary)
- Drop chance calculations
- Helper functions for validation

### 3. **ItemDropSpecific.j** (Unit-Specific Drops)
- Handles special creature types:
  - Wolves (jawbone, meat, skin)
  - Stags (hoof, meat, hair)
  - Gnolls (Phat Lewt, quest items)
  - Dragons (claws, scales, flame sacs)
- Each unit type has its own drop table

### 4. **ItemDropBoss.j** (Boss Drops)
- Special drops for boss units
- Guaranteed legendary items
- Quest item handling
- Boss units covered:
  - Deathlord Fel'Dok
  - Margul, Mur'gal, Sargoth
  - Unknown Entity, Rol'jin
  - Velaria (Succubus)
  - Colossus, Gollum, Mordrax

### 5. **ItemDropDestructible.j** (Destructible Drops)
- Handles crates, barrels, etc.
- Uses same drop logic as units
- Requires **DestructibleDeathEngine**

### 6. **ItemDropSystem.j** (Main Controller)
- Ties all systems together
- Event registration
- Drop priority routing
- API functions

---

## Drop Priority System

When a unit dies, the system checks in this order:

1. **Boss Check**: Is unit registered as boss?
   - YES → Use **ItemDropBoss** (skip generic)
   - NO → Continue

2. **Specific Check**: Is unit a special type (wolf, dragon, etc.)?
   - YES → Use **ItemDropSpecific** + generic drops
   - NO → Continue

3. **Generic Drops**: Level-based drops (always happens unless boss)
   - Useless items
   - Generic consumables
   - Random equipment

---

## Drop Rates by Level Range

### Levels 1-5
- **Useless**: 15% (6/40 chance)
- **Generic**: 12.5% (5/40 chance)
- **Equipment**: 12.5% (5/40 chance)
  - Common: 85%
  - Uncommon: 14%
  - Rare: 1%

### Levels 6-10
- **Useless**: 15%
- **Generic**: 12.5%
- **Equipment**: 12.5%
  - Common: 60%
  - Uncommon: 25%
  - Rare: 14%
  - Epic: 1%

### Levels 11-15
- **Useless**: 10%
- **Generic**: 15%
- **Equipment**: 17.5%
  - Common: 60%
  - Uncommon: 25%
  - Rare: 10%
  - Epic: 4%
  - Legendary: 1%

### Levels 16-20
- **Useless**: 10%
- **Generic**: 15%
- **Equipment**: 17.5%
  - Common: 60%
  - Uncommon: 25%
  - Rare: 10%
  - Epic: 4%
  - Legendary: 1%

### Levels 21-25
- **Useless**: 7.5%
- **Generic**: 12.5%
- **Equipment**: 20%
  - Common: 50%
  - Uncommon: 30%
  - Rare: 15%
  - Epic: 4%
  - Legendary: 1%

### Levels 26-30+
- **Useless**: 5%
- **Generic**: 10%
- **Equipment**: 25%
  - Common: 40%
  - Uncommon: 30%
  - Rare: 15%
  - Epic: 10%
  - Legendary: 5%

---

## API Functions

### Boss Management
```jass
// Register a unit as boss (boss drops only, no generic)
call ItemDropSystem_RegisterBoss(myBossUnit)

// Unregister boss
call ItemDropSystem_UnregisterBoss(myBossUnit)
```

### Statistics (Debug)
```jass
// Get drop statistics
local string stats = ItemDropSystem_GetStats()
// Returns: "Total Drops: 150 | Boss: 5 | Specific: 20 | Generic: 125"

// Reset statistics
call ItemDropSystem_ResetStats()
```

---

## Configuration Guide

### Adding New Items

**1. Useless Items** (ItemDropConfig.j, line ~85)
```jass
set ItemUseless[7] = 'I007' // New Useless Item
```

**2. Generic Consumables** (ItemDropConfig.j, line ~92-160)
```jass
// Add to appropriate level range
set ItemGeneric_1_5[9] = 'I018' // New Level 1-5 item
```

**3. Equipment Loot Ranges** (ItemDropConfig.j, line ~162+)
```jass
// Add new item levels to loot ranges
set ItemLootRanges_1_5_Common[18] = 900
```

### Adding New Unit-Specific Drops

**Edit ItemDropSpecific.j:**
```jass
// Add new function for your unit type
function ItemDropSpecific_Bear takes unit u, location loc returns boolean
    local integer unitTypeId = GetUnitTypeId(u)
    
    if unitTypeId == 'n030' then // Bear unit ID
        set ItemLootTable[1] = 'I300' // Bear Pelt
        set ItemLootTable[2] = 'I301' // Bear Claw
        
        if GetRandomInt(1, 6) == 1 then
            local integer randomIndex = GetRandomInt(1, 2)
            call CreateItem(ItemLootTable[randomIndex], GetLocationX(loc), GetLocationY(loc))
        endif
        
        return true
    endif
    
    return false
endfunction

// Add to ItemDropSpecific_Process function
function ItemDropSpecific_Process takes unit u, location loc returns boolean
    // ... existing checks ...
    
    if ItemDropSpecific_Bear(u, loc) then
        return true
    endif
    
    return false
endfunction
```

### Adding New Boss Drops

**Edit ItemDropBoss.j:**
```jass
function ItemDropBoss_MyNewBoss takes unit u, location loc returns boolean
    if GetUnitTypeId(u) == 'U020' then // MyNewBoss ID
        call CreateItem('I400', GetLocationX(loc), GetLocationY(loc)) // Boss Item
        return true
    endif
    
    return false
endfunction

// Add to ItemDropBoss_Process
function ItemDropBoss_Process takes unit u, location loc returns boolean
    // ... existing checks ...
    
    if ItemDropBoss_MyNewBoss(u, loc) then
        return true
    endif
    
    return false
endfunction
```

### Adding Destructible Types

**Edit ItemDropDestructible.j** (function ItemDropDestructible_GetLevel):
```jass
function ItemDropDestructible_GetLevel takes destructable d returns integer
    local integer dType = GetDestructableTypeId(d)
    
    // Add your destructible types
    if dType == 'B020' then // My Custom Crate
        return 15 // Level 15 equivalent drops
    endif
    
    // ... rest of function ...
endfunction
```

---

## Dependencies

### Required Libraries
- **DestructibleDeathEngine**: For destructible death detection
  - Must provide: `DestructibleDeathEvent` and `DestructibleDeathTarget`

### Optional Systems
- Quest system for quest item tracking (commented out in ItemDropSpecific.j and ItemDropBoss.j)

---

## Installation

1. **Copy all 6 library files to your map:**
   - ItemDropConfig.j
   - ItemDropCore.j
   - ItemDropSpecific.j
   - ItemDropBoss.j
   - ItemDropDestructible.j
   - ItemDropSystem.j

2. **Ensure DestructibleDeathEngine is installed**

3. **Update item IDs in ItemDropConfig.j** to match your map's items

4. **Update unit type IDs** in ItemDropSpecific.j and ItemDropBoss.j

5. **Configure drop players** in ItemDropConfig_Init function

6. **System auto-initializes** - no manual setup needed!

---

## Advantages Over GUI Triggers

### ✅ Modularity
- Each system is separated into its own library
- Easy to add/remove features without breaking others

### ✅ Maintainability
- All item IDs in one place (ItemDropConfig.j)
- Clear separation of data and logic
- Easy to find and update drop rates

### ✅ Performance
- Single event handler instead of multiple triggers
- Efficient drop checking with early returns
- No redundant location creation

### ✅ Scalability
- Easy to add new unit types
- Simple to add new boss encounters
- Drop rates are centralized and consistent

### ✅ Debugging
- Built-in statistics tracking
- Clear function names and structure
- Comments explain every section

---

## Troubleshooting

### Items not dropping?
1. Check if unit's owner is in `ItemDrop_Players` force
2. Verify unit doesn't have Locust ability
3. Confirm unit isn't summoned (if that matters)
4. Check item IDs in ItemDropConfig.j

### Wrong drop rates?
- Verify level ranges in ItemDropCore.j
- Check dice thresholds in ProcessGenericDrop

### Boss drops not working?
- Ensure boss is registered with `ItemDropSystem_RegisterBoss()`
- Verify boss unit type ID matches ItemDropBoss.j

### Destructible drops not working?
- Check DestructibleDeathEngine is installed
- Verify destructible type IDs in ItemDropDestructible.j

---

## Future Enhancements

Possible additions:
- **Drop multipliers** for special events
- **Player-specific drop rates** (higher drops for certain players)
- **Drop quality modifiers** (magic find system)
- **Loot lockout system** (prevent farming same unit)
- **Drop announcements** (legendary item notifications)

---

## Credits

**Author**: Valdemar  
**Based on**: Original GUI trigger system  
**Version**: 1.0  
**Date**: 2026

---

## License

Free to use and modify for your Warcraft 3 maps.  
Credit appreciated but not required.
