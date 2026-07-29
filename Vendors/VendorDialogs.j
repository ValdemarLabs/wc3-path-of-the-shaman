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
    Import after DialogInteraction, DialogSystem, Shop, ShopUI, VendorLines,
    Interface, and Table. Vendor unit types must be registered in Shop before
    the delayed scan runs, or individual units can be registered manually.

    API:
    - call VendorDialogs_RegisterVendor(vendor)
    - call VendorDialogs_RegisterExistingVendors()
    - set vendor = VendorDialogs_GetSelectedVendor()
    - set hero = VendorDialogs_GetSelectedHero()

**/
library VendorDialogs initializer Init requires Table, DialogInteraction, DialogSystem, Shop, ShopUI, VendorLines, Interface, optional Events
    globals
        private constant real VDI_DIALOG_RANGE = 450.00
        private constant real VDI_DIALOG_COOLDOWN = 1.00
        private constant boolean VDI_ALLOW_NAZGREK = true
        private constant boolean VDI_ALLOW_ZULKIS = true
        private constant boolean VDI_REQUIRE_DIALOG_HERO = true
        private constant boolean VDI_CINEMATIC = false

        private constant integer VDI_ACTION_TRADE = 1
        private constant integer VDI_ACTION_FAREWELL = 2

        private dialog VDI_Dialog = null
        private timer VDI_DialogCooldown = null
        private Table VDI_RegisteredVendor = 0

        private unit VDI_SelectedVendor = null
        private unit VDI_SelectedHero = null
    endglobals

    private function VDI_IsSelectedContextValid takes nothing returns boolean
        return VDI_SelectedVendor != null and VDI_SelectedHero != null and DialogInteraction_IsUnitAlive(VDI_SelectedVendor) and DialogInteraction_IsUnitAlive(VDI_SelectedHero) and Shop_GetVendorIdForUnit(VDI_SelectedVendor) > 0
    endfunction

    private function VDI_ReportSelectionFailure takes unit vendor returns nothing
        local string reason = DialogInteraction_GetLastSelectionBlockReason()
        local string vendorName = VendorLines_GetVendorName(vendor)

        if reason == "missing allowed hero" then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080No player hero found near the " + vendorName + ".|r")
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
        elseif reason == "hero out of range" then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080Move closer to the " + vendorName + ".|r")
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
        elseif reason == "dialog sequence active" then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
        endif

        set vendor = null
    endfunction

    private function VDI_CreateGreetSequence takes unit vendor, unit hero returns integer
        local integer seq = DialogSystem_CreateSequence()
        local string vendorName = VendorLines_GetVendorName(vendor)

        call DialogSystem_SetSequenceDefaultSpeaker(seq, vendor, vendorName)
        call DialogSystem_AddMakeFaceEachOther(seq, vendor, hero, 0.45, 0.00)

        call DialogSystem_PickGreetLine(vendor, vendorName)
        call DialogSystem_AddLine(seq, vendor, vendorName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)

        return seq
    endfunction

    private function VDI_CreateFarewellSequence takes unit vendor, unit hero returns integer
        local integer seq = DialogSystem_CreateSequence()
        local string vendorName = VendorLines_GetVendorName(vendor)

        call DialogSystem_SetSequenceDefaultSpeaker(seq, vendor, vendorName)
        call DialogSystem_AddMakeFaceEachOther(seq, vendor, hero, 0.45, 0.00)

        call DialogSystem_PickFarewellLine(vendor, vendorName)
        call DialogSystem_AddLine(seq, vendor, vendorName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)

        return seq
    endfunction

    private function VDI_EndDialog takes boolean startCooldown returns nothing
        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(VDI_Dialog, Player(0))

        if startCooldown then
            set VDI_DialogCooldown = DialogInteraction_StartCooldown(VDI_DialogCooldown, VDI_DIALOG_COOLDOWN)
        endif

        set VDI_SelectedVendor = null
        set VDI_SelectedHero = null
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

        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(VDI_Dialog, Player(0))
        call VendorLines_PlayTradeLine(vendor)
        set VDI_DialogCooldown = DialogInteraction_StartCooldown(VDI_DialogCooldown, VDI_DIALOG_COOLDOWN)
        call ShopUI_ShowForVendor(vendor, hero)
        set VDI_SelectedVendor = null
        set VDI_SelectedHero = null

        set vendor = null
        set hero = null
    endfunction

    private function VDI_OnFarewellEnd takes nothing returns nothing
        call VDI_EndDialog(true)
    endfunction

    private function VDI_OnFarewell takes nothing returns nothing
        local integer seq

        if not VDI_IsSelectedContextValid() then
            call VDI_EndDialog(true)
            return
        endif

        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(VDI_Dialog, Player(0))
        set seq = VDI_CreateFarewellSequence(VDI_SelectedVendor, VDI_SelectedHero)
        call DialogSystem_SetSequenceCallbacks(seq, null, function VDI_OnFarewellEnd)
        call DialogSystem_PlaySequence(seq, Player(0), VDI_SelectedVendor)
    endfunction

    private function VDI_BuildDialog takes nothing returns nothing
        local button b
        local string vendorName

        if VDI_SelectedVendor == null then
            set b = null
            return
        endif

        set vendorName = VendorLines_GetVendorName(VDI_SelectedVendor)
        if VDI_Dialog == null then
            set VDI_Dialog = DialogSystem_CreateDialog(vendorName)
        endif

        call DialogSystem_ClearDialog(VDI_Dialog)
        call DialogSystem_SetTitle(VDI_Dialog, vendorName)

        set b = DialogSystem_AddButtonTrade(VDI_Dialog, VDI_ACTION_TRADE)
        call DialogSystem_BindButtonCode(b, function VDI_OnTrade)

        set b = DialogSystem_AddButtonExit(VDI_Dialog, VDI_ACTION_FAREWELL)
        call DialogSystem_SetButtonInterfaceEvent(b, Interface_EVENT_DIALOG_BUTTON_CLOSE)
        call DialogSystem_BindButtonCode(b, function VDI_OnFarewell)

        set b = null
    endfunction

    private function VDI_ShowDialogForSelection takes nothing returns nothing
        local integer seq

        if not VDI_IsSelectedContextValid() then
            call VDI_EndDialog(false)
            return
        endif

        call VDI_BuildDialog()
        set seq = VDI_CreateGreetSequence(VDI_SelectedVendor, VDI_SelectedHero)
        call DialogInteraction_PlayGreetSequenceEx(seq, VDI_SelectedVendor, Player(0), VDI_Dialog, VDI_CINEMATIC)
    endfunction

    private function VDI_OnSelected takes nothing returns nothing
        local unit vendor = DialogInteraction_GetSelectedUnit()
        local unit hero
        local boolean gateOk

        if vendor == null or Shop_GetVendorIdForUnit(vendor) <= 0 then
            set vendor = null
            set hero = null
            return
        endif

        set hero = DialogInteraction_GetDialogSelectionHero(vendor, VDI_DIALOG_RANGE, VDI_ALLOW_NAZGREK, VDI_ALLOW_ZULKIS)
        set gateOk = DialogInteraction_PassDialogSelectionGate(vendor, hero, VDI_DIALOG_RANGE, VDI_DialogCooldown, VDI_REQUIRE_DIALOG_HERO, true, true, true, false, false)
        if not gateOk then
            call VDI_ReportSelectionFailure(vendor)
            set vendor = null
            set hero = null
            return
        endif

        set VDI_SelectedVendor = vendor
        set VDI_SelectedHero = hero
        call VDI_ShowDialogForSelection()

        set vendor = null
        set hero = null
    endfunction

    public function RegisterVendor takes unit vendor returns nothing
        local integer handleId

        if vendor == null or not DialogInteraction_IsUnitAlive(vendor) or Shop_GetVendorIdForUnit(vendor) <= 0 then
            set vendor = null
            return
        endif

        set handleId = GetHandleId(vendor)
        if VDI_RegisteredVendor.boolean[handleId] then
            set vendor = null
            return
        endif

        set VDI_RegisteredVendor.boolean[handleId] = true
        call DialogInteraction_Register(vendor)
        call DialogInteraction_SetGreetOrder(vendor, DIALOGINTERACTION_GREET_NONE)
        call DialogInteraction_RegisterSelectionHandler(vendor, function VDI_OnSelected)

        set vendor = null
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
        set initTimer = CreateTimer()
        call TimerStart(initTimer, 0.00, false, function VDI_InitDelayed)
        set initTimer = null
    endfunction
endlibrary
