# HeroItemCheck Bug Fix - October 24, 2025

## Problem Description
Items were disappearing from hero inventories when using `HeroItemCheckBothAndRemove` or `HeroItemCheckBoth` functions. The issue manifested after the system worked initially, with items vanishing unexpectedly after repeated use.

## Root Causes Identified

### 1. **Race Condition from TriggerSleepAction**
```jass
// OLD CODE - BUGGY
function HeroItemCheck takes unit whichHero, integer itemId, integer requiredAmount returns boolean
    call TriggerSleepAction(0.05)  // <-- PROBLEM: Creates timing gap
    set result = GetDInvItemChargesByTypeThreshold(whichHero, itemId, requiredAmount)
    return result
endfunction
```
**Issue**: The 0.05 second sleep created a window where:
- Game state could change
- Items could be consumed/moved
- Other scripts could modify inventory
- Multiple rapid calls would stack delays

### 2. **Global Variable Pollution**
```jass
// OLD CODE - BUGGY
function HeroItemCheckBoth takes integer itemId, integer requiredAmount returns boolean
    if HeroItemCheck(udg_Nazgrek, itemId, requiredAmount) then
        set udg_DInvUnit = udg_Nazgrek  // <-- PROBLEM: Global side effect
        return true
    endif
    // ...
endfunction
```
**Issue**: Using `udg_DInvUnit` as a global output parameter caused:
- Multiple simultaneous checks to overwrite each other
- Wrong hero being targeted for item removal
- Race conditions when triggers fire rapidly

### 3. **Non-Atomic Check-and-Remove**
```jass
// OLD CODE - BUGGY
function HeroItemCheckBothAndRemove takes integer itemId, integer requiredAmount returns boolean
    local boolean hasItems = HeroItemCheckBoth(itemId, requiredAmount)  // Check here
    // TIME GAP - state can change!
    if hasItems then
        call RemoveDInvItemChargesByType(udg_DInvUnit, itemId, requiredAmount)  // Remove here
    endif
endfunction
```
**Issue**: Time gap between check and remove allowed:
- Items to be consumed/moved between check and removal
- `udg_DInvUnit` to be changed by other code
- Items removed from wrong hero

## The Fix

### 1. **Removed Sleep from HeroItemCheck**
```jass
// NEW CODE - FIXED
function HeroItemCheck takes unit whichHero, integer itemId, integer requiredAmount returns boolean
    local boolean result = false
    
    set result = GetDInvItemChargesByTypeThreshold(whichHero, itemId, requiredAmount)
    return result  // No sleep - instant check
endfunction
```
**Benefit**: Eliminates timing issues. If caller needs delay, they call `TriggerSleepAction` BEFORE this function.

### 2. **Return Value Instead of Global**
```jass
// NEW CODE - FIXED
function HeroItemCheckBoth takes integer itemId, integer requiredAmount returns unit
    if HeroItemCheck(udg_Nazgrek, itemId, requiredAmount) then
        return udg_Nazgrek  // Return directly, no global pollution
    endif
    if HeroItemCheck(udg_Zulkis, itemId, requiredAmount) then
        return udg_Zulkis
    endif
    return null  // Neither hero has items
endfunction
```
**Benefit**: No global variable pollution. Each call gets its own result. Thread-safe.

### 3. **Atomic Check-and-Remove**
```jass
// NEW CODE - FIXED
function HeroItemCheckBothAndRemove takes integer itemId, integer requiredAmount returns boolean
    local unit heroWithItems = HeroItemCheckBoth(itemId, requiredAmount)  // Check
    
    if heroWithItems != null then
        // IMMEDIATELY remove from the correct hero - no time gap
        call RemoveDInvItemChargesByType(heroWithItems, itemId, requiredAmount)
        set udg_DInvUnit = heroWithItems  // Set global for backwards compatibility
        return true
    endif
    
    return false
endfunction
```
**Benefit**: Check and remove happen atomically using local variable. No race condition window.

### 4. **GUI-Friendly Helper Function**
```jass
// NEW CODE - ADDED
function HeroItemCheckBothBoolean takes integer itemId, integer requiredAmount returns boolean
    local unit heroWithItems = HeroItemCheckBoth(itemId, requiredAmount)
    if heroWithItems != null then
        set udg_DInvUnit = heroWithItems
        return true
    endif
    set udg_DInvUnit = null
    return false
endfunction
```
**Benefit**: Provides boolean return for GUI triggers while still being safer than old implementation.

## Migration Guide

### If you were using HeroItemCheckBoth in GUI:

**OLD GUI Trigger:**
```
If (HeroItemCheckBoth('I000', 10)) then
    Actions
    - Set DInvUnit = (use the unit from DInvUnit global)
```

**NEW GUI Trigger (Option 1 - Recommended):**
```
If (HeroItemCheckBothBoolean('I000', 10)) then
    Actions
    - Set DInvUnit = (use the unit from DInvUnit global)
```

**NEW GUI Trigger (Option 2 - Better):**
```
Actions
- Set HeroWithItems = HeroItemCheckBoth('I000', 10)
If (HeroWithItems != null) then
    - Use HeroWithItems variable
```

### If you need delay before checking:

**OLD CODE:**
```jass
// Sleep was inside HeroItemCheck
if HeroItemCheck(hero, 'I000', 10) then
```

**NEW CODE:**
```jass
// Sleep BEFORE calling
call TriggerSleepAction(0.05)  // Let inventory update
if HeroItemCheck(hero, 'I000', 10) then
```

## Testing Checklist

- [x] Fixed race condition from TriggerSleepAction
- [x] Fixed global variable pollution  
- [x] Fixed non-atomic check-and-remove
- [x] Added GUI-friendly helper function
- [x] Maintained backwards compatibility with udg_DInvUnit
- [ ] Test with rapid successive calls
- [ ] Test with both heroes having items
- [ ] Test with items being consumed during check
- [ ] Test GUI trigger integration

## Performance Impact

**Improvement**: Removing `TriggerSleepAction` makes the function **instant** instead of taking 50ms per call. For checking both heroes, this saves 100ms total.

**Example**: A quest that checks 5 times now takes 0ms instead of 500ms.

## Breaking Changes

⚠️ **IMPORTANT**: `HeroItemCheckBoth` now returns a `unit` instead of `boolean`

**If you have custom JASS code calling this function directly:**
- Old: `if HeroItemCheckBoth('I000', 10) then`
- New: `if HeroItemCheckBoth('I000', 10) != null then`

**OR use the new boolean helper:**
- New: `if HeroItemCheckBothBoolean('I000', 10) then`

## Files Modified

- `HeroItemCheck.j` - All functions updated with fixes

## Additional Notes

The underlying `GetDInvItemChargesByTypeThreshold` and `RemoveDInvItemChargesByType` functions in `SharedDInvLib.j` are working correctly. The bug was entirely in the wrapper functions due to timing and global variable issues.
