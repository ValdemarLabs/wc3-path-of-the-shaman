# qAradion Refactoring Summary
## Date: February 12, 2026

## Overview
Refactored qAradion to extract generic quest-giver patterns into the QuestGiver library, making it easier to create new quest givers (qQuestGiverXXX) by reducing boilerplate. qAradion now focuses on **content and custom logic only**.

---

## What Was Added to QuestGiver

### 1. Generic Sequence-End Handler
**Function**: `QuestGiver_HandleSequenceEnd(giver, cooldownTimer, cooldownDuration, stopCamera, cameraStopDuration, useCamera, reopenDialog)`

**Purpose**: Consolidates the repetitive cleanup logic that appears at the end of every accept/complete/fail/farewell sequence.

**What it does**:
- Closes the active dialog
- Starts cooldown timer
- Stops dialog camera with transition
- (Future: reopen dialog support)

**Replaces**: All individual `OnAcceptQuestXEnd`, `OnCompleteQuestXEnd`, `OnFarewellEnd` functions that duplicated:
```jass
call QuestGiver_CloseActiveDialog()
set AradionDialogCooldown = QuestGiver_StartCooldown(AradionDialogCooldown, DIALOG_COOLDOWN)
call DialogSystem_StopDialogCamera(Player(0), 2.00, USE_DIALOG_CAMERA)
```

---

### 2. Generic Accept Sequence Builder
**Function**: `QuestGiver_CreateAcceptSequence(giver, giverName, hero, heroName, dialogRange, allowNazgrek, allowZulkis)`

**Purpose**: Builds the boilerplate "accept quest" sequence with hero greeting and NPC response.

**What it does**:
- Creates sequence with default speaker
- Auto-resolves hero if not provided
- Adds hero accept line (picked from dialog pool)
- Adds NPC accept response (picked from dialog pool)
- Returns sequence ID for caller to add custom lines

**Replaces**: The repetitive pattern in every `OnAcceptQuestX`:
```jass
local integer seq
local unit hero
local string heroName
set seq = DialogSystem_CreateSequence()
call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
set heroName = QuestGiver_GetHeroName(hero)
if hero != null then
    call DialogSystem_PickAcceptLine(hero, heroName)
    call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
endif
call DialogSystem_PickAcceptLine(Aradion, "Aradion the Farseer")
call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
```

**Now becomes**:
```jass
local integer seq
set seq = QuestGiver_CreateAcceptSequence(Aradion, "Aradion the Farseer", null, "", DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
// Add custom quest-specific lines here
```

---

### 3. Generic Complete Sequence Builder
**Function**: `QuestGiver_CreateCompleteSequence(giver, giverName)`

**Purpose**: Creates a minimal complete sequence skeleton.

**What it does**:
- Creates sequence with default speaker
- Returns sequence ID for caller to add custom completion dialog

**Replaces**:
```jass
local integer seq
set seq = DialogSystem_CreateSequence()
call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
```

---

### 4. Generic Farewell Sequence Builder
**Function**: `QuestGiver_CreateFarewellSequence(giver, giverName, hero, heroName, dialogRange, allowNazgrek, allowZulkis)`

**Purpose**: Builds the complete "farewell" sequence with hero goodbye and NPC response.

**What it does**:
- Creates sequence with default speaker
- Auto-resolves hero if not provided
- Adds hero farewell line (picked from dialog pool)
- Adds NPC farewell response (picked from dialog pool)
- Returns complete sequence ready to play

**Replaces**: The entire `OnFarewell` body (except callbacks):
```jass
local integer seq
local unit hero
local string heroName
set seq = DialogSystem_CreateSequence()
call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
set heroName = QuestGiver_GetHeroName(hero)
if hero != null then
    call DialogSystem_PickFarewellLine(hero, heroName)
    call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
endif
call DialogSystem_PickFarewellLine(Aradion, "")
call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
```

**Now becomes**:
```jass
local integer seq
set seq = QuestGiver_CreateFarewellSequence(Aradion, "Aradion the Farseer", null, "", DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
```

---

## What Was Removed from qAradion

### Removed Functions
1. **`GetQuest(questName)`** - Unused wrapper; callers now use `QuestGiver_GetByNameAndGiver` directly
2. **`CameraWide()`** - Unused camera preset wrapper
3. **`CameraClose()`** - Unused camera preset wrapper

### Simplified Functions
All quest handlers now use the generic QuestGiver helpers:
- `OnAcceptQuest1/2/3/4` - Now ~10 lines instead of ~25
- `OnCompleteQuest1/2/3/4` - Now ~10 lines instead of ~15
- `OnFarewell` - Now ~6 lines instead of ~18
- All `*End` callbacks - Now ~3 lines instead of ~5

---

## Code Size Reduction

**Before refactoring**: 678 lines
**After refactoring**: 595 lines
**Reduction**: 83 lines (~12% smaller)

More importantly, **boilerplate code is now centralized** in QuestGiver, so:
- New quest givers can be created faster
- Consistency is enforced (all quest givers use same patterns)
- Bugs fixed in QuestGiver helpers benefit all quest givers
- Each qQuestGiverXXX file remains focused on **content and story**, not infrastructure

---

## What qAradion Still Contains (Content/Custom Logic Only)

### Configuration
- Quest names
- Item type IDs
- Dialog range, camera settings
- Hero restrictions (Nazgrek/Zulkis)

### Custom State Flags
- `AradionBackstorySeen`
- `RangerMissingReq1Complete`

### Content-Specific Sequences
- `PlayGreetFirstSequence()` - First meeting with Aradion (unique)
- `PlayGreetNormalSequence()` - Random normal greetings
- `BuildInfoSequence()` - Backstory (unique to Aradion)
- Custom quest-specific lines in each accept/complete handler

### Dialog Building Logic
- `BuildDialog()` - Quest button visibility rules (could be further abstracted in future)
- Custom gating conditions (e.g., `RangerMissingReq1Complete and QuestGiver_IsUnitAlive(Valeria)`)

### Quest Definitions
- `CreateQuests()` - Quest metadata (title, icon, description, requirements)

### Line Registration
- `RegisterLines()` - Farewell line pool for Aradion

---

## Future Refactoring Opportunities

### High Priority
1. **Generic Dialog Builder** - Extract `BuildDialog()` pattern into a rule-based system
   - Each quest giver would provide a list of button rules
   - QuestGiver would handle the state checks and button creation
   
2. **Generic Selection Handler** - Extract `OnSelected()` pattern into a callback-based system
   - Each quest giver would provide callbacks for first greet, normal greet, dialog build
   - QuestGiver would handle selection gating, cooldown checks, first-greet flag

### Medium Priority
3. **Quest Definition Structs** - Replace `CreateQuests()` with data-driven approach
   - Define quests as array of structs
   - Call `QuestGiver_CreateQuestsFromDefs(giver, questDefs[])`

4. **Init/Wait Pattern** - Extract `InitDelayed()` + `Init()` pattern
   - Most quest givers wait for globals like `udg_Aradion` to initialize
   - Could be a generic `QuestGiver_InitWithWait(unitGlobalVarName, callback)`

---

## Example: Creating a New Quest Giver

**Before this refactoring**, creating a new quest giver required:
- ~25 lines per accept sequence × N quests
- ~15 lines per complete sequence × N quests
- ~5 lines per sequence-end callback × N quests × 2 (accept + complete)
- ~18 lines for farewell
- Selection handler boilerplate
- Camera wrappers (if needed)

**After this refactoring**, a new quest giver needs:
- ~10 lines per accept sequence (helper + custom lines)
- ~10 lines per complete sequence (helper + custom lines)
- ~3 lines per sequence-end callback (just call `HandleSequenceEnd`)
- ~6 lines for farewell (just use helper)
- Selection handler (still boilerplate, future work)
- Quest definitions (still manual, future work)

**Result**: ~40% less code per quest giver, with better consistency.

---

## Testing Checklist

Before deploying, verify:
- [ ] All quest accept sequences play correctly
- [ ] All quest complete sequences play correctly
- [ ] Quest fail sequence works (Quest 1)
- [ ] Farewell sequence plays correctly
- [ ] Backstory info sequence reopens dialog at end
- [ ] Camera starts and stops correctly
- [ ] Cooldown timer prevents rapid re-selection
- [ ] Custom gating conditions work (e.g., Valeria range check for Quest 1 completion)
- [ ] Item checks work (Quest 2: mana crystals, Quest 3: wraith essences + rod)

---

## Notes for Future Quest Givers

When creating a new qQuestGiverXXX library:

1. **Use the helpers**:
   - `QuestGiver_CreateAcceptSequence()` for accept
   - `QuestGiver_CreateCompleteSequence()` for complete
   - `QuestGiver_CreateFarewellSequence()` for farewell
   - `QuestGiver_HandleSequenceEnd()` for all end callbacks

2. **Focus on content**:
   - Custom greeting sequences (first + normal)
   - Quest-specific dialog lines
   - Custom gating conditions
   - Backstory/info sequences

3. **Avoid duplicating**:
   - Selection gating logic (use existing patterns or wait for generic handler)
   - Sequence-end cleanup (use `HandleSequenceEnd`)
   - Hero resolution (let helpers auto-resolve)
   - Generic accept/farewell scaffolding (use helpers)

4. **Keep configuration clear**:
   - Separate config constants from runtime state
   - Document what external systems need to set (e.g., `SetRangerMissingReq1Complete`)
