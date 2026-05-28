# UnitHider3 Critical Bug Fixes - Session 2

## Issues Fixed

### 1. **BlzGroupAddGroupFast Not Available**
**Problem:** Using `BlzGroupAddGroupFast` which doesn't exist in many WC3 versions, causing crashes or silent failures.

**Fix:** Replaced with standard `GroupAddGroup` which is universally supported.

**Changed in:**
- `UpdateReferenceCache()` - Line 101
- `UnitHider_SetSystemEnabled()` - Line 316

### 2. **Reference Units Being Hidden**
**Problem:** The filter was checking `IsUnitInGroup(u, udg_UnitHider_ReferenceGroup)` but this could fail if:
- The group enumeration is happening simultaneously
- The group check returns false positives/negatives during iteration

**Fix:** Changed filter to check against the **cached reference unit array** instead of the group. This ensures reference units are NEVER hidden because they're identified by direct unit comparison.

**Changed in:** `FilterValidUnits()`

### 3. **System Not Working Dynamically**
**Problem:** Several issues prevented dynamic behavior:
- `systemEnabled` was set before unhiding units (blocking the unhide loop)
- Not enough debug messages to track what's happening
- Filter was being called before reference cache was updated

**Fix:** 
- Unhide all units BEFORE setting `systemEnabled = false`
- Added comprehensive debug messages at every step
- Ensured `UpdateReferenceCache()` is called BEFORE enumeration

### 4. **Incomplete Unhiding**
**Problem:** When disabling system, the check `if not enable` wasn't sufficient - needed to also check if system was currently enabled.

**Fix:** Changed condition to `if not enable and systemEnabled` to only unhide when actually transitioning from enabled to disabled.

### 5. **Added Extensive Debug Messages**
To help diagnose issues in-game, added debug messages for:
- Reference unit caching (count, positions)
- Each unit processed (stays visible, stays hidden, shown, hidden)
- System state changes
- Group counts at each step

## How to Test

### Step 1: Enable Debug Mode
```jass
call UnitHider_SetDebugEnabled(true)
```

### Step 2: Check Initial State
Look for these messages:
```
[UnitHider3] Initialized - Interval: 0.50s, Distance: 5500.00
[UnitHider3] ===== Starting visibility check =====
[UnitHider3] Reference units in group: X
[UnitHider3] Cached X reference positions
```

If you see "Reference units in group: 0" - YOUR REFERENCE GROUP IS EMPTY!

### Step 3: Verify Reference Units Are Not Hidden
You should see messages like:
```
[UnitHider3] STAYS VISIBLE: [Hero Name] (near reference)
```

If you see "HIDDEN: [Hero Name]" for your player unit - the filter isn't working!

### Step 4: Test Disable
```jass
call UnitHider_SetSystemEnabled(false)
```

Should see:
```
[UnitHider3] System DISABLING - Will unhide all units. Currently hidden: X
[UnitHider3] Copied X units to unhide
[UnitHider3] Force unhiding: [Unit Name]
[UnitHider3] Force unhiding: [Unit Name]
...
[UnitHider3] All units unhidden. Remaining in hiddenUnits: 0
```

If "Remaining in hiddenUnits" is not 0 - something is wrong!

### Step 5: Test Re-enable
```jass
call UnitHider_SetSystemEnabled(true)
```

Should see:
```
[UnitHider3] System ENABLING... Current state: 0
[UnitHider3] ===== Starting visibility check =====
[UnitHider3] Cached X reference positions
[UnitHider3] HIDDEN: [Far Unit]
[UnitHider3] STAYS VISIBLE: [Near Unit]
```

### Step 6: Test Dynamic Behavior
Move your hero around. Every 0.5 seconds you should see:
```
[UnitHider3] ===== Starting visibility check =====
[UnitHider3] Stats - Checked: X | Hidden: Y | Shown: Z | Total Currently Hidden: W
```

If you don't see these periodic messages - THE TIMER ISN'T RUNNING!

## Common Issues and Solutions

### Issue: "Reference units in group: 0"
**Cause:** `udg_UnitHider_ReferenceGroup` is empty or not initialized
**Solution:** Make sure you add units to the reference group BEFORE calling `UnitHider_StartHideUnitsSystem`

### Issue: Reference units are being hidden
**Cause:** Filter isn't correctly identifying reference units
**Solution:** Check debug messages - if you see reference units in the "Enumerated X valid units" but they're being hidden, the filter fix didn't work. Make sure `refCount > 0` when filter runs.

### Issue: No periodic checks happening
**Cause:** Timer isn't running or `systemEnabled = false`
**Solution:** 
- Check if you see "System ENABLED" message
- Verify timer was created in `Init()`
- Make sure no other code is setting `systemEnabled = false`

### Issue: Units not unhiding when disabling system
**Cause:** 
- `GroupAddGroup` failing
- Group is empty
- `ShowUnit` not working

**Solution:** Check debug messages:
- "Copied X units to unhide" - if 0, the hiddenUnits group is empty
- "Force unhiding: [name]" - should see this for each unit
- "Remaining in hiddenUnits: X" - should be 0

### Issue: System works at start but stops working
**Cause:** Something is calling `UnitHider_SetSystemEnabled(false)` or the timer is being destroyed
**Solution:** 
- Enable debug mode and watch for "System DISABLED" messages
- Make sure no other triggers are modifying the system state

## Code Structure (Correct Order)

1. **Configuration Functions**
   - `UnitHider_SetHidingDistance`
   - `UnitHider_SetDebugEnabled`

2. **Reference Caching**
   - `UpdateReferenceCache` (fills refUnit[], refX[], refY[] arrays)
   - `IsUnitNearAnyReference` (uses cached arrays)

3. **Filter** (called during GroupEnumUnitsInRect)
   - `FilterValidUnits` (uses cached refUnit[] array to skip reference units)

4. **Core System**
   - `CheckUnitsVisibility` (main logic - calls UpdateReferenceCache FIRST!)
   - `OnTimerExpire` (timer callback)

5. **Enable/Disable**
   - `UnitHider_SetSystemEnabled` (calls CheckUnitsVisibility)

6. **Initialization**
   - `Init` (creates timer, starts periodic checks)
   - `UnitHider_StartHideUnitsSystem` (public start function)

## Performance Notes

The system now:
- ✅ Uses `GroupAddGroup` (slower than BlzGroupAddGroupFast but works everywhere)
- ✅ Checks reference units via array comparison (fast)
- ✅ Caches reference positions (avoids repeated GetUnitX/Y)
- ✅ Uses squared distance (no SquareRoot)
- ✅ Reuses groups (no create/destroy spam)

With debug enabled, expect some performance impact from all the debug messages. Disable debug in production!

## Final Checklist

Before using in production:
- [ ] Verify reference units are added to `udg_UnitHider_ReferenceGroup`
- [ ] Test enable/disable cycle multiple times
- [ ] Verify reference units NEVER get hidden
- [ ] Disable debug mode (`call UnitHider_SetDebugEnabled(false)`)
- [ ] Check that units hide/unhide as player moves
- [ ] Verify no units stay hidden when system is disabled
