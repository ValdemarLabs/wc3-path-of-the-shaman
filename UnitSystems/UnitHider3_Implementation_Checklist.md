# UnitHider3 Implementation Checklist

## 📋 Pre-Implementation Checklist

### Dependencies
- [ ] **Table library** (by Bribe) is imported in your map
  - Check: Search for `library Table` in your scripts
  - If missing: Import Table.j before UnitHider3

- [ ] **TimerUtils** (by Vexorian) is imported in your map
  - Check: Search for `library TimerUtils` in your scripts
  - If missing: Import TimerUtils.j before UnitHider3

### Global Variables (Create in World Editor)
- [ ] **udg_UnitHider_ReferenceGroup** exists
  - Type: Unit Group
  - Initial Value: Empty unit group
  - Purpose: Stores units that define visibility range (heroes, camera follows, etc.)

- [ ] **udg_UnitHider_IgnoredUnits** exists
  - Type: Unit Group
  - Initial Value: Empty unit group
  - Purpose: Units that should NEVER be hidden (quest NPCs, important units, etc.)

### Current System Review
- [ ] Identify which UnitHider version you're currently using
  - [ ] UnitHider.j (no filter, severe lag)
  - [ ] UnitHider2.j (basic filter, some lag)
  - [ ] Other version

- [ ] Backup current UnitHider file
  - [ ] Copy to `UnitHider_OLD_BACKUP.j`

- [ ] Note current hiding distance setting: _________ (default: 5500.0)

- [ ] Note current check interval: _________ (default: 0.5s)

---

## 🚀 Implementation Steps

### Step 1: Import UnitHider3_Optimized.j
- [ ] Copy `UnitHider3_Optimized.j` to your map's script folder

- [ ] In World Editor, import the file
  - Trigger Editor → Import File → Select UnitHider3_Optimized.j

### Step 2: Update Library Requirements
Find your map initialization or main library:

```jass
// OLD (before):
library MapInit requires Table, TimerUtils, UnitHider
    // ...
endlibrary

// NEW (after):
library MapInit requires Table, TimerUtils, UnitHider3
    // ...
endlibrary
```

- [ ] Changed `requires UnitHider` to `requires UnitHider3`
- [ ] Or changed `requires UnitHider2` to `requires UnitHider3`

### Step 3: Remove Old UnitHider Import
- [ ] Comment out or remove old UnitHider import:
  ```jass
  // //! import "UnitHider.j"  // OLD - removed
  //! import "UnitHider3_Optimized.j"  // NEW
  ```

### Step 4: Verify Initialization Code
Find where UnitHider is initialized (usually in map init):

- [ ] Check that system is started:
  ```jass
  call UnitHider_StartHideUnitsSystem()
  ```

- [ ] Check that reference units are added:
  ```jass
  // Example: Add hero units
  call GroupAddUnit(udg_UnitHider_ReferenceGroup, gg_unit_Hero_0001)
  call GroupAddUnit(udg_UnitHider_ReferenceGroup, playerHero)
  ```

- [ ] Check that ignored units are added (if any):
  ```jass
  // Example: Important NPCs that should never hide
  call GroupAddUnit(udg_UnitHider_IgnoredUnits, questGiverNPC)
  ```

---

## 🧪 Testing Phase

### Test 1: Enable Debug Mode
Add after system initialization:
```jass
call UnitHider_SetDebugEnabled(true)
```

- [ ] Debug enabled
- [ ] Map compiles without errors

### Test 2: Start Game and Verify
- [ ] Game starts without errors
- [ ] See initialization message: `[UnitHider3] Initialized...`
- [ ] See periodic messages every 0.5s: `[UnitHider3] Stats - Checked: XX | Hidden: XX | Shown: XX`

### Test 3: Check Performance Metrics
Watch the debug messages. What you SHOULD see:

- [ ] **Checked value**: 50-150 units per cycle (not 400-500!)
  - If showing 400-500: Filter not working - check reference group has units

- [ ] **Hidden value**: Reasonable number (5-20 typically)
  - Units being hidden this cycle

- [ ] **Shown value**: Reasonable number (2-10 typically)
  - Units being shown this cycle

- [ ] **Total Hidden**: Total currently hidden units (increases as you move)

### Test 4: Functional Testing
- [ ] Move hero across map
  - Units should hide almost instantly
  - No lag spikes every 0.5 seconds
  - Smooth gameplay

- [ ] Units near hero are visible
  - Reference units themselves are never hidden
  - Units within hiding distance are visible

- [ ] Units far from hero are hidden
  - Units beyond hiding distance are hidden
  - No units visible in unexplored areas

- [ ] Ignored units are never hidden
  - Quest NPCs remain visible
  - Important units remain visible

### Test 5: Performance Check
- [ ] No lag when standing still
- [ ] No lag when moving
- [ ] No lag with many units on map (500+)
- [ ] Smooth frame rate
- [ ] No stuttering or freezing

---

## ⚙️ Configuration & Tuning

### Adjust Hiding Distance (if needed)
```jass
// After UnitHider_StartHideUnitsSystem():
call UnitHider_SetHidingDistance(5500.0)  // Your desired distance
```

- [ ] Set hiding distance to: _________ units

### Adjust Check Interval (if needed)
Edit in UnitHider3_Optimized.j:
```jass
globals
    private constant real CHECK_INTERVAL = 0.50  // Change this
endglobals
```

Recommendations:
- **0.33s** - Very responsive, more operations (good for small maps)
- **0.50s** - Default, balanced (recommended for most maps)
- **1.00s** - Less responsive, fewer operations (good for huge maps)

- [ ] Check interval set to: _________ seconds

### Adjust Max Reference Units (if needed)
Edit in UnitHider3_Optimized.j:
```jass
globals
    private constant integer MAX_REF_UNITS = 20  // Change if needed
endglobals
```

- [ ] Max reference units set to: _________

---

## 🐛 Troubleshooting

### Issue: All units are being hidden
**Symptoms:** Debug shows "Checked: 500", everything disappears

**Solutions:**
- [ ] Verify reference group has units:
  ```jass
  call GroupAddUnit(udg_UnitHider_ReferenceGroup, heroUnit)
  ```
- [ ] Verify system is enabled:
  ```jass
  call UnitHider_SetSystemEnabled(true)
  ```
- [ ] Check that reference units are alive

### Issue: No units are being hidden
**Symptoms:** Debug shows "Hidden: 0", units stay visible

**Solutions:**
- [ ] Check hiding distance is reasonable:
  ```jass
  call UnitHider_SetHidingDistance(5500.0)  // Not 50000.0!
  ```
- [ ] Verify units aren't in ignored group
- [ ] Check that system is enabled

### Issue: Still seeing lag
**Symptoms:** Game stutters, "Checked" is still high (400+)

**Solutions:**
- [ ] Verify using UnitHider3 (not old version)
- [ ] Check that reference group has units (filter won't work without them)
- [ ] Try increasing CHECK_INTERVAL to 1.0s
- [ ] Reduce hiding distance to process fewer units

### Issue: Compilation errors
**Symptoms:** Map won't compile, shows errors

**Solutions:**
- [ ] Verify Table library is imported
- [ ] Verify TimerUtils library is imported
- [ ] Check that udg_UnitHider_ReferenceGroup exists
- [ ] Check that udg_UnitHider_IgnoredUnits exists
- [ ] Verify UnitHider3 is imported AFTER dependencies

### Issue: Units hide/show too slowly
**Symptoms:** Units take time to hide when you move away

**Solutions:**
- [ ] Decrease CHECK_INTERVAL (e.g., 0.33s)
- [ ] Verify "Checked" count is low (50-150)
- [ ] Check that filter is working properly

---

## ✅ Final Verification

### Performance Verification
Run the map with debug enabled for 2-3 minutes:

- [ ] Average "Checked" value: _________ (should be 50-150)
- [ ] No lag spikes observed
- [ ] Smooth gameplay
- [ ] Units hide/show instantly
- [ ] FPS remains stable

### Functional Verification
- [ ] Hero units are never hidden
- [ ] Reference units are never hidden
- [ ] Ignored units are never hidden
- [ ] Units near hero are visible
- [ ] Units far from hero are hidden
- [ ] Moving reveals new units
- [ ] Moving hides distant units

### Code Quality Verification
- [ ] No compilation errors
- [ ] No compilation warnings
- [ ] Debug messages are clear
- [ ] System initializes properly

---

## 🎯 Post-Implementation

### Disable Debug Mode
Once everything is working:
```jass
call UnitHider_SetDebugEnabled(false)
```

- [ ] Debug disabled for release

### Document Your Settings
Record your final configuration:

```
Configuration:
- Hiding Distance: _________ units
- Check Interval: _________ seconds
- Max Reference Units: _________
- Reference Units: _________________________________
- Ignored Units: ___________________________________
```

### Backup Final Version
- [ ] Save working version
- [ ] Document any custom changes
- [ ] Keep UnitHider3_Optimized.j as-is for easy updates

---

## 📊 Performance Comparison Results

Fill in after testing:

### Before (Old UnitHider):
- Checked per cycle: _________
- Operations per cycle: _________ (estimated)
- Lag: [ ] None [ ] Some [ ] Severe
- Hide speed: [ ] Instant [ ] Slow [ ] Very Slow

### After (UnitHider3):
- Checked per cycle: _________
- Operations per cycle: _________ (estimated)
- Lag: [ ] None [ ] Some [ ] Severe
- Hide speed: [ ] Instant [ ] Slow [ ] Very Slow

### Improvement:
- Units processed: _________% reduction
- Estimated operations: _________% reduction
- Lag: [ ] Eliminated [ ] Reduced [ ] Same
- Performance: [ ] Much Better [ ] Better [ ] Same

---

## 🎓 Knowledge Check

Answer these to verify understanding:

1. **Why is filter function important?**
   - [ ] I understand: Pre-filters units before main loop, reducing processed units by 90%

2. **Why cache reference positions?**
   - [ ] I understand: Avoids repeated GetUnitX/Y calls (10,000 → 20 calls)

3. **Why use squared distance?**
   - [ ] I understand: Eliminates expensive SquareRoot calculations (5,000 → 0 calls)

4. **What should "Checked" value be?**
   - [ ] I understand: Should be 50-150 (not 400-500), indicating filter is working

5. **When to increase CHECK_INTERVAL?**
   - [ ] I understand: If still experiencing lag or performance issues

---

## 📝 Notes & Custom Changes

Document any custom modifications or issues encountered:

```
Date: __________

Changes Made:
- 
- 
- 

Issues Encountered:
- 
- 
- 

Solutions Applied:
- 
- 
- 

Performance Results:
- 
- 
- 
```

---

## 🎉 Success Criteria

Your implementation is successful when:

- [✓] Map compiles without errors
- [✓] Game starts without errors
- [✓] "Checked" value is 50-150 per cycle
- [✓] No lag or stuttering
- [✓] Units hide instantly when you move away
- [✓] Units show instantly when you move close
- [✓] Reference units never hide
- [✓] Ignored units never hide
- [✓] Smooth gameplay
- [✓] Performance improved by 90%+

---

## 🆘 Getting Help

If you encounter issues:

1. **Check debug messages**: Enable debug and watch "Checked" value
2. **Verify reference group**: Make sure it has units
3. **Check dependencies**: Table and TimerUtils must be imported
4. **Review documentation**: Read UnitHider_OPTIMIZATION_GUIDE.md
5. **Check JASS reference**: https://jass.sourceforge.net/doc/library.shtml

---

**Implementation Date:** __________
**Implemented By:** __________
**Status:** [ ] Planning [ ] In Progress [ ] Testing [ ] Complete
**Result:** [ ] Success [ ] Partial [ ] Failed (see notes)

---

**Ready to implement?** Follow this checklist step-by-step for a smooth migration!
