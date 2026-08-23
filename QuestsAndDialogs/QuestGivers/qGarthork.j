/**
    qGarthork

    Author: Valdemar
    Version:

    Description:
    Converts Garthork's legacy Magical Eye quest and Shadowmoon dialogue to
    the current QuestGiver and DialogInteraction systems.

    Credits:
    Converted from QuestsAndDialogs/OLDGUI/Garthork.

    How to install:
    Import after the required quest, dialog, hero-item, and voiceline
    libraries. Keep the Garthork and hero GUI unit globals assigned.

    API:
    - qGarthork_IsProofTaskComplete()
    - qGarthork_RefreshAvailability()
    - qGarthork_RefreshRespawnedUnitHooks()

**/
library qGarthork initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck, VoicelinesGarthork, VoicelinesNazgrek

globals
    private constant boolean DEBUG = false

    public constant string QUEST_MAGICAL_EYE = "The Magical Eye"
    private constant string GARTHORK_NAME = "Garthork"

    private constant integer UNIT_MURGAL = 'n607'
    private constant integer ITEM_MAGICAL_EYE = 'I601'
    private constant integer ITEM_ADEPT_SHAMAN_CLAWS = 'I66R'
    private constant integer HOSTILE_OWNER = 11

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

    private unit Garthork = null
    private unit Nazgrek = null
    private unit Zulkis = null
    private unit Murgal = null
    private unit SelectedHero = null
    private dialog GarthorkDialog = null
    private timer GarthorkDialogCooldown = null
    private boolean GarthorkInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qGarthork]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Garthork != null and udg_Garthork != Garthork then
        set Garthork = udg_Garthork
    endif
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
    if udg_Zulkis != null and udg_Zulkis != Zulkis then
        set Zulkis = udg_Zulkis
    endif
endfunction

private function ResolveDialogHero takes nothing returns unit
    call SyncUnitReferences()
    return DialogInteraction_ResolveDialogHero(SelectedHero, Garthork, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function GetMagicalEyeQuest takes nothing returns QuestData
    call SyncUnitReferences()
    if Garthork == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(QUEST_MAGICAL_EYE, Garthork)
endfunction

private function StartExitFadeOut takes nothing returns nothing
    call DialogInteraction_StartConfiguredDialogExitTransition(Garthork, SelectedHero, GarthorkDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
endfunction

private function EnsureMurgal takes nothing returns nothing
    if udg_Murgal != null and udg_Murgal != Murgal then
        set Murgal = udg_Murgal
    endif
    set Murgal = QuestGiver_ReuseOrCreateUnitAtPoint(Murgal, Player(HOSTILE_OWNER), UNIT_MURGAL, GetRectCenterX(gg_rct_Murgal), GetRectCenterY(gg_rct_Murgal), 310.00, false)
    set udg_Murgal = Murgal
endfunction

private function OnAcceptEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_MAGICAL_EYE, Garthork)
    call EnsureMurgal()
    call StartExitFadeOut()
endfunction

private function OnAccept takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Garthork, GARTHORK_NAME)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0083_TEXT, VL_NAZGREK_0083_KEY, true)
    call DialogSystem_AddLine(seq, Garthork, GARTHORK_NAME, VL_GARTHORK_0013_TEXT, VL_GARTHORK_0013_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Garthork)
    set hero = null
endfunction

private function OnDeclineEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnDecline takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Garthork, GARTHORK_NAME)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0084_TEXT, VL_NAZGREK_0084_KEY, true)
    call DialogSystem_AddLine(seq, Garthork, GARTHORK_NAME, VL_GARTHORK_0014_TEXT, VL_GARTHORK_0014_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnDeclineEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Garthork)
    set hero = null
endfunction

private function OnCompleteEnd takes nothing returns nothing
    local QuestData q = GetMagicalEyeQuest()
    if q != 0 and q.active and not q.completed and HeroItemCheckBoth(ITEM_MAGICAL_EYE, 1) then
        call QuestGiver_RemoveHeroItemsEither(ITEM_MAGICAL_EYE, 0, 1)
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_MAGICAL_EYE, Garthork)
        call ExecuteFunc("qChieftainThork_ReportGarthorkTaskComplete")
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnComplete takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Garthork, GARTHORK_NAME)
    call DialogSystem_AddLine(seq, Garthork, GARTHORK_NAME, VL_GARTHORK_0016_TEXT, VL_GARTHORK_0016_KEY, true)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0087_TEXT, VL_NAZGREK_0087_KEY, true)
    call DialogSystem_AddLine(seq, Garthork, GARTHORK_NAME, VL_GARTHORK_0017_TEXT, VL_GARTHORK_0017_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Garthork)
    set hero = null
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateFarewellSequence(Garthork, GARTHORK_NAME, hero, DialogInteraction_GetHeroName(hero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Garthork)
    set hero = null
endfunction

private function BuildDialog takes nothing returns nothing
    local button b
    if GarthorkDialog == null then
        set GarthorkDialog = DialogSystem_CreateDialog(GARTHORK_NAME)
    endif
    call QuestGiver_RefreshAvailabilityForGiver(Garthork)
    call DialogSystem_ClearDialog(GarthorkDialog)
    call DialogSystem_SetTitle(GarthorkDialog, GARTHORK_NAME)
    if QuestGiver_AddAvailableQuestAcceptButton(GarthorkDialog, QUEST_MAGICAL_EYE, Garthork, 1, function OnAccept, true, true) then
        set b = DialogSystem_AddButton(GarthorkDialog, "Decline", 2)
        call DialogSystem_BindButtonCode(b, function OnDecline)
        set b = null
    endif
    call QuestGiver_AddReadyQuestCompleteButton(GarthorkDialog, QUEST_MAGICAL_EYE, Garthork, 3, function OnComplete, true)
    set b = DialogSystem_AddFarewellButton(GarthorkDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
endfunction

private function AddPreDialogBark takes integer seq returns nothing
    local QuestData q = GetMagicalEyeQuest()
    if q != 0 and q.active and q.state == QUEST_STATE_READY_TURNIN then
        call DialogSystem_AddLine(seq, Garthork, GARTHORK_NAME, VL_GARTHORK_0016_TEXT, VL_GARTHORK_0016_KEY, true)
    elseif q != 0 and q.active then
        call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0085_TEXT, VL_NAZGREK_0085_KEY, true)
        call DialogSystem_AddLine(seq, Garthork, GARTHORK_NAME, VL_GARTHORK_0015_TEXT, VL_GARTHORK_0015_KEY, true)
    elseif q != 0 and not q.completed then
        call DialogSystem_AddLine(seq, Garthork, GARTHORK_NAME, VL_GARTHORK_0010_TEXT, VL_GARTHORK_0010_KEY, true)
        call DialogSystem_AddLine(seq, Garthork, GARTHORK_NAME, VL_GARTHORK_0011_TEXT, VL_GARTHORK_0011_KEY, true)
        call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0081_TEXT, VL_NAZGREK_0081_KEY, true)
        call DialogSystem_AddLine(seq, Garthork, GARTHORK_NAME, VL_GARTHORK_0012_TEXT, VL_GARTHORK_0012_KEY, true)
    else
        call DialogSystem_AddLine(seq, Garthork, GARTHORK_NAME, VL_GARTHORK_0006_TEXT, VL_GARTHORK_0006_KEY, true)
    endif
    set q = 0
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq = DialogInteraction_CreateGreetSequenceBase(Garthork, GARTHORK_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, false)
    call AddPreDialogBark(seq)
    call DialogInteraction_PlayGreetSequenceEx(seq, Garthork, Player(0), GarthorkDialog, CINEMATIC)
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Garthork) then
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
    if not DialogInteraction_IsUnitAlive(Garthork) then
        return
    endif
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Garthork, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Garthork, SelectedHero, DIALOG_RANGE, GarthorkDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif
    call DialogInteraction_StartConfiguredDialogEntryTransition(Garthork, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qGarthork_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string infoText = "|cffffcc00Quest giver:|r " + GARTHORK_NAME + "\n|cffffcc00Zone:|r Thornwoods (6)\n"
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_MAGICAL_EYE, Garthork) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_MAGICAL_EYE, Garthork, "normal", 6, null, QUEST_MAGICAL_EYE, "ReplaceableTextures\\CommandButtons\\BTNMurloc.blp", "Kill the murloc high sorcerer Mur'gal, recover his magical eye, and return it to Garthork.\n\n", infoText, "|cffffcc00Recommended level:|r 6\n\n", 3, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", GARTHORK_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, -50, false, 0, false, 0, false)
        call q.setRewardItemType(ITEM_ADEPT_SHAMAN_CLAWS)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_SetRequirements(q.id, "", "Bring Mur'gal's magical eye to Garthork", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Garthork, 1, ITEM_MAGICAL_EYE, 1)
    endif
    set q = 0
endfunction

private function RegisterDialogLines takes nothing returns nothing
    call DialogSystem_RegisterFarewellLineForUnit(Garthork, VL_GARTHORK_0007_TEXT, VL_GARTHORK_0007_KEY, true)
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()
    if Garthork == null or Nazgrek == null then
        if not GarthorkInitWaitingLogged then
            call DebugMsg("Waiting for Garthork and Nazgrek.")
            set GarthorkInitWaitingLogged = true
        endif
        call TimerStart(GetExpiredTimer(), 0.50, false, function InitDelayed)
        return
    endif
    call QuestGiver_Register(Garthork)
    call DialogInteraction_ConfigureDialogTransition(Garthork, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call CreateQuests()
    call RegisterDialogLines()
    call DialogInteraction_RegisterSelectionHandler(Garthork, function OnSelected)
    call QuestGiver_RefreshAvailabilityForGiver(Garthork)
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set GarthorkDialogCooldown = CreateTimer()
    call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
endfunction

public function IsProofTaskComplete takes nothing returns boolean
    call SyncUnitReferences()
    return Garthork != null and QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_MAGICAL_EYE, Garthork)
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if Garthork != null then
        call QuestGiver_RefreshAvailabilityForGiver(Garthork)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Garthork != null then
        call QuestGiver_Register(Garthork)
        call DialogInteraction_ConfigureDialogTransition(Garthork, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Garthork, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

endlibrary
