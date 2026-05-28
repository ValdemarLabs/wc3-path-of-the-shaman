# Future Refactoring Suggestions for qAradion

The two remaining todos are more complex refactoring opportunities that would further reduce boilerplate:

## 1. Add generic dialog builder with rule system

**Current state**: Each quest giver has a `BuildDialog()` function with repetitive state-checking logic like this from qAradion:

```jass
if QuestGiver_QuestExistsByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
    if AradionBackstorySeen and not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion) == QUEST_STATE_AVAILABLE then
        set b = DialogSystem_AddButtonQuestAcceptNoAutoPlay(AradionDialog, QUEST_RANGER_MISSING, 2)
        call DialogSystem_BindButtonCode(b, function OnAcceptQuest1)
    elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and QuestGiver_IsQuestFailedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
        set b = DialogSystem_AddButtonQuestFailed(AradionDialog, QUEST_RANGER_MISSING, 3)
        call DialogSystem_BindButtonCode(b, function OnFailQuest1)
    elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
        if RangerMissingReq1Complete and QuestGiver_IsUnitAlive(Valeria) and QuestGiver_IsWithinRange(Aradion, Valeria, VALERIA_RANGE) then
            set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_RANGER_MISSING, 4)
            call DialogSystem_BindButtonCode(b, function OnCompleteQuest1)
        endif
    endif
endif
```

**Goal**: Create a rule-based system where qAradion only provides quest button rules:

```jass
// Quest 1 rules
local QuestButtonRule rule
set rule = QuestGiver_CreateQuestRule(QUEST_RANGER_MISSING)
rule.acceptCondition = function CheckAcceptQuest1  // Custom gating
rule.completeCondition = function CheckCompleteQuest1  // Custom gating
rule.onAccept = function OnAcceptQuest1
rule.onComplete = function OnCompleteQuest1
call QuestGiver_AddQuestRule(rules, rule)

// Then just:
call QuestGiver_BuildDialogFromRules(dialog, rules)
```

This would make quest button logic declarative instead of imperative.

---

## 2. Add generic selection handler with callbacks

**Current state**: Each quest giver has an `OnSelected()` function that duplicates this pattern:

```jass
private function OnSelected takes nothing returns nothing
    local unit hero
    local boolean gateOk
    // ... debug vars ...
    
    if DialogSystem_IsSequenceActive() then
        call DebugMsg("Select gate blocked: dialog sequence active")
        return
    endif
    set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if REQUIRE_DIALOG_HERO and hero == null then
        call DebugMsg("Select gate blocked: missing allowed hero in range")
        return
    endif
    set gateOk = QuestGiver_PassSelectionGate(Aradion, hero, DIALOG_RANGE, AradionDialogCooldown)
    if not gateOk then
        // ... debug logging ...
        return
    endif
    if not QuestGiver_IsFirstGreetDone(Aradion) then
        if AradionDialog == null then
            call DebugMsg("Creating Aradion dialog")
            set AradionDialog = DialogSystem_CreateDialog("Aradion the Farseer")
            call BuildDialog()
        endif
        call DebugMsg("Playing first greet sequence")
        call DialogSystem_StartDialogCamera(Player(0), Aradion, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK, USE_DIALOG_CAMERA)
        call PlayGreetFirstSequence()
        return
    endif
    call ShowDialog(Player(0))
endfunction
```

**Goal**: Create a callback-based system where qAradion only provides the content-specific parts:

```jass
// Config struct
local QuestGiverConfig cfg
set cfg = QuestGiver_CreateConfig(Aradion, "Aradion the Farseer")
cfg.dialogRange = DIALOG_RANGE
cfg.cooldownTimer = AradionDialogCooldown
cfg.cooldownDuration = DIALOG_COOLDOWN
cfg.allowNazgrek = ALLOW_NAZGREK
cfg.allowZulkis = ALLOW_ZULKIS
cfg.cameraConfig = ... // camera settings
cfg.onFirstGreet = function PlayGreetFirstSequence
cfg.onGreet = function PlayGreetNormalSequence
cfg.onBuildDialog = function BuildDialog

// Then just:
call QuestGiver_RegisterWithConfig(cfg)
// No need to write OnSelected at all!
```

This would eliminate the entire `OnSelected` function and `ShowDialog` function from quest giver sublibraries.

---

## Why weren't these done yet?

These are more complex because they require:
1. Designing struct/data structures (JASS doesn't have great struct support)
2. Handling function references (JASS has limitations with function pointers)
3. Ensuring backward compatibility
4. More extensive testing across multiple quest givers

They'd be great next steps once you have 2-3 more quest givers to validate the pattern against!
