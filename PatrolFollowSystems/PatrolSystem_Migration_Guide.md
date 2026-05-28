# PatrolSystem Migration Guide

## Overview

The new **unified PatrolSystem** consolidates `PatrolSystem3.j` and `PatrolGroupSystem.j` into a single library that uses only **Bribe's Table** for all data storage.

## What Changed

### Architecture
- **Before**: PatrolSystem3.j used 2 vanilla hashtables (`ht`, `grpHt`) + PatrolGroupSystem.j used Table
- **After**: Single library using only Table for all data storage
- **Benefits**:
  - No more hashtable/Table mixing
  - Eliminates synchronization issues
  - Better performance with Table's optimizations
  - Cleaner, more maintainable code
  - All patrol data in one unified structure

### File Changes
1. **PatrolSystem3.j** → **PatrolSystem_Unified.j** (or rename to PatrolSystem.j)
2. **PatrolGroupSystem.j** → Functionality now built into PatrolSystem_Unified.j

## API Compatibility

### ✅ Single Unit Patrol API (100% Compatible)

All existing single unit patrol functions work exactly the same:

```jass
// Start patrol
call PatrolSystem_Start(unit, waypointCount, resetTime, pathStyle, autoContinue, moveOrder, patrolSpeed)

// Control functions
call PatrolSystem_Stop(unit)
call PatrolSystem_Pause(unit)
call PatrolSystem_Resume(unit)
call PatrolSystem_Continue(unit)
call PatrolSystem_SetMoveStyle(unit, moveOrder)
```

**No changes needed** for existing single unit patrol code!

### ✅ Group Patrol Low-Level API (100% Compatible)

```jass
// Initialize group
local integer groupId = PatrolSystem_GroupInit(group, waypointCount, resetTime, pathStyle, autoResume, moveOrder, patrolSpeed)

// Set waypoints
call PatrolSystem_GroupSetWaypoint(groupId, index, x, y, waitTime)

// Start patrol
call PatrolSystem_GroupStart(groupId)

// Control functions
call PatrolSystem_GroupPause(groupId)
call PatrolSystem_GroupResume(groupId)
call PatrolSystem_GroupContinue(groupId)
call PatrolSystem_GroupStop(groupId)
```

**No changes needed** for existing group patrol code!

### ✅ High-Level PatrolGroup Struct (100% Compatible)

The `PatrolGroup` struct is now **built into** the main PatrolSystem library:

```jass
local PatrolGroup pg = PatrolGroup.create()
set pg.owner = Player(0)
set pg.unitType = 'hfoo'
set pg.unitCount = 4
set pg.respawnTime = 120.0
set pg.waypointCount = 5
set pg.patrolSpeed = 250.0
set pg.waypointWait = 2.0
set pg.resetTime = 15.0
set pg.patrolRegion = gg_rct_PatrolArea
set pg.spawnRegion = gg_rct_SpawnPoint
set pg.pathStyle = PATROL_STYLE_PINGPONG
set pg.moveOrder = "move"
call pg.start()
```

**No changes needed** - just remove the separate `library PatrolGroupSystem` requirement!

## Migration Steps

### Option 1: Clean Replacement (Recommended)

1. **Backup your current files**:
   - Move `PatrolSystem3.j` → `PatrolSystem3_old.j`
   - Move `PatrolGroupSystem.j` → `PatrolGroupSystem_old.j`

2. **Rename the new file**:
   - Rename `PatrolSystem_Unified.j` → `PatrolSystem.j`

3. **Update your map script**:
   - Remove `PatrolGroupSystem` from any trigger requirements
   - Keep only `requires PatrolSystem, Table, UnitDeathEvent`

4. **Test thoroughly**:
   - Test single unit patrols
   - Test group patrols
   - Test PatrolGroup struct functionality

### Option 2: Side-by-Side Testing

1. Keep both systems temporarily
2. Use `PatrolSystem_Unified.j` alongside old files
3. Test with new system
4. Remove old files once confirmed working

## Requirements

The unified system requires:
- **Table** (Bribe's Table library - version 5 or 6)
- **UnitDeathEvent** (centralized death event system)
- **Damage Engine** (for udg_DamageEvent, udg_DamageEventTarget)

## Troubleshooting

### Issue: "Table not found"
**Solution**: Ensure you have Bribe's Table library in your map. Check `Core/Table6.j` or similar.

### Issue: "UnitDeathEvent not found"
**Solution**: Ensure you have the UnitDeathEvent library. This is required for death event handling.

### Issue: Patrols not working
**Solution**: Check that GUI variables are set up correctly:
- `udg_PatrolSystem_Point[]` - location array
- `udg_PatrolSystem_Wait[]` - real array
- `udg_DamageEvent` - real variable
- `udg_DamageEventTarget` - unit variable

## Internal Changes (For Developers)

### Data Storage Structure

#### Single Unit Patrol Data (Table: PatrolData[unitId])
```
Key 2:    current waypoint index
Key 3:    reset time (as integer * 100)
Key 4:    state (0=paused, 1=travel, 2=wait, 3=reset)
Key 5:    direction (+1 or -1 for pingpong)
Key 6:    waypoint count
Key 7:    auto-continue flag
Key 8:    path style
Key 9:    move order (string)
Key 10:   patrol speed (real)
Key 50:   suppress flag
Key 100:  group ID (0 if not in group)
Key 1000: nested Table with waypoints
          [idx*3+0] = x
          [idx*3+1] = y
          [idx*3+2] = wait time
```

#### Group Patrol Data (Table: GroupData[groupId])
```
Key 999:    group ID
Key 2:      current waypoint
Key 3:      reset time
Key 4:      state
Key 5:      direction
Key 6:      waypoint count
Key 7:      auto-continue
Key 8:      path style
Key 9:      move order (string)
Key 10:     patrol speed (real)
Key 11:     unit count
Key 50:     suppress flag
Key 1000:   nested Table with waypoints
Key 2000:   nested Table with formation offsets
            [i*2+0] = offsetX
            [i*2+1] = offsetY
Key 10000+i: unit handles
```

### Performance Notes

- Table is faster than vanilla hashtables for most operations
- Nested tables are automatically managed
- No manual FlushChildHashtable needed (Table handles cleanup)
- Formation offsets calculated once and stored

## Benefits Summary

✅ **Unified Data Storage**: All data in Table, no mixing  
✅ **Better Performance**: Table optimizations throughout  
✅ **Easier Debugging**: Single data structure to inspect  
✅ **No Sync Issues**: No data split between systems  
✅ **Cleaner Code**: One library instead of two  
✅ **100% API Compatible**: No code changes needed  
✅ **Maintainability**: Easier to extend and fix  

## Questions?

Check the library header documentation in `PatrolSystem_Unified.j` for detailed usage examples.
