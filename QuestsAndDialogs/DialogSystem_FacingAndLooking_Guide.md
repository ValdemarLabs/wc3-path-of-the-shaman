# DialogSystem - Facing and Looking Building Blocks

## Overview
New sequence building blocks have been added to DialogSystem to make facing and looking actions more convenient. These functions combine actions with delays in a single call, making sequences more readable and maintainable.

## Available Functions

### 1. AddMakeFaceEachOther
Makes two units face each other.

```jass
public function AddMakeFaceEachOther takes integer seqId, unit unit1, unit unit2, real faceDuration, real delay returns integer
```

**Parameters:**
- `seqId` - Sequence ID returned from CreateSequence
- `unit1` - First unit
- `unit2` - Second unit  
- `faceDuration` - Time for facing animation (if <= 0, uses random duration for natural movement)
- `delay` - Time to wait after initiating the action

**Example:**
```jass
// Make Aradion and hero face each other
call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 1.0)
```

### 2. AddMakeUnitFaceUnit
Makes one unit face another.

```jass
public function AddMakeUnitFaceUnit takes integer seqId, unit source, unit target, real faceDuration, real delay returns integer
```

**Example:**
```jass
// Make Valeria face Aradion
call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, Aradion, 0.50, 0.5)
```

### 3. AddMakeUnitFacePoint
Makes a unit face a specific point.

```jass
public function AddMakeUnitFacePoint takes integer seqId, unit source, real x, real y, real faceDuration, real delay returns integer
```

**Example:**
```jass
// Make Aradion look at ruins coordinates
local real ruinsX = GetUnitX(Aradion) + 400.00
local real ruinsY = GetUnitY(Aradion) + 400.00
call DialogSystem_AddMakeUnitFacePoint(seq, Aradion, ruinsX, ruinsY, 0.25, 0.5)
```

### 4. AddLookAtUnit
Makes a unit look at another unit with automatic head movement and facing adjustment.

```jass
public function AddLookAtUnit takes integer seqId, unit source, unit target, real delay returns integer
```

**Example:**
```jass
// Make Aradion look at hero with head movement
call DialogSystem_AddLookAtUnit(seq, Aradion, hero, 1.0)
```

### 5. AddLookAtPoint
Makes a unit look at a point with automatic head movement and facing adjustment.

```jass
public function AddLookAtPoint takes integer seqId, unit source, real x, real y, real delay returns integer
```

**Example:**
```jass
call DialogSystem_AddLookAtPoint(seq, Aradion, targetX, targetY, 1.0)
```

### 6. AddResetLookAt
Resets a unit's look-at state (returns head to normal position).

```jass
public function AddResetLookAt takes integer seqId, unit source, real delay returns integer
```

**Example:**
```jass
// Reset Aradion's head position after looking somewhere
call DialogSystem_AddResetLookAt(seq, Aradion, 0.5)
```

## Before vs After Comparison

### OLD WAY (using BindLineAction)
```jass
private function InfoLookAtHero takes nothing returns nothing
    local unit hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if hero == null then
        return
    endif
    call DialogSystem_LookAtUnitWithFacing(Aradion, hero)
    call DialogSystem_LookAtUnitWithFacing(hero, Aradion)
endfunction

private function BuildSequence takes nothing returns integer
    local integer seq
    local integer line
    set seq = DialogSystem_CreateSequence()
    
    // Add line and bind action
    set line = DialogSystem_AddLine(seq, Aradion, "Aradion", "Looking at you...", "sound", true)
    call DialogSystem_BindLineAction(seq, line, function InfoLookAtHero)
    
    return seq
endfunction
```

### NEW WAY (using building blocks)
```jass
private function BuildSequence takes nothing returns integer
    local integer seq
    local unit hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    
    set seq = DialogSystem_CreateSequence()
    
    // Make units face each other automatically
    call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 1.0)
    
    // Add dialogue line
    call DialogSystem_AddLine(seq, Aradion, "Aradion", "Looking at you...", "sound", true)
    
    // Look at each other with head movement
    call DialogSystem_AddLookAtUnit(seq, Aradion, hero, 0.5)
    
    return seq
endfunction
```

## Real World Example

Here's a complete sequence showing a conversation:

```jass
private function OnAcceptQuest takes nothing returns nothing
    local integer seq
    local unit hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    
    set seq = DialogSystem_CreateSequence()
    call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
    
    // Step 1: Make hero and Aradion face each other
    call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 1.0)
    
    // Step 2: First dialogue line
    call DialogSystem_AddLine(seq, Aradion, "Aradion", "I need your help...", "Aradion_0035", true)
    
    // Step 3: Look at nearby ruins
    call DialogSystem_AddMakeUnitFacePoint(seq, Aradion, ruinsX, ruinsY, 0.25, 0.5)
    
    // Step 4: Dialogue while looking at ruins
    call DialogSystem_AddLine(seq, Aradion, "Aradion", "The ruins hold secrets...", "Aradion_0036", true)
    
    // Step 5: Turn back to face hero
    call DialogSystem_AddMakeUnitFaceUnit(seq, Aradion, hero, 0.50, 0.5)
    
    // Step 6: Final dialogue
    call DialogSystem_AddLine(seq, Aradion, "Aradion", "Will you help me?", "Aradion_0037", true)
    
    call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction
```

## Benefits

1. **More Readable** - Actions are inline with dialogue, making sequences easier to understand
2. **Less Code** - No need for separate callback functions for simple facing/looking actions
3. **Adjustable Delays** - Each action has its own delay parameter for fine control
4. **Type Safety** - Parameters are validated at the function level
5. **Reusable** - Can be called multiple times in a sequence without creating new functions

## Migration Tips

When migrating existing sequences:

1. Identify `BindLineAction` calls that perform facing/looking
2. Replace with appropriate `Add*` function calls
3. Remove the callback function if it's only used for that one action
4. Adjust delay parameters to match desired timing

## Notes

- **Delays** are executed AFTER the action is initiated (e.g., after unit starts turning)
- **LookAt** functions use default settings from `DIALOGSYSTEM_LOOK_*` constants
- **FaceDuration** of `<= 0` for `AddMakeFaceEachOther` uses random duration for natural movement
- All functions return the line index (same as `AddLine` and `AddDelay`)
