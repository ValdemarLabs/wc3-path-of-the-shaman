/**
    qErduk

    Author: Valdemar
    Version:

    Description:
    Converts Erduk's Heads of the Murlocs quest and dialogue from legacy GUI.
    The shared item tracker counts Murloc Heads and enables turn-in at Erduk.

    Credits:
    Converted from QuestsAndDialogs/OLDGUI/Erduk.

    How to install:
    Import after the quest and dialog master libraries. Keep udg_Erduk,
    udg_Nazgrek, and gg_rct_LakeAmbient042 assigned, and disable the old
    Erduk GUI trigger group.

    API:
    - qErduk_RefreshAvailability()
    - qErduk_RefreshRespawnedUnitHooks()

**/
library qErduk initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem

globals
    private constant boolean DEBUG = false

    public constant string QUEST_HEADS_OF_THE_MURLOCS = "Heads of the Murlocs"
    private constant string ERDUK_NAME = "Erduk"

    private constant integer ITEM_MURLOC_HEAD = 'I610'
    private constant integer MURLOC_HEAD_COUNT = 40
    private constant integer QUEST_ZONE_ID = 7

    private constant real DIALOG_RANGE = 500.00
    private constant real DIALOG_COOLDOWN = 6.00
    private constant integer CINEMATIC_MOVE_MODE = 1
    private constant real CINEMATIC_MOVE_OFFSET = 256.00
    private constant real CINEMATIC_MOVE_ANGLE = 210.00

    private constant boolean ALLOW_NAZGREK = true
    private constant boolean ALLOW_ZULKIS = false
    private constant boolean USE_DIALOG_CAMERA = true
    private constant boolean CINEMATIC = true
    private constant real CAMERA_DIST = 1000.00
    private constant real CAMERA_Z_OFFSET = 20.00
    private constant real CAMERA_ANGLE = 350.00
    private constant real CAMERA_ROT_OFFSET = 180.00
    private constant real CAMERA_FAR_Z = 10000.00
    private constant real CAMERA_FOV = 60.00
    private constant real CAMERA_BLOCK_RADIUS = 0.00
    private constant boolean CAMERA_BLOCK_CHECK = true

    private unit Erduk = null
    private unit Nazgrek = null
    private unit SelectedHero = null
    private dialog ErdukDialog = null
    private timer ErdukDialogCooldown = null
    private timer ErdukInitTimer = null
    private boolean ErdukInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qErduk]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Erduk != null and udg_Erduk != Erduk then
        set Erduk = udg_Erduk
    endif
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
endfunction

private function ResolveDialogHero takes nothing returns unit
    call SyncUnitReferences()
    return DialogInteraction_ResolveDialogHero(SelectedHero, Erduk, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function GetErdukQuest takes nothing returns QuestData
    call SyncUnitReferences()
    if Erduk == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(QUEST_HEADS_OF_THE_MURLOCS, Erduk)
endfunction

private function StartExitFadeOut takes nothing returns nothing
    call DialogInteraction_StartConfiguredDialogExitTransition(Erduk, SelectedHero, ErdukDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
endfunction

private function RevealObjectiveArea takes nothing returns nothing
    local fogmodifier visibility = CreateFogModifierRadius(Player(0), FOG_OF_WAR_VISIBLE, GetRectCenterX(gg_rct_LakeAmbient042), GetRectCenterY(gg_rct_LakeAmbient042), 600.00, true, false)

    call FogModifierStart(visibility)
    call DestroyFogModifier(visibility)
    set visibility = null
endfunction

private function OnAcceptQuestEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_HEADS_OF_THE_MURLOCS, Erduk)
    call RevealObjectiveArea()
    call StartExitFadeOut()
endfunction

private function OnAcceptQuest takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Erduk, ERDUK_NAME)
    call DialogSystem_AddLineNoSound(seq, Erduk, ERDUK_NAME, "As you may have seen, the rivers are full of these murlocs.")
    call DialogSystem_AddLineNoSound(seq, Erduk, ERDUK_NAME, "They keep attacking us, stealing food from us and destroying our lodges.")
    call DialogSystem_AddMakeFaceEachOther(seq, Erduk, hero, 0.75, 0.50)
    call DialogSystem_AddLineNoSound(seq, hero, DialogInteraction_GetHeroName(hero), "Is there something I could do for you?")
    call DialogSystem_AddLineNoSound(seq, Erduk, ERDUK_NAME, "Hunt down as many as you can. Bring me 40 murloc heads and I promise I shall reward you well.")
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuestEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Erduk)
    set hero = null
endfunction

private function OnCompleteQuestEnd takes nothing returns nothing
    local QuestData q = GetErdukQuest()

    if q != 0 and q.active and not q.completed and QuestGiver_ValidateItemRequirements(q.id) then
        call QuestGiver_RemoveHeroItemsEither(ITEM_MURLOC_HEAD, 0, MURLOC_HEAD_COUNT)
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_HEADS_OF_THE_MURLOCS, Erduk)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteQuest takes nothing returns nothing
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Erduk, ERDUK_NAME)
    call DialogSystem_AddLineNoSound(seq, Erduk, ERDUK_NAME, "Thank you. I'll use them wisely.")
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuestEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Erduk)
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq

    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Erduk, ERDUK_NAME)
    call DialogSystem_AddLineNoSound(seq, hero, DialogInteraction_GetHeroName(hero), "Farewell.")
    call DialogSystem_AddLineNoSound(seq, Erduk, ERDUK_NAME, "We'll meet again, if fate wills it.")
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Erduk)
    set hero = null
endfunction

private function BuildDialog takes nothing returns nothing
    local button b

    if ErdukDialog == null then
        set ErdukDialog = DialogSystem_CreateDialog(ERDUK_NAME)
    endif
    call QuestGiver_RefreshAvailabilityForGiver(Erduk)
    call DialogSystem_ClearDialog(ErdukDialog)
    call DialogSystem_SetTitle(ErdukDialog, ERDUK_NAME)
    call QuestGiver_AddAvailableQuestAcceptButton(ErdukDialog, QUEST_HEADS_OF_THE_MURLOCS, Erduk, 1, function OnAcceptQuest, true, false)
    call QuestGiver_AddReadyQuestCompleteButton(ErdukDialog, QUEST_HEADS_OF_THE_MURLOCS, Erduk, 2, function OnCompleteQuest, true)
    set b = DialogSystem_AddFarewellButton(ErdukDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
endfunction

private function PlayDialogGreeting takes nothing returns nothing
    local integer seq = DialogInteraction_CreateBaseSequence(Erduk, ERDUK_NAME)

    call DialogSystem_AddLineNoSound(seq, Erduk, ERDUK_NAME, "Our ancestors are within us.")
    if not DialogInteraction_IsFirstGreetDone(Erduk) then
        call DialogInteraction_PlayFirstGreetSequenceEx(Erduk, Player(0), ErdukDialog, seq, CINEMATIC)
    else
        call DialogInteraction_PlayGreetSequenceEx(seq, Erduk, Player(0), ErdukDialog, CINEMATIC)
    endif
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero

    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Erduk) then
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
    if not DialogInteraction_IsUnitAlive(Erduk) then
        return
    endif
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Erduk, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Erduk, SelectedHero, DIALOG_RANGE, ErdukDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif
    call DialogInteraction_StartConfiguredDialogEntryTransition(Erduk, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qErduk_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string infoText = "|cffffcc00Quest giver:|r " + ERDUK_NAME + "\n|cffffcc00Zone:|r Havenwoods (7)\n|cffffcc00Objective area:|r Rivers near Erduk\n"

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_HEADS_OF_THE_MURLOCS, Erduk) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_HEADS_OF_THE_MURLOCS, Erduk, "normal", 8, null, QUEST_HEADS_OF_THE_MURLOCS, "ReplaceableTextures\\CommandButtons\\BTNMurlocFlesheater.blp", "Murlocs from the nearby rivers keep raiding Erduk's lodges and stealing their food. Gather their heads and return them to Erduk.\n\n", infoText, "|cffffcc00Recommended level:|r 8\n\n", 5, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", ERDUK_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, true, 100, false)
        call QuestGiver_SetRequirements(q.id, "", "Bring 40 Murloc Heads to Erduk", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Erduk, 1, ITEM_MURLOC_HEAD, MURLOC_HEAD_COUNT)
        call q.setTargetRect(gg_rct_LakeAmbient042)
        call q.setTargetZone(QUEST_ZONE_ID)
    endif
    set q = 0
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()
    if Erduk == null or Nazgrek == null then
        if not ErdukInitWaitingLogged then
            call DebugMsg("Waiting for Erduk and Nazgrek.")
            set ErdukInitWaitingLogged = true
        endif
        call TimerStart(ErdukInitTimer, 0.50, false, function InitDelayed)
        return
    endif
    call QuestGiver_Register(Erduk)
    call DialogInteraction_ConfigureDialogTransition(Erduk, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call CreateQuests()
    call DialogInteraction_RegisterSelectionHandler(Erduk, function OnSelected)
    call QuestGiver_RefreshAvailabilityForGiver(Erduk)
    call DestroyTimer(ErdukInitTimer)
    set ErdukInitTimer = null
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set ErdukDialogCooldown = CreateTimer()
    set ErdukInitTimer = CreateTimer()
    call TimerStart(ErdukInitTimer, 0.00, false, function InitDelayed)
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if Erduk != null then
        call QuestGiver_RefreshAvailabilityForGiver(Erduk)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Erduk != null then
        call QuestGiver_Register(Erduk)
        call DialogInteraction_ConfigureDialogTransition(Erduk, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Erduk, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

endlibrary
