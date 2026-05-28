# QuestGiver Helper Functions - Quick Reference
## New Generic Functions for Creating Quest Giver SubLibraries

---

## Sequence-End Handler

```jass
QuestGiver_HandleSequenceEnd(unit giver, timer cooldownTimer, real cooldownDuration, 
                              boolean stopCamera, real cameraStopDuration, 
                              boolean useCamera, boolean reopenDialog)
```

**Use for**: All `OnAcceptQuestXEnd`, `OnCompleteQuestXEnd`, `OnFailQuestX`, `OnFarewellEnd` callbacks

**Example**:
```jass
private function OnAcceptQuest1End takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_NAME, MyGiver)
    call QuestGiver_HandleSequenceEnd(MyGiver, MyDialogCooldown, DIALOG_COOLDOWN, 
                                       true, 2.00, USE_DIALOG_CAMERA, false)
endfunction
```

**Parameters**:
- `giver` - The quest giver unit
- `cooldownTimer` - Timer for dialog cooldown (can be null)
- `cooldownDuration` - Cooldown duration in seconds
- `stopCamera` - Whether to stop the dialog camera
- `cameraStopDuration` - Camera transition duration
- `useCamera` - Whether dialog camera is enabled
- `reopenDialog` - Reserved for future (pass false)

---

## Accept Sequence Builder

```jass
integer QuestGiver_CreateAcceptSequence(unit giver, string giverName, 
                                        unit hero, string heroName, 
                                        real dialogRange, boolean allowNazgrek, 
                                        boolean allowZulkis)
```

**Use for**: `OnAcceptQuestX` functions

**Example**:
```jass
private function OnAcceptQuest1 takes nothing returns nothing
    local integer seq
    
    // Create skeleton with hero accept + NPC response
    set seq = QuestGiver_CreateAcceptSequence(MyGiver, "My Giver Name", 
                                                null, "", DIALOG_RANGE, 
                                                ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest1End)
    
    // Add quest-specific lines
    call DialogSystem_AddLine(seq, MyGiver, "My Giver Name", "Quest-specific text...", "Sound_0001", true)
    call DialogSystem_AddLine(seq, MyGiver, "My Giver Name", "More text...", "Sound_0002", true)
    
    call DialogSystem_PlaySequence(seq, Player(0), MyGiver)
endfunction
```

**Parameters**:
- `giver` - The quest giver unit
- `giverName` - Display name for the quest giver
- `hero` - Hero unit (pass null to auto-resolve)
- `heroName` - Hero name (pass "" if hero is null)
- `dialogRange` - Range to search for hero
- `allowNazgrek` - Whether Nazgrek can accept
- `allowZulkis` - Whether Zulkis can accept

**Returns**: Sequence ID with hero accept line + NPC response already added

---

## Complete Sequence Builder

```jass
integer QuestGiver_CreateCompleteSequence(unit giver, string giverName)
```

**Use for**: `OnCompleteQuestX` functions

**Example**:
```jass
private function OnCompleteQuest1 takes nothing returns nothing
    local integer seq
    
    // Create skeleton
    set seq = QuestGiver_CreateCompleteSequence(MyGiver, "My Giver Name")
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest1End)
    
    // Add completion dialog
    call DialogSystem_AddLine(seq, MyGiver, "My Giver Name", "Thank you!", "Sound_0010", true)
    
    call DialogSystem_PlaySequence(seq, Player(0), MyGiver)
endfunction
```

**Parameters**:
- `giver` - The quest giver unit
- `giverName` - Display name for the quest giver

**Returns**: Empty sequence with default speaker set

---

## Farewell Sequence Builder

```jass
integer QuestGiver_CreateFarewellSequence(unit giver, string giverName, 
                                          unit hero, string heroName, 
                                          real dialogRange, boolean allowNazgrek, 
                                          boolean allowZulkis)
```

**Use for**: `OnFarewell` functions

**Example**:
```jass
private function OnFarewell takes nothing returns nothing
    local integer seq
    
    // Create complete farewell sequence
    set seq = QuestGiver_CreateFarewellSequence(MyGiver, "My Giver Name", 
                                                  null, "", DIALOG_RANGE, 
                                                  ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), MyGiver)
endfunction
```

**Parameters**:
- `giver` - The quest giver unit
- `giverName` - Display name for the quest giver
- `hero` - Hero unit (pass null to auto-resolve)
- `heroName` - Hero name (pass "" if hero is null)
- `dialogRange` - Range to search for hero
- `allowNazgrek` - Whether Nazgrek can interact
- `allowZulkis` - Whether Zulkis can interact

**Returns**: Complete farewell sequence (hero goodbye + NPC response)

---

## Before/After Comparison

### Before (Old Pattern)

```jass
// Accept Quest End Handler - OLD
private function OnAcceptQuest1End takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
    call QuestGiver_CloseActiveDialog()
    set AradionDialogCooldown = QuestGiver_StartCooldown(AradionDialogCooldown, DIALOG_COOLDOWN)
    call DialogSystem_StopDialogCamera(Player(0), 2.00, USE_DIALOG_CAMERA)
endfunction

// Accept Quest - OLD
private function OnAcceptQuest1 takes nothing returns nothing
    local integer seq
    local unit hero
    local string heroName
    set seq = DialogSystem_CreateSequence()
    call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest1End)
    
    set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    set heroName = QuestGiver_GetHeroName(hero)
    if hero != null then
        call DialogSystem_PickAcceptLine(hero, heroName)
        call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
    endif
    
    call DialogSystem_PickAcceptLine(Aradion, "Aradion the Farseer")
    call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
    
    call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Quest text...", "Aradion_0035", true)
    call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction
```

### After (New Pattern)

```jass
// Accept Quest End Handler - NEW
private function OnAcceptQuest1End takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
    call QuestGiver_HandleSequenceEnd(Aradion, AradionDialogCooldown, DIALOG_COOLDOWN, true, 2.00, USE_DIALOG_CAMERA, false)
endfunction

// Accept Quest - NEW
private function OnAcceptQuest1 takes nothing returns nothing
    local integer seq
    set seq = QuestGiver_CreateAcceptSequence(Aradion, "Aradion the Farseer", null, "", DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest1End)
    
    call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Quest text...", "Aradion_0035", true)
    call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction
```

**Result**: 25 lines → 10 lines (60% reduction)

---

## Tips

1. **Always pass `null, ""` for hero/heroName** to let the helper auto-resolve
2. **Use the same callback pattern** - set callbacks, add custom lines, play sequence
3. **Don't forget `HandleSequenceEnd`** in all end callbacks
4. **Keep quest-specific logic separate** - helpers provide structure, you provide content
