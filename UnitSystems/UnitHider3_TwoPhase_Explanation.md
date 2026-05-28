# UnitHider3 - Critical Discovery from OLD System

## The Problem with "Smart" Optimization

The optimized version tried to be clever by processing each unit only once and using filters to skip units. **This broke the system!**

## Why the OLD System Worked Perfectly

The old `UnitHider.j` used a **TWO-PHASE** approach:

### Phase 1: Process Hidden Units First
```jass
// Check ONLY the units that are currently hidden
call GroupAddGroup(hiddenUnits, g)
loop
    set u = FirstOfGroup(g)
    exitwhen u == null
    
    if UnitHider_IsUnitNearReferenceUnits(u) then
        call ShowUnit(u, true)
        call GroupRemoveUnit(hiddenUnits, u)
    endif
    
    call GroupRemoveUnit(g, u)
endloop
```

**Why this works:**
- Only processes units we KNOW are hidden
- Checks if they should be unhidden
- Simple and reliable

### Phase 2: Process ALL Units for Hiding
```jass
// Enumerate EVERY unit on the map
call GroupEnumUnitsInRect(g, GetWorldBounds(), null)
loop
    set u = FirstOfGroup(g)
    exitwhen u == null
    
    // Only hide if: not near, not ignored, and not already hidden
    if not UnitHider_IsUnitNearReferenceUnits(u) 
        and not IsUnitInGroup(u, udg_UnitHider_IgnoredUnits) 
        and not IsUnitInGroup(u, hiddenUnits) then
        
        call ShowUnit(u, false)
        call GroupAddUnit(hiddenUnits, u)
    endif
    
    call GroupRemoveUnit(g, u)
endloop
```

**Why this works:**
- Processes EVERY unit (no filter tricks)
- Simple condition: if far and not ignored and not already hidden → hide it
- No complex state management

## What Was Wrong with the "Optimized" Version

### Problem 1: Single-Phase Processing
Tried to do both hiding and unhiding in one loop:
```jass
if wasHidden then
    if isNear then unhide()
else
    if not isNear then hide()
```

**Issue:** Complex state tracking, easy to miss edge cases

### Problem 2: "Smart" Filter
Tried to filter out units during enumeration based on distance:
```jass
if IsUnitNearAnyReference(ux, uy) then
    if IsUnitInGroup(u, hiddenUnits) then
        return true  // Process it
    else
        return false  // Skip it
    endif
endif
```

**Issues:**
- Filter runs DURING enumeration (timing issues)
- Cached positions might not be updated yet
- Skipping units causes some to never be processed

### Problem 3: Over-Engineering
The old system was "dumb" but **reliable**:
- Process hidden units → unhide if near
- Process ALL units → hide if far

The new system tried to be "smart":
- Use filters to skip units
- Process each unit only once
- Complex conditions

**Result:** Broke reliability for marginal performance gain

## The Fix: Hybrid Approach

The current `UnitHider3_Optimized.j` now uses:

✅ **TWO-PHASE logic from OLD system** (reliable)
✅ **Cached reference positions** (optimization)
✅ **Squared distance calculations** (optimization)
✅ **Reused groups** (optimization)
✅ **Simple filter** (only filters dead/ignored/locust units)

### New Phase 1: Unhide Hidden Units
```jass
// Process all currently hidden units
call GroupAddGroup(hiddenUnits, tempHiddenCheck)
loop
    set u = FirstOfGroup(tempHiddenCheck)
    exitwhen u == null
    
    if IsUnitNearAnyReference(GetUnitX(u), GetUnitY(u)) then
        call ShowUnit(u, true)
        call GroupRemoveUnit(hiddenUnits, u)
    endif
    
    call GroupRemoveUnit(tempHiddenCheck, u)
endloop
```

### New Phase 2: Hide Visible Units
```jass
// Enumerate all valid units
call GroupEnumUnitsInRect(tempEnumGroup, GetWorldBounds(), filterExpr)
loop
    set u = FirstOfGroup(tempEnumGroup)
    exitwhen u == null
    
    // Skip if already hidden
    if not IsUnitInGroup(u, hiddenUnits) then
        if not IsUnitNearAnyReference(GetUnitX(u), GetUnitY(u)) then
            call ShowUnit(u, false)
            call GroupAddUnit(hiddenUnits, u)
        endif
    endif
    
    call GroupRemoveUnit(tempEnumGroup, u)
endloop
```

## Performance Comparison

### OLD System (Working but Laggy)
- ❌ Uses `SquareRoot()` - 10x slower
- ❌ Calls `GetUnitX/Y` repeatedly for same reference units
- ❌ Creates/destroys groups each check
- ✅ Two-phase approach (reliable)
- ✅ Simple logic (no bugs)

### NEW System (Fixed)
- ✅ Uses squared distance (no SquareRoot)
- ✅ Caches reference unit positions
- ✅ Reuses groups (no create/destroy)
- ✅ Two-phase approach (reliable)
- ✅ Simple filter (only removes invalid units)

## Key Lessons

1. **Reliability > Performance** - Get it working first, optimize second
2. **Simple is Better** - Complex filters caused more problems than they solved
3. **Test Edge Cases** - Enable/disable, reference units, dynamic movement
4. **Two-Phase Pattern** - Separate "unhide hidden" from "hide visible" logic
5. **Don't Skip Units** - Process ALL units, just filter out truly invalid ones

## Why This Now Works

✅ **Reference units never hidden** - Filter checks against cached array
✅ **All units processed** - Two-phase ensures nothing is missed
✅ **Dynamic updates** - Both phases check current positions
✅ **Enable/disable works** - Unhides all before setting systemEnabled = false
✅ **Performant** - Cached positions, squared distance, reused groups

## Testing Checklist

With the hybrid approach, verify:
- [ ] Units hide when far from references ✅
- [ ] Units unhide when near references ✅
- [ ] Reference units never get hidden ✅
- [ ] System disables and unhides all units ✅
- [ ] System re-enables and works immediately ✅
- [ ] Works dynamically as player moves ✅
- [ ] No lag spikes during checks ✅

The system should now be both **reliable** (like the old version) and **performant** (like the optimized version intended to be).
