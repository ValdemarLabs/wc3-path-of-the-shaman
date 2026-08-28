/**
    qQuinx

    Author: Valdemar
    Version: 1.0.0

    Description:
    Implements Quinx's Shredder Fuel quest and starts an ambient harvesting
    loop after his shredder receives Goblin Rocket Fuel.

    Credits:
    - Path of the Shaman QuestGiver and DialogInteraction systems

    How to install:
    Import after the quest/dialog and HeroItemCheck libraries. Keep udg_Quinx
    assigned to the placed shredder unit and keep Goblin Rocket Fuel item
    j4c2 available from its configured vendors.

    API:
    - qQuinx_IsFuelDelivered()
    - qQuinx_RefreshAvailability()
    - qQuinx_RefreshRespawnedUnitHooks()

**/
library qQuinx initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck

globals
    private constant boolean DEBUG = false

    public constant string QUEST_SHREDDER_FUEL = "Shredder Fuel"
    public constant integer ITEM_GOBLIN_ROCKET_FUEL = 'j4c2'
    private constant string QUINX_NAME = "Quinx"

    private constant real DIALOG_RANGE = 500.00
    private constant real DIALOG_COOLDOWN = 6.00
    private constant integer CINEMATIC_MOVE_MODE = 0
    private constant real CINEMATIC_MOVE_OFFSET = 0.00
    private constant real CINEMATIC_MOVE_ANGLE = 0.00

    private constant boolean ALLOW_NAZGREK = true
    private constant boolean ALLOW_ZULKIS = true
    private constant boolean USE_DIALOG_CAMERA = true
    private constant boolean CINEMATIC = true
    private constant real CAMERA_DIST = 1100.00
    private constant real CAMERA_Z_OFFSET = 80.00
    private constant real CAMERA_ANGLE = 345.00
    private constant real CAMERA_ROT_OFFSET = 180.00
    private constant real CAMERA_FAR_Z = 10000.00
    private constant real CAMERA_FOV = 60.00
    private constant real CAMERA_BLOCK_RADIUS = 180.00
    private constant boolean CAMERA_BLOCK_CHECK = true

    private constant real HARVEST_RADIUS = 900.00
    private constant real HARVEST_WORK_DURATION = 18.00
    private constant real HARVEST_PAUSE_DURATION = 5.00
    private constant real HARVEST_RETRY_DURATION = 8.00

    private unit Quinx = null
    private unit SelectedHero = null
    private dialog QuinxDialog = null
    private timer QuinxDialogCooldown = null
    private timer QuinxInitTimer = null
    private timer HarvestTimer = null
    private rect HarvestScanRect = null
    private destructable HarvestTree = null
    private boolean HarvestWorking = false
    private boolean QuinxInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cffffcc00[qQuinx]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Quinx != null and udg_Quinx != Quinx then
        set Quinx = udg_Quinx
    endif
endfunction

private function ResolveDialogHero takes nothing returns unit
    call SyncUnitReferences()
    return DialogInteraction_ResolveDialogHero(SelectedHero, Quinx, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function GetFuelQuest takes nothing returns QuestData
    call SyncUnitReferences()
    if Quinx == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(QUEST_SHREDDER_FUEL, Quinx)
endfunction

private function FuelIsDelivered takes nothing returns boolean
    local QuestData q = GetFuelQuest()
    local boolean delivered = q != 0 and q.completed
    set q = 0
    return delivered
endfunction

// The harvest order itself filters nearby destructables to valid tree targets.
private function TryHarvestTreeEnum takes nothing returns nothing
    local destructable d = GetEnumDestructable()

    if HarvestTree == null and d != null and GetDestructableLife(d) > 0.405 then
        if IssueTargetDestructableOrder(Quinx, "harvest", d) then
            set HarvestTree = d
        endif
    endif
    set d = null
endfunction

private function IssueNearbyHarvestOrder takes nothing returns boolean
    local real x
    local real y

    if not DialogInteraction_IsUnitAlive(Quinx) then
        return false
    endif
    set x = GetUnitX(Quinx)
    set y = GetUnitY(Quinx)
    set HarvestTree = null
    call SetRect(HarvestScanRect, x - HARVEST_RADIUS, y - HARVEST_RADIUS, x + HARVEST_RADIUS, y + HARVEST_RADIUS)
    call EnumDestructablesInRect(HarvestScanRect, null, function TryHarvestTreeEnum)
    return HarvestTree != null
endfunction

private function OnHarvestPhase takes nothing returns nothing
    if not FuelIsDelivered() or not DialogInteraction_IsUnitAlive(Quinx) then
        set HarvestWorking = false
        set HarvestTree = null
        return
    endif
    if HarvestWorking then
        call IssueImmediateOrder(Quinx, "stop")
        set HarvestWorking = false
        set HarvestTree = null
        call TimerStart(HarvestTimer, HARVEST_PAUSE_DURATION, false, function OnHarvestPhase)
    elseif IssueNearbyHarvestOrder() then
        set HarvestWorking = true
        call TimerStart(HarvestTimer, HARVEST_WORK_DURATION, false, function OnHarvestPhase)
    else
        call IssueImmediateOrder(Quinx, "stop")
        call TimerStart(HarvestTimer, HARVEST_RETRY_DURATION, false, function OnHarvestPhase)
    endif
endfunction

private function ScheduleHarvesting takes real delay returns nothing
    if FuelIsDelivered() and DialogInteraction_IsUnitAlive(Quinx) then
        set HarvestWorking = false
        set HarvestTree = null
        call TimerStart(HarvestTimer, delay, false, function OnHarvestPhase)
    endif
endfunction

private function PauseHarvesting takes nothing returns nothing
    call PauseTimer(HarvestTimer)
    set HarvestWorking = false
    set HarvestTree = null
    if DialogInteraction_IsUnitAlive(Quinx) then
        call IssueImmediateOrder(Quinx, "stop")
    endif
endfunction

private function StartExitFadeOut takes nothing returns nothing
    local unit hero = SelectedHero
    set SelectedHero = null
    call DialogInteraction_StartConfiguredDialogExitTransition(Quinx, hero, QuinxDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
    call ScheduleHarvesting(DIALOG_COOLDOWN)
    set hero = null
endfunction

private function OnAcceptQuestEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_SHREDDER_FUEL, Quinx)
    call StartExitFadeOut()
endfunction

private function OnAcceptQuest takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Quinx, QUINX_NAME)
    call DialogSystem_AddLineNoSound(seq, Quinx, QUINX_NAME, "Shredder's dry as a banker's heart. Bring me one canister of Goblin Rocket Fuel. The specialist goblin merchants should have some.")
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuestEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Quinx)
endfunction

private function OnCompleteQuestEnd takes nothing returns nothing
    local QuestData q = GetFuelQuest()
    if q != 0 and q.active and not q.completed and HeroItemCheckBothAndRemove(ITEM_GOBLIN_ROCKET_FUEL, 1) then
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_SHREDDER_FUEL, Quinx)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteQuest takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Quinx, QUINX_NAME)
    call DialogSystem_AddLineNoSound(seq, Quinx, QUINX_NAME, "That's proper rocket fuel! Stand back - the shredder's got a lot of missed work to catch up on.")
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuestEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Quinx)
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Quinx, QUINX_NAME)
    call DialogSystem_AddLineNoSound(seq, Quinx, QUINX_NAME, "Keep your sparks dry.")
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Quinx)
endfunction

private function BuildDialog takes nothing returns nothing
    local button b
    if QuinxDialog == null then
        set QuinxDialog = DialogSystem_CreateDialog(QUINX_NAME)
    endif
    call QuestGiver_RefreshAvailabilityForGiver(Quinx)
    call DialogSystem_ClearDialog(QuinxDialog)
    call DialogSystem_SetTitle(QuinxDialog, QUINX_NAME)
    call QuestGiver_AddAvailableQuestAcceptButton(QuinxDialog, QUEST_SHREDDER_FUEL, Quinx, 1, function OnAcceptQuest, true, false)
    call QuestGiver_AddReadyQuestCompleteButton(QuinxDialog, QUEST_SHREDDER_FUEL, Quinx, 2, function OnCompleteQuest, true)
    set b = DialogSystem_AddFarewellButton(QuinxDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
endfunction

private function PlayDialogGreeting takes nothing returns nothing
    local QuestData q = GetFuelQuest()
    local integer seq = DialogInteraction_CreateBaseSequence(Quinx, QUINX_NAME)

    if not DialogInteraction_IsFirstGreetDone(Quinx) then
        call DialogSystem_AddLineNoSound(seq, Quinx, QUINX_NAME, "Easy there! Quinx is the name. I'd be clearing these trees already if my shredder hadn't run bone dry.")
        call DialogInteraction_PlayFirstGreetSequenceEx(Quinx, Player(0), QuinxDialog, seq, CINEMATIC)
    else
        if q != 0 and q.completed then
            call DialogSystem_AddLineNoSound(seq, Quinx, QUINX_NAME, "Hear that engine purr? Best sound in the forest!")
        elseif q != 0 and q.state == QUEST_STATE_READY_TURNIN then
            call DialogSystem_AddLineNoSound(seq, Quinx, QUINX_NAME, "You found the rocket fuel? Hand it over!")
        elseif q != 0 and q.active then
            call DialogSystem_AddLineNoSound(seq, Quinx, QUINX_NAME, "No fuel, no chopping. Try a goblin who deals in explosives and reagents.")
        else
            call DialogSystem_AddLineNoSound(seq, Quinx, QUINX_NAME, "A shredder without fuel is just an expensive chair.")
        endif
        call DialogInteraction_PlayGreetSequenceEx(seq, Quinx, Player(0), QuinxDialog, CINEMATIC)
    endif
    set q = 0
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Quinx) then
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
    if not DialogInteraction_IsUnitAlive(Quinx) then
        return
    endif
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Quinx, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Quinx, SelectedHero, DIALOG_RANGE, QuinxDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif
    call PauseHarvesting()
    call DialogInteraction_StartConfiguredDialogEntryTransition(Quinx, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qQuinx_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string infoText = "|cffffcc00Quest giver:|r " + QUINX_NAME + "\n|cffffcc00Item source:|r Specialized goblin merchants\n"

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_SHREDDER_FUEL, Quinx) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_SHREDDER_FUEL, Quinx, "normal", 5, null, QUEST_SHREDDER_FUEL, "ReplaceableTextures\\CommandButtons\\BTNFuelCell.blp", "Quinx's shredder has run out of fuel. Buy Goblin Rocket Fuel from a specialized goblin merchant and bring it back to him.\n\n", infoText, "|cffffcc00Recommended level:|r 5\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", QUINX_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
        call QuestGiver_SetRequirements(q.id, "", "Bring Goblin Rocket Fuel to Quinx", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Quinx, 1, ITEM_GOBLIN_ROCKET_FUEL, 1)
    endif
    set q = 0
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()
    if Quinx == null then
        if not QuinxInitWaitingLogged then
            call DebugMsg("Waiting for udg_Quinx.")
            set QuinxInitWaitingLogged = true
        endif
        call TimerStart(QuinxInitTimer, 0.50, false, function InitDelayed)
        return
    endif
    call QuestGiver_Register(Quinx)
    call DialogInteraction_ConfigureDialogTransition(Quinx, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call CreateQuests()
    call DialogInteraction_RegisterSelectionHandler(Quinx, function OnSelected)
    call QuestGiver_RefreshAvailabilityForGiver(Quinx)
    call ScheduleHarvesting(0.00)
    call DestroyTimer(QuinxInitTimer)
    set QuinxInitTimer = null
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set QuinxDialogCooldown = CreateTimer()
    set QuinxInitTimer = CreateTimer()
    set HarvestTimer = CreateTimer()
    set HarvestScanRect = Rect(0.00, 0.00, 0.00, 0.00)
    call TimerStart(QuinxInitTimer, 0.00, false, function InitDelayed)
endfunction

public function IsFuelDelivered takes nothing returns boolean
    return FuelIsDelivered()
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if Quinx != null then
        call QuestGiver_RefreshAvailabilityForGiver(Quinx)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Quinx != null then
        call QuestGiver_Register(Quinx)
        call DialogInteraction_ConfigureDialogTransition(Quinx, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Quinx, function OnSelected)
        call RefreshAvailability()
        call ScheduleHarvesting(0.00)
    endif
endfunction

endlibrary
