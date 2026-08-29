/**
    qChieftainThork

    Author: Valdemar
    Version: 1.1.1

    Description:
    Handles Ragno's Call of the Horde handoff and Chieftain Thork's Duty For
    The Horde proof quest. Granis and Garthork report their proof tasks
    independently, and completed QuestData is also queried for recovery.

    Credits:
    Converted from the original ChieftainThork GUI triggers.

    How to install:
    Import after qRagno, qZulkis, and the required quest, dialog, inventory,
    equipment, item-check, and voiceline libraries.

    API:
    Public Duty For The Horde and respawn hooks are declared at the end.

**/
library qChieftainThork initializer Init requires qRagno, qZulkis, QuestGiver, QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck, DInventory, DEquipment, VoicelinesThork, VoicelinesNazgrek, VoicelinesZulkis

globals
    private constant boolean DEBUG = false

    private constant string QUEST_GIVING_LETTER = "Call of the Horde"
    private constant string QUEST_DUTY_FOR_HORDE = "Duty For The Horde"
    private constant string QUEST_GRANIS_PROOF = "Punish"
    private constant string QUEST_GARTHORK_PROOF = "The Magical Eye"
    private constant string THORK_NAME = "Chieftain Thork"

    private constant integer ITEM_BLOOD_SIGNED_LETTER = 'I625'
    private constant integer ITEM_LESSER_CLARITY = 'plcl'
    private constant integer ITEM_HEALING_WARDS = 'whwd'

    private constant real DIALOG_RANGE = 500.00
    private constant real DIALOG_COOLDOWN = 6.00
    private constant real DIALOG_FADE_OUT = 1.00
    private constant real DIALOG_FADE_IN = 1.00
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
    private constant real POST_CALL_OF_HORDE_DIALOG_DELAY = 3.00

    private unit Thork = null
    private unit Ragno = null
    private unit Nazgrek = null
    private unit Zulkis = null
    private unit Granis = null
    private unit Garthork = null
    private unit Drekthor = null
    private unit SelectedHero = null

    private dialog ThorkDialog = null
    private timer ThorkDialogCooldown = null
    private timer PostCallOfHordeDialogTimer = null
    private boolean DutyForHordeUnlocked = false
    private boolean GranisProofComplete = false
    private boolean GarthorkProofComplete = false
    private boolean ThorkInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qChieftainThork]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Thork != null and udg_Thork != Thork then
        set Thork = udg_Thork
    endif
    if udg_Ragno != null and udg_Ragno != Ragno then
        set Ragno = udg_Ragno
    endif
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
    if udg_Zulkis != null and udg_Zulkis != Zulkis then
        set Zulkis = udg_Zulkis
    endif
    if udg_Granis != null and udg_Granis != Granis then
        set Granis = udg_Granis
    endif
    if udg_Garthork != null and udg_Garthork != Garthork then
        set Garthork = udg_Garthork
    endif
    if udg_Drekthor != null and udg_Drekthor != Drekthor then
        set Drekthor = udg_Drekthor
    endif
endfunction

private function ResolveDialogHero takes nothing returns unit
    local unit hero
    call SyncUnitReferences()
    set hero = DialogInteraction_ResolveDialogHero(SelectedHero, Thork, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if hero == null and DialogInteraction_IsUnitAlive(Nazgrek) then
        set hero = Nazgrek
    endif
    return hero
endfunction

private function StartExitFadeOut takes nothing returns nothing
    call DialogInteraction_StartConfiguredDialogExitTransition(Thork, SelectedHero, ThorkDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
endfunction

private function GetGivingLetterQuest takes nothing returns QuestData
    call SyncUnitReferences()
    if Ragno == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(QUEST_GIVING_LETTER, Ragno)
endfunction

private function GetDutyForHordeQuest takes nothing returns QuestData
    call SyncUnitReferences()
    if Thork == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(QUEST_DUTY_FOR_HORDE, Thork)
endfunction

private function IsGivingLetterActive takes nothing returns boolean
    local QuestData q = GetGivingLetterQuest()
    local boolean result = false
    if q != 0 then
        set result = q.discovered and not q.completed and not q.failed
    endif
    set q = 0
    return result
endfunction

private function IsDutyForHordeRelevant takes nothing returns boolean
    local QuestData q = GetDutyForHordeQuest()
    local boolean result = false
    if q != 0 then
        set result = q.discovered and not q.completed and not q.failed
    endif
    set q = 0
    return result
endfunction

private function CanOfferDutyForHorde takes nothing returns boolean
    return DutyForHordeUnlocked
endfunction

private function RefreshDutyForHordeProofs takes nothing returns nothing
    local QuestData q = GetDutyForHordeQuest()

    if Granis != null and QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_GRANIS_PROOF, Granis) then
        set GranisProofComplete = true
    endif
    if Garthork != null and QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_GARTHORK_PROOF, Garthork) then
        set GarthorkProofComplete = true
    endif

    if q != 0 and q.active and not q.completed and not q.failed then
        call q.markRequirementCompleted(1, GranisProofComplete)
        call q.markRequirementCompleted(2, GarthorkProofComplete)
        if GranisProofComplete and GarthorkProofComplete then
            call q.addReturnRequirement()
            call q.setState(QUEST_STATE_READY_TURNIN)
        elseif q.state == QUEST_STATE_READY_TURNIN then
            call q.removeReturnRequirement()
            call q.setState(QUEST_STATE_IN_PROGRESS)
        endif
    endif

    set q = 0
endfunction

private function RefreshThorkAvailabilityInternal takes nothing returns nothing
    local QuestData q = GetGivingLetterQuest()

    call RefreshDutyForHordeProofs()
    if Thork != null then
        call QuestGiver_RefreshAvailabilityForGiver(Thork)
    endif
    if q != 0 and q.active and not q.completed and not q.failed then
        if qZulkis_IsPrologueCompleted() and HeroItemCheckBoth(ITEM_BLOOD_SIGNED_LETTER, 1) then
            if q.state != QUEST_STATE_READY_TURNIN then
                call q.setState(QUEST_STATE_READY_TURNIN)
            endif
        elseif q.state == QUEST_STATE_READY_TURNIN then
            call q.setState(QUEST_STATE_IN_PROGRESS)
        endif
    endif

    set q = 0
endfunction

private function UnlockDutyForHorde takes nothing returns nothing
    local QuestData q = GetDutyForHordeQuest()

    set DutyForHordeUnlocked = true
    call RefreshThorkAvailabilityInternal()
    if q != 0 and not q.discovered and not q.completed then
        call QuestGiver_AcceptQuestByNameAndGiver(QUEST_DUTY_FOR_HORDE, Thork)
    endif

    set q = 0
endfunction

private function EnableZulkisCompanion takes nothing returns nothing
    local item it

    if Zulkis == null then
        set it = null
        return
    endif

    call SetUnitOwner(Zulkis, Player(0), true)
    call SetUnitInvulnerable(Zulkis, false)
    call PauseUnit(Zulkis, false)
    call ShowUnit(Zulkis, true)
    call InitializeDInventoryForUnit(Zulkis)
    call InitializeDEquipmentForUnit(Zulkis)
    call QuestMaster_RefreshUnitSpecificQuests()

    set it = UnitAddItemById(Zulkis, ITEM_LESSER_CLARITY)
    set it = UnitAddItemById(Zulkis, ITEM_HEALING_WARDS)
    set it = UnitAddItemById(Zulkis, ITEM_LESSER_CLARITY)
    set it = null
endfunction

private function CompleteGivingLetterQuest takes nothing returns boolean
    local QuestData q = GetGivingLetterQuest()

    if q == 0 or not qZulkis_IsPrologueCompleted() then
        return false
    endif
    if not HeroItemCheckBothAndRemove(ITEM_BLOOD_SIGNED_LETTER, 1) then
        set q = 0
        return false
    endif

    call q.markRequirementCompleted(1, true)
    call QuestGiver_CompleteQuestByNameAndGiver(QUEST_GIVING_LETTER, Ragno)
    call EnableZulkisCompanion()
    call UnlockDutyForHorde()
    call qRagno_RefreshAvailability()
    call RefreshThorkAvailabilityInternal()

    set q = 0
    return true
endfunction

private function OnPostCallOfHordeDialogEnd takes nothing returns nothing
    call DialogSystem_ReleaseInteractions()
endfunction

private function PlayPostCallOfHordeDialog takes nothing returns nothing
    local integer seq

    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Zulkis) or not DialogInteraction_IsUnitAlive(Nazgrek) then
        call DialogSystem_ReleaseInteractions()
        return
    endif

    set seq = DialogInteraction_CreateBaseSequence(Zulkis, "Zul'kis")
    call DialogSystem_AddMakeFaceEachOther(seq, Zulkis, Nazgrek, 0.50, 0.00)
    call DialogSystem_AddLine(seq, Zulkis, "Zul'kis", VL_ZULKIS_0003_TEXT, VL_ZULKIS_0003_KEY, true)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0065_TEXT, VL_NAZGREK_0065_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnPostCallOfHordeDialogEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Zulkis)
endfunction

private function OnGivingLetterMeetingEnd takes nothing returns nothing
    if CompleteGivingLetterQuest() then
        call DialogSystem_ReserveInteractions(0.00)
        call TimerStart(PostCallOfHordeDialogTimer, POST_CALL_OF_HORDE_DIALOG_DELAY, false, function PlayPostCallOfHordeDialog)
    endif
    call StartExitFadeOut()
endfunction

private function OnGiveLetter takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Thork, THORK_NAME)
    call DialogSystem_AddMakeFaceEachOther(seq, Thork, hero, 0.50, 0.00)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0005_TEXT, VL_NAZGREK_0005_KEY, true)
    call DialogSystem_AddLine(seq, Thork, THORK_NAME, VL_THORK_0002_TEXT, VL_THORK_0002_KEY, true)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0006_TEXT, VL_NAZGREK_0006_KEY, true)
    call DialogSystem_AddLine(seq, Thork, THORK_NAME, VL_THORK_0006_TEXT, VL_THORK_0006_KEY, true)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0069_TEXT, VL_NAZGREK_0069_KEY, true)
    call DialogSystem_AddLine(seq, Thork, THORK_NAME, VL_THORK_0008_TEXT, VL_THORK_0008_KEY, true)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0064_TEXT, VL_NAZGREK_0064_KEY, true)
    if Zulkis != null then
        call DialogSystem_AddLookAtUnit(seq, Thork, Zulkis, 0.50)
    endif
    call DialogSystem_AddLine(seq, Thork, THORK_NAME, VL_THORK_0003_TEXT, VL_THORK_0003_KEY, true)
    if Zulkis != null then
        call DialogSystem_AddLine(seq, Zulkis, "Zul'kis", VL_ZULKIS_0001_TEXT, VL_ZULKIS_0001_KEY, true)
    endif
    call DialogSystem_AddLookAtUnit(seq, Thork, Nazgrek, 0.50)
    call DialogSystem_AddLine(seq, Thork, THORK_NAME, VL_THORK_0004_TEXT, VL_THORK_0004_KEY, true)
    if Zulkis != null then
        call DialogSystem_AddLookAtUnit(seq, Nazgrek, Zulkis, 0.50)
        call DialogSystem_AddLine(seq, Zulkis, "Zul'kis", VL_ZULKIS_0002_TEXT, VL_ZULKIS_0002_KEY, true)
    endif
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0066_TEXT, VL_NAZGREK_0066_KEY, true)
    call DialogSystem_AddLine(seq, Thork, THORK_NAME, VL_THORK_0005_TEXT, VL_THORK_0005_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnGivingLetterMeetingEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Thork)

    set hero = null
endfunction

private function OnMissingLetterEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnMissingLetter takes nothing returns nothing
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Thork, THORK_NAME)
    call DialogSystem_AddLine(seq, Thork, THORK_NAME, VL_THORK_0011_TEXT, VL_THORK_0011_KEY, true)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0025_TEXT, VL_NAZGREK_0025_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnMissingLetterEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Thork)
endfunction

private function OnCompleteDutyForHordeEnd takes nothing returns nothing
    local QuestData q = GetDutyForHordeQuest()
    if q != 0 and q.active and not q.completed then
        call q.markRequirementCompleted(1, true)
        call q.markRequirementCompleted(2, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_DUTY_FOR_HORDE, Thork)
        call RefreshThorkAvailabilityInternal()
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteDutyForHorde takes nothing returns nothing
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Thork, THORK_NAME)
    call DialogSystem_AddLine(seq, Thork, THORK_NAME, "Granis and Garthork have both spoken of your deeds. The Horde has more work for you.", VL_THORK_0001_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteDutyForHordeEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Thork)
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateFarewellSequence(Thork, THORK_NAME, hero, DialogInteraction_GetHeroName(hero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Thork)

    set hero = null
endfunction

private function BuildDialog takes nothing returns nothing
    local QuestData letterQuest
    local QuestData dutyQuest
    local button b

    if ThorkDialog == null then
        set ThorkDialog = DialogSystem_CreateDialog(THORK_NAME)
    endif

    call RefreshThorkAvailabilityInternal()
    set letterQuest = GetGivingLetterQuest()
    set dutyQuest = GetDutyForHordeQuest()

    call DialogSystem_ClearDialog(ThorkDialog)
    call DialogSystem_SetTitle(ThorkDialog, THORK_NAME)

    if qZulkis_IsPrologueCompleted() and letterQuest != 0 and letterQuest.discovered and not letterQuest.completed and not letterQuest.failed then
        if not QuestGiver_AddReadyQuestCompleteButton(ThorkDialog, QUEST_GIVING_LETTER, Ragno, 1, function OnGiveLetter, true) then
            set b = DialogSystem_AddButton(ThorkDialog, "Speak to " + THORK_NAME, 2)
            call DialogSystem_BindButtonCode(b, function OnMissingLetter)
            set b = null
        endif
    endif

    if dutyQuest != 0 and dutyQuest.discovered and not dutyQuest.completed and dutyQuest.state == QUEST_STATE_READY_TURNIN then
        set b = DialogSystem_AddButtonQuestComplete(ThorkDialog, QUEST_DUTY_FOR_HORDE, 3)
        call DialogSystem_BindButtonCode(b, function OnCompleteDutyForHorde)
        set b = null
    endif

    set b = DialogSystem_AddFarewellButton(ThorkDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
    set letterQuest = 0
    set dutyQuest = 0
endfunction

private function AddPreDialogBark takes integer seq returns nothing
    if IsGivingLetterActive() then
        call DialogSystem_AddLine(seq, Thork, THORK_NAME, VL_THORK_0010_TEXT, VL_THORK_0010_KEY, true)
    elseif IsDutyForHordeRelevant() then
        call DialogSystem_AddLine(seq, Thork, THORK_NAME, VL_THORK_0001_TEXT, VL_THORK_0001_KEY, true)
    else
        call DialogSystem_AddLine(seq, Thork, THORK_NAME, VL_THORK_0012_TEXT, VL_THORK_0012_KEY, true)
    endif
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq = DialogInteraction_CreateGreetSequenceBase(Thork, THORK_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, false)
    call AddPreDialogBark(seq)
    call DialogInteraction_PlayGreetSequenceEx(seq, Thork, Player(0), ThorkDialog, CINEMATIC)
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero

    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Thork) then
        call StartExitFadeOut()
        return
    endif

    set hero = ResolveDialogHero()
    if hero == null then
        call StartExitFadeOut()
        return
    endif

    call BuildDialog()
    call PlayDialogGreeting(hero)

    set hero = null
endfunction

public function ContinueToDialogAfterSelection takes nothing returns nothing
    call ContinueToDialogInternal()
endfunction

private function HasAnyThorkDialogContent takes nothing returns boolean
    return IsGivingLetterActive() or IsDutyForHordeRelevant()
endfunction

private function OnSelected takes nothing returns nothing
    call SyncUnitReferences()
    if qZulkis_IsPrologueActive() then
        call DialogInteraction_ConsumeSelection()
        call qZulkis_HandleThorkSelection()
        return
    endif
    if not DialogInteraction_IsUnitAlive(Thork) or not HasAnyThorkDialogContent() then
        return
    endif

    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Thork, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Thork, SelectedHero, DIALOG_RANGE, ThorkDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif

    call DialogInteraction_StartConfiguredDialogEntryTransition(Thork, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qChieftainThork_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string infoText = "|cffffcc00Quest giver:|r " + THORK_NAME + "\n"
    local trigger availabilityCondition

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_DUTY_FOR_HORDE, Thork) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_DUTY_FOR_HORDE, Thork, "normal", 3, null, QUEST_DUTY_FOR_HORDE, "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp", "Chieftain Thork wants Nazgrek to prove his value to the Horde by aiding Granis and Garthork.\n\n", infoText, "|cffffcc00Recommended level:|r 8\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", THORK_NAME)
        call QuestGiver_SetQuestRewards(q, false, 0, false, 0, false, 0, false, 0, false)
        set availabilityCondition = CreateTrigger()
        call TriggerAddCondition(availabilityCondition, Condition(function CanOfferDutyForHorde))
        call QuestGiver_SetQuestCustomCondition(q, availabilityCondition)
        call QuestGiver_SetRequirements(q.id, "", "Complete Granis' Punish quest", "Complete Garthork's The Magical Eye quest", "", "", "", "", "", "")
        call QuestGiver_SetStateByNameAndGiver(QUEST_DUTY_FOR_HORDE, Thork, QUEST_STATE_UNAVAILABLE)
    endif

    set availabilityCondition = null
    set q = 0
endfunction

private function RegisterDialogLines takes nothing returns nothing
    call DialogSystem_RegisterFarewellLineForUnit(Thork, "Go. The Horde is not kept waiting.", VL_THORK_0005_KEY, true)
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()

    if Thork == null or Ragno == null or Nazgrek == null or Zulkis == null or not QuestGiver_QuestExistsByNameAndGiver(QUEST_GIVING_LETTER, Ragno) then
        if not ThorkInitWaitingLogged then
            call DebugMsg("Waiting for Chieftain Thork, Ragno, Nazgrek, Zulkis, and Ragno's letter quest.")
            set ThorkInitWaitingLogged = true
        endif
        call TimerStart(GetExpiredTimer(), 0.50, false, function InitDelayed)
        return
    endif

    call QuestGiver_Register(Thork)
    call DialogInteraction_ConfigureDialogTransition(Thork, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call RegisterDialogLines()
    call CreateQuests()
    call RefreshThorkAvailabilityInternal()
    call DialogInteraction_RegisterSelectionHandler(Thork, function OnSelected)
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set ThorkDialogCooldown = CreateTimer()
    set PostCallOfHordeDialogTimer = CreateTimer()
    call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    call RefreshThorkAvailabilityInternal()
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Thork != null then
        call QuestGiver_Register(Thork)
        call DialogInteraction_ConfigureDialogTransition(Thork, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Thork, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

public function DiscoverDutyForHorde takes nothing returns nothing
    call UnlockDutyForHorde()
endfunction

public function MarkDutyForHordeReady takes nothing returns nothing
    local QuestData q = GetDutyForHordeQuest()
    if q != 0 and q.active and not q.completed and not q.failed then
        call q.markRequirementCompleted(1, true)
        call q.markRequirementCompleted(2, true)
        set GranisProofComplete = true
        set GarthorkProofComplete = true
        call q.setState(QUEST_STATE_READY_TURNIN)
        call q.addReturnRequirement()
        call RefreshThorkAvailabilityInternal()
    endif
    set q = 0
endfunction

public function CompleteDutyForHorde takes nothing returns nothing
    local QuestData q = GetDutyForHordeQuest()
    if q != 0 and not q.completed then
        call q.markRequirementCompleted(1, true)
        call q.markRequirementCompleted(2, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_DUTY_FOR_HORDE, Thork)
        call RefreshThorkAvailabilityInternal()
    endif
    set q = 0
endfunction

public function ReportGranisTaskComplete takes nothing returns nothing
    set GranisProofComplete = true
    call RefreshThorkAvailabilityInternal()
endfunction

public function ReportGarthorkTaskComplete takes nothing returns nothing
    set GarthorkProofComplete = true
    call RefreshThorkAvailabilityInternal()
endfunction

endlibrary
