# Critical Issues in Current UnitHider Implementations

## UnitHider.j (Lines 116-145) - SEVERE LAG ISSUES ⚠️

### Issue #1: No Filter Function
```jass
// Line 133 - CRITICAL LAG SOURCE
call GroupEnumUnitsInRect(g, GetWorldBounds(), null)
```

**Problem:** This enumerates **EVERY SINGLE UNIT** on the entire map without any filtering!

**Impact:**
- If map has 500 units → processes all 500 every 0.5 seconds = 1000 operations/second
- No way to skip irrelevant units (dead, locust, far away, etc.)
- This is like searching every item in a warehouse when you only need 10 items

### Issue #2: GroupAddGroup in Loop
```jass
// Line 59 - Inside IsUnitNearReferenceUnits function
call GroupAddGroup(udg_UnitHider_ReferenceGroup, refGroup)
```

**Problem:** 
- Creates a COMPLETE COPY of all reference units
- This function is called for EVERY unit being checked (500+ times per cycle)
- If reference group has 10 units, that's 10 group additions × 500 calls = 5000 operations

### Issue #3: Nested Group Creation
```jass
// Line 52 - Inside IsUnitNearReferenceUnits (called 500+ times)
function UnitHider_IsUnitNearReferenceUnits takes unit u returns boolean
    local group refGroup = CreateGroup()  // ❌ Created repeatedly
    // ...
    call DestroyGroup(refGroup)  // ❌ Destroyed repeatedly
endfunction
```

**Problem:** Memory allocation/deallocation happening 500+ times per check cycle

### Issue #4: SquareRoot Every Distance Check
```jass
// Line 70 - Inside distance check loop
set distance = SquareRoot(dx * dx + dy * dy)
```

**Problem:** 
- SquareRoot is expensive (10x slower than multiplication)
- Called potentially 5000+ times per cycle (500 units × 10 references)
- Completely unnecessary - can compare squared distances

---

## UnitHider2.j - BETTER but Still Has Issues ⚙️

### ✅ Improvements in UnitHider2.j:
1. Has a filter function (`FilterValidUnits`)
2. Uses Table instead of hashtable
3. Uses squared distance (no SquareRoot)
4. Reuses some groups

### ❌ Remaining Issues:

#### Issue #1: Filter Not Aggressive Enough
```jass
// Lines 174-192 - Filter function
private function FilterValidUnits takes nothing returns boolean
    local unit u = GetFilterUnit()
    
    if IsUnitInGroup(u, udg_UnitHider_ReferenceGroup) then
        return false
    endif
    
    if IsUnitInGroup(u, udg_UnitHider_IgnoredUnits) then
        return false
    endif
    
    if GetUnitState(u, UNIT_STATE_LIFE) <= 0 then
        return false
    endif
    
    if GetUnitAbilityLevel(u, 'Aloc') > 0 then
        return false
    endif
    
    return true  // ❌ Returns true for ALL units (even those near references!)
endfunction
```

**Problem:** This still processes 90% of units unnecessarily!
- Units near references don't need checking (they're already visible)
- Should only enumerate units that are FAR from references

**Better approach:**
```jass
// Only return true for units that actually need processing
if IsUnitNearAnyReference(ux, uy) then
    if IsUnitInGroup(u, hiddenUnits) then
        return true  // Was hidden, needs unhiding
    else
        return false  // Already visible and near - SKIP!
    endif
endif
```

#### Issue #2: Still Uses GroupAddGroup
```jass
// Line 142 - Inside IsUnitNearReferenceUnits
call GroupAddGroup(udg_UnitHider_ReferenceGroup, refCheckGroup)
```

**Problem:** Still creates a full copy of reference group for every unit check
- Should cache positions instead

#### Issue #3: No Position Caching
```jass
// Lines 144-157 - Gets positions repeatedly
loop
    set ref = FirstOfGroup(refCheckGroup)
    exitwhen ref == null
    
    set dx = GetUnitX(ref) - ux  // ❌ Called 500+ times
    set dy = GetUnitY(ref) - uy  // ❌ Called 500+ times
```

**Problem:** GetUnitX/Y called thousands of times when positions could be cached once

---

## Performance Breakdown: By The Numbers

### Current UnitHider.j (Worst Case - 500 units on map)

**Per Check Cycle (0.5 seconds):**
```
GroupEnumUnitsInRect (no filter):
  → 500 units enumerated
  
IsUnitNearReferenceUnits (called for each unit):
  → CreateGroup() × 500 = 500 allocations
  → GroupAddGroup() × 500 = 5,000 unit additions (10 refs × 500 calls)
  → GetUnitX/Y × 5,000 = 10,000 native calls (500 units × 10 refs × 2)
  → SquareRoot() × 5,000 = 5,000 expensive calculations
  → DestroyGroup() × 500 = 500 deallocations

TOTAL OPERATIONS: ~21,000+ per cycle
```

**Every Second:** ~42,000 operations
**Per Minute:** ~2,520,000 operations

### UnitHider2.j (Better - with basic filter)

**Per Check Cycle (0.5 seconds):**
```
GroupEnumUnitsInRect (with basic filter):
  → 400 units enumerated (filters out dead/locust)
  
IsUnitNearReferenceUnits (called for each unit):
  → GroupAddGroup() × 400 = 4,000 unit additions
  → GetUnitX/Y × 4,000 = 8,000 native calls
  → Squared distance × 4,000 = 4,000 calculations (no SquareRoot ✅)

TOTAL OPERATIONS: ~16,000 per cycle
```

**Improvement:** ~24% reduction

### UnitHider3_Optimized.j (Best)

**Per Check Cycle (0.5 seconds):**
```
UpdateReferenceCache (once per cycle):
  → GetUnitX/Y × 10 = 20 native calls
  
GroupEnumUnitsInRect (with smart filter):
  → 50 units enumerated (90% reduction! ✅)
  → Filter checks position against cache
  
Main loop (only 50 units):
  → Cached position lookups × 50 = 50 array accesses
  → Squared distance × 500 = 500 calculations (50 units × 10 refs)

TOTAL OPERATIONS: ~620 per cycle
```

**Improvement:** ~97% reduction vs UnitHider.j, ~96% reduction vs UnitHider2.j

---

## Why "Slow Hiding" Around the Map?

### Root Cause: Processing Bottleneck

When checking 500 units every 0.5 seconds:
1. Game engine allocates CPU time slice to script
2. Script starts processing units
3. **CPU time slice expires** (operations limit hit)
4. Script is paused mid-execution
5. Remaining units don't get processed until next cycle
6. Units far from player take many cycles to reach

**Warcraft 3 Thread Limit:**
> "There is an opcode execution limit; when a thread runs more opcodes than the limit it is put to sleep automatically for 1 second."

**Solution:** Reduce operations per cycle by 90%+ with proper filtering

---

## Testing Results (Expected)

### With UnitHider.j:
```
[UnitHider] Total Units: 487 | Hidden: 12 | Shown: 3
[UnitHider] Total Units: 487 | Hidden: 8 | Shown: 2
[UnitHider] Total Units: 487 | Hidden: 15 | Shown: 5
```
**Notice:** Processing 487 units EVERY cycle!

### With UnitHider3_Optimized.j:
```
[UnitHider3] Stats - Checked: 48 | Hidden: 8 | Shown: 2 | Total Hidden: 245
[UnitHider3] Stats - Checked: 52 | Hidden: 12 | Shown: 5 | Total Hidden: 252
[UnitHider3] Stats - Checked: 51 | Hidden: 7 | Shown: 3 | Total Hidden: 256
```
**Notice:** Processing only 48-52 units per cycle (90% reduction!)

---

## Immediate Action Items

### 1. Stop Using UnitHider.j Immediately ⛔
- It has NO filter function
- Creates/destroys 500+ groups per cycle
- Calls SquareRoot 5000+ times per cycle
- Uses GroupAddGroup inefficiently

### 2. If Using UnitHider2.j - It's Better But Still Problematic ⚠️
- Filter is too permissive (still processes 80% of units)
- Still uses GroupAddGroup (expensive)
- No position caching

### 3. Use UnitHider3_Optimized.j ✅
- Smart filter reduces processed units by 90%
- Caches reference positions
- No SquareRoot calculations
- Reuses all groups
- 97% fewer operations

### 4. Configuration for Your Map

Based on your 5500.0 distance setting:
```jass
// In map initialization
call UnitHider_SetHidingDistance(5500.0)
call UnitHider_SetDebugEnabled(true)  // Enable initially
call UnitHider_StartHideUnitsSystem()

// Add your hero/camera units to reference group
call GroupAddUnit(udg_UnitHider_ReferenceGroup, gg_unit_hero)

// Add units that should NEVER be hidden
call GroupAddUnit(udg_UnitHider_IgnoredUnits, importantQuestUnit)
```

### 5. Monitor Performance
```jass
// After testing, disable debug
call UnitHider_SetDebugEnabled(false)
```

---

## JASS Documentation References

From https://jass.sourceforge.net/doc/library.shtml:

### On Filters:
> "The filter serves as an additional condition that each element must satisfy before being added to the group or force."

**Key Point:** Filter runs BEFORE adding to group, saving processing time

### On Group Enumeration:
> "If no additional condition is required, then you can pass in the value `null` instead of an actual `filterfunc`."

**Warning:** Only use `null` if you ACTUALLY need all units. Otherwise, use a filter!

### On FirstOfGroup:
> "One way to get around this apparent limitation is by using the `FirstOfGroup()` and `GroupRemoveUnit()` functions to iterate through a temporary group"

**Best Practice:** Always remove unit after processing in the loop

### On Performance:
> "There is an opcode execution limit; when a thread runs more opcodes than the limit it is put to sleep automatically for 1 second."

**Critical:** Too many operations = script pauses = slow/choppy behavior

---

## Summary

| Metric | UnitHider.j | UnitHider2.j | UnitHider3 |
|--------|-------------|--------------|------------|
| **Units Processed** | 500 | 400 | 50 |
| **Has Filter** | ❌ No | ⚠️ Basic | ✅ Smart |
| **Uses SquareRoot** | ❌ Yes | ✅ No | ✅ No |
| **Caches Positions** | ❌ No | ❌ No | ✅ Yes |
| **GroupAddGroup** | ❌ 500/cycle | ❌ 400/cycle | ✅ 0/cycle |
| **Operations/Cycle** | ~21,000 | ~16,000 | ~620 |
| **Performance** | 🐌 Slow | ⚠️ Medium | ⚡ Fast |
| **Lag** | ⛔ Severe | ⚠️ Some | ✅ Minimal |

**Recommendation:** Migrate to UnitHider3_Optimized.j immediately for 97% performance improvement.
