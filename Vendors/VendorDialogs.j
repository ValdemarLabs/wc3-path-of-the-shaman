/**
    VendorDialogs

    Author: Valdemar
    Version:

    Description:
    Selectable-NPC dialogue entry for PotS shop vendors. Registered vendor
    units greet the player, offer a Trade button, and open ShopUI for the
    selected hero.

    Credits:

    How to install:
    Import after DialogInteraction, DialogCamera, DialogSystem, Shop, ShopUI,
    VendorCatalogs, every imported VendorFactions library, VendorLines,
    Reputation, Interface, Table, and optional QuestsVendor.

    API:
    - call VendorDialogs_RegisterVendor(vendor)
    - call VendorDialogs_RegisterCustomVendor(vendor, returnHandler)
    - call VendorDialogs_RegisterExistingVendors()
    - ShopUI's close button returns to the active vendor dialogue.
    - set vendor = VendorDialogs_GetSelectedVendor()
    - set hero = VendorDialogs_GetSelectedHero()

**/
library VendorDialogs initializer Init requires Table, DialogInteraction, DialogCamera, DialogSystem, Shop, ShopUI, VendorCatalogs, VendorOrcs, VendorSatyrs, VendorHumans, VendorGoblins, VendorBonecrusherOgres, VendorElarindor, VendorTauren, VendorDwarves, VendorTrolls, VendorLines, Reputation, Interface, optional QuestsVendor, optional Events, optional UnitDeathEvent
    globals
        private constant real VDI_DIALOG_RANGE = 900.00
        private constant real VDI_DIALOG_COOLDOWN = 3.00
        private constant boolean VDI_ALLOW_NAZGREK = true
        private constant boolean VDI_ALLOW_ZULKIS = true
        private constant boolean VDI_REQUIRE_DIALOG_HERO = true
        private constant boolean VDI_USE_DIALOG_CAMERA = true
        private constant boolean VDI_CINEMATIC = true
        private constant integer VDI_CINEMATIC_MOVE_MODE = 1
        private constant real VDI_CINEMATIC_MOVE_OFFSET = 256.00
        private constant real VDI_CINEMATIC_MOVE_ANGLE = 210.00
        private constant real VDI_CAMERA_DIST = 850.00
        private constant real VDI_CAMERA_Z_OFFSET = 90.00
        private constant real VDI_CAMERA_ANGLE = 328.00
        private constant real VDI_CAMERA_ROT_OFFSET = 180.00
        private constant real VDI_CAMERA_FAR_Z = 10000.00
        private constant real VDI_CAMERA_FOV = 60.00
        private constant real VDI_CAMERA_BLOCK_RADIUS = 180.00
        private constant boolean VDI_CAMERA_BLOCK_CHECK = true
        private constant real VDI_CAMERA_CHANGE_MIN_INTERVAL = 16.00
        private constant real VDI_CAMERA_CHANGE_MAX_INTERVAL = 26.00
        private constant real VDI_CAMERA_RESET_TIME = 0.75

        private constant integer VDI_ACTION_TRADE = 1
        private constant integer VDI_ACTION_FAREWELL = 2

        private dialog VDI_Dialog = null
        private timer VDI_DialogCooldown = null
        private Table VDI_RegisteredVendor = 0
        private Table VDI_CustomDialogVendor = 0
        private Table VDI_CustomReturnHandler = 0
        private trigger VDI_AttackTrigger = null
        private trigger VDI_DeathTrigger = null

        private unit VDI_SelectedVendor = null
        private unit VDI_SelectedHero = null
    endglobals

    private function VDI_IsSelectedContextValid takes nothing returns boolean
        return VDI_SelectedVendor != null and VDI_SelectedHero != null and DialogInteraction_IsUnitAlive(VDI_SelectedVendor) and DialogInteraction_IsUnitAlive(VDI_SelectedHero) and Shop_GetVendorIdForUnit(VDI_SelectedVendor) > 0
    endfunction

    private function VDI_IsSelectedContextUnit takes unit whichUnit returns boolean
        return whichUnit != null and (whichUnit == VDI_SelectedVendor or whichUnit == VDI_SelectedHero)
    endfunction

    private function VDI_ReportSelectionFailure takes unit vendor returns nothing
        local string reason = DialogInteraction_GetLastSelectionBlockReason()
        local string vendorName = VendorLines_GetVendorName(vendor)
        local string message = ""

        if reason == "missing allowed hero" then
            set message = "No player hero found near the " + vendorName + "."
        elseif reason == "hero out of range" then
            set message = "Move closer to the " + vendorName + "."
        elseif reason == "dialog sequence active" then
            set message = "Finish the current conversation first."
        elseif reason == "dialog interaction reserved" then
            set message = "Another interaction is still finishing."
        elseif reason == "cooldown active" then
            set message = "Wait a moment before speaking with this vendor again."
        elseif reason == "hero is casting" or reason == "hero is in combat" then
            set message = "Your hero is currently too busy to trade."
        elseif reason == "npc is casting" or reason == "npc is in combat" then
            set message = "This vendor is currently too busy to trade."
        else
            set message = "This vendor cannot start a trade conversation right now."
        endif

        if message != "" then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080" + message + "|r")
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
        endif

        set vendor = null
    endfunction

    private function VDI_GetHeroCameraRotationOffset takes unit vendor, unit hero returns real
        local real dx
        local real dy

        if vendor == null or hero == null then
            return VDI_CAMERA_ROT_OFFSET
        endif

        set dx = GetUnitX(hero) - GetUnitX(vendor)
        set dy = GetUnitY(hero) - GetUnitY(vendor)
        if dx * dx + dy * dy < 1.00 then
            return VDI_CAMERA_ROT_OFFSET
        endif

        return (Atan2(dy, dx) * bj_RADTODEG + 180.00) - GetUnitFacing(vendor)
    endfunction

    private function VDI_ReportReputationFailure takes unit vendor, unit hero returns nothing
        local player p = Player(0)
        local string factionName = Reputation_GetUnitFactionName(vendor)

        if hero != null then
            set p = GetOwningPlayer(hero)
        endif
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, p)
        if factionName == "" then
            call DisplayTextToPlayer(p, 0.00, 0.00, "|cffff8040Your reputation with this vendor's faction is too low to trade.|r")
        else
            call DisplayTextToPlayer(p, 0.00, 0.00, "|cffff8040Your reputation with " + factionName + " is too low to trade.|r")
        endif

        set p = null
        set vendor = null
        set hero = null
    endfunction

    private function VDI_ConfigureVendorCamera takes unit vendor, unit hero returns nothing
        if vendor == null then
            return
        endif

        call DialogInteraction_ConfigureDialogTransition(vendor, VDI_CINEMATIC_MOVE_MODE, VDI_CINEMATIC_MOVE_OFFSET, VDI_CINEMATIC_MOVE_ANGLE, VDI_CAMERA_DIST, VDI_CAMERA_Z_OFFSET, VDI_CAMERA_ANGLE, VDI_GetHeroCameraRotationOffset(vendor, hero), VDI_CAMERA_FAR_Z, VDI_CAMERA_FOV, VDI_CAMERA_BLOCK_RADIUS, VDI_CAMERA_BLOCK_CHECK)
    endfunction

    private function VDI_CreateGreetSequence takes unit vendor, unit hero returns integer
        local integer seq = DialogSystem_CreateSequence()
        local string vendorName = VendorLines_GetVendorName(vendor)
        local string speakerName = VendorLines_GetVendorSpeakerName(vendor)

        call DialogSystem_SetSequenceDefaultSpeaker(seq, vendor, speakerName)
        call DialogSystem_AddMakeFaceEachOther(seq, vendor, hero, 0.45, 0.00)

        call DialogSystem_PickGreetLine(vendor, vendorName)
        call DialogSystem_AddLine(seq, vendor, speakerName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)

        return seq
    endfunction

    private function VDI_EndDialog takes boolean startCooldown returns nothing
        local unit hero = VDI_SelectedHero

        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(VDI_Dialog, Player(0))
        call DialogSystem_StopDialogCamera(Player(0), VDI_CAMERA_RESET_TIME, VDI_USE_DIALOG_CAMERA)
        call DialogInteraction_EndCinematicSequence(VDI_CINEMATIC)

        if startCooldown then
            set VDI_DialogCooldown = DialogInteraction_StartCooldown(VDI_DialogCooldown, VDI_DIALOG_COOLDOWN)
        endif
        if hero != null and DialogInteraction_IsUnitAlive(hero) then
            call ShowUnit(hero, true)
            call PauseUnit(hero, false)
            call SelectUnitForPlayerSingle(hero, Player(0))
        endif

        set VDI_SelectedVendor = null
        set VDI_SelectedHero = null
        set hero = null
    endfunction

    private function VDI_OnTrade takes nothing returns nothing
        local unit vendor = VDI_SelectedVendor
        local unit hero = VDI_SelectedHero

        if not VDI_IsSelectedContextValid() then
            call VDI_EndDialog(true)
            set vendor = null
            set hero = null
            return
        endif
        if not Shop_CanPlayerTradeWithVendor(GetOwningPlayer(hero), vendor) then
            call VDI_ReportReputationFailure(vendor, hero)
            call VDI_EndDialog(true)
            set vendor = null
            set hero = null
            return
        endif

        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(VDI_Dialog, Player(0))
        call VendorLines_PlayTradeLine(vendor)
        call ShowUnit(hero, true)
        set VDI_DialogCooldown = DialogInteraction_StartCooldown(VDI_DialogCooldown, VDI_DIALOG_COOLDOWN)
        call ShopUI_ShowForVendorWithReturn(vendor, hero)
        set VDI_SelectedVendor = null
        set VDI_SelectedHero = null

        set vendor = null
        set hero = null
    endfunction

    private function VDI_InterruptDialog takes nothing returns nothing
        if VDI_SelectedVendor == null and VDI_SelectedHero == null then
            return
        endif

        call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080Trade interrupted.|r")
        call DialogSystem_CancelActiveSequence()
        static if LIBRARY_QuestsVendor then
            call QuestsVendor_CancelPendingAction()
        endif
        call VDI_EndDialog(true)
    endfunction

    private function VDI_AttackInterruptAction takes nothing returns nothing
        local unit target = null

        static if LIBRARY_Events then
            set target = Events_GetTriggerUnit()
        else
            set target = GetTriggerUnit()
        endif

        if VDI_IsSelectedContextUnit(target) then
            call VDI_InterruptDialog()
        endif

        set target = null
    endfunction

    private function VDI_GetDeathUnit takes nothing returns unit
        static if LIBRARY_UnitDeathEvent then
            return UnitDeathEvent_GetDyingUnit()
        else
            return GetDyingUnit()
        endif
    endfunction

    private function VDI_DeathInterruptAction takes nothing returns nothing
        local unit target = VDI_GetDeathUnit()

        if VDI_IsSelectedContextUnit(target) then
            call VDI_InterruptDialog()
        endif

        set target = null
    endfunction

    private function VDI_OnFarewell takes nothing returns nothing
        local unit vendor = VDI_SelectedVendor

        if not VDI_IsSelectedContextValid() then
            call VDI_EndDialog(true)
            set vendor = null
            return
        endif

        // Restore gameplay first, then play the farewell without keeping cinematic mode open.
        call VDI_EndDialog(true)
        call VendorLines_PlayFarewellLine(vendor)
        set vendor = null
    endfunction

    private function VDI_OnQuestSequenceEnd takes nothing returns nothing
        local boolean openTrade = false

        static if LIBRARY_QuestsVendor then
            call QuestsVendor_FinishPendingAction()
            set openTrade = QuestsVendor_ConsumeOpenTradeRequest()
        endif
        if openTrade then
            call VDI_OnTrade()
        else
            call VDI_EndDialog(true)
        endif
    endfunction

    private function VDI_OnQuest takes nothing returns nothing
        local integer seq = 0

        if not VDI_IsSelectedContextValid() then
            call VDI_EndDialog(true)
            return
        endif

        static if LIBRARY_QuestsVendor then
            set seq = QuestsVendor_BeginAction(DialogSystem_LastAction, VDI_SelectedVendor, VDI_SelectedHero)
        endif
        if seq > 0 then
            call DialogInteraction_BeginDialogSequence()
            call DialogSystem_SetSequenceCallbacks(seq, null, function VDI_OnQuestSequenceEnd)
            call DialogSystem_PlaySequence(seq, Player(0), VDI_SelectedVendor)
        else
            call VDI_EndDialog(true)
        endif
    endfunction

    private function VDI_BuildDialog takes nothing returns nothing
        local button b
        local string vendorName

        if VDI_SelectedVendor == null then
            set b = null
            return
        endif

        set vendorName = VendorLines_GetVendorSpeakerName(VDI_SelectedVendor)
        if VDI_Dialog == null then
            set VDI_Dialog = DialogSystem_CreateDialog(vendorName)
        endif

        call DialogSystem_ClearDialog(VDI_Dialog)
        call DialogSystem_SetTitle(VDI_Dialog, vendorName)

        static if LIBRARY_QuestsVendor then
            call QuestsVendor_AddDialogButtons(VDI_Dialog, VDI_SelectedVendor, function VDI_OnQuest)
        endif

        set b = DialogSystem_AddButtonTrade(VDI_Dialog, VDI_ACTION_TRADE)
        call DialogSystem_BindButtonCode(b, function VDI_OnTrade)

        set b = DialogSystem_AddButtonExit(VDI_Dialog, VDI_ACTION_FAREWELL)
        call DialogSystem_SetButtonInterfaceEvent(b, Interface_EVENT_DIALOG_BUTTON_CLOSE)
        call DialogSystem_BindButtonCode(b, function VDI_OnFarewell)

        set b = null
    endfunction

    private function VDI_ReturnFromTrade takes nothing returns boolean
        local unit vendor = ShopUI_GetVendorUnit()
        local unit hero = ShopUI_GetBuyerUnit()
        local trigger returnHandler
        local boolean handled

        if vendor == null or hero == null or not DialogInteraction_IsUnitAlive(vendor) or not DialogInteraction_IsUnitAlive(hero) or Shop_GetVendorIdForUnit(vendor) <= 0 then
            set vendor = null
            set hero = null
            set returnHandler = null
            return false
        endif
        if VDI_CustomDialogVendor.boolean[GetHandleId(vendor)] then
            set returnHandler = VDI_CustomReturnHandler.trigger[GetHandleId(vendor)]
            set handled = returnHandler != null and TriggerEvaluate(returnHandler)
            set vendor = null
            set hero = null
            set returnHandler = null
            return handled
        endif

        set VDI_SelectedVendor = vendor
        set VDI_SelectedHero = hero
        call PauseUnit(hero, true)
        call VDI_BuildDialog()
        call DialogSystem_SetContext(vendor, GetOwningPlayer(hero))
        call DialogSystem_ShowDialog(VDI_Dialog, GetOwningPlayer(hero))

        set vendor = null
        set hero = null
        set returnHandler = null
        return true
    endfunction

    private function VDI_ShowDialogForSelection takes nothing returns nothing
        local integer seq

        if not VDI_IsSelectedContextValid() then
            call VDI_EndDialog(false)
            return
        endif

        if VDI_USE_DIALOG_CAMERA then
            call DialogCameraStartRandomCycle(Player(0), VDI_SelectedVendor, VDI_GetHeroCameraRotationOffset(VDI_SelectedVendor, VDI_SelectedHero), VDI_CAMERA_CHANGE_MIN_INTERVAL, VDI_CAMERA_CHANGE_MAX_INTERVAL, false)
        endif
        call VDI_BuildDialog()
        set seq = VDI_CreateGreetSequence(VDI_SelectedVendor, VDI_SelectedHero)
        call DialogInteraction_PlayGreetSequenceEx(seq, VDI_SelectedVendor, Player(0), VDI_Dialog, VDI_CINEMATIC)
    endfunction

    public function ContinueToDialogAfterSelection takes nothing returns nothing
        call VDI_ShowDialogForSelection()
    endfunction

    public function RegisterVendor takes unit vendor returns nothing
        local integer handleId

        if vendor == null or not DialogInteraction_IsUnitAlive(vendor) or Shop_GetVendorIdForUnit(vendor) <= 0 then
            set vendor = null
            return
        endif

        set handleId = GetHandleId(vendor)
        if VDI_RegisteredVendor.boolean[handleId] then
            static if LIBRARY_QuestsVendor then
                call QuestsVendor_RegisterUnit(vendor)
            endif
            set vendor = null
            return
        endif

        set VDI_RegisteredVendor.boolean[handleId] = true
        call Shop_ApplyVendorUnitTypeName(vendor)
        call DialogInteraction_Register(vendor)
        call DialogInteraction_SetGreetOrder(vendor, DIALOGINTERACTION_GREET_NONE)
        static if LIBRARY_QuestsVendor then
            call QuestsVendor_RegisterUnit(vendor)
        endif

        set vendor = null
    endfunction

    public function RegisterCustomVendor takes unit vendor, code returnHandler returns nothing
        local integer handleId
        local trigger oldHandler
        local trigger newHandler

        if vendor == null then
            set vendor = null
            set oldHandler = null
            set newHandler = null
            return
        endif

        set handleId = GetHandleId(vendor)
        set VDI_CustomDialogVendor.boolean[handleId] = true
        if returnHandler != null then
            set oldHandler = VDI_CustomReturnHandler.trigger[handleId]
            if oldHandler != null then
                call DestroyTrigger(oldHandler)
            endif
            set newHandler = CreateTrigger()
            call TriggerAddCondition(newHandler, Filter(returnHandler))
            set VDI_CustomReturnHandler.trigger[handleId] = newHandler
        endif
        call VendorDialogs_RegisterVendor(vendor)
        set vendor = null
        set oldHandler = null
        set newHandler = null
    endfunction

    private function VDI_OnSelected takes nothing returns nothing
        local unit vendor = DialogInteraction_GetSelectedUnit()
        local unit hero
        local boolean gateOk
        local string canonicalName

        if vendor != null and VDI_CustomDialogVendor.boolean[GetHandleId(vendor)] then
            set vendor = null
            set hero = null
            return
        endif
        if vendor == null or Shop_GetVendorIdForUnit(vendor) <= 0 then
            if vendor != null then
                set canonicalName = Shop_GetVendorUnitTypeName(GetUnitTypeId(vendor))
                if canonicalName != null and canonicalName != "" then
                    call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff4040Vendor setup error: " + canonicalName + " has no registered catalog binding.|r")
                    call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
                endif
            endif
            set vendor = null
            set hero = null
            return
        endif

        call VendorDialogs_RegisterVendor(vendor)
        set hero = DialogInteraction_GetDialogSelectionHero(vendor, VDI_DIALOG_RANGE, VDI_ALLOW_NAZGREK, VDI_ALLOW_ZULKIS)
        // Reputation owns faction access; transient vendor combat/cast flags must not silently block shop dialogue.
        set gateOk = DialogInteraction_PassDialogSelectionGate(vendor, hero, VDI_DIALOG_RANGE, VDI_DialogCooldown, VDI_REQUIRE_DIALOG_HERO, true, false, false, false, false)
        if not gateOk then
            call VDI_ReportSelectionFailure(vendor)
            set vendor = null
            set hero = null
            return
        endif
        if not Shop_CanPlayerTradeWithVendor(GetOwningPlayer(hero), vendor) then
            call VDI_ReportReputationFailure(vendor, hero)
            set vendor = null
            set hero = null
            return
        endif
        set VDI_SelectedVendor = vendor
        set VDI_SelectedHero = hero
        call VDI_ConfigureVendorCamera(vendor, hero)
        call DialogInteraction_StartConfiguredDialogEntryTransition(vendor, hero, false, VDI_USE_DIALOG_CAMERA, VDI_CINEMATIC, "VendorDialogs_ContinueToDialogAfterSelection")

        set vendor = null
        set hero = null
    endfunction

    public function RegisterExistingVendors takes nothing returns nothing
        local group worldUnits = CreateGroup()
        local rect worldBounds = GetWorldBounds()
        local unit enumUnit

        call GroupEnumUnitsInRect(worldUnits, worldBounds, null)
        loop
            set enumUnit = FirstOfGroup(worldUnits)
            exitwhen enumUnit == null
            call GroupRemoveUnit(worldUnits, enumUnit)
            call VendorDialogs_RegisterVendor(enumUnit)
        endloop

        call DestroyGroup(worldUnits)
        call RemoveRect(worldBounds)
        set worldUnits = null
        set worldBounds = null
        set enumUnit = null
    endfunction

    public function GetSelectedVendor takes nothing returns unit
        return VDI_SelectedVendor
    endfunction

    public function GetSelectedHero takes nothing returns unit
        return VDI_SelectedHero
    endfunction

    private function VDI_OnUnitEnter takes nothing returns nothing
        call VendorDialogs_RegisterVendor(GetTriggerUnit())
    endfunction

    private function VDI_InitDelayed takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()

        call VendorDialogs_RegisterExistingVendors()
        static if LIBRARY_Events then
            call Events_RegisterUnitEnter(function VDI_OnUnitEnter)
        endif

        call DestroyTimer(expiredTimer)
        set expiredTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer

        set VDI_DialogCooldown = CreateTimer()
        set VDI_RegisteredVendor = Table.create()
        set VDI_CustomDialogVendor = Table.create()
        set VDI_CustomReturnHandler = Table.create()
        call ShopUI_RegisterReturnHandler(function VDI_ReturnFromTrade)
        call DialogInteraction_RegisterAnySelectionHandler(function VDI_OnSelected)
        static if LIBRARY_Events then
            call Events_RegisterUnitAttacked(function VDI_AttackInterruptAction)
        else
            set VDI_AttackTrigger = CreateTrigger()
            call TriggerRegisterAnyUnitEventBJ(VDI_AttackTrigger, EVENT_PLAYER_UNIT_ATTACKED)
            call TriggerAddAction(VDI_AttackTrigger, function VDI_AttackInterruptAction)
        endif
        static if LIBRARY_UnitDeathEvent then
            call UnitDeathEvent_Register(function VDI_DeathInterruptAction)
        else
            set VDI_DeathTrigger = CreateTrigger()
            call TriggerRegisterAnyUnitEventBJ(VDI_DeathTrigger, EVENT_PLAYER_UNIT_DEATH)
            call TriggerAddAction(VDI_DeathTrigger, function VDI_DeathInterruptAction)
        endif
        set initTimer = CreateTimer()
        call TimerStart(initTimer, 0.00, false, function VDI_InitDelayed)
        set initTimer = null
    endfunction
endlibrary
