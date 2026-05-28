# LAG SPIKE ANALYSIS REPORT
## 5-15 Second FPS Drops (100 fps → 2 fps)

### Date: 2025-10-23
### Analysis Focus: Periodic Timers & Group Operations

---

## 🔴 CRITICAL LAG SUSPECTS (Highest Priority)

### 1. **UnitStats.j** - SEVERE PERFORMANCE ISSUE ⚠️
**CHECK_INTERVAL**: 3.0 seconds  
**Operation**: `GroupEnumUnitsInRect(tempGroup, GetWorldBounds(), filter)`

**PROBLEM**:
- Scans **ENTIRE MAP** every 3 seconds
- Uses `GetWorldBounds()` = checks every single unit on map
- Processes every unit with `Stats_Yes` ability
- Multiple ability checks per unit (Dodge, Crit, Block, Spell Power, Hit)
- Each stat category has 13 ability levels to check (5%, 10%, 15%...100%)

**LAG PATTERN MATCH**: ✅ YES - Every 3 seconds aligns with periodic spikes

**CODE LOCATION**: Lines 490-520
```jass
private function CheckAllStats takes nothing returns nothing
    // Enumerate all units with Stats_Yes ability
    call GroupClear(tempGroup)
    set filter = Filter(function FilterStatsUnits)
    call GroupEnumUnitsInRect(tempGroup, GetWorldBounds(), filter)  // ⚠️ ENTIRE MAP
    call DestroyBoolExpr(filter)
    
    // Process each unit
    loop
        set u = FirstOfGroup(tempGroup)
        exitwhen u == null
        call ProcessUnitStats(u)  // Multiple ability checks per unit
        call GroupRemoveUnit(tempGroup, u)
        set count = count + 1
    endloop
endfunction
```

**OPTIMIZATION SUGGESTIONS**:
1. ✅ Change `CHECK_INTERVAL` from 3.0 to 10.0+ seconds
2. ✅ Use region-based enumeration instead of world bounds
3. ✅ Cache units with Stats_Yes ability in a persistent group
4. ✅ Only check new units or units that changed regions
5. ✅ Process units in batches across multiple frames

---

### 2. **UnitHider3_Optimized.j** - MODERATE PERFORMANCE ISSUE ⚠️
**CHECK_INTERVAL**: 0.5 seconds (VERY FREQUENT)  
**Operation**: `GroupEnumUnitsInRect(tempEnumGroup, GetWorldBounds(), filterExpr)`

**PROBLEM**:
- Scans **ENTIRE MAP** twice per second
- Two-phase system:
  - Phase 1: Check all hidden units if they should be shown
  - Phase 2: Check all visible units if they should be hidden
- Even with filter optimization, GetWorldBounds() is expensive at 0.5s interval

**LAG PATTERN MATCH**: ⚠️ POSSIBLE - Could contribute to periodic spikes

**CODE LOCATION**: Lines 281, 414-418
```jass
// Phase 2: HIDE units that are far from references
call GroupEnumUnitsInRect(tempEnumGroup, GetWorldBounds(), filterExpr)
```

**OPTIMIZATION SUGGESTIONS**:
1. ✅ Increase `CHECK_INTERVAL` from 0.5 to 1.0-2.0 seconds
2. ✅ Use spatial partitioning (divide map into regions)
3. ✅ Only check units near reference unit movement
4. ✅ Skip checks when no reference units have moved significantly

---

### 3. **Reputation.j** - MINOR PERFORMANCE ISSUE ⚠️
**RELATION_UPDATE_INTERVAL**: 5.0 seconds  
**BOARD_UPDATE_INTERVAL**: 1.5 seconds

**PROBLEM**:
- Alliance update system runs every 5 seconds
- Loops through all factions checking reputation thresholds
- Multiboard updates every 1.5 seconds (string operations)

**LAG PATTERN MATCH**: ⚠️ POSSIBLE - 5 second interval matches some spike patterns

**CODE LOCATION**: Lines 477-478, 748
```jass
// Multiboard update
call TimerStart(updater, BOARD_UPDATE_INTERVAL, true, function thistype.update)

// Alliance updates
call TimerStart(CreateTimer(), RELATION_UPDATE_INTERVAL, true, function UpdateFactionAlliances)
```

**OPTIMIZATION SUGGESTIONS**:
1. ✅ Increase `RELATION_UPDATE_INTERVAL` from 5.0 to 10.0 seconds
2. ✅ Only update board when visible to player
3. ✅ Cache faction states to avoid redundant alliance changes

---

### 4. **FloatingTT.j (FloatingTextSimple)** - MINOR PERFORMANCE ISSUE
**UPDATE_INTERVAL**: 0.03125 seconds (32 FPS)

**PROBLEM**:
- Updates ALL active floating text tags every 0.03125 seconds
- Performs distance calculations and visibility checks per text tag
- Uses `GetCameraEyePositionX/Y/Z()` calls each frame

**LAG PATTERN MATCH**: ❌ NO - Continuous, not periodic spikes

**CODE LOCATION**: Lines 17, 162
```jass
private timer TMR = CreateTimer()
call TimerStart(TMR, 0.03125, true, function thistype.update)
```

**OPTIMIZATION SUGGESTIONS**:
1. ✅ Reduce update frequency to 0.1 seconds (10 FPS for text)
2. ✅ Limit max concurrent floating texts
3. ✅ Skip visibility checks if text count is low

---

## 🟡 LOWER PRIORITY SUSPECTS

### 5. **PatrolSystem2_Improved.j** - LOW RISK
**No periodic global timer** - Uses per-unit timers only

**OPERATION**:
- Event-driven (per unit patrol timers)
- No global GroupEnum operations
- Only affects individual patrolling units

**LAG PATTERN MATCH**: ❌ NO - Not periodic, event-based

**OPTIMIZATION**: Already well optimized with TimerUtils

---

### 6. **QuestIconSystem.j** - LOW RISK
**No periodic timer** - Event-driven only

**OPERATION**:
- Only updates icons when quest state changes (trigger-based)
- No continuous polling or group enumeration

**LAG PATTERN MATCH**: ❌ NO - Event-based, not periodic

**OPTIMIZATION**: Already efficient

---

### 7. **UnitExperience2.j / UnitExperience3.j** - LOW RISK
**No periodic timer** - Event-based (on unit death)

**OPERATION**:
- Only runs `ForGroup()` when a unit dies (XP distribution)
- Uses `GroupEnumUnitsInRange()` with limited radius

**LAG PATTERN MATCH**: ❌ NO - Only on death events

**OPTIMIZATION**: Already localized to event radius

---

## 📊 RECOMMENDED ACTION PLAN

### Immediate Actions (Test in Order):

#### 1️⃣ **DISABLE UnitStats.j** (Highest Priority)
```jass
// In Init function, comment out:
// call TimerStart(t, CHECK_INTERVAL, true, function OnTimerExpire)
```
**Expected Result**: Should significantly reduce/eliminate 3-second lag spikes

---

#### 2️⃣ **Increase UnitStats CHECK_INTERVAL**
If system is needed, change:
```jass
private constant real CHECK_INTERVAL = 10.00  // Was 3.00
```
**Expected Result**: Reduce frequency of spikes by 3x

---

#### 3️⃣ **Increase UnitHider3 CHECK_INTERVAL**
```jass
private constant real CHECK_INTERVAL = 1.50  // Was 0.50
```
**Expected Result**: Reduce background load by 3x

---

#### 4️⃣ **Increase Reputation RELATION_UPDATE_INTERVAL**
```jass
private constant real RELATION_UPDATE_INTERVAL = 10.00  // Was 5.00
```
**Expected Result**: Reduce 5-second alliance checks

---

### Advanced Optimizations (If needed):

#### UnitStats.j Complete Rewrite:
1. Maintain persistent group of units with Stats_Yes ability
2. Only add/remove units when ability is added/removed (use trigger)
3. Process 10-20 units per frame instead of all at once
4. Use UnitIndexer events to track ability changes

#### UnitHider3.j Spatial Optimization:
1. Divide map into 4-9 regions
2. Only check regions near reference units
3. Track which units are in which regions
4. Skip entire regions that are far from all references

---

## 🧪 TESTING METHODOLOGY

### Step 1: Identify the Culprit
1. Test map with all systems active (reproduce lag)
2. Disable UnitStats.j - test for 5 minutes
3. If lag persists, disable UnitHider3.j - test again
4. If lag persists, disable Reputation.j - test again

### Step 2: Measure Performance
Use these debug commands in-game:
```jass
// Add to UnitStats.j
call BJDebugMsg("[UnitStats] Processed " + I2S(count) + " units in " + R2S(time) + "s")

// Add to UnitHider3.j  
call BJDebugMsg("[UnitHider] Checked " + I2S(statChecked) + " units")
```

### Step 3: Monitor FPS
- Enable debug mode: `call UnitHider_SetDebugEnabled(true)`
- Monitor messages for timing correlation with FPS drops
- Note exact intervals between lag spikes

---

## 🎯 VERDICT

**PRIMARY SUSPECT**: `UnitStats.j`
- ✅ Matches lag interval (every 3 seconds)
- ✅ Scans entire map with GetWorldBounds()
- ✅ Processes potentially hundreds of units per check
- ✅ Multiple ability checks per unit (65+ ability checks possible)

**SECONDARY SUSPECT**: `UnitHider3_Optimized.j`
- ⚠️ Very frequent checks (0.5 seconds)
- ⚠️ Scans entire map twice per second
- ⚠️ Could compound with UnitStats causing cumulative lag

**TERTIARY SUSPECT**: `Reputation.j`
- ⚠️ 5-second alliance updates could contribute
- ⚠️ Lower impact but still worth optimizing

---

## 📝 NOTES

1. The lag pattern (5-15 seconds of 2 fps, then recovery) suggests:
   - Multiple systems triggering simultaneously
   - Possible timer synchronization (3s + 5s = spikes at 15s intervals)
   - GetWorldBounds() is the common denominator

2. Modern WC3 optimizations:
   - Avoid GetWorldBounds() in periodic functions
   - Use spatial partitioning for large maps
   - Limit GroupEnum operations to 1-2 per second maximum
   - Process units in batches across frames

3. The combination of:
   - UnitStats (3s) + UnitHider (0.5s) + Reputation (5s)
   - Could create worst-case scenario at 15-second intervals when all fire together

---

## 🔧 QUICK TEST CODE

Add to initialization to disable suspects:

```jass
// DISABLE UNITSTATS (Test 1)
// Comment out in UnitStats.j Init():
// call TimerStart(t, CHECK_INTERVAL, true, function OnTimerExpire)

// DISABLE UNITHIDER (Test 2)  
// Comment out in UnitHider3_Optimized.j Init():
// call TimerStart(t, CHECK_INTERVAL, true, function OnTimerExpire)

// DISABLE REPUTATION UPDATES (Test 3)
// Comment out in Reputation.j InitReputations():
// call TimerStart(CreateTimer(), RELATION_UPDATE_INTERVAL, true, function UpdateFactionAlliances)
```

Test each individually, then combinations to isolate the exact cause.

---

**END OF REPORT**
