/**
    qGrim

    Author: Valdemar
    Version:

    Description:
    Converts Grim's Big Bear Tooth daily quest and dialogue from legacy GUI.
    The shared item tracker detects Big Bear Tooth pickups and makes the quest
    ready for turn-in at Grim.

    Credits:
    Converted from QuestsAndDialogs/OLDGUI/Grim.

    How to install:
    Import after the quest/dialog, HeroItemCheck, Orc Peon voiceline, and
    Nazgrek voiceline libraries. Keep udg_Grim and disable the old Grim GUI
    trigger group to prevent duplicate quest and dialogue handling.

    API:
    - qGrim_RefreshAvailability()
    - qGrim_RefreshRespawnedUnitHooks()

**/
library qGrim initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck, VoicelinesOrcPeon, VoicelinesNazgrek

globals
    private constant boolean DEBUG = false

    public constant string QUEST_BIG_BEAR_TOOTH = "Big Bear Tooth"
    private constant string GRIM_NAME = "Grim"

    private constant integer ITEM_BIG_BEAR_TOOTH = 'I6AB'

    private constant real DIALOG_RANGE = 500.00
    private constant real DIALOG_COOLDOWN = 6.00
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

    private unit Grim = null
    private unit Nazgrek = null
    private unit SelectedHero = null
    private dialog GrimDialog = null
    private timer GrimDialogCooldown = null
    private timer GrimInitTimer = null
    private boolean GrimInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qGrim]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Grim != null and udg_Grim != Grim then
        set Grim = udg_Grim
    endif
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
endfunction

private function ResolveDialogHero takes nothing returns unit
    call SyncUnitReferences()
    return DialogInteraction_ResolveDialogHero(SelectedHero, Grim, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function GetGrimQuest takes nothing returns QuestData
    call SyncUnitReferences()
    if Grim == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(QUEST_BIG_BEAR_TOOTH, Grim)
endfunction

private function StartExitFadeOut takes nothing returns nothing
    call DialogInteraction_StartConfiguredDialogExitTransition(Grim, SelectedHero, GrimDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
endfunction

private function OnAcceptQuestEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_BIG_BEAR_TOOTH, Grim)
    call StartExitFadeOut()
endfunction

private function OnAcceptQuest takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Grim, GRIM_NAME)
    call DialogSystem_AddLine(seq, Grim, GRIM_NAME, VL_ORCPEON_0024_TEXT, VL_ORCPEON_0024_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuestEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grim)
endfunction

private function OnCompleteQuestEnd takes nothing returns nothing
    local QuestData q = GetGrimQuest()
    if q != 0 and q.active and not q.completed and HeroItemCheckBothAndRemove(ITEM_BIG_BEAR_TOOTH, 1) then
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_BIG_BEAR_TOOTH, Grim)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteQuest takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Grim, GRIM_NAME)
    call DialogSystem_AddLine(seq, Grim, GRIM_NAME, VL_ORCPEON_0025_TEXT, VL_ORCPEON_0025_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuestEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grim)
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Grim, GRIM_NAME)
    if hero == Nazgrek then
        call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0004_TEXT, VL_NAZGREK_0004_KEY, true)
    endif
    call DialogSystem_AddLine(seq, Grim, GRIM_NAME, VL_ORCPEON_0021_TEXT, VL_ORCPEON_0021_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grim)
    set hero = null
endfunction

private function BuildDialog takes nothing returns nothing
    local button b
    if GrimDialog == null then
        set GrimDialog = DialogSystem_CreateDialog(GRIM_NAME)
    endif
    call QuestGiver_RefreshAvailabilityForGiver(Grim)
    call DialogSystem_ClearDialog(GrimDialog)
    call DialogSystem_SetTitle(GrimDialog, GRIM_NAME)
    call QuestGiver_AddAvailableQuestAcceptButton(GrimDialog, QUEST_BIG_BEAR_TOOTH, Grim, 1, function OnAcceptQuest, true, false)
    call QuestGiver_AddReadyQuestCompleteButton(GrimDialog, QUEST_BIG_BEAR_TOOTH, Grim, 2, function OnCompleteQuest, true)
    set b = DialogSystem_AddFarewellButton(GrimDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
endfunction

private function PlayDialogGreeting takes nothing returns nothing
    local integer seq = DialogInteraction_CreateBaseSequence(Grim, GRIM_NAME)
    if not DialogInteraction_IsFirstGreetDone(Grim) then
        call DialogSystem_AddLine(seq, Grim, GRIM_NAME, VL_ORCPEON_0022_TEXT, VL_ORCPEON_0022_KEY, true)
        call DialogSystem_AddLine(seq, Grim, GRIM_NAME, VL_ORCPEON_0023_TEXT, VL_ORCPEON_0023_KEY, true)
        call DialogInteraction_PlayFirstGreetSequenceEx(Grim, Player(0), GrimDialog, seq, CINEMATIC)
    else
        call DialogSystem_AddLine(seq, Grim, GRIM_NAME, VL_ORCPEON_0020_TEXT, VL_ORCPEON_0020_KEY, true)
        call DialogInteraction_PlayGreetSequenceEx(seq, Grim, Player(0), GrimDialog, CINEMATIC)
    endif
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Grim) then
        call StartExitFadeOut()
        return
    endif
    set hero = ResolveDialogHero()
    if hero == null then
        call StartExitFadeOut()
        return
    endif
    call BuildDialog()
    call PlayDialogGreeting()
    set hero = null
endfunction

public function ContinueToDialogAfterSelection takes nothing returns nothing
    call ContinueToDialogInternal()
endfunction

private function OnSelected takes nothing returns nothing
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Grim) then
        return
    endif
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Grim, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Grim, SelectedHero, DIALOG_RANGE, GrimDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif
    call DialogInteraction_StartConfiguredDialogEntryTransition(Grim, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qGrim_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string infoText = "|cffffcc00Quest giver:|r " + GRIM_NAME + "\n|cffffcc00Zone:|r Thornwoods (6)\n|cffffcc00Objective area:|r Thornwoods wildlife\n"
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_BIG_BEAR_TOOTH, Grim) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_BIG_BEAR_TOOTH, Grim, "daily", 3, null, QUEST_BIG_BEAR_TOOTH, "ReplaceableTextures\\CommandButtons\\BTNGrizzlyBear.blp", "Grim wants you to kill a bear and return to him with its tooth.\n\n", infoText, "|cffffcc00Recommended level:|r 3\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", GRIM_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 150, false, 0, false, 0, false)
        call QuestGiver_SetRequirements(q.id, "", "Bring a Big Bear Tooth to Grim", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Grim, 1, ITEM_BIG_BEAR_TOOTH, 1)
    endif
    set q = 0
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()
    if Grim == null or Nazgrek == null then
        if not GrimInitWaitingLogged then
            call DebugMsg("Waiting for Grim and Nazgrek.")
            set GrimInitWaitingLogged = true
        endif
        call TimerStart(GrimInitTimer, 0.50, false, function InitDelayed)
        return
    endif
    call QuestGiver_Register(Grim)
    call DialogInteraction_ConfigureDialogTransition(Grim, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call CreateQuests()
    call DialogInteraction_RegisterSelectionHandler(Grim, function OnSelected)
    call QuestGiver_RefreshAvailabilityForGiver(Grim)
    call DestroyTimer(GrimInitTimer)
    set GrimInitTimer = null
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set GrimDialogCooldown = CreateTimer()
    set GrimInitTimer = CreateTimer()
    call TimerStart(GrimInitTimer, 0.00, false, function InitDelayed)
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if Grim != null then
        call QuestGiver_RefreshAvailabilityForGiver(Grim)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Grim != null then
        call QuestGiver_Register(Grim)
        call DialogInteraction_ConfigureDialogTransition(Grim, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Grim, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

endlibrary
