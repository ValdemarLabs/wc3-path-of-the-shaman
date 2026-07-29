/**
    qZaekolaerr

    Author: Valdemar
    Version:

    Description:
    Prince Zaekolaerr dialog conversion for the Ragno-owned Satyr
    Negotiations quest. This library restores Zaekolaerr as the
    external satyr dialog endpoint while keeping quest ownership,
    completion, and reward flow in qRagno.

    Credits:
    - Legacy Ragno GUI trigger notes.
    - Voicelines/_oldExcel/VoicelinesMaster.xlsx

    How to install:
    Import after qRagno, QuestGiver, DialogInteraction, DialogSystem,
    and VoicelinesSatyr. CreepUnitAssignment should refresh this
    library when the Zaekolaerr unit type respawns.

    API:
    qZaekolaerr_RefreshAvailability()
    qZaekolaerr_RefreshRespawnedUnitHooks()
    qZaekolaerr_ContinueToDialogAfterSelection()

**/
library qZaekolaerr initializer Init requires qRagno, QuestGiver, DialogInteraction, DialogSystem, VoicelinesSatyr

globals
    private constant boolean DEBUG = false

    private constant string ZA_NAME = "Prince Zaekolaerr"
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
    private constant real CAMERA_DIST = 1050.00
    private constant real CAMERA_Z_OFFSET = 20.00
    private constant real CAMERA_ANGLE = 350.00
    private constant real CAMERA_ROT_OFFSET = 180.00
    private constant real CAMERA_FAR_Z = 10000.00
    private constant real CAMERA_FOV = 60.00
    private constant real CAMERA_BLOCK_RADIUS = 0.00
    private constant boolean CAMERA_BLOCK_CHECK = true

    private unit Zaekolaerr = null
    private unit Nazgrek = null
    private unit Zulkis = null
    private unit SelectedHero = null

    private dialog ZaekolaerrDialog = null
    private timer ZaekolaerrDialogCooldown = null

    private boolean ZaekolaerrFirstMeetDone = false
    private boolean SatyrNegotiationIntroDone = false
    private boolean ZaekolaerrInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qZaekolaerr]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Zaekolaerr != null and udg_Zaekolaerr != Zaekolaerr then
        set Zaekolaerr = udg_Zaekolaerr
    endif
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
    if udg_Zulkis != null and udg_Zulkis != Zulkis then
        set Zulkis = udg_Zulkis
    endif
endfunction

private function ResolveDialogHero takes nothing returns unit
    local unit hero
    call SyncUnitReferences()
    set hero = DialogInteraction_ResolveDialogHero(SelectedHero, Zaekolaerr, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if hero == null and DialogInteraction_IsUnitAlive(Nazgrek) then
        set hero = Nazgrek
    endif
    return hero
endfunction

private function RefreshZaekolaerrAvailabilityInternal takes nothing returns nothing
    call SyncUnitReferences()
    if Zaekolaerr == null then
        return
    endif

    if qRagno_IsSatyrNegotiationsActive() and not qRagno_IsSatyrNegotiationsReady() then
        call QuestGiver_CreateDummyQuestIcon(Zaekolaerr, "normal", QUEST_STATE_READY_TURNIN)
    else
        call QuestGiver_RemoveDummyQuestIcon(Zaekolaerr)
    endif
endfunction

private function StartExitFadeOut takes nothing returns nothing
    call DialogSystem_ClearEscapeAction()
    call RefreshZaekolaerrAvailabilityInternal()
    call DialogInteraction_StartConfiguredDialogExitTransition(Zaekolaerr, SelectedHero, ZaekolaerrDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
endfunction

private function OnZaekolaerrEscape takes nothing returns nothing
    call DialogInteraction_CloseActiveDialog()
    call StartExitFadeOut()
endfunction

private function AddRandomGreetingLine takes integer seq returns nothing
    local integer roll = GetRandomInt(1, 5)

    if roll == 1 then
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0013_TEXT, VL_SATYR_0013_KEY, true)
    elseif roll == 2 then
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0014_TEXT, VL_SATYR_0014_KEY, true)
    elseif roll == 3 then
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0015_TEXT, VL_SATYR_0015_KEY, true)
    elseif roll == 4 then
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0016_TEXT, VL_SATYR_0016_KEY, true)
    else
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0017_TEXT, VL_SATYR_0017_KEY, true)
    endif
endfunction

private function AddRandomFarewellLine takes integer seq returns nothing
    local integer roll = GetRandomInt(1, 5)

    if roll == 1 then
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0020_TEXT, VL_SATYR_0020_KEY, true)
    elseif roll == 2 then
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0021_TEXT, VL_SATYR_0021_KEY, true)
    elseif roll == 3 then
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0022_TEXT, VL_SATYR_0022_KEY, true)
    elseif roll == 4 then
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0023_TEXT, VL_SATYR_0023_KEY, true)
    else
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0024_TEXT, VL_SATYR_0024_KEY, true)
    endif
endfunction

private function AddFirstMeetLine takes integer seq returns nothing
    local integer roll = GetRandomInt(1, 3)

    if roll == 1 then
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0001_TEXT, VL_SATYR_0001_KEY, true)
    elseif roll == 2 then
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0002_TEXT, VL_SATYR_0002_KEY, true)
    else
        call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0003_TEXT, VL_SATYR_0003_KEY, true)
    endif
    set ZaekolaerrFirstMeetDone = true
endfunction

private function AddSatyrNegotiationIntro takes integer seq returns nothing
    call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0026_TEXT, VL_SATYR_0026_KEY, true)
    call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0047_TEXT, VL_SATYR_0047_KEY, true)
    call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0029_TEXT, VL_SATYR_0029_KEY, true)
    set SatyrNegotiationIntroDone = true
endfunction

private function OnTrialByCombatEnd takes nothing returns nothing
    call qRagno_UpdateSatyrNegotiationsArena()
    call qRagno_MarkSatyrNegotiationsReady()
    call StartExitFadeOut()
endfunction

private function OnTrialByCombat takes nothing returns nothing
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Zaekolaerr, ZA_NAME)
    call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0031_TEXT, VL_SATYR_0031_KEY, true)
    call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0032_TEXT, VL_SATYR_0032_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnTrialByCombatEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Zaekolaerr)
endfunction

private function OnUnlikelyAllianceEnd takes nothing returns nothing
    call qRagno_UpdateSatyrNegotiationsUnlikelyAlliances()
    call qRagno_MarkSatyrNegotiationsReady()
    call StartExitFadeOut()
endfunction

private function OnUnlikelyAlliance takes nothing returns nothing
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Zaekolaerr, ZA_NAME)
    call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0036_TEXT, VL_SATYR_0036_KEY, true)
    call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0037_TEXT, VL_SATYR_0037_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnUnlikelyAllianceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Zaekolaerr)
endfunction

private function OnDiplomacyGoneWrongEnd takes nothing returns nothing
    call qRagno_UpdateSatyrNegotiationsDiplomacyGoneWrong()
    call qRagno_MarkSatyrNegotiationsReady()
    call StartExitFadeOut()
endfunction

private function OnDiplomacyGoneWrong takes nothing returns nothing
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Zaekolaerr, ZA_NAME)
    call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0043_TEXT, VL_SATYR_0043_KEY, true)
    call DialogSystem_AddLine(seq, Zaekolaerr, ZA_NAME, VL_SATYR_0044_TEXT, VL_SATYR_0044_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnDiplomacyGoneWrongEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Zaekolaerr)
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Zaekolaerr, ZA_NAME)
    call AddRandomFarewellLine(seq)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Zaekolaerr)
endfunction

private function BuildDialog takes nothing returns nothing
    local button b

    if ZaekolaerrDialog == null then
        set ZaekolaerrDialog = DialogSystem_CreateDialog(ZA_NAME)
    endif

    call DialogSystem_ClearDialog(ZaekolaerrDialog)
    call DialogSystem_SetTitle(ZaekolaerrDialog, ZA_NAME)

    if qRagno_IsSatyrNegotiationsActive() and not qRagno_IsSatyrNegotiationsReady() then
        set b = DialogSystem_AddButton(ZaekolaerrDialog, "Trial by combat", 1)
        call DialogSystem_BindButtonCode(b, function OnTrialByCombat)
        set b = DialogSystem_AddButton(ZaekolaerrDialog, "Offer betrayal", 2)
        call DialogSystem_BindButtonCode(b, function OnUnlikelyAlliance)
        set b = DialogSystem_AddButton(ZaekolaerrDialog, "Insult the prince", 3)
        call DialogSystem_BindButtonCode(b, function OnDiplomacyGoneWrong)
    endif

    set b = DialogSystem_AddFarewellButton(ZaekolaerrDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
endfunction

private function AddPreDialogBark takes integer seq returns nothing
    if not ZaekolaerrFirstMeetDone then
        call AddFirstMeetLine(seq)
    else
        call AddRandomGreetingLine(seq)
    endif

    if qRagno_IsSatyrNegotiationsActive() and not qRagno_IsSatyrNegotiationsReady() and not SatyrNegotiationIntroDone then
        call AddSatyrNegotiationIntro(seq)
    endif
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq = DialogInteraction_CreateGreetSequenceBase(Zaekolaerr, ZA_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, true)
    call AddPreDialogBark(seq)
    call DialogInteraction_PlayGreetSequenceEx(seq, Zaekolaerr, Player(0), ZaekolaerrDialog, CINEMATIC)
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero

    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Zaekolaerr) then
        call StartExitFadeOut()
        return
    endif

    set hero = ResolveDialogHero()
    if hero == null then
        call StartExitFadeOut()
        return
    endif

    call RefreshZaekolaerrAvailabilityInternal()
    call BuildDialog()
    call DialogSystem_SetEscapeAction(function OnZaekolaerrEscape)
    call PlayDialogGreeting(hero)

    set hero = null
endfunction

public function ContinueToDialogAfterSelection takes nothing returns nothing
    call ContinueToDialogInternal()
endfunction

private function OnSelected takes nothing returns nothing
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Zaekolaerr) then
        return
    endif

    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Zaekolaerr, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Zaekolaerr, SelectedHero, DIALOG_RANGE, ZaekolaerrDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif

    call DialogInteraction_StartConfiguredDialogEntryTransition(Zaekolaerr, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qZaekolaerr_ContinueToDialogAfterSelection")
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()

    if Zaekolaerr == null or Nazgrek == null then
        if not ZaekolaerrInitWaitingLogged then
            call DebugMsg("Waiting for Zaekolaerr and Nazgrek unit references.")
            set ZaekolaerrInitWaitingLogged = true
        endif
        call TimerStart(GetExpiredTimer(), 0.50, false, function InitDelayed)
        return
    endif

    call QuestGiver_Register(Zaekolaerr)
    call DialogInteraction_ConfigureDialogTransition(Zaekolaerr, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call RefreshZaekolaerrAvailabilityInternal()
    call DialogInteraction_RegisterSelectionHandler(Zaekolaerr, function OnSelected)
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set ZaekolaerrDialogCooldown = CreateTimer()
    call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
endfunction

public function RefreshAvailability takes nothing returns nothing
    call RefreshZaekolaerrAvailabilityInternal()
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Zaekolaerr != null then
        call QuestGiver_Register(Zaekolaerr)
        call DialogInteraction_ConfigureDialogTransition(Zaekolaerr, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Zaekolaerr, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

endlibrary
