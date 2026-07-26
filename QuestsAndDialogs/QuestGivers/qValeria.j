//============================================================================
// qValeria
//============================================================================
// Valeria quest giver conversion from legacy GUI triggers.
//
// Converted GUI trigger group:
// - Valeria quests
//
// Purpose:
// - Provides Valeria's qXXX sublibrary using the shared QuestGiver,
//   QuestMaster, DialogInteraction, and DialogSystem APIs.
// - Keeps Valeria-specific quest/dialog/patrol behavior here while relying on
//   the master systems for quest state, requirements, rewards, dialog flow, and
//   camera transitions.
//
// Notes:
// - Legacy GUI implementation details are intentionally not mechanically ported
//   when master APIs already provide the same gameplay result.
// - Token of Love and Lost Supplies keep their legacy titles, rewards, faction,
//   item requirements, dialog branches, and prerequisite chain.
//============================================================================
library qValeria initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, PatrolSystem, Reputation, HeroItemCheck, VoicelinesValeria, VoicelinesNazgrek

globals
    private constant boolean DEBUG = false

    private constant string QUEST_RANGER_MISSING = "Ranger Missing"
    private constant string QUEST_TOKEN_LOVE = "Token of Love"
    private constant string QUEST_LOST_SUPPLIES = "Lost Supplies"

    private constant integer ITEM_HEART_OCEAN = 'I00Z'
    private constant integer ITEM_SUPPLIES = 'I010'
    private constant integer TOKEN_HEART_REQUIRED = 1
    private constant integer SUPPLIES_REQUIRED = 6
    private constant integer SUPPLIES_SPAWN_COUNT = 8

    private constant real DIALOG_RANGE = 500.00
    private constant real DIALOG_COOLDOWN = 6.00
    private constant real DIALOG_FADE_OUT = 1.00
    private constant real DIALOG_FADE_IN = 1.00
    private constant real QUEST_ITEM_SPAWN_OFFSET = 64.00
    private constant integer CINEMATIC_MOVE_MODE = 1
    private constant real CINEMATIC_MOVE_OFFSET = 256.00
    private constant real CINEMATIC_MOVE_ANGLE = 210.00

    private constant boolean ALLOW_NAZGREK = true
    private constant boolean ALLOW_ZULKIS = false
    private constant boolean USE_DIALOG_CAMERA = true
    private constant boolean CINEMATIC = true
    private constant real CAMERA_DIST = 1050.00
    private constant real CAMERA_Z_OFFSET = 20.00
    private constant real CAMERA_ANGLE = 350.00
    private constant real CAMERA_ROT_OFFSET = 180.00
    private constant real CAMERA_FAR_Z = 10000.00
    private constant real CAMERA_FOV = 60.00
    private constant real CAMERA_BLOCK_RADIUS = 0.00
    private constant boolean CAMERA_BLOCK_CHECK = true

    private unit Valeria = null
    private unit Nazgrek = null
    private unit Aradion = null
    private unit SelectedHero = null

    private dialog ValeriaDialog = null
    private timer ValeriaDialogCooldown = null
    private boolean ValeriaInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qValeria]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Valeria != null and udg_Valeria != Valeria then
        set Valeria = udg_Valeria
    endif
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
    if udg_Aradion != null and udg_Aradion != Aradion then
        set Aradion = udg_Aradion
    endif
endfunction

private function ResolveDialogHero takes nothing returns unit
    local unit hero
    call SyncUnitReferences()
    set hero = DialogInteraction_ResolveDialogHero(SelectedHero, Valeria, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if hero == null and DialogInteraction_IsUnitAlive(Nazgrek) then
        set hero = Nazgrek
    endif
    return hero
endfunction

private function PauseValeriaPatrolInternal takes nothing returns nothing
    call SyncUnitReferences()
    if DialogInteraction_IsUnitAlive(Valeria) then
        call PatrolSystem_Pause(Valeria)
    endif
endfunction

private function ContinueValeriaPatrolInternal takes nothing returns nothing
    call SyncUnitReferences()
    if DialogInteraction_IsUnitAlive(Valeria) then
        call PatrolSystem_Continue(Valeria)
    endif
endfunction

private function StartExitFadeOut takes nothing returns nothing
    call ContinueValeriaPatrolInternal()
    call DialogInteraction_StartConfiguredDialogExitTransition(Valeria, SelectedHero, ValeriaDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
endfunction

private function GetRangerMissingData takes nothing returns QuestData
    call SyncUnitReferences()
    if Aradion == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
endfunction

private function HasRangerMissingReq1 takes nothing returns boolean
    local QuestData q = GetRangerMissingData()
    if q == 0 then
        return false
    endif
    return q.completed or q.req1Completed
endfunction

private function IsRangerMissingInProgress takes nothing returns boolean
    local QuestData q = GetRangerMissingData()
    if q == 0 then
        return false
    endif
    return q.discovered and not q.completed and not q.failed
endfunction

private function CreateQuestItemsAtHero takes integer itemTypeId, integer count returns nothing
    local unit source = null
    local unit hero = null
    local real baseX
    local real baseY
    local integer index = 0
    local real angle
    local item createdItem

    if count <= 0 then
        return
    endif

    set hero = ResolveDialogHero()
    if DialogInteraction_IsUnitAlive(hero) then
        set source = hero
    elseif DialogInteraction_IsUnitAlive(Nazgrek) then
        set source = Nazgrek
    else
        set source = Valeria
    endif
    if source == null then
        set hero = null
        return
    endif

    set baseX = GetUnitX(source)
    set baseY = GetUnitY(source)

    loop
        exitwhen index >= count
        set angle = 6.283185307 * I2R(index) / I2R(count)
        set createdItem = QuestGiver_CreateQuestItem(itemTypeId, 0, baseX + QUEST_ITEM_SPAWN_OFFSET * Cos(angle), baseY + QUEST_ITEM_SPAWN_OFFSET * Sin(angle))
        set index = index + 1
    endloop

    set createdItem = null
    set hero = null
    set source = null
endfunction

private function RefreshQuestAfterAccept takes string questName returns nothing
    local QuestData q = QuestGiver_GetByNameAndGiver(questName, Valeria)
    if q != 0 then
        call QuestGiver_RefreshItemRequirementsForQuest(q.id)
    endif
endfunction

private function CompleteItemQuest takes string questName, integer itemTypeId, integer amount returns nothing
    local QuestData q = QuestGiver_GetByNameAndGiver(questName, Valeria)
    if q == 0 then
        return
    endif

    if HeroItemCheckBothAndRemove(itemTypeId, amount) then
        call QuestGiver_CompleteItemRequirements(q.id)
        call QuestGiver_CompleteQuestByNameAndGiver(questName, Valeria)
        call QuestGiver_RefreshAvailabilityForGiver(Valeria)
    endif
endfunction

private function OnNoDialogGreetEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function PlayRangerMissingUnfinishedSequence takes unit hero returns nothing
    local integer seq = DialogInteraction_CreateGreetSequenceBase(Valeria, "Valeria", hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, true)
    if GetRandomInt(1, 2) == 1 then
        call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0021_TEXT, VL_VALERIA_0021_KEY, true)
    else
        call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0022_TEXT, VL_VALERIA_0022_KEY, true)
    endif
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnNoDialogGreetEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Valeria)
endfunction

private function OnAcceptTokenLoveEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TOKEN_LOVE, Valeria)
    call RefreshQuestAfterAccept(QUEST_TOKEN_LOVE)
    call CreateQuestItemsAtHero(ITEM_HEART_OCEAN, TOKEN_HEART_REQUIRED)
    call StartExitFadeOut()
endfunction

private function OnAcceptTokenLove takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Valeria, "Valeria")

    call DialogSystem_AddMakeFaceEachOther(seq, Valeria, hero, 0.50, 0.0)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0028_TEXT, VL_VALERIA_0028_KEY, true)
    call DialogInteraction_AddHeroLookAtLine(seq, hero, Valeria, VL_NAZGREK_0355_TEXT, VL_NAZGREK_0355_KEY)
    call DialogInteraction_AddHeroLookAtLine(seq, hero, Valeria, VL_NAZGREK_0356_TEXT, VL_NAZGREK_0356_KEY)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0029_TEXT, VL_VALERIA_0029_KEY, true)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0030_TEXT, VL_VALERIA_0030_KEY, true)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0031_TEXT, VL_VALERIA_0031_KEY, true)
    call DialogInteraction_AddHeroLookAtLine(seq, hero, Valeria, VL_NAZGREK_0358_TEXT, VL_NAZGREK_0358_KEY)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptTokenLoveEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Valeria)

    set hero = null
endfunction

private function OnCompleteTokenLoveEnd takes nothing returns nothing
    call CompleteItemQuest(QUEST_TOKEN_LOVE, ITEM_HEART_OCEAN, TOKEN_HEART_REQUIRED)
    call StartExitFadeOut()
endfunction

private function OnCompleteTokenLove takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Valeria, "Valeria")

    call DialogSystem_AddMakeFaceEachOther(seq, Valeria, hero, 0.50, 0.0)
    call DialogInteraction_AddHeroLookAtLine(seq, hero, Valeria, VL_NAZGREK_0361_TEXT, VL_NAZGREK_0361_KEY)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0034_TEXT, VL_VALERIA_0034_KEY, true)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0035_TEXT, VL_VALERIA_0035_KEY, true)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0036_TEXT, VL_VALERIA_0036_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteTokenLoveEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Valeria)

    set hero = null
endfunction

private function OnAcceptLostSuppliesEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_LOST_SUPPLIES, Valeria)
    call RefreshQuestAfterAccept(QUEST_LOST_SUPPLIES)
    call CreateQuestItemsAtHero(ITEM_SUPPLIES, SUPPLIES_SPAWN_COUNT)
    call StartExitFadeOut()
endfunction

private function OnAcceptLostSupplies takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Valeria, "Valeria")

    call DialogSystem_AddMakeFaceEachOther(seq, Valeria, hero, 0.50, 0.0)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0051_TEXT, VL_VALERIA_0051_KEY, true)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0052_TEXT, VL_VALERIA_0052_KEY, true)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0053_TEXT, VL_VALERIA_0053_KEY, true)
    call DialogInteraction_AddHeroLookAtLine(seq, hero, Valeria, VL_NAZGREK_0375_TEXT, VL_NAZGREK_0375_KEY)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptLostSuppliesEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Valeria)

    set hero = null
endfunction

private function OnCompleteLostSuppliesEnd takes nothing returns nothing
    call CompleteItemQuest(QUEST_LOST_SUPPLIES, ITEM_SUPPLIES, SUPPLIES_REQUIRED)
    call StartExitFadeOut()
endfunction

private function OnCompleteLostSupplies takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Valeria, "Valeria")

    call DialogSystem_AddMakeFaceEachOther(seq, Valeria, hero, 0.50, 0.0)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0057_TEXT, VL_VALERIA_0057_KEY, true)
    call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0058_TEXT, VL_VALERIA_0058_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteLostSuppliesEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Valeria)

    set hero = null
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq = DialogInteraction_CreateFarewellSequence(Valeria, "Valeria", hero, DialogInteraction_GetHeroName(hero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)

    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Valeria)

    set hero = null
endfunction

private function RegisterDialogLines takes nothing returns nothing
    call DialogSystem_RegisterFarewellLineForUnit(Valeria, VL_VALERIA_0046_TEXT, VL_VALERIA_0046_KEY, true)
    call DialogSystem_RegisterFarewellLineForUnit(Valeria, VL_VALERIA_0047_TEXT, VL_VALERIA_0047_KEY, true)
    call DialogSystem_RegisterFarewellLineForUnit(Valeria, VL_VALERIA_0048_TEXT, VL_VALERIA_0048_KEY, true)
endfunction

private function BuildDialog takes nothing returns nothing
    local button b

    if ValeriaDialog == null then
        set ValeriaDialog = DialogSystem_CreateDialog("Valeria")
    endif

    call DialogSystem_ClearDialog(ValeriaDialog)
    call DialogSystem_SetTitle(ValeriaDialog, "Valeria")

    call QuestGiver_AddAvailableQuestAcceptButton(ValeriaDialog, QUEST_TOKEN_LOVE, Valeria, 1, function OnAcceptTokenLove, true, false)
    call QuestGiver_AddReadyQuestCompleteButton(ValeriaDialog, QUEST_TOKEN_LOVE, Valeria, 2, function OnCompleteTokenLove, true)
    call QuestGiver_AddAvailableQuestAcceptButton(ValeriaDialog, QUEST_LOST_SUPPLIES, Valeria, 3, function OnAcceptLostSupplies, true, false)
    call QuestGiver_AddReadyQuestCompleteButton(ValeriaDialog, QUEST_LOST_SUPPLIES, Valeria, 4, function OnCompleteLostSupplies, true)
    set b = DialogSystem_AddFarewellButton(ValeriaDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
endfunction

private function AddPreDialogBark takes integer seq returns nothing
    if QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TOKEN_LOVE, Valeria) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_TOKEN_LOVE, Valeria) then
        if GetRandomInt(1, 2) == 1 then
            call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0032_TEXT, VL_VALERIA_0032_KEY, true)
        else
            call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0033_TEXT, VL_VALERIA_0033_KEY, true)
        endif
    elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_LOST_SUPPLIES, Valeria) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_LOST_SUPPLIES, Valeria) then
        if GetRandomInt(1, 2) == 1 then
            call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0054_TEXT, VL_VALERIA_0054_KEY, true)
        else
            call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0055_TEXT, VL_VALERIA_0055_KEY, true)
        endif
    else
        if GetRandomInt(1, 4) == 1 then
            call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0038_TEXT, VL_VALERIA_0038_KEY, true)
        elseif GetRandomInt(1, 3) == 1 then
            call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0039_TEXT, VL_VALERIA_0039_KEY, true)
        elseif GetRandomInt(1, 2) == 1 then
            call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0040_TEXT, VL_VALERIA_0040_KEY, true)
        else
            call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0041_TEXT, VL_VALERIA_0041_KEY, true)
        endif
    endif
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq = DialogInteraction_CreateGreetSequenceBase(Valeria, "Valeria", hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, true)
    call AddPreDialogBark(seq)
    call DialogInteraction_PlayGreetSequenceEx(seq, Valeria, Player(0), ValeriaDialog, CINEMATIC)
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero

    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Valeria) or not HasRangerMissingReq1() then
        call StartExitFadeOut()
        return
    endif

    set hero = ResolveDialogHero()
    if hero == null then
        call StartExitFadeOut()
        return
    endif

    if IsRangerMissingInProgress() then
        call PlayRangerMissingUnfinishedSequence(hero)
    else
        call QuestGiver_RefreshAvailabilityForGiver(Valeria)
        call BuildDialog()
        call PlayDialogGreeting(hero)
    endif

    set hero = null
endfunction

public function ContinueToDialogAfterSelection takes nothing returns nothing
    call ContinueToDialogInternal()
endfunction

private function OnSelected takes nothing returns nothing
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Valeria) or not HasRangerMissingReq1() then
        return
    endif

    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Valeria, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Valeria, SelectedHero, DIALOG_RANGE, ValeriaDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif

    call PauseValeriaPatrolInternal()
    call DialogInteraction_StartConfiguredDialogEntryTransition(Valeria, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qValeria_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string giverName = DialogInteraction_GetUnitDisplayName(Valeria)
    local string infoText = "|cff99ff99Quest Giver:|r " + giverName
    local string info2Text = "|cff99ff99Location:|r Ruins of Elarindor"

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_TOKEN_LOVE, Valeria) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_TOKEN_LOVE, Valeria, "normal", 18, null, "Token of Love", "ReplaceableTextures\\CommandButtons\\BTNINV_Jewelry_Necklace_11.TGA", "Find Valeria's missing necklace somewhere around the ruins of Elarindor.\n\n", infoText, info2Text, 18, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
        call QuestGiver_SetQuestRequiredReputation(q, Reputation_REP_ENEMY)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, true, 200, false)
        call QuestGiver_AddQuestPrerequisite(q, QUEST_RANGER_MISSING, Aradion)
        call QuestGiver_SetRequirements(q.id, "", "Find Valeria's missing necklace", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Valeria, 1, ITEM_HEART_OCEAN, TOKEN_HEART_REQUIRED)
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_LOST_SUPPLIES, Valeria) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_LOST_SUPPLIES, Valeria, "normal", 18, null, "Lost Supplies", "ReplaceableTextures\\CommandButtons\\BTNINV_Crate_03.TGA", "Find supplies found around the ruins of Elarindor.\n\n", infoText, info2Text, 18, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
        call QuestGiver_SetQuestRequiredReputation(q, Reputation_REP_ENEMY)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, true, 200, false)
        call QuestGiver_AddQuestPrerequisite(q, QUEST_TOKEN_LOVE, Valeria)
        call QuestGiver_SetRequirements(q.id, "", "Find lost supplies", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Valeria, 1, ITEM_SUPPLIES, SUPPLIES_REQUIRED)
    endif

    set q = 0
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()

    if Valeria == null or Nazgrek == null or Aradion == null then
        if not ValeriaInitWaitingLogged then
            call DebugMsg("Waiting for Valeria, Nazgrek, and Aradion unit references.")
            set ValeriaInitWaitingLogged = true
        endif
        call TimerStart(GetExpiredTimer(), 0.50, false, function InitDelayed)
        return
    endif

    call QuestGiver_Register(Valeria)
    call DialogInteraction_ConfigureDialogTransition(Valeria, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call RegisterDialogLines()
    call CreateQuests()
    call QuestGiver_RefreshAvailabilityForGiver(Valeria)
    call DialogInteraction_RegisterSelectionHandler(Valeria, function OnSelected)
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set ValeriaDialogCooldown = CreateTimer()
    call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if Valeria != null then
        call QuestGiver_RefreshAvailabilityForGiver(Valeria)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Valeria != null then
        call QuestGiver_Register(Valeria)
        call DialogInteraction_ConfigureDialogTransition(Valeria, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Valeria, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

endlibrary
