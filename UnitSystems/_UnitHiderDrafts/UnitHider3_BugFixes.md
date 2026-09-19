# UnitHider3 Bug Fixes - Enable/Disable Issues

## Problems Identified

### 1. **UpdateReferenceCache Destroyed Reference Group**
**Issue:** The function was removing units from `udg_UnitHider_ReferenceGroup` and then re-adding them. This could cause:
- Race conditions if multiple systems use the reference group
- Reference units temporarily missing during updates
- Potential for units to be lost if the function is interrupted

**Fix:** Use a temporary group copy instead of modifying the original reference group.

### 2. **Filter Function Was Too Complex**
**Issue:** The filter tried to do proximity checks and even unhide units during enumeration. This caused:
- Using stale cached positions (cache was updated AFTER filter runs)
- State inconsistencies (hiding/unhiding during filter phase)
- Units being skipped that should have been processed

**Fix:** Simplified filter to only check if a unit is valid (alive, not ignored, not locust). All proximity checks now happen in the main loop.

### 3. **Incomplete Unhiding When Disabling System**
**Issue:** `UnitHider_SetSystemEnabled(false)` only unhid units in the `hiddenUnits` group, but:
- If the group was corrupted or incomplete, some units stayed hidden
- No safety check to ensure all units were actually unhidden
- Modifying group while iterating over it could cause issues

**Fix:** 
- Use temporary group copy to safely iterate
- Added debug messages to track unhiding
- Added count verification to ensure group is empty after unhiding

### 4. **No Immediate Check When Re-enabling**
**Issue:** When calling `UnitHider_SetSystemEnabled(true)`, the system would wait until the next timer tick to check visibility. This caused:
- Delay before system starts working
- Inconsistent behavior (works immediately at map start, delayed when re-enabled)

**Fix:** Added immediate call to `CheckUnitsVisibility()` when enabling the system.

### 5. **Better State Management**
**Issue:** The main visibility check didn't properly track unit states.

**Fix:** 
- Added `wasHidden` variable for clearer logic
- Better debug messages showing what's happening
- Process ALL valid units, not just a filtered subset

## Testing Recommendations

1. **Test Enable/Disable Cycle:**
   ```jass
   call UnitHider_SetDebugEnabled(true)
   call TriggerSleepAction(5.0)
   call UnitHider_SetSystemEnabled(false)  // Should see "Force unhiding" messages
   call TriggerSleepAction(5.0)
   call UnitHider_SetSystemEnabled(true)   // Should see immediate check
   ```

2. **Verify All Units Unhidden:**
   - Check debug message: "Remaining in hiddenUnits: 0"
   - Manually verify no units are invisible after disabling

3. **Test Dynamic Behavior:**
   - Move reference units around while system is enabled
   - Units should hide/unhide dynamically based on distance
   - Enable/disable multiple times - should work consistently each time

4. **Performance Check:**
   - Watch "Stats - Checked" count in debug messages
   - Should process all valid units on map
   - If count seems wrong, check filter criteria

## Code Changes Summary

### Function: `UnitHider_SetSystemEnabled`
- Added temporary group for safe iteration
- Added BlzGroupAddGroupFast for efficient group copying
- Added immediate visibility check when enabling
- Added better debug messages

### Function: `UpdateReferenceCache`
- Uses temporary group instead of modifying original
- Properly cleans up temporary group
- No longer risks corrupting reference group

### Function: `FilterValidUnits`
- Removed proximity checks (was using stale cache)
- Removed unhiding logic (caused state issues)
- Now only filters truly invalid units
- Much simpler and more reliable

### Function: `CheckUnitsVisibility`
- Added `wasHidden` variable for clearer logic
- Better debug messages
- Process ALL valid units (not position-filtered)
- Added count of units found before processing

## Notes on BlzGroupAddGroupFast

This is a native function in Warcraft 3 v1.29+ that efficiently copies all units from one group to another without iteration. If you're on an older version, replace:
```jass
call BlzGroupAddGroupFast(sourceGroup, destGroup)
```

With:
```jass
// Fallback for older versions
local unit tempUnit
loop
    set tempUnit = FirstOfGroup(sourceGroup)
    exitwhen tempUnit == null
    call GroupAddUnit(destGroup, tempUnit)
    call GroupRemoveUnit(sourceGroup, tempUnit)
endloop
// Then restore sourceGroup the same way
```

## Performance Impact

These fixes should **improve** performance because:
- Filter is simpler (fewer checks per unit)
- No longer doing proximity checks with stale data
- No longer processing units multiple times
- Reference group is never destroyed/rebuilt

The system will enumerate more units (since filter is simpler), but the main loop is efficient enough to handle this. The previous "smart filter" was causing more problems than it solved.
