# JASS Group Operations - Quick Reference Card

## 📋 Essential Group Functions

### Creating & Destroying Groups
```jass
// Create new group
local group g = CreateGroup()

// Destroy when done (if not reusing)
call DestroyGroup(g)

// ✅ BEST PRACTICE: Create once, reuse many times
globals
    private group myPersistentGroup = CreateGroup()
endglobals

// Clear and reuse instead of destroying
call GroupClear(myPersistentGroup)
```

### Adding & Removing Units
```jass
// Add single unit
call GroupAddUnit(myGroup, whichUnit)

// Remove single unit
call GroupRemoveUnit(myGroup, whichUnit)

// Check if unit is in group
if IsUnitInGroup(whichUnit, myGroup) then
    // ...
endif

// Clear all units from group
call GroupClear(myGroup)

// ⚠️ EXPENSIVE: Copy all units from one group to another
call GroupAddGroup(sourceGroup, destGroup)
```

---

## 🔍 Group Enumeration Functions

### Basic Enumeration
```jass
// Enumerate all units in rectangular area
call GroupEnumUnitsInRect(
    group whichGroup,           // Group to add units to
    rect r,                     // Rectangle to search
    boolexpr filter             // Filter function (or null)
)

// Enumerate units in radius around point
call GroupEnumUnitsInRange(
    group whichGroup,           // Group to add units to
    real x, real y,             // Center point
    real radius,                // Search radius
    boolexpr filter             // Filter function (or null)
)

// Enumerate units of specific type
call GroupEnumUnitsOfType(
    group whichGroup,           // Group to add units to
    string unitname,            // Unit type name (e.g., "hfoo")
    boolexpr filter             // Filter function (or null)
)

// Enumerate units belonging to player
call GroupEnumUnitsOfPlayer(
    group whichGroup,           // Group to add units to
    player whichPlayer,         // Player to check
    boolexpr filter             // Filter function (or null)
)
```

### Counted Enumeration (with limit)
```jass
// Stop after finding 'countLimit' units
call GroupEnumUnitsInRangeCounted(
    group whichGroup,
    real x, real y,
    real radius,
    boolexpr filter,
    integer countLimit          // Maximum units to add
)

call GroupEnumUnitsOfTypeCounted(
    group whichGroup,
    string unitname,
    boolexpr filter,
    integer countLimit
)
```

---

## 🎯 Filter Functions (CRITICAL FOR PERFORMANCE!)

### Creating a Filter
```jass
// Define filter function (must return boolean)
function MyFilterFunction takes nothing returns boolean
    local unit u = GetFilterUnit()  // Get unit being filtered
    
    // Return true to INCLUDE unit, false to EXCLUDE
    return GetUnitState(u, UNIT_STATE_LIFE) > 0
endfunction

// Create filter expression
local boolexpr myFilter = Filter(function MyFilterFunction)

// Use filter
call GroupEnumUnitsInRect(myGroup, someRect, myFilter)

// ✅ IMPORTANT: Destroy filter when done (unless reusing)
call DestroyBoolExpr(myFilter)

// ✅ BEST PRACTICE: Create once, reuse
globals
    private boolexpr persistentFilter = null
endglobals

function InitFilters takes nothing returns nothing
    set persistentFilter = Filter(function MyFilterFunction)
endfunction
```

### Common Filter Patterns
```jass
// Filter: Living units only
function FilterLiving takes nothing returns boolean
    return GetUnitState(GetFilterUnit(), UNIT_STATE_LIFE) > 0
endfunction

// Filter: Units belonging to specific player
function FilterPlayerUnits takes nothing returns boolean
    return GetOwningPlayer(GetFilterUnit()) == somePlayer
endfunction

// Filter: Units within range of point
function FilterInRange takes nothing returns boolean
    local unit u = GetFilterUnit()
    local real dx = GetUnitX(u) - targetX
    local real dy = GetUnitY(u) - targetY
    return (dx*dx + dy*dy) <= rangeSquared
endfunction

// Filter: Exclude dead, locust, and specific units
function FilterValidTargets takes nothing returns boolean
    local unit u = GetFilterUnit()
    
    // Exclude dead
    if GetUnitState(u, UNIT_STATE_LIFE) <= 0 then
        return false
    endif
    
    // Exclude Locust (dummy units)
    if GetUnitAbilityLevel(u, 'Aloc') > 0 then
        return false
    endif
    
    // Exclude specific group
    if IsUnitInGroup(u, excludedUnits) then
        return false
    endif
    
    return true
endfunction
```

---

## 🔄 Iterating Through Groups

### Method 1: ForGroup (with callback)
```jass
// Define callback function
function ProcessUnit takes nothing returns nothing
    local unit u = GetEnumUnit()  // Get current unit
    // Do something with unit
    call KillUnit(u)
endfunction

// Process all units in group
call ForGroup(myGroup, function ProcessUnit)

// ⚠️ NOTE: GetEnumUnit() does NOT work in AI scripts!
```

### Method 2: FirstOfGroup (recommended for flexibility)
```jass
// ✅ BEST PRACTICE: Use FirstOfGroup with removal
local group tempGroup = CreateGroup()
local unit u

call GroupAddGroup(sourceGroup, tempGroup)  // Copy to temp

loop
    set u = FirstOfGroup(tempGroup)
    exitwhen u == null
    
    // Process unit
    call KillUnit(u)
    
    // ⚠️ CRITICAL: Must remove or infinite loop!
    call GroupRemoveUnit(tempGroup, u)
endloop

call DestroyGroup(tempGroup)
```

### Method 3: FirstOfGroup without copy (destructive)
```jass
// ⚠️ WARNING: This modifies the original group!
local unit u

loop
    set u = FirstOfGroup(myGroup)
    exitwhen u == null
    
    // Process unit
    call KillUnit(u)
    
    // Remove from original group
    call GroupRemoveUnit(myGroup, u)
endloop

// Now myGroup is empty!
```

---

## ⚡ Performance Best Practices

### ✅ DO:
```jass
// 1. Use filters to pre-screen units
local boolexpr filter = Filter(function MyFilter)
call GroupEnumUnitsInRect(g, rect, filter)  // Only adds units that pass filter
call DestroyBoolExpr(filter)

// 2. Reuse groups instead of creating new ones
call GroupClear(myGroup)  // Clear and reuse

// 3. Use squared distance (no SquareRoot)
local real distSq = dx*dx + dy*dy
if distSq <= maxDistSq then  // Compare squared values

// 4. Cache expensive lookups
local real ux = GetUnitX(u)  // Get once
local real uy = GetUnitY(u)  // Use many times

// 5. Early exit in loops
loop
    set u = FirstOfGroup(g)
    exitwhen u == null
    
    if ConditionMet(u) then
        exitwhen true  // ✅ Exit early when found
    endif
    
    call GroupRemoveUnit(g, u)
endloop

// 6. Use counted enumeration when you only need a few units
call GroupEnumUnitsInRangeCounted(g, x, y, radius, filter, 5)  // Stop at 5
```

### ❌ DON'T:
```jass
// 1. ❌ Don't enumerate without filter (processes ALL units)
call GroupEnumUnitsInRect(g, GetWorldBounds(), null)  // BAD!

// 2. ❌ Don't use GroupAddGroup in loops
loop
    // ...
    call GroupAddGroup(bigGroup, tempGroup)  // Copies all units!
endloop

// 3. ❌ Don't call expensive functions repeatedly
loop
    set u = FirstOfGroup(g)
    exitwhen u == null
    
    set dist = SquareRoot(dx*dx + dy*dy)  // ❌ Expensive!
    set ux = GetUnitX(u)  // ❌ If used multiple times, cache it
    
    call GroupRemoveUnit(g, u)
endloop

// 4. ❌ Don't create/destroy groups in loops
loop
    // ...
    local group temp = CreateGroup()  // ❌ Memory allocation in loop!
    // ...
    call DestroyGroup(temp)
endloop

// 5. ❌ Don't forget to remove units in FirstOfGroup loop
loop
    set u = FirstOfGroup(g)
    exitwhen u == null
    
    // Process unit
    // ❌ FORGOT: call GroupRemoveUnit(g, u)
    // This will cause INFINITE LOOP!
endloop
```

---

## 🎓 Example: Efficient Group Processing

### Scenario: Find and damage all enemy units within 500 range of caster

#### ❌ BAD (Inefficient):
```jass
function DamageNearbyEnemies takes unit caster, real damage returns nothing
    local group g = CreateGroup()  // ❌ Created in function
    local unit u
    local real cx = GetUnitX(caster)
    local real cy = GetUnitY(caster)
    local real dx
    local real dy
    local real dist
    
    // ❌ No filter - enumerates ALL units
    call GroupEnumUnitsInRect(g, GetWorldBounds(), null)
    
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null
        
        // ❌ Calculate distance for EVERY unit on map
        set dx = GetUnitX(u) - cx
        set dy = GetUnitY(u) - cy
        set dist = SquareRoot(dx * dx + dy * dy)  // ❌ Expensive!
        
        if dist <= 500 then
            if IsUnitEnemy(u, GetOwningPlayer(caster)) then
                call UnitDamageTarget(caster, u, damage, true, false, 
                    ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
            endif
        endif
        
        call GroupRemoveUnit(g, u)
    endloop
    
    call DestroyGroup(g)
endfunction
```

#### ✅ GOOD (Optimized):
```jass
// Global filter and group (created once)
globals
    private boolexpr damageFilter = null
    private group damageGroup = CreateGroup()
    private player filterPlayer = null
endglobals

// Filter function
private function FilterEnemyUnits takes nothing returns boolean
    local unit u = GetFilterUnit()
    
    // Pre-filter: Only enemy units
    if not IsUnitEnemy(u, filterPlayer) then
        return false
    endif
    
    // Pre-filter: Only living units
    if GetUnitState(u, UNIT_STATE_LIFE) <= 0 then
        return false
    endif
    
    // Pre-filter: No locust
    if GetUnitAbilityLevel(u, 'Aloc') > 0 then
        return false
    endif
    
    return true
endfunction

// Initialize filter
function InitDamageFilter takes nothing returns nothing
    set damageFilter = Filter(function FilterEnemyUnits)
endfunction

// Optimized damage function
function DamageNearbyEnemies takes unit caster, real damage returns nothing
    local unit u
    local real cx = GetUnitX(caster)
    local real cy = GetUnitY(caster)
    
    // Set filter context
    set filterPlayer = GetOwningPlayer(caster)
    
    // ✅ Clear and reuse group
    call GroupClear(damageGroup)
    
    // ✅ Enumerate with filter AND radius (pre-filtered!)
    call GroupEnumUnitsInRange(damageGroup, cx, cy, 500, damageFilter)
    
    // ✅ Process only relevant units
    loop
        set u = FirstOfGroup(damageGroup)
        exitwhen u == null
        
        // ✅ Already filtered - just damage
        call UnitDamageTarget(caster, u, damage, true, false, 
            ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
        
        call GroupRemoveUnit(damageGroup, u)
    endloop
endfunction
```

**Performance Difference:**
- **BAD:** Processes 500 units, 500 SquareRoot calls
- **GOOD:** Processes 5-10 units, 0 SquareRoot calls, 100x faster!

---

## 📊 Performance Comparison

| Operation | Cost | Alternative |
|-----------|------|-------------|
| `CreateGroup()` | High | Reuse persistent group |
| `DestroyGroup()` | High | Reuse instead of destroying |
| `GroupAddGroup()` | Very High | Cache data instead |
| `GroupEnumUnitsInRect(..., null)` | Extreme | Always use filter! |
| `SquareRoot()` | High | Use squared distance |
| `GetUnitX/Y()` in loop | Medium | Cache value |
| `GroupEnumUnitsInRange()` with filter | Low | ✅ Use this! |
| `IsUnitInGroup()` | Low | ✅ Fast check |

---

## 🔗 References

- [JASS Manual - Enumerations](https://jass.sourceforge.net/doc/library.shtml#Enumerations)
- [JASS Manual - Filters](https://jass.sourceforge.net/doc/library.shtml#Filters)
- [JASS API Browser](https://jass.sourceforge.net/doc/api/index.shtml)

---

## 💡 Key Takeaways

1. **ALWAYS use filters** when enumerating units
2. **Reuse groups** instead of creating/destroying
3. **Avoid SquareRoot** - use squared distance
4. **Cache expensive lookups** (GetUnitX/Y, etc.)
5. **GroupAddGroup is expensive** - use sparingly
6. **Early exit** when condition is met
7. **Remember to remove units** in FirstOfGroup loops

**Performance Rule:** If processing 500 units, you're doing it wrong. Use filters to reduce to 10-50 relevant units!
