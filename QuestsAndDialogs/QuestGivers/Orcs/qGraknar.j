/**
    qGraknar

    Author: Valdemar
    Version:

    Description:
    Converts Graknar's legacy Mistaken Kin quest to the current quest and
    dialog systems. Graknar's custom dialog delegates bag trading to ShopUI.

    Credits:
    - Legacy GUI triggers in QuestsAndDialogs/OLDGUI/Graknar.

    How to install:
    Import after the required quest, dialog, follow, death-event, and vendor libraries.
    Disable the converted Graknar GUI trigger group and keep the Graknar,
    Nazgrek, KodoSpawn, and KodoEnd World Editor globals assigned.

    API:
    - call qGraknar_RefreshAvailability()
    - call qGraknar_RefreshRespawnedUnitHooks()

**/
library qGraknar initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, FollowSystem, UnitDeathEvent, VendorBags, VendorDialogs, Shop, ShopUI, VendorLines
    globals
        private constant boolean DEBUG = false

        public constant string QUEST_MISTAKEN_KIN = "Mistaken Kin"
        private constant string GRAKNAR_NAME = "Graknar"

        private constant integer UNIT_KODO = 'o008'
        private constant integer KODO_ESCORT_OWNER = 5

        private constant real DIALOG_RANGE = 500.00
        private constant real DIALOG_COOLDOWN = 6.00
        private constant real DIALOG_FADE_OUT = 1.00
        private constant real DIALOG_FADE_IN = 1.00
        private constant real KODO_FIND_RANGE = 500.00
        private constant real KODO_RETURN_RANGE = 500.00
        private constant real KODO_MONITOR_PERIOD = 0.25
        private constant real KODO_FOLLOW_MAX_DISTANCE = 800.00
        private constant real KODO_UNFOLLOW_DURATION = 5.00
        private constant real KODO_AMBUSH_RANGE = 2000.00
        private constant integer CINEMATIC_MOVE_MODE = 1
        private constant real CINEMATIC_MOVE_OFFSET = 256.00
        private constant real CINEMATIC_MOVE_ANGLE = 210.00

        private constant boolean ALLOW_NAZGREK = true
        private constant boolean ALLOW_ZULKIS = true
        private constant boolean END_ON_COMBAT = true
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

        private constant integer ACTION_ACCEPT = 1
        private constant integer ACTION_RETRY = 2
        private constant integer ACTION_COMPLETE = 3
        private constant integer ACTION_TRADE = 4

        private unit Graknar = null
        private unit Nazgrek = null
        private unit SelectedHero = null
        private unit Kodo = null
        private dialog GraknarDialog = null
        private timer GraknarDialogCooldown = null
        private timer KodoMonitorTimer = null
        private boolean KodoFound = false
        private boolean KodoReturned = false
        private boolean GraknarInitWaitingLogged = false
    endglobals

    private function DebugMsg takes string msg returns nothing
        if DEBUG then
            call BJDebugMsg("|cff88ccff[qGraknar]|r " + msg)
        endif
    endfunction

    private function SyncUnitReferences takes nothing returns nothing
        if udg_Graknar != null and udg_Graknar != Graknar then
            set Graknar = udg_Graknar
        endif
        if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
            set Nazgrek = udg_Nazgrek
        endif
    endfunction

    private function IsWithinRange takes unit a, unit b, real range returns boolean
        local real dx
        local real dy

        if a == null or b == null then
            set a = null
            set b = null
            return false
        endif
        set dx = GetUnitX(a) - GetUnitX(b)
        set dy = GetUnitY(a) - GetUnitY(b)
        set a = null
        set b = null
        return dx * dx + dy * dy <= range * range
    endfunction

    private function ResolveDialogHero takes nothing returns unit
        call SyncUnitReferences()
        return DialogInteraction_ResolveDialogHero(SelectedHero, Graknar, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    endfunction

    private function GetMistakenKinQuest takes nothing returns QuestData
        call SyncUnitReferences()
        if Graknar == null then
            return 0
        endif
        return QuestGiver_GetByNameAndGiver(QUEST_MISTAKEN_KIN, Graknar)
    endfunction

    private function StopKodoFollowing takes nothing returns nothing
        if Kodo != null and FollowSystem_IsFollowing(Kodo) then
            call FollowSystem_RemoveUnit(Kodo)
        endif
    endfunction

    private function RemoveQuestKodo takes nothing returns nothing
        call StopKodoFollowing()
        if Kodo != null then
            if udg_KodoGrak == Kodo then
                set udg_KodoGrak = null
            endif
            call RemoveUnit(Kodo)
            set Kodo = null
        endif
    endfunction

    private function CleanupKodoRuntime takes boolean removeKodo returns nothing
        call PauseTimer(KodoMonitorTimer)
        if removeKodo then
            call RemoveQuestKodo()
        else
            call StopKodoFollowing()
        endif
        set KodoFound = false
        set KodoReturned = false
    endfunction

    private function ResetQuestRequirements takes QuestData q returns nothing
        if q == 0 then
            return
        endif
        call q.removeReturnRequirement()
        call q.updateRequirementText(1, "Find Graknar's lost Kodo")
        call q.markRequirementCompleted(1, false)
        call q.updateRequirementText(2, "Escort the Kodo to Graknar")
        call q.markRequirementCompleted(2, false)
        call q.refreshQuestLog()
    endfunction

    private function AggroNearbyHostiles takes unit hero returns nothing
        local group nearby = CreateGroup()
        local unit target

        if hero == null then
            call DestroyGroup(nearby)
            set nearby = null
            set target = null
            set hero = null
            return
        endif
        call GroupEnumUnitsInRange(nearby, GetUnitX(hero), GetUnitY(hero), KODO_AMBUSH_RANGE, null)
        loop
            set target = FirstOfGroup(nearby)
            exitwhen target == null
            call GroupRemoveUnit(nearby, target)
            if DialogInteraction_IsUnitAlive(target) and GetOwningPlayer(target) == Player(PLAYER_NEUTRAL_AGGRESSIVE) then
                call IssueTargetOrder(target, "attack", hero)
            endif
        endloop
        call DestroyGroup(nearby)
        set nearby = null
        set target = null
        set hero = null
    endfunction

    private function GetHeroNearKodo takes nothing returns unit
        if ALLOW_NAZGREK and DialogInteraction_IsUnitAlive(Nazgrek) and IsWithinRange(Nazgrek, Kodo, KODO_FIND_RANGE) then
            return Nazgrek
        endif
        if ALLOW_ZULKIS and DialogInteraction_IsUnitAlive(udg_Zulkis) and IsWithinRange(udg_Zulkis, Kodo, KODO_FIND_RANGE) then
            return udg_Zulkis
        endif
        return null
    endfunction

    private function MarkKodoFound takes QuestData q, unit hero returns nothing
        set KodoFound = true
        call q.markRequirementCompleted(1, true)
        call q.refreshQuestLog()
        call QuestMessageBJ(bj_FORCE_ALL_PLAYERS, bj_QUESTMESSAGE_UPDATED, "|cffffcc00QUEST UPDATED|r\n" + QUEST_MISTAKEN_KIN + "\n\n- Escort the Kodo to Graknar")
        call SetUnitOwner(Kodo, Player(KODO_ESCORT_OWNER), true)
        call SetUnitCreepGuard(Kodo, false)
        call FollowSystem_SetFollow(Kodo, hero, KODO_FOLLOW_MAX_DISTANCE, true, KODO_UNFOLLOW_DURATION, FOLLOW_STYLE_PASSIVE, true, true)
        call AggroNearbyHostiles(hero)
        set hero = null
    endfunction

    private function MarkKodoReturned takes QuestData q returns nothing
        set KodoReturned = true
        call StopKodoFollowing()
        call q.markRequirementCompleted(2, true)
        call q.setState(QUEST_STATE_READY_TURNIN)
        call q.addReturnRequirement()
        call IssuePointOrder(Kodo, "move", GetRectCenterX(gg_rct_KodoEnd), GetRectCenterY(gg_rct_KodoEnd))
    endfunction

    private function OnKodoMonitor takes nothing returns nothing
        local QuestData q = GetMistakenKinQuest()
        local unit hero

        if q == 0 or q.completed or q.failed then
            call PauseTimer(KodoMonitorTimer)
        elseif not q.active then
            call CleanupKodoRuntime(true)
            call ResetQuestRequirements(q)
            call q.setDiscovered(false)
            call QuestGiver_RefreshAvailabilityForGiver(Graknar)
        elseif not DialogInteraction_IsUnitAlive(Kodo) then
            call PauseTimer(KodoMonitorTimer)
        elseif KodoReturned then
            if RectContainsUnit(gg_rct_KodoEnd, Kodo) then
                call SetUnitFacingTimed(Kodo, 275.00, 0.50)
                call PauseTimer(KodoMonitorTimer)
            endif
        elseif not KodoFound then
            set hero = GetHeroNearKodo()
            if hero != null then
                call MarkKodoFound(q, hero)
            endif
        elseif IsWithinRange(Kodo, Graknar, KODO_RETURN_RANGE) then
            call MarkKodoReturned(q)
        endif

        set hero = null
        set q = 0
    endfunction

    private function OnAnyUnitDeath takes nothing returns nothing
        local unit dyingUnit = GetTriggerUnit()
        local QuestData q = GetMistakenKinQuest()

        if dyingUnit == Kodo and q != 0 and q.active and not q.completed then
            call QuestGiver_FailQuestByNameAndGiver(QUEST_MISTAKEN_KIN, Graknar, "Graknar's Kodo was slain.")
            call ResetQuestRequirements(q)
            call CleanupKodoRuntime(false)
            call QuestGiver_RefreshAvailabilityForGiver(Graknar)
        endif
        set dyingUnit = null
        set q = 0
    endfunction

    private function SpawnQuestKodo takes nothing returns nothing
        call CleanupKodoRuntime(true)
        set Kodo = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_KODO, GetRectCenterX(gg_rct_KodoSpawn), GetRectCenterY(gg_rct_KodoSpawn), bj_UNIT_FACING)
        set udg_KodoGrak = Kodo
        call SetUnitCreepGuard(Kodo, false)
        call TimerStart(KodoMonitorTimer, KODO_MONITOR_PERIOD, true, function OnKodoMonitor)
    endfunction

    private function StartExitFadeOut takes nothing returns nothing
        call DialogInteraction_EndCombatSensitiveInteraction()
        call DialogInteraction_StartConfiguredDialogExitTransition(Graknar, SelectedHero, GraknarDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
    endfunction

    private function InterruptDialog takes nothing returns nothing
        local unit hero = SelectedHero

        call DialogInteraction_EndCombatSensitiveInteraction()
        call DialogSystem_CancelActiveSpeech()
        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(GraknarDialog, Player(0))
        call DialogSystem_StopDialogCamera(Player(0), 0.75, USE_DIALOG_CAMERA)
        call TriggerExecute(gg_trg_Cinematic_OFF)
        call DialogInteraction_EndCinematicSequence(CINEMATIC)
        set GraknarDialogCooldown = DialogInteraction_StartCooldown(GraknarDialogCooldown, DIALOG_COOLDOWN)
        if hero != null and DialogInteraction_IsUnitAlive(hero) then
            call ShowUnit(hero, true)
            call PauseUnit(hero, false)
            call SelectUnitForPlayerSingle(hero, Player(0))
        endif
        set SelectedHero = null
        set hero = null
    endfunction

    private function OnAcceptEnd takes nothing returns nothing
        local QuestData q = GetMistakenKinQuest()

        if q != 0 and not q.active and not q.completed then
            call ResetQuestRequirements(q)
            call QuestGiver_AcceptQuestByNameAndGiver(QUEST_MISTAKEN_KIN, Graknar)
            call SpawnQuestKodo()
        endif
        call StartExitFadeOut()
        set q = 0
    endfunction

    private function OnAccept takes nothing returns nothing
        local unit hero = ResolveDialogHero()
        local integer seq

        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Graknar, GRAKNAR_NAME)
        call DialogSystem_AddMakeFaceEachOther(seq, Graknar, hero, 0.50, 0.00)
        call DialogSystem_AddLineNoSound(seq, Graknar, GRAKNAR_NAME, "Graknar lost Kodo near the salamanders. Find Kodo. Bring Kodo back.")
        call DialogSystem_AddLineNoSound(seq, hero, DialogInteraction_GetHeroName(hero), "I will bring it home.")
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Graknar)
        set hero = null
    endfunction

    private function OnRetryEnd takes nothing returns nothing
        local QuestData q = GetMistakenKinQuest()

        if q != 0 and q.failed and not q.completed then
            call q.resetAfterFail()
            call ResetQuestRequirements(q)
            call QuestGiver_AcceptQuestByNameAndGiver(QUEST_MISTAKEN_KIN, Graknar)
            call SpawnQuestKodo()
        endif
        call StartExitFadeOut()
        set q = 0
    endfunction

    private function OnRetry takes nothing returns nothing
        local unit hero = ResolveDialogHero()
        local integer seq

        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Graknar, GRAKNAR_NAME)
        call DialogSystem_AddMakeFaceEachOther(seq, Graknar, hero, 0.50, 0.00)
        call DialogSystem_AddLineNoSound(seq, Graknar, GRAKNAR_NAME, "Kodo gone, but Graknar knows where another wandered. Try again.")
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnRetryEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Graknar)
        set hero = null
    endfunction

    private function OnCompleteEnd takes nothing returns nothing
        local QuestData q = GetMistakenKinQuest()

        if q != 0 and q.active and q.state == QUEST_STATE_READY_TURNIN then
            call CleanupKodoRuntime(false)
            call QuestGiver_CompleteQuestByNameAndGiver(QUEST_MISTAKEN_KIN, Graknar)
        endif
        call StartExitFadeOut()
        set q = 0
    endfunction

    private function OnComplete takes nothing returns nothing
        local unit hero = ResolveDialogHero()
        local integer seq

        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Graknar, GRAKNAR_NAME)
        call DialogSystem_AddMakeFaceEachOther(seq, Graknar, hero, 0.50, 0.00)
        call DialogSystem_AddLineNoSound(seq, Graknar, GRAKNAR_NAME, "Kodo back. Good. Graknar carries bags again.")
        call DialogSystem_AddLineNoSound(seq, hero, DialogInteraction_GetHeroName(hero), "Keep a closer eye on it this time.")
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Graknar)
        set hero = null
    endfunction

    private function OpenTrade takes nothing returns nothing
        local unit hero = ResolveDialogHero()

        call VendorBags_RegisterUnit(Graknar)
        if hero == null or Shop_GetVendorIdForUnit(Graknar) != VendorBags_GetVendorId() or not Shop_CanPlayerTradeWithVendor(GetOwningPlayer(hero), Graknar) then
            set hero = null
            call StartExitFadeOut()
            return
        endif
        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(GraknarDialog, Player(0))
        call VendorLines_PlayTradeLine(Graknar)
        call ShowUnit(hero, true)
        set GraknarDialogCooldown = DialogInteraction_StartCooldown(GraknarDialogCooldown, DIALOG_COOLDOWN)
        call ShopUI_ShowForVendorWithReturnAndInterrupt(Graknar, hero, END_ON_COMBAT, function InterruptDialog)
        set hero = null
    endfunction

    private function OnTrade takes nothing returns nothing
        call OpenTrade()
    endfunction

    private function EndVendorDialog takes nothing returns nothing
        local unit hero = SelectedHero

        call DialogInteraction_EndCombatSensitiveInteraction()
        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(GraknarDialog, Player(0))
        call DialogSystem_StopDialogCamera(Player(0), 0.75, USE_DIALOG_CAMERA)
        call TriggerExecute(gg_trg_Cinematic_OFF)
        call DialogInteraction_EndCinematicSequence(CINEMATIC)
        set GraknarDialogCooldown = DialogInteraction_StartCooldown(GraknarDialogCooldown, DIALOG_COOLDOWN)
        if hero != null and DialogInteraction_IsUnitAlive(hero) then
            call ShowUnit(hero, true)
            call PauseUnit(hero, false)
            call SelectUnitForPlayerSingle(hero, Player(0))
        endif
        set SelectedHero = null
        set hero = null
    endfunction

    private function OnFarewell takes nothing returns nothing
        local unit vendor = Graknar

        call EndVendorDialog()
        call VendorLines_PlayFarewellLine(vendor)
        set vendor = null
    endfunction

    private function BuildDialog takes nothing returns nothing
        local button b

        if GraknarDialog == null then
            set GraknarDialog = DialogSystem_CreateDialog(GRAKNAR_NAME)
        endif
        call QuestGiver_RefreshAvailabilityForGiver(Graknar)
        call DialogSystem_ClearDialog(GraknarDialog)
        call DialogSystem_SetTitle(GraknarDialog, GRAKNAR_NAME)
        call QuestGiver_AddAvailableQuestAcceptButton(GraknarDialog, QUEST_MISTAKEN_KIN, Graknar, ACTION_ACCEPT, function OnAccept, true, false)
        call QuestGiver_AddFailedQuestButton(GraknarDialog, QUEST_MISTAKEN_KIN, Graknar, ACTION_RETRY, function OnRetry)
        call QuestGiver_AddReadyQuestCompleteButton(GraknarDialog, QUEST_MISTAKEN_KIN, Graknar, ACTION_COMPLETE, function OnComplete, false)
        set b = DialogSystem_AddButtonTrade(GraknarDialog, ACTION_TRADE)
        call DialogSystem_BindButtonCode(b, function OnTrade)
        set b = DialogSystem_AddFarewellButton(GraknarDialog)
        call DialogSystem_BindButtonCode(b, function OnFarewell)
        set b = null
    endfunction

    private function AddPreDialogBark takes integer seq returns nothing
        local QuestData q = GetMistakenKinQuest()

        if q != 0 and q.failed then
            call DialogSystem_AddLineNoSound(seq, Graknar, GRAKNAR_NAME, "Kodo was lost. Graknar can show you where to search again.")
        elseif q != 0 and q.active and q.state == QUEST_STATE_READY_TURNIN then
            call DialogSystem_AddLineNoSound(seq, Graknar, GRAKNAR_NAME, "Kodo home! Graknar sees.")
        elseif q != 0 and q.active and KodoFound then
            call DialogSystem_AddLineNoSound(seq, Graknar, GRAKNAR_NAME, "Bring Kodo back. Kodo carries Graknar's best bags.")
        elseif q != 0 and q.active then
            call DialogSystem_AddLineNoSound(seq, Graknar, GRAKNAR_NAME, "Kodo still lost near salamanders.")
        elseif VendorLines_PickGreetLine(Graknar) then
            call DialogSystem_AddLine(seq, Graknar, VendorLines_GetVendorSpeakerName(Graknar), DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
        else
            call DialogSystem_AddLineNoSound(seq, Graknar, GRAKNAR_NAME, "Strong bags. Strong price.")
        endif
        set q = 0
    endfunction

    private function ContinueToDialogInternal takes nothing returns nothing
        local unit hero = ResolveDialogHero()
        local integer seq

        if hero == null or not DialogInteraction_IsUnitAlive(Graknar) then
            set hero = null
            call StartExitFadeOut()
            return
        endif
        call BuildDialog()
        set seq = DialogInteraction_CreateGreetSequenceBase(Graknar, GRAKNAR_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, true)
        call AddPreDialogBark(seq)
        call DialogInteraction_PlayGreetSequenceEx(seq, Graknar, Player(0), GraknarDialog, CINEMATIC)
        set hero = null
    endfunction

    public function ContinueToDialogAfterSelection takes nothing returns nothing
        call ContinueToDialogInternal()
    endfunction

    private function OnSelected takes nothing returns nothing
        call SyncUnitReferences()
        if not DialogInteraction_IsUnitAlive(Graknar) then
            return
        endif
        set SelectedHero = DialogInteraction_GetDialogSelectionHero(Graknar, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
        if not DialogInteraction_PassDialogSelectionGate(Graknar, SelectedHero, DIALOG_RANGE, GraknarDialogCooldown, true, true, true, true, false, true) then
            call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
            set SelectedHero = null
            return
        endif
        if not DialogInteraction_BeginCombatSensitiveInteractionEx(Graknar, SelectedHero, function InterruptDialog, END_ON_COMBAT) then
            set SelectedHero = null
            return
        endif
        call DialogInteraction_StartConfiguredDialogEntryTransition(Graknar, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qGraknar_ContinueToDialogAfterSelection")
    endfunction

    private function ReturnFromTrade takes nothing returns boolean
        local unit vendor = ShopUI_GetVendorUnit()
        local unit hero = ShopUI_GetBuyerUnit()

        if vendor != Graknar or hero == null or not DialogInteraction_IsUnitAlive(vendor) or not DialogInteraction_IsUnitAlive(hero) then
            set vendor = null
            set hero = null
            return false
        endif
        set SelectedHero = hero
        if not DialogInteraction_BeginCombatSensitiveInteractionEx(vendor, hero, function InterruptDialog, END_ON_COMBAT) then
            set SelectedHero = null
            set vendor = null
            set hero = null
            return false
        endif
        call PauseUnit(hero, true)
        call BuildDialog()
        call DialogSystem_SetContext(vendor, GetOwningPlayer(hero))
        call DialogSystem_SetEscapeAction(function EndVendorDialog)
        call DialogSystem_ShowDialog(GraknarDialog, GetOwningPlayer(hero))
        set vendor = null
        set hero = null
        return true
    endfunction

    private function CreateQuests takes nothing returns nothing
        local QuestData q
        local string infoText = "|cffffcc00Quest giver:|r " + GRAKNAR_NAME + "\n"

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_MISTAKEN_KIN, Graknar) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_MISTAKEN_KIN, Graknar, "normal", 2, null, QUEST_MISTAKEN_KIN, "ReplaceableTextures\\CommandButtons\\BTNKotoBeast.blp", "Recover Graknar's lost Kodo and escort it safely home.\n\n", infoText, "|cffffcc00Recommended level:|r 2\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", GRAKNAR_NAME)
            call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, true, 100, false)
            call QuestGiver_SetRequirements(q.id, "", "Find Graknar's lost Kodo", "Escort the Kodo to Graknar", "", "", "", "", "", "")
        endif
        set q = 0
    endfunction

    private function ConfigureGraknar takes nothing returns nothing
        call VendorBags_RegisterUnit(Graknar)
        call ShopUI_RegisterVendorReturnHandler(Graknar, function ReturnFromTrade)
        call VendorDialogs_RegisterCustomVendor(Graknar, function ReturnFromTrade)
        call QuestGiver_Register(Graknar)
        call DialogInteraction_ConfigureDialogTransition(Graknar, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_SetGreetOrder(Graknar, DIALOGINTERACTION_GREET_NONE)
        call DialogInteraction_RegisterSelectionHandler(Graknar, function OnSelected)
    endfunction

    private function RestoreActiveQuestRuntime takes nothing returns nothing
        local QuestData q = GetMistakenKinQuest()

        if q != 0 and q.active and not q.completed and not q.failed then
            call SpawnQuestKodo()
            if q.state == QUEST_STATE_READY_TURNIN then
                set KodoFound = true
                set KodoReturned = true
                call SetUnitOwner(Kodo, Player(KODO_ESCORT_OWNER), true)
                call SetUnitPosition(Kodo, GetRectCenterX(gg_rct_KodoEnd), GetRectCenterY(gg_rct_KodoEnd))
                call SetUnitFacing(Kodo, 275.00)
                call PauseTimer(KodoMonitorTimer)
            elseif q.req1Completed and DialogInteraction_IsUnitAlive(Nazgrek) then
                set KodoFound = true
                call SetUnitOwner(Kodo, Player(KODO_ESCORT_OWNER), true)
                call FollowSystem_SetFollow(Kodo, Nazgrek, KODO_FOLLOW_MAX_DISTANCE, true, KODO_UNFOLLOW_DURATION, FOLLOW_STYLE_PASSIVE, true, true)
            endif
        endif
        set q = 0
    endfunction

    private function InitDelayed takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()

        call SyncUnitReferences()
        if Graknar == null or Nazgrek == null then
            if not GraknarInitWaitingLogged then
                call DebugMsg("Waiting for Graknar and Nazgrek.")
                set GraknarInitWaitingLogged = true
            endif
            call TimerStart(initTimer, 0.50, false, function InitDelayed)
            set initTimer = null
            return
        endif
        call ConfigureGraknar()
        call CreateQuests()
        call UnitDeathEvent_Register(function OnAnyUnitDeath)
        call QuestGiver_RefreshAvailabilityForGiver(Graknar)
        call RestoreActiveQuestRuntime()
        call DebugMsg("Initialized.")
        call DestroyTimer(initTimer)
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        set GraknarDialogCooldown = CreateTimer()
        set KodoMonitorTimer = CreateTimer()
        call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
    endfunction

    public function RefreshAvailability takes nothing returns nothing
        call SyncUnitReferences()
        if Graknar != null then
            call QuestGiver_RefreshAvailabilityForGiver(Graknar)
        endif
    endfunction

    public function RefreshRespawnedUnitHooks takes nothing returns nothing
        call SyncUnitReferences()
        if Graknar != null then
            call ConfigureGraknar()
            call RefreshAvailability()
        endif
    endfunction
endlibrary
