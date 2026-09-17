# Hero Item Stats System - Implementation Guide

## Overview
This guide explains what stat abilities you need to create in WC3 World Editor and how to modify UnitStats.j to handle Hero item pickup/drop events for dynamic stat application.

---

## Part 1: Required Stat Abilities in WC3 World Editor

### Current State Analysis

**You currently have these stat abilities:**

| Stat Type | Current Increments |
|-----------|-------------------|
| **Hit** | 1%, 2%, 3%, 4%, 5%, 10%, 15%, 20%, 25%, 30%, 35%, 40%, 50%, 60%, 75%, 90%, 100% (18 abilities) ✅ |
| **Crit** | 5%, 10%, 15%, 20%, 25%, 30%, 35%, 40%, 50%, 60%, 75%, 90%, 100% (13 abilities) ❌ |
| **Block** | 5%, 10%, 15%, 20%, 25%, 30%, 35%, 40%, 50%, 60%, 75%, 90%, 100% (13 abilities) ❌ |
| **Dodge** | 5%, 10%, 15%, 20%, 25%, 30%, 35%, 40%, 50%, 60%, 75%, 90%, 100% (13 abilities) ❌ |
| **Spell Power** | 5%, 10%, 15%, 20%, 25%, 30%, 35%, 40%, 50%, 60%, 75%, 90%, 100% (13 abilities) ❌ |

### What You Already Have (Discovered from w3a export)

**GOOD NEWS: You already have 1-5% abilities from old testing!**

#### Hit Abilities (✅ Complete 1-5%)
- `A649` = 1% hit chance
- `A64A` = 2% hit chance
- `A64C` = 3% hit chance
- `A64D` = 4% hit chance
- `A64B` = 5% hit chance

#### Crit Abilities (✅ Complete 1-5%)
- `A64E` = 1% crit chance
- `A64F` = 2% crit chance
- `A64G` = 3% crit chance
- `A64H` = 4% crit chance
- `A64I` = 5% crit chance

#### Block Abilities (✅ Complete 1-5%)
- `A64J` = 1% block chance
- `A64K` = 2% block chance
- `A64L` = 3% block chance
- `A64M` = 4% block chance
- `A64N` = 5% block chance
- `A64T` = 100% block chance

#### Dodge Abilities (✅ Complete 1-5%)
- `A64O` = 1% dodge chance
- `A64P` = 2% dodge chance
- `A64Q` = 3% dodge chance
- `A64R` = 4% dodge chance
- `A64S` = 5% dodge chance

#### Spell Power Abilities (✅ Complete 1-5%)
- `A06M` = 1% spell power
- `A06N` = 2% spell power
- `A06O` = 3% spell power
- `A06P` = 4% spell power
- Plus existing 5-100% abilities

**Total: 0 new abilities needed - All complete! ✅**

### How to Create These in WC3 World Editor

1. **Open Object Editor** → **Abilities** tab
2. **Find existing stat ability** (e.g., `Stats_Crit 5%`)
3. **Copy the ability** 4 times
4. **Modify each copy:**
   - Change the stat bonus value to 1%, 2%, 3%, or 4%
   - Update the name (e.g., "Stats_Crit 1%")
   - Update tooltip if visible
   - Note down the **ability code** (e.g., 'A0XX')
5. **Repeat for all 4 stat types**

### Example: Creating Crit 1% Ability

```
Base Ability: Stats_Crit 5% (A01G)
New Ability:  Stats_Crit 1% (A0XX)  ← Your new code

Fields to modify:
- Critical Strike - Chance: 1.00
- Name: Stats_Crit 1%
- Tooltip: (If visible to users)
```

---

## Part 2: Database Integration

### Update WC3_Database Ability Mapping

After creating the 16 new abilities, you need to import them into your database:

```sql
-- Add new Crit abilities
INSERT INTO wc3_abilities (ability_code, ability_name, ability_type, stat_value) VALUES
('A0XX', 'Stats_Crit 1%', 'crit', 1),
('A0XY', 'Stats_Crit 2%', 'crit', 2),
('A0XZ', 'Stats_Crit 3%', 'crit', 3),
('A0X0', 'Stats_Crit 4%', 'crit', 4);

-- Add new Block abilities
INSERT INTO wc3_abilities (ability_code, ability_name, ability_type, stat_value) VALUES
('A0X1', 'Stats_Block 1%', 'block', 1),
('A0X2', 'Stats_Block 2%', 'block', 2),
('A0X3', 'Stats_Block 3%', 'block', 3),
('A0X4', 'Stats_Block 4%', 'block', 4);

-- Add new Dodge abilities
INSERT INTO wc3_abilities (ability_code, ability_name, ability_type, stat_value) VALUES
('A0X5', 'Stats_Dodge 1%', 'dodge', 1),
('A0X6', 'Stats_Dodge 2%', 'dodge', 2),
('A0X7', 'Stats_Dodge 3%', 'dodge', 3),
('A0X8', 'Stats_Dodge 4%', 'dodge', 4);

-- Add new Spell Power abilities
INSERT INTO wc3_abilities (ability_code, ability_name, ability_type, stat_value) VALUES
('A0X9', 'Stats_Spell 1%', 'spell', 1),
('A0XA', 'Stats_Spell 2%', 'spell', 2),
('A0XB', 'Stats_Spell 3%', 'spell', 3),
('A0XC', 'Stats_Spell 4%', 'spell', 4);
```

*(Replace A0XX, A0XY, etc. with your actual ability codes)*

### Update StatAbilityMapper.cs

After importing to database, the C# mapper will automatically pick them up in the next database load. No code changes needed - the system is dynamic!

---

## Part 3: Modifying UnitStats.j for Hero Item Events

### Architecture Overview

```
┌─────────────────────┐
│ Hero picks up item  │
│   (ItemHook)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────┐
│ Parse item abilities        │
│ (Extract stat ability codes)│
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Add stat abilities to Hero  │
│ UnitAddAbility()            │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Update global stat vars     │
│ udg_Stats_Crit[id] += value │
└─────────────────────────────┘

┌─────────────────────┐
│ Hero drops item     │
│   (ItemHook)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────┐
│ Remove stat abilities       │
│ UnitRemoveAbility()         │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Update global stat vars     │
│ udg_Stats_Crit[id] -= value │
└─────────────────────────────┘
```

### Key Design Decisions

1. **Storage**: Store item stat abilities in a Table per item (key = item handle ID)
2. **Hero Check**: Only process Hero units (`IsUnitType(u, UNIT_TYPE_HERO)`)
3. **Event System**: Use existing ItemHook system for pickup/drop events
4. **Ability Parsing**: Parse WC3 abilities string from item data
5. **Dynamic Application**: Add/remove abilities in real-time

### Integration with Existing Systems

**ItemHook.j** - Already exists, provides:
- `ItemHookRegisterCreate()` - Register item creation callbacks
- `ItemHookGetEventItem()` - Get the item in event
- `ItemHookGetEventHero()` - Get the hero that acquired item

**Approach**: We need to hook into **item pickup/drop events**, NOT just item creation.

---

## Part 4: Implementation Code

### Step 1: Add New Globals to UnitStats.j

```jass
globals
    // ... existing globals ...
    
    // NEW: Item stat tracking
    private Table itemStatAbilities  // [itemId][abilityIndex] = abilityCode
    private Table itemStatCount      // [itemId] = count of stat abilities
    private Table heroItemStats      // [heroId][itemId] = 1 if item stats applied
    
    // NEW: Ability codes for 1-5% abilities (EXISTING FROM OLD TESTING)
    private constant integer ABILITY_HIT_1     = 'A649'
    private constant integer ABILITY_HIT_2     = 'A64A'
    private constant integer ABILITY_HIT_3     = 'A64C'
    private constant integer ABILITY_HIT_4     = 'A64D'
    // Note: ABILITY_HIT_5 already defined at line ~110
    
    private constant integer ABILITY_CRIT_1    = 'A64E'
    private constant integer ABILITY_CRIT_2    = 'A64F'
    private constant integer ABILITY_CRIT_3    = 'A64G'
    private constant integer ABILITY_CRIT_4    = 'A64H'
    // Note: ABILITY_CRIT_5 already defined at line ~70
    
    private constant integer ABILITY_BLOCK_1   = 'A64J'
    private constant integer ABILITY_BLOCK_2   = 'A64K'
    private constant integer ABILITY_BLOCK_3   = 'A64L'
    private constant integer ABILITY_BLOCK_4   = 'A64M'
    // Note: ABILITY_BLOCK_5 already defined at line ~85
    
    private constant integer ABILITY_DODGE_1   = 'A64O'
    private constant integer ABILITY_DODGE_2   = 'A64P'
    private constant integer ABILITY_DODGE_3   = 'A64Q'
    private constant integer ABILITY_DODGE_4   = 'A64R'
    // Note: ABILITY_DODGE_5 already defined at line ~55
    
    private constant integer ABILITY_SPELL_1   = 'A06M'
    private constant integer ABILITY_SPELL_2   = 'A06N'
    private constant integer ABILITY_SPELL_3   = 'A06O'
    private constant integer ABILITY_SPELL_4   = 'A06P'
endglobals
```

### Step 2: Add Helper Functions

```jass
/**
 * Check if unit is a Hero
 */
private function IsHeroUnit takes unit u returns boolean
    return IsUnitType(u, UNIT_TYPE_HERO)
endfunction

/**
 * Get ability stat value by ability code
 */
private function GetAbilityStatValue takes integer abilCode returns integer
    // Crit abilities
    if abilCode == ABILITY_CRIT_1 then
        return 1
    elseif abilCode == ABILITY_CRIT_2 then
        return 2
    elseif abilCode == ABILITY_CRIT_3 then
        return 3
    elseif abilCode == ABILITY_CRIT_4 then
        return 4
    elseif abilCode == ABILITY_CRIT_5 then
        return 5
    elseif abilCode == ABILITY_CRIT_10 then
        return 10
    // ... add all other crit increments ...
    
    // Block abilities
    elseif abilCode == ABILITY_BLOCK_1 then
        return 1
    elseif abilCode == ABILITY_BLOCK_2 then
        return 2
    // ... add all block abilities ...
    
    // Dodge abilities
    elseif abilCode == ABILITY_DODGE_1 then
        return 1
    // ... add all dodge abilities ...
    
    // Hit abilities
    elseif abilCode == ABILITY_HIT_5 then
        return 5
    // ... add all hit abilities ...
    
    // Spell abilities
    elseif abilCode == ABILITY_SPELL_1 then
        return 1
    // ... add all spell abilities ...
    endif
    
    return 0  // Unknown ability
endfunction

/**
 * Get stat type by ability code
 */
private function GetAbilityStatType takes integer abilCode returns string
    // Check crit abilities
    if abilCode == ABILITY_CRIT_1 or abilCode == ABILITY_CRIT_2 or abilCode == ABILITY_CRIT_5 or abilCode == ABILITY_CRIT_10 /*...*/ then
        return "crit"
    // Check dodge abilities
    elseif abilCode == ABILITY_DODGE_1 or abilCode == ABILITY_DODGE_5 /*...*/ then
        return "dodge"
    // Check block abilities
    elseif abilCode == ABILITY_BLOCK_1 or abilCode == ABILITY_BLOCK_5 /*...*/ then
        return "block"
    // Check hit abilities
    elseif abilCode == ABILITY_HIT_5 or abilCode == ABILITY_HIT_10 /*...*/ then
        return "hit"
    // Check spell abilities
    elseif abilCode == ABILITY_SPELL_1 or abilCode == ABILITY_SPELL_5 /*...*/ then
        return "spell"
    endif
    
    return ""  // Unknown
endfunction

/**
 * Apply a single stat ability to hero
 */
private function ApplyStatAbilityToHero takes unit hero, integer abilCode returns nothing
    local integer heroId = GetUnitId(hero)
    local integer value = GetAbilityStatValue(abilCode)
    local string statType = GetAbilityStatType(abilCode)
    
    if value == 0 or statType == "" then
        return  // Not a stat ability
    endif
    
    // Add ability to hero
    call UnitAddAbility(hero, abilCode)
    call UnitMakeAbilityPermanent(hero, true, abilCode)
    
    // Update stat globals
    if statType == "crit" then
        set udg_Stats_Crit[heroId] = udg_Stats_Crit[heroId] + value
    elseif statType == "dodge" then
        set udg_Stats_Dodge[heroId] = udg_Stats_Dodge[heroId] + value
    elseif statType == "block" then
        set udg_Stats_Block[heroId] = udg_Stats_Block[heroId] + value
    elseif statType == "hit" then
        set udg_Stats_Hit[heroId] = udg_Stats_Hit[heroId] + value
    elseif statType == "spell" then
        set udg_Stats_SpellPowerPct[heroId] = udg_Stats_SpellPowerPct[heroId] + value
    endif
    
    if debugEnabled then
        call BJDebugMsg("[HeroStats] " + GetUnitName(hero) + " gained +" + I2S(value) + " " + statType)
    endif
endfunction

/**
 * Remove a single stat ability from hero
 */
private function RemoveStatAbilityFromHero takes unit hero, integer abilCode returns nothing
    local integer heroId = GetUnitId(hero)
    local integer value = GetAbilityStatValue(abilCode)
    local string statType = GetAbilityStatType(abilCode)
    
    if value == 0 or statType == "" then
        return
    endif
    
    // Remove ability from hero
    call UnitRemoveAbility(hero, abilCode)
    
    // Update stat globals
    if statType == "crit" then
        set udg_Stats_Crit[heroId] = udg_Stats_Crit[heroId] - value
    elseif statType == "dodge" then
        set udg_Stats_Dodge[heroId] = udg_Stats_Dodge[heroId] - value
    elseif statType == "block" then
        set udg_Stats_Block[heroId] = udg_Stats_Block[heroId] - value
    elseif statType == "hit" then
        set udg_Stats_Hit[heroId] = udg_Stats_Hit[heroId] - value
    elseif statType == "spell" then
        set udg_Stats_SpellPowerPct[heroId] = udg_Stats_SpellPowerPct[heroId] - value
    endif
    
    if debugEnabled then
        call BJDebugMsg("[HeroStats] " + GetUnitName(hero) + " lost -" + I2S(value) + " " + statType)
    endif
endfunction
```

### Step 3: Parse Item Abilities String

```jass
/**
 * Parse comma-separated ability codes from string
 * Example: "A01G,A04K,A6EV" → [A01G, A04K, A6EV]
 */
private function ParseItemAbilities takes string abilitiesStr, integer itemId returns integer
    local integer count = 0
    local integer i = 0
    local integer len = StringLength(abilitiesStr)
    local string current = ""
    local integer abilCode = 0
    
    // Clear any existing data for this item
    call FlushChildHashtable(ItemHook_Hash, itemId)
    
    loop
        exitwhen i >= len
        
        local string char = SubString(abilitiesStr, i, i + 1)
        
        if char == "," or i == len - 1 then
            // End of ability code, convert and store
            if i == len - 1 and char != "," then
                set current = current + char
            endif
            
            // Convert 4-character code to integer
            set abilCode = S2ID(current)
            
            if abilCode != 0 then
                call SaveInteger(ItemHook_Hash, itemId, count, abilCode)
                set count = count + 1
            endif
            
            set current = ""
        elseif char != " " then
            // Add to current ability code (skip spaces)
            set current = current + char
        endif
        
        set i = i + 1
    endloop
    
    call SaveInteger(ItemHook_Hash, itemId, -1, count)  // Store count at key -1
    return count
endfunction

/**
 * Convert 4-character string to integer ability code
 * Example: "A01G" → 'A01G'
 */
private function S2ID takes string s returns integer
    // WC3 converts 4-char strings to integers automatically in some contexts
    // If this doesn't work, you'll need to implement manual conversion
    // or store abilities as integers in your item database
    return StringHash(s)  // PLACEHOLDER - may need custom implementation
endfunction
```

### Step 4: Hero Item Pickup Handler

```jass
/**
 * Called when a hero picks up an item
 * Integrates with your item system to get ability data
 */
function HeroItemPickup takes unit hero, item whichItem returns nothing
    local integer heroId
    local integer itemId
    local integer abilCount
    local integer i
    local integer abilCode
    local string abilitiesStr
    
    if not IsHeroUnit(hero) then
        return  // Only process heroes
    endif
    
    set heroId = GetUnitId(hero)
    set itemId = GetHandleId(whichItem)
    
    // TODO: Get item abilities string from your database/system
    // Option 1: Use ItemHook to store data on item creation
    // Option 2: Query database by item type code
    // Option 3: Store in item name/tooltip (hacky but works)
    
    // PLACEHOLDER: This needs to connect to your item database
    set abilitiesStr = LoadStr(ItemHook_Hash, GetItemTypeId(whichItem), 0)
    
    if abilitiesStr == null or abilitiesStr == "" then
        return  // No stat abilities on this item
    endif
    
    // Parse and apply abilities
    set abilCount = ParseItemAbilities(abilitiesStr, itemId)
    set i = 0
    
    loop
        exitwhen i >= abilCount
        set abilCode = LoadInteger(ItemHook_Hash, itemId, i)
        
        call ApplyStatAbilityToHero(hero, abilCode)
        
        set i = i + 1
    endloop
    
    // Mark that this hero has this item's stats applied
    call SaveInteger(heroItemStats, heroId * 10000 + itemId, 1, 1)
    
    if debugEnabled then
        call BJDebugMsg("[HeroStats] " + GetUnitName(hero) + " equipped item with " + I2S(abilCount) + " stat abilities")
    endif
endfunction

/**
 * Called when a hero drops an item
 */
function HeroItemDrop takes unit hero, item whichItem returns nothing
    local integer heroId
    local integer itemId
    local integer abilCount
    local integer i
    local integer abilCode
    
    if not IsHeroUnit(hero) then
        return
    endif
    
    set heroId = GetUnitId(hero)
    set itemId = GetHandleId(whichItem)
    
    // Check if stats were applied for this item
    if LoadInteger(heroItemStats, heroId * 10000 + itemId, 1) == 0 then
        return  // Stats not applied for this item
    endif
    
    // Get ability count
    set abilCount = LoadInteger(ItemHook_Hash, itemId, -1)
    set i = 0
    
    loop
        exitwhen i >= abilCount
        set abilCode = LoadInteger(ItemHook_Hash, itemId, i)
        
        call RemoveStatAbilityFromHero(hero, abilCode)
        
        set i = i + 1
    endloop
    
    // Clear the flag
    call RemoveSavedInteger(heroItemStats, heroId * 10000 + itemId, 1)
    
    if debugEnabled then
        call BJDebugMsg("[HeroStats] " + GetUnitName(hero) + " unequipped item with " + I2S(abilCount) + " stat abilities")
    endif
endfunction
```

### Step 5: Register Events in Init

```jass
private function Init takes nothing returns nothing
    // Initialize Tables
    set dodgeApplied = Table.create()
    set critApplied = Table.create()
    set blockApplied = Table.create()
    set spellApplied = Table.create()
    set hitApplied = Table.create()
    set processedUnits = Table.create()
    set heroItemStats = Table.create()
    
    // Schedule initial scan for pre-placed units
    call TimerStart(CreateTimer(), INITIAL_SCAN_DELAY, false, function UnitStats_InitialScan)
    
    // TODO: Register item pickup/drop events
    // This depends on your item system implementation
    // You may need to create triggers for:
    // - EVENT_PLAYER_UNIT_PICKUP_ITEM
    // - EVENT_PLAYER_UNIT_DROP_ITEM
    // - EVENT_PLAYER_UNIT_USE_ITEM (for consumables)
    
    if debugEnabled then
        call BJDebugMsg("[UnitStats] System initialized - waiting for initial scan...")
    endif
endfunction
```

---

## Part 5: Connecting to Your Item Database

### Challenge: Getting Item Ability Data In-Game

**Problem**: WC3 JASS cannot directly query your PostgreSQL database at runtime.

**Solutions**:

#### Option A: Preload Item Data (RECOMMENDED)
```jass
// In map initialization, preload all item stat abilities
private function PreloadItemAbilities takes nothing returns nothing
    // Hardcode or generate from database export
    call SaveStr(ItemHook_Hash, 'I001', 0, "A01G,A04K")  // Sword of Power
    call SaveStr(ItemHook_Hash, 'I002', 0, "A6EV,A01C")  // Shield of Defense
    // ... etc for all items
endfunction
```

**Generate this code from database**:
```sql
-- Run this query to generate JASS code
SELECT 
    'call SaveStr(ItemHook_Hash, ''' || item_code || ''', 0, "' || wc3_abilities || '")'
FROM items
WHERE wc3_abilities IS NOT NULL AND wc3_abilities != '';
```

#### Option B: Encode in Item Name
```jass
// Store abilities in item name with special delimiter
// Item name: "Sword of Power|A01G,A04K"
private function GetItemAbilitiesFromName takes item whichItem returns string
    local string name = GetItemName(whichItem)
    local integer pipePos = 0
    
    // Find pipe character
    loop
        exitwhen pipePos >= StringLength(name)
        exitwhen SubString(name, pipePos, pipePos + 1) == "|"
        set pipePos = pipePos + 1
    endloop
    
    if pipePos < StringLength(name) then
        return SubString(name, pipePos + 1, StringLength(name))
    endif
    
    return ""
endfunction
```

#### Option C: Use Custom Object Data (Tooltip Hidden Field)
Store ability codes in a hidden custom field of the item in Object Editor.

---

## Part 6: Testing Checklist

### Test Cases

1. **Hero picks up item with +15% Crit**
   - ✅ Hero gains +15% to `udg_Stats_Crit[heroId]`
   - ✅ Crit ability added to hero (visible in ability panel)
   - ✅ Debug message shows "+15 crit"

2. **Hero drops the same item**
   - ✅ Hero loses -15% from `udg_Stats_Crit[heroId]`
   - ✅ Crit ability removed from hero
   - ✅ Debug message shows "-15 crit"

3. **Hero picks up item with 23% Hit (requires 20% + 3% abilities)**
   - ✅ Both abilities (A04K + A64C) applied
   - ✅ Total `udg_Stats_Hit[heroId]` increases by 23

4. **Non-hero unit picks up item**
   - ✅ Nothing happens (system ignores non-heroes)

5. **Hero picks up same item twice**
   - ✅ Stats stack correctly (30% total if 15% each)

### Debug Commands

```jass
// Enable debug mode
call UnitStats_SetDebugEnabled(true)

// Check hero stats
call BJDebugMsg("Hero Crit: " + I2S(udg_Stats_Crit[GetUnitId(hero)]))
```

---

## Part 7: Priority Order Summary

### Verifying Existing Abilities (Do First)
1. ✅ Confirm 1-5% Hit abilities exist (A649-A64D)
2. ✅ Confirm 1-5% Crit abilities exist (A64E-A64I)
3. ✅ Confirm 1-5% Block abilities exist (A64J-A64N)
4. ✅ Confirm 1-5% Dodge abilities exist (A64O-A64S)
5. ✅ Spell Power 1-4% created (A06M-A06P)
6. ✅ Import all ability codes into database `wc3_abilities` table

### Modifying UnitStats.j (Do Second)
1. ✅ Add new ability constants
2. ✅ Add helper functions (GetAbilityStatValue, GetAbilityStatType)
3. ✅ Add hero check function
4. ✅ Add ApplyStatAbilityToHero function
5. ✅ Add RemoveStatAbilityFromHero function
6. ✅ Add item ability parser
7. ✅ Add HeroItemPickup function
8. ✅ Add HeroItemDrop function
9. ✅ Register item pickup/drop events in Init

### Implementing Data Bridge (Do Third)
1. ✅ Choose a method (Preload, Name Encoding, or Custom Field)
2. ✅ Implement item ability data retrieval
3. ✅ Test with a few items
4. ✅ Generate full item database integration

### Testing (Do Last)
1. ✅ Test pickup/drop for single stats
2. ✅ Test combined stats (e.g., 23% = 20% + 3%)
3. ✅ Test stacking items
4. ✅ Test non-hero units (should be ignored)
5. ✅ Test edge cases (null items, empty abilities, etc.)

---

## Questions?

Let me know:
1. Which data bridge method you want to use (Preload, Name Encoding, Custom Field)
2. The actual ability codes you create in WC3 WE
3. Any specific integration points with your existing systems

I'll provide the complete updated UnitStats.j file once you have the ability codes!
