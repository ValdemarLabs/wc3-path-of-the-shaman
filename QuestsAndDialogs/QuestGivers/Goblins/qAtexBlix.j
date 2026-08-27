/**
    qAtexBlix

    Author: Valdemar
    Version: 1.0.0

    Description:
    Converts Atex Blix's recovered inspection dialogue and receiver-side
    objectives for the Boom Brothers quest chain.

    Credits:
    - QuestsAndDialogs/OLDGUI/AtexBlix
    - QuestsAndDialogs/OLDGUI/BoomBrothers

    How to install:
    Import after qBoomBrothers and the quest/dialog systems. Keep the placed
    Atex Blix global and disable the recovered Atex Blix GUI folder.

    API:
    - qAtexBlix_GetApprovedLogCount()
    - qAtexBlix_SyncDustProgress()
    - qAtexBlix_RefreshAvailability()
    - qAtexBlix_RefreshRespawnedUnitHooks()

**/
library qAtexBlix initializer Init requires qBoomBrothers, QuestGiver, QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck, Voicelines, VoicelinesAtexBlix, VoicelinesBoomBrothers, VoicelinesNazgrek

globals
    private constant boolean DEBUG = false
    private constant string ATEX_NAME = "Atex Blix"
    private constant string BOOM_NAME = "Boom Brothers"
    private constant integer ITEM_PILE_WOOD = 'I60K'
    private constant integer ITEM_DUST_COLLECTOR = 'I00I'
    private constant integer ITEM_DUST_FILTER = 'I00G'
    private constant integer ITEM_VENT_BLOWER = 'I00H'
    private constant integer REQUIRED_APPROVED_LOGS = 10

    private constant real DIALOG_RANGE = 500.00
    private constant real DIALOG_COOLDOWN = 6.00
    private constant real DIALOG_FADE_OUT = 1.00
    private constant real DIALOG_FADE_IN = 1.00
    private constant integer CINEMATIC_MOVE_MODE = 1
    private constant real CINEMATIC_MOVE_OFFSET = 256.00
    private constant real CINEMATIC_MOVE_ANGLE = 210.00
    private constant boolean ALLOW_NAZGREK = true
    private constant boolean ALLOW_ZULKIS = true
    private constant boolean USE_DIALOG_CAMERA = true
    private constant boolean CINEMATIC = true
    private constant real CAMERA_DIST = 750.00
    private constant real CAMERA_Z_OFFSET = 100.00
    private constant real CAMERA_ANGLE = 358.00
    private constant real CAMERA_ROT_OFFSET = 0.00
    private constant real CAMERA_FAR_Z = 10000.00
    private constant real CAMERA_FOV = 75.00
    private constant real CAMERA_BLOCK_RADIUS = 0.00
    private constant boolean CAMERA_BLOCK_CHECK = true

    private unit AtexBlix = null
    private unit BoomBrothers = null
    private unit SelectedHero = null
    private dialog AtexDialog = null
    private timer AtexDialogCooldown = null
    private timer DustProgressTimer = null
    private integer ApprovedLogCount = 0
    private boolean RuntimeRegistered = false
    private boolean InitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cffff6633[qAtexBlix]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_AtexBlix != null and udg_AtexBlix != AtexBlix then
        set AtexBlix = udg_AtexBlix
    endif
    set BoomBrothers = qBoomBrothers_GetGiver()
endfunction

private function GetBoomQuest takes string questName returns QuestData
    call SyncUnitReferences()
    if BoomBrothers == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(questName, BoomBrothers)
endfunction

private function ResolveDialogHero takes nothing returns unit
    call SyncUnitReferences()
    return DialogInteraction_ResolveDialogHero(SelectedHero, AtexBlix, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function StartExitFadeOut takes nothing returns nothing
    local unit hero = SelectedHero
    set SelectedHero = null
    call DialogInteraction_StartConfiguredDialogExitTransition(AtexBlix, hero, AtexDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
    set hero = null
endfunction

private function ShouldAtexBeHidden takes nothing returns boolean
    local QuestData training = GetBoomQuest(qBoomBrothers_QUEST_MANDATORY_TRAINING)
    local boolean result = training != 0 and training.completed
    set training = 0
    return result
endfunction

private function RecoverApprovedLogProgress takes nothing returns nothing
    local QuestData compliance = GetBoomQuest(qBoomBrothers_QUEST_BOOMSITE_COMPLIANCE)
    if compliance != 0 and compliance.req1Completed and ApprovedLogCount < REQUIRED_APPROVED_LOGS then
        set ApprovedLogCount = REQUIRED_APPROVED_LOGS
    endif
    set compliance = 0
endfunction

private function SyncDustProgressInternal takes nothing returns nothing
    local QuestData q = GetBoomQuest(qBoomBrothers_QUEST_DUST_CULTURE)
    local boolean hasCollector
    local boolean hasFilter
    local boolean hasBlower
    local boolean changed = false
    if q == 0 or not q.active or q.completed then
        set q = 0
        return
    endif
    set hasCollector = HeroItemCheckBoth(ITEM_DUST_COLLECTOR, 1)
    set hasFilter = HeroItemCheckBoth(ITEM_DUST_FILTER, 1)
    set hasBlower = HeroItemCheckBoth(ITEM_VENT_BLOWER, 1)
    if q.req1Completed != hasCollector then
        call q.markRequirementCompleted(1, hasCollector)
        set changed = true
    endif
    if q.req2Completed != hasFilter then
        call q.markRequirementCompleted(2, hasFilter)
        set changed = true
    endif
    if q.req3Completed != hasBlower then
        call q.markRequirementCompleted(3, hasBlower)
        set changed = true
    endif
    if hasCollector and hasFilter and hasBlower and q.state != QUEST_STATE_READY_TURNIN then
        call q.addReturnRequirement()
        call q.setState(QUEST_STATE_READY_TURNIN)
        set changed = true
    elseif (not hasCollector or not hasFilter or not hasBlower) and q.state == QUEST_STATE_READY_TURNIN then
        call q.removeReturnRequirement()
        call q.setState(QUEST_STATE_IN_PROGRESS)
        set changed = true
    endif
    if changed then
        call q.refreshQuestLog()
        call QuestGiver_RefreshAvailabilityForGiver(AtexBlix)
    endif
    set q = 0
endfunction

private function OnDustProgressTimer takes nothing returns nothing
    call SyncDustProgressInternal()
endfunction

private function OnInspectLogEnd takes nothing returns nothing
    call DialogInteraction_QueueDialogReopen("qAtexBlix_ContinueToDialogAfterSelection", 0.20)
endfunction

private function OnInspectLog takes nothing returns nothing
    local QuestData q = GetBoomQuest(qBoomBrothers_QUEST_BOOMSITE_COMPLIANCE)
    local integer seq
    local boolean approved
    if q == 0 or not q.active or q.completed or ApprovedLogCount >= REQUIRED_APPROVED_LOGS or not HeroItemCheckBothAndRemove(ITEM_PILE_WOOD, 1) then
        set q = 0
        return
    endif
    set approved = GetRandomInt(1, 2) == 1
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(AtexBlix, ATEX_NAME)
    if approved then
        set ApprovedLogCount = ApprovedLogCount + 1
        call q.updateRequirementText(1, "Have Atex inspect suitable logs (" + I2S(ApprovedLogCount) + " / 10)")
        call QuestMaster_ShowUpdateMessage(q.id, "Logs approved: " + I2S(ApprovedLogCount) + " / 10")
        if ApprovedLogCount >= REQUIRED_APPROVED_LOGS then
            call q.markRequirementCompleted(1, true)
            call q.addReturnRequirement()
            call q.setState(QUEST_STATE_READY_TURNIN)
            call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0033_TEXT, VL_ATEXBLIX_0033_KEY, true)
        elseif GetRandomInt(1, 2) == 1 then
            call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0029_TEXT, VL_ATEXBLIX_0029_KEY, true)
        else
            call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0030_TEXT, VL_ATEXBLIX_0030_KEY, true)
        endif
    elseif GetRandomInt(1, 2) == 1 then
        call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0031_TEXT, VL_ATEXBLIX_0031_KEY, true)
    else
        call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0032_TEXT, VL_ATEXBLIX_0032_KEY, true)
    endif
    call q.refreshQuestLog()
    call QuestGiver_RefreshAvailabilityForGiver(AtexBlix)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnInspectLogEnd)
    call DialogSystem_PlaySequence(seq, Player(0), AtexBlix)
    set q = 0
endfunction

private function OnCompleteComplianceEnd takes nothing returns nothing
    local QuestData q = GetBoomQuest(qBoomBrothers_QUEST_BOOMSITE_COMPLIANCE)
    if q != 0 and q.active and not q.completed and ApprovedLogCount >= REQUIRED_APPROVED_LOGS then
        call QuestGiver_CompleteQuestByNameAndGiver(qBoomBrothers_QUEST_BOOMSITE_COMPLIANCE, BoomBrothers)
        call QuestGiver_RefreshAvailabilityForGiver(AtexBlix)
        call qBoomBrothers_RefreshAvailability()
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteCompliance takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(AtexBlix, ATEX_NAME)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0033_TEXT, VL_ATEXBLIX_0033_KEY, true)
    call DialogInteraction_AddHeroLine(seq, hero, VL_NAZGREK_0270_TEXT, VL_NAZGREK_0270_KEY)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0031_TEXT, VL_BOOMBROTHERS_0031_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0032_TEXT, VL_BOOMBROTHERS_0032_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteComplianceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), AtexBlix)
    set hero = null
endfunction

private function OnCompleteDustEnd takes nothing returns nothing
    local QuestData q = GetBoomQuest(qBoomBrothers_QUEST_DUST_CULTURE)
    if q != 0 and q.active and not q.completed and HeroItemCheckBoth(ITEM_DUST_COLLECTOR, 1) and HeroItemCheckBoth(ITEM_DUST_FILTER, 1) and HeroItemCheckBoth(ITEM_VENT_BLOWER, 1) then
        if HeroItemCheckBothAndRemove(ITEM_DUST_COLLECTOR, 1) and HeroItemCheckBothAndRemove(ITEM_DUST_FILTER, 1) and HeroItemCheckBothAndRemove(ITEM_VENT_BLOWER, 1) then
            call q.markRequirementCompleted(1, true)
            call q.markRequirementCompleted(2, true)
            call q.markRequirementCompleted(3, true)
            call QuestGiver_CompleteQuestByNameAndGiver(qBoomBrothers_QUEST_DUST_CULTURE, BoomBrothers)
            call QuestGiver_RefreshAvailabilityForGiver(AtexBlix)
            call qBoomBrothers_RefreshAvailability()
        endif
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteDust takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(AtexBlix, ATEX_NAME)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0041_TEXT, VL_ATEXBLIX_0041_KEY, true)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0042_TEXT, VL_ATEXBLIX_0042_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0047_TEXT, VL_BOOMBROTHERS_0047_KEY, true)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0044_TEXT, VL_ATEXBLIX_0044_KEY, true)
    call DialogInteraction_AddHeroLine(seq, hero, VL_NAZGREK_0272_TEXT, VL_NAZGREK_0272_KEY)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0047_TEXT, VL_ATEXBLIX_0047_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteDustEnd)
    call DialogSystem_PlaySequence(seq, Player(0), AtexBlix)
    set hero = null
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateFarewellSequence(AtexBlix, ATEX_NAME, hero, DialogInteraction_GetHeroName(hero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), AtexBlix)
    set hero = null
endfunction

private function BuildDialog takes nothing returns nothing
    local QuestData compliance = GetBoomQuest(qBoomBrothers_QUEST_BOOMSITE_COMPLIANCE)
    local QuestData dust = GetBoomQuest(qBoomBrothers_QUEST_DUST_CULTURE)
    local button b
    call RecoverApprovedLogProgress()
    call SyncDustProgressInternal()
    if AtexDialog == null then
        set AtexDialog = DialogSystem_CreateDialog(ATEX_NAME)
    endif
    call DialogSystem_ClearDialog(AtexDialog)
    call DialogSystem_SetTitle(AtexDialog, ATEX_NAME)
    if compliance != 0 and compliance.active and not compliance.completed then
        if compliance.state == QUEST_STATE_READY_TURNIN then
            call QuestGiver_AddReadyQuestCompleteButton(AtexDialog, qBoomBrothers_QUEST_BOOMSITE_COMPLIANCE, BoomBrothers, 1, function OnCompleteCompliance, false)
        elseif ApprovedLogCount < REQUIRED_APPROVED_LOGS and HeroItemCheckBoth(ITEM_PILE_WOOD, 1) then
            set b = DialogSystem_AddButton(AtexDialog, "Inspect a Pile Of Wood (" + I2S(ApprovedLogCount) + " / 10 approved)", 2)
            call DialogSystem_BindButtonCode(b, function OnInspectLog)
        endif
    endif
    if dust != 0 and dust.active and not dust.completed and dust.state == QUEST_STATE_READY_TURNIN and HeroItemCheckBoth(ITEM_DUST_COLLECTOR, 1) and HeroItemCheckBoth(ITEM_DUST_FILTER, 1) and HeroItemCheckBoth(ITEM_VENT_BLOWER, 1) then
        call QuestGiver_AddReadyQuestCompleteButton(AtexDialog, qBoomBrothers_QUEST_DUST_CULTURE, BoomBrothers, 3, function OnCompleteDust, false)
    endif
    set b = DialogSystem_AddFarewellButton(AtexDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set compliance = 0
    set dust = 0
    set b = null
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq
    if not DialogInteraction_IsFirstGreetDone(AtexBlix) then
        set seq = DialogInteraction_CreateBaseSequence(AtexBlix, ATEX_NAME)
        call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0001_TEXT, VL_ATEXBLIX_0001_KEY, true)
        call DialogInteraction_PlayFirstGreetSequenceEx(AtexBlix, Player(0), AtexDialog, seq, CINEMATIC)
    else
        set seq = DialogInteraction_CreateGreetSequenceBase(AtexBlix, ATEX_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, false)
        if GetRandomInt(1, 3) == 1 then
            call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0006_TEXT, VL_ATEXBLIX_0006_KEY, true)
        elseif GetRandomInt(1, 2) == 1 then
            call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0007_TEXT, VL_ATEXBLIX_0007_KEY, true)
        else
            call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0008_TEXT, VL_ATEXBLIX_0008_KEY, true)
        endif
        call DialogInteraction_PlayGreetSequenceEx(seq, AtexBlix, Player(0), AtexDialog, CINEMATIC)
    endif
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(AtexBlix) or ShouldAtexBeHidden() then
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

private function OnSelected takes nothing returns nothing
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(AtexBlix) or ShouldAtexBeHidden() then
        return
    endif
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(AtexBlix, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(AtexBlix, SelectedHero, DIALOG_RANGE, AtexDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif
    call DialogInteraction_StartConfiguredDialogEntryTransition(AtexBlix, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qAtexBlix_ContinueToDialogAfterSelection")
endfunction

private function RegisterDialogLines takes nothing returns nothing
    call DialogSystem_RegisterFarewellLineForUnit(AtexBlix, VL_ATEXBLIX_0004_TEXT, VL_ATEXBLIX_0004_KEY, true)
    call DialogSystem_RegisterFarewellLineForUnit(AtexBlix, VL_ATEXBLIX_0005_TEXT, VL_ATEXBLIX_0005_KEY, true)
endfunction

private function RegisterSoundKeys takes nothing returns nothing
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0001_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0004_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0005_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0006_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0007_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0008_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0023_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0024_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0026_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0027_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0029_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0030_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0031_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0032_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0033_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0036_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0037_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0040_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0041_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0042_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0044_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0047_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0050_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0051_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0052_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0058_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0059_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0060_KEY)
    call Voicelines_RegisterKey(VL_ATEXBLIX_FOLDER, VL_ATEXBLIX_0061_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0031_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0032_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0047_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0270_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0272_KEY)
endfunction

private function RegisterRuntime takes nothing returns nothing
    if RuntimeRegistered then
        return
    endif
    set RuntimeRegistered = true
    call TimerStart(DustProgressTimer, 1.00, true, function OnDustProgressTimer)
endfunction

private function ApplyAtexStoryState takes nothing returns nothing
    if ShouldAtexBeHidden() then
        call PauseUnit(AtexBlix, true)
        call ShowUnit(AtexBlix, false)
    endif
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()
    if AtexBlix == null or BoomBrothers == null or udg_Nazgrek == null or not QuestGiver_QuestExistsByNameAndGiver(qBoomBrothers_QUEST_EXPLOSIVE_CRISIS, BoomBrothers) then
        if not InitWaitingLogged then
            call DebugMsg("Waiting for Atex Blix, Boom Brothers, Nazgrek, and the Boom Brothers quest chain.")
            set InitWaitingLogged = true
        endif
        call TimerStart(GetExpiredTimer(), 0.50, false, function InitDelayed)
        return
    endif
    call QuestGiver_Register(AtexBlix)
    call DialogInteraction_ConfigureDialogTransition(AtexBlix, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call RegisterSoundKeys()
    call RegisterDialogLines()
    call RegisterRuntime()
    call DialogInteraction_RegisterSelectionHandler(AtexBlix, function OnSelected)
    call RecoverApprovedLogProgress()
    call ApplyAtexStoryState()
    call QuestGiver_RefreshAvailabilityForGiver(AtexBlix)
    call DestroyTimer(GetExpiredTimer())
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set AtexDialogCooldown = CreateTimer()
    set DustProgressTimer = CreateTimer()
    call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
endfunction

public function GetApprovedLogCount takes nothing returns integer
    return ApprovedLogCount
endfunction

public function SyncDustProgress takes nothing returns nothing
    call SyncDustProgressInternal()
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if AtexBlix != null then
        call QuestGiver_RefreshAvailabilityForGiver(AtexBlix)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if AtexBlix == null then
        return
    endif
    if ShouldAtexBeHidden() then
        call ApplyAtexStoryState()
        return
    endif
    call QuestGiver_Register(AtexBlix)
    call DialogInteraction_ConfigureDialogTransition(AtexBlix, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call DialogInteraction_RegisterSelectionHandler(AtexBlix, function OnSelected)
    call RefreshAvailability()
endfunction

endlibrary
