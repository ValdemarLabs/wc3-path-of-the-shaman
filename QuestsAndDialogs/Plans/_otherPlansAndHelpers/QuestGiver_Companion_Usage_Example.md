# QuestGiver Companion Management - Usage Guide

## Overview
Generic companion management functions have been added to QuestGiver.j that handle all the complexity of adding/removing companions from the player's party.

## Functions

### QuestGiver_AddCompanion
```jass
public function AddCompanion takes unit companionUnit, string companionIcon returns nothing
```

**What it does:**
- Plays rescue sound
- Adds unit to `Companion_Group` and `CompanionFocusNazgrek`
- Displays "{Name} has joined the party!" message
- Updates companion tracking (count, index, icon)
- Syncs with GUI variables
- Triggers multiboard update

**Parameters:**
- `companionUnit` - The unit to add as a companion
- `companionIcon` - Icon path (e.g., `"ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp"`)

### QuestGiver_RemoveCompanion
```jass
public function RemoveCompanion takes unit companionUnit returns nothing
```

**What it does:**
- Orders unit to stop
- Displays debug kick message
- Removes from all companion groups (`Companion_Group`, `CompanionFocusNazgrek`, `CompanionFocusZulkis`)
- Triggers multiboard update

**Parameters:**
- `companionUnit` - The unit to remove from party

## Usage Example (in qValeria.j or similar)

### Before (Old OLDGUI Style):
```jass
// In "Valeria Add Companion" trigger:
Sound - Play Rescue <gen>
Unit Group - Add Valeria to Companion_Group
Unit Group - Add Valeria to CompanionFocusNazgrek
Game - Display to (All players) the text: ((Name of Valeria) + has joined the party!)
Set CompanionCount = (CompanionCount + 1)
Set CompanionUnit[CompanionCount] = Valeria
Set CompanionIndex[(Custom value of Valeria)] = CompanionCount
Set CompanionIcon[CompanionCount] = ReplaceableTextures\CommandButtons\BTNHighElvenArcher.blp
Trigger - Run MultiboardUpdate Add Companion <gen>
```

### After (New QuestGiver.j Style):
```jass
// In qValeria.j (or any quest script):
call QuestGiver_AddCompanion(udg_Valeria, "ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp")
```

### Removing a Companion:
```jass
call QuestGiver_RemoveCompanion(udg_Valeria)
```

## Required GUI Variables

These must be defined in World Editor for the system to work:

**Groups:**
- `udg_Companion_Group` (unit group)
- `udg_CompanionFocusNazgrek` (unit group)
- `udg_CompanionFocusZulkis` (unit group)

**Tracking:**
- `udg_CompanionCount` (integer)
- `udg_CompanionUnit[]` (unit array)
- `udg_CompanionIndex[]` (integer array)
- `udg_CompanionIcon[]` (string array)

**Triggers:**
- `gg_trg_MultiboardUpdate_Add_Companion` (trigger)
- `gg_trg_MultiboardUpdate_Remove_Companion` (trigger)

**Sounds:**
- `gg_snd_Rescue` (sound)

## Benefits

1. **Simplicity**: One-line call instead of 9+ GUI actions
2. **Consistency**: Same behavior across all companions
3. **Maintainability**: Change companion logic in one place
4. **Type Safety**: JASS compilation errors catch mistakes
5. **Reusability**: Works for any companion unit
6. **No State Mismatch**: Uses `udg_CompanionCount` directly, so GUI and JASS code stay synchronized

## Design: Avoiding State Mismatch

**The Problem:**
If we copied `udg_CompanionCount` to a local variable at Init, the two would diverge:
```jass
// BAD: Local copy diverges from GUI variable
private integer CompanionCount = 0
// At Init: CompanionCount = udg_CompanionCount  // Takes value at Init time only
// Later GUI changes to udg_CompanionCount won't be reflected in CompanionCount
```

**The Solution:**
Always use `udg_CompanionCount` directly:
```jass
// GOOD: Always in sync
set udg_CompanionCount = udg_CompanionCount + 1
set CompanionUnit[udg_CompanionCount] = companionUnit
```

**Why Groups Are Different:**
Groups are **reference types** - both variables point to the same object:
```jass
private group Companion_Group = null
// At Init: Companion_Group = udg_Companion_Group  // Both point to same group object
// Changes through either variable affect the same group!
```

This design ensures the system works correctly even if:
- Old GUI triggers still add companions the old way
- New JASS code uses `QuestGiver_AddCompanion`
- Both methods are used in the same map

## Integration with Quest System

These functions integrate seamlessly with the quest system, allowing companion recruitment as quest rewards or actions:

```jass
// Example: Quest completion rewards player with Valeria companion
if q.state == QUEST_STATE_READY_TURNIN then
    call QuestGiver_AddCompanion(udg_Valeria, "ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp")
    call QuestMaster_Complete(q.id)
endif
```

## Notes

- **State Management**: The library uses `udg_CompanionCount` directly instead of maintaining a local copy to prevent state mismatch between GUI and JASS code
- For **reference types** (groups, triggers, sounds), the library stores references that point to the same objects as GUI variables
- For **value types** (integers), the library reads/writes directly to `udg_` variables to ensure synchronization
- `CompanionIndex` uses the unit's custom value as the key
- `CompanionIcon` uses the companion count as the key
- Icon paths should use double backslashes in JASS strings
- If GUI variables don't exist, the functions safely skip those operations (null checks)
- The system is compatible with both old GUI-based and new JASS-based companion management
