/**
    PotSSaveUI

    Author: Valdemar
    Version: 1.1.1

    Description:
    Provides the first-run New Game / Load Saved choice and the in-game
    fixed-slot party save panel opened from MasterUI.

    Credits:
    - Tasyen for Warcraft III frame UI examples used throughout PotS

    How to install:
    Import after PotSSaveLoad, GameMode, ImagesUI, Interface, MasterUI, and
    Companions.
    Preloader calls PotSSaveUI_ShowStartup() after preload.

    API:
    - PotSSaveUI_ShowStartup()
    - PotSSaveUI_Show()
    - PotSSaveUI_Hide()
    - PotSSaveUI_RelocateLoadedPartyToHut()

**/
library PotSSaveUI initializer AutoInit requires PotSSaveLoad, GameMode, Start, ImagesUI, Interface, MasterUI, Companions
    globals
        private constant integer PSU_SLOT_COUNT = 6
        private constant integer PSU_LOAD_PARTY_UNITS_PER_RING = 8
        private constant real PSU_LOAD_PARTY_FIRST_RING_RADIUS = 112.00
        private constant real PSU_LOAD_PARTY_RING_SPACING = 96.00
        private boolean PSU_Initialized = false
        private boolean PSU_StartupMode = false
        private boolean PSU_ShowingSlots = false
        private boolean PSU_StartupRecoveryBlocked = false
        private framehandle PSU_Parent = null
        private framehandle PSU_Title = null
        private framehandle PSU_Body = null
        private framehandle PSU_NewGameButton = null
        private framehandle PSU_LoadSavedButton = null
        private framehandle PSU_BackButton = null
        private framehandle PSU_ReturnButton = null
        private framehandle array PSU_SlotText
        private framehandle array PSU_SaveButton
        private framehandle array PSU_LoadButton
        private trigger PSU_NewGameTrigger = null
        private trigger PSU_LoadSavedTrigger = null
        private trigger PSU_BackTrigger = null
        private trigger PSU_ReturnTrigger = null
        private trigger PSU_SaveTrigger = null
        private trigger PSU_LoadTrigger = null
        private trigger PSU_ClearFocusTrigger = null
        private trigger PSU_InitTrigger = null
    endglobals

    private function PSU_MoveLoadedPartyUnit takes unit whichUnit, group movedUnits, integer placementIndex, real centerX, real centerY returns boolean
        local integer ringIndex
        local integer ringSlot
        local real angle
        local real radius
        local real x = centerX
        local real y = centerY

        if whichUnit == null or GetUnitTypeId(whichUnit) == 0 or GetWidgetLife(whichUnit) <= 0.405 or IsUnitHidden(whichUnit) or IsUnitInGroup(whichUnit, movedUnits) then
            return false
        endif

        if placementIndex > 0 then
            set ringIndex = (placementIndex - 1) / PSU_LOAD_PARTY_UNITS_PER_RING
            set ringSlot = (placementIndex - 1) - ringIndex * PSU_LOAD_PARTY_UNITS_PER_RING
            set angle = 2.00 * bj_PI * I2R(ringSlot) / I2R(PSU_LOAD_PARTY_UNITS_PER_RING)
            set radius = PSU_LOAD_PARTY_FIRST_RING_RADIUS + I2R(ringIndex) * PSU_LOAD_PARTY_RING_SPACING
            set x = centerX + radius * Cos(angle)
            set y = centerY + radius * Sin(angle)
        endif

        call SetUnitPosition(whichUnit, x, y)
        call IssueImmediateOrder(whichUnit, "stop")
        call GroupAddUnit(movedUnits, whichUnit)
        return true
    endfunction

    public function RelocateLoadedPartyToHut takes nothing returns nothing
        local group movedUnits
        local group pendingUnits
        local unit partyUnit
        local integer placementIndex = 0
        local integer rosterIndex = 1
        local integer displayIndex = 1
        local real centerX
        local real centerY

        if gg_rct_NazgrekIntroPoint == null then
            call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cffff8080PotSSaveUI: gg_rct_NazgrekIntroPoint is missing; the loaded party could not be relocated.|r")
            return
        endif

        set centerX = GetRectCenterX(gg_rct_NazgrekIntroPoint)
        set centerY = GetRectCenterY(gg_rct_NazgrekIntroPoint)
        set movedUnits = CreateGroup()

        if PSU_MoveLoadedPartyUnit(udg_Nazgrek, movedUnits, placementIndex, centerX, centerY) then
            set placementIndex = placementIndex + 1
        endif
        if PSU_MoveLoadedPartyUnit(udg_Zulkis, movedUnits, placementIndex, centerX, centerY) then
            set placementIndex = placementIndex + 1
        endif

        loop
            exitwhen rosterIndex > udg_CompanionCount
            if PSU_MoveLoadedPartyUnit(udg_CompanionUnit[rosterIndex], movedUnits, placementIndex, centerX, centerY) then
                set placementIndex = placementIndex + 1
            endif
            set rosterIndex = rosterIndex + 1
        endloop

        if udg_TamedUnits != null then
            set pendingUnits = CreateGroup()
            call GroupAddGroup(udg_TamedUnits, pendingUnits)
            loop
                set partyUnit = FirstOfGroup(pendingUnits)
                exitwhen partyUnit == null
                call GroupRemoveUnit(pendingUnits, partyUnit)
                if PSU_MoveLoadedPartyUnit(partyUnit, movedUnits, placementIndex, centerX, centerY) then
                    set placementIndex = placementIndex + 1
                endif
            endloop
            call DestroyGroup(pendingUnits)
            set pendingUnits = null
        endif

        loop
            exitwhen displayIndex > Companions_GetControlledDisplayCount()
            set partyUnit = Companions_GetControlledDisplayUnit(displayIndex)
            if PSU_MoveLoadedPartyUnit(partyUnit, movedUnits, placementIndex, centerX, centerY) then
                set placementIndex = placementIndex + 1
            endif
            set displayIndex = displayIndex + 1
        endloop

        call DestroyGroup(movedUnits)
        set movedUnits = null
        set pendingUnits = null
        set partyUnit = null
    endfunction

    private function PSU_GetSlotId takes integer index returns string
        return "slot" + I2S(index)
    endfunction

    private function PSU_SetVisible takes framehandle frame, boolean visible returns nothing
        if frame != null then
            call BlzFrameSetVisible(frame, visible)
        endif
    endfunction

    private function PSU_GetClickedSlot takes framehandle clicked, boolean saveButton returns integer
        local integer i = 1
        loop
            exitwhen i > PSU_SLOT_COUNT
            if (saveButton and clicked == PSU_SaveButton[i]) or (not saveButton and clicked == PSU_LoadButton[i]) then
                set clicked = null
                return i
            endif
            set i = i + 1
        endloop
        set clicked = null
        return 0
    endfunction

    private function PSU_RefreshSlots takes nothing returns nothing
        local integer i = 1
        local string slot
        local string title
        local boolean exists
        local boolean busy = PotSSaveLoad_IsBusy(Player(0))

        loop
            exitwhen i > PSU_SLOT_COUNT
            set slot = PSU_GetSlotId(i)
            set exists = PotSSaveLoad_SlotExists(slot)
            if exists then
                set title = PotSSaveLoad_GetSlotTitle(slot)
            else
                set title = "Slot " + I2S(i) + " - Empty"
            endif
            call BlzFrameSetText(PSU_SlotText[i], title)
            call BlzFrameSetEnable(PSU_SaveButton[i], not PSU_StartupMode and not busy)
            call BlzFrameSetEnable(PSU_LoadButton[i], exists and not busy)
            set i = i + 1
        endloop
    endfunction

    private function PSU_ApplyView takes nothing returns nothing
        local integer i = 1
        local boolean choiceView = PSU_StartupMode and not PSU_ShowingSlots

        call PSU_SetVisible(PSU_NewGameButton, choiceView)
        call PSU_SetVisible(PSU_LoadSavedButton, choiceView)
        call BlzFrameSetEnable(PSU_NewGameButton, not PSU_StartupRecoveryBlocked)
        call BlzFrameSetEnable(PSU_LoadSavedButton, not PSU_StartupRecoveryBlocked)
        call PSU_SetVisible(PSU_Body, choiceView)
        call PSU_SetVisible(PSU_BackButton, PSU_StartupMode and PSU_ShowingSlots)
        call PSU_SetVisible(PSU_ReturnButton, not PSU_StartupMode)
        loop
            exitwhen i > PSU_SLOT_COUNT
            call PSU_SetVisible(PSU_SlotText[i], not choiceView)
            call PSU_SetVisible(PSU_SaveButton[i], not choiceView and not PSU_StartupMode)
            call PSU_SetVisible(PSU_LoadButton[i], not choiceView)
            set i = i + 1
        endloop
        if choiceView then
            call BlzFrameSetText(PSU_Title, "|cffffe4a3Path of the Shaman|r")
            if PSU_StartupRecoveryBlocked then
                call BlzFrameSetText(PSU_Body, "The load failed after restoration began. Restart the map before starting or loading another game.")
            else
                call BlzFrameSetText(PSU_Body, "Begin a new adventure, or restore Nazgrek and Zul'kis from a local PotS save.")
            endif
        else
            call BlzFrameSetText(PSU_Title, "|cffffe4a3Saved Games|r")
            call PSU_RefreshSlots()
        endif
    endfunction

    private function PSU_HideInternal takes nothing returns nothing
        call PSU_SetVisible(PSU_Parent, false)
    endfunction

    public function Hide takes nothing returns nothing
        call PSU_HideInternal()
    endfunction

    public function ShowStartup takes nothing returns nothing
        set PSU_StartupMode = true
        set PSU_ShowingSlots = false
        set PSU_StartupRecoveryBlocked = false
        call PSU_ApplyView()
        call EnableUserControl(true)
        call PSU_SetVisible(PSU_Parent, true)
    endfunction

    public function Show takes nothing returns nothing
        set PSU_StartupMode = false
        set PSU_ShowingSlots = true
        call PSU_ApplyView()
        if PSU_Parent != null then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, Player(0))
            call PSU_SetVisible(PSU_Parent, true)
        endif
    endfunction

    private function PSU_ClearFocusAction takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            call StopCamera()
        endif
    endfunction

    private function PSU_NewGameAction takes nothing returns nothing
        if GetTriggerPlayer() == Player(0) and not PSU_StartupRecoveryBlocked then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_CONFIRM, GetTriggerPlayer())
            call PotSSaveLoad_SetLoadAllowed(GetTriggerPlayer(), false)
            call PSU_HideInternal()
            call GameMode_Show()
        endif
    endfunction

    private function PSU_LoadSavedAction takes nothing returns nothing
        if GetTriggerPlayer() == Player(0) and not PSU_StartupRecoveryBlocked then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_BUTTON_CLICK, GetTriggerPlayer())
            set PSU_ShowingSlots = true
            call PSU_ApplyView()
        endif
    endfunction

    private function PSU_BackAction takes nothing returns nothing
        if GetTriggerPlayer() == Player(0) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_CANCEL, GetTriggerPlayer())
            set PSU_ShowingSlots = false
            call PSU_ApplyView()
        endif
    endfunction

    private function PSU_ReturnAction takes nothing returns nothing
        call Hide()
        call MasterUI_Show()
    endfunction

    private function PSU_SaveAction takes nothing returns nothing
        local integer index = PSU_GetClickedSlot(BlzGetTriggerFrame(), true)
        if GetTriggerPlayer() == Player(0) and index > 0 then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_CONFIRM, GetTriggerPlayer())
            call PotSSaveLoad_RequestSave(GetTriggerPlayer(), PSU_GetSlotId(index))
            call PSU_RefreshSlots()
        endif
    endfunction

    private function PSU_LoadAction takes nothing returns nothing
        local integer index = PSU_GetClickedSlot(BlzGetTriggerFrame(), false)
        local string slot
        if GetTriggerPlayer() == Player(0) and index > 0 then
            set slot = PSU_GetSlotId(index)
            if PotSSaveLoad_SlotExists(slot) then
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_CONFIRM, GetTriggerPlayer())
                if PSU_StartupMode then
                    call PSU_HideInternal()
                    // The startup choice remains valid even if the player spent
                    // longer than the command-oriented initial load window here.
                    call PotSSaveLoad_SetLoadAllowed(GetTriggerPlayer(), true)
                    if Start_IsAwaitingLoad() then
                        call GameMode_StartSavedGame(slot, PotSSaveLoad_GetSlotMode(slot), PotSSaveLoad_GetSlotDifficulty(slot))
                        call PotSSaveLoad_RequestLoad(GetTriggerPlayer(), slot)
                    else
                        call GameMode_StartSavedGame(slot, PotSSaveLoad_GetSlotMode(slot), PotSSaveLoad_GetSlotDifficulty(slot))
                    endif
                else
                    call PotSSaveLoad_RequestLoad(GetTriggerPlayer(), slot)
                    call PSU_RefreshSlots()
                endif
            endif
        endif
    endfunction

    private function PSU_OnOperationFinished takes nothing returns nothing
        call PSU_RefreshSlots()
    endfunction

    private function PSU_OnLoadFailed takes nothing returns nothing
        if PSU_StartupMode and Start_IsAwaitingLoad() then
            set PSU_StartupRecoveryBlocked = not PotSSaveLoad_CanRecoverFromLoadFailure(Player(0))
            set PSU_ShowingSlots = false
            call PSU_ApplyView()
            call EnableUserControl(true)
            call PSU_SetVisible(PSU_Parent, true)
        else
            call PSU_RefreshSlots()
        endif
    endfunction

    private function PSU_CreateButton takes string name, string label, real x, real y, real width, trigger eventTrigger returns framehandle
        local framehandle buttonFrame = BlzCreateFrameByType("GLUETEXTBUTTON", name, PSU_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetPoint(buttonFrame, FRAMEPOINT_TOPLEFT, PSU_Parent, FRAMEPOINT_TOPLEFT, x, y)
        call BlzFrameSetSize(buttonFrame, width, 0.034)
        call BlzFrameSetText(buttonFrame, label)
        call BlzTriggerRegisterFrameEvent(eventTrigger, buttonFrame, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(PSU_ClearFocusTrigger, buttonFrame, FRAMEEVENT_CONTROL_CLICK)
        return buttonFrame
    endfunction

    private function PSU_CreateFrames takes nothing returns nothing
        local integer i = 1
        local real y

        set PSU_Parent = BlzCreateFrameByType("BACKDROP", "PotSSaveUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetLevel(PSU_Parent, 8)
        call BlzFrameSetAbsPoint(PSU_Parent, FRAMEPOINT_TOPLEFT, 0.145, 0.545)
        call BlzFrameSetAbsPoint(PSU_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.655, 0.160)

        set PSU_Title = BlzCreateFrameByType("TEXT", "PotSSaveUITitle", PSU_Parent, "", 0)
        call BlzFrameSetPoint(PSU_Title, FRAMEPOINT_TOP, PSU_Parent, FRAMEPOINT_TOP, 0.000, -0.024)
        call BlzFrameSetSize(PSU_Title, 0.420, 0.028)
        call BlzFrameSetTextAlignment(PSU_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(PSU_Title, 1.18)
        call BlzFrameSetEnable(PSU_Title, false)

        set PSU_Body = BlzCreateFrameByType("TEXT", "PotSSaveUIBody", PSU_Parent, "", 0)
        call BlzFrameSetPoint(PSU_Body, FRAMEPOINT_TOP, PSU_Title, FRAMEPOINT_BOTTOM, 0.000, -0.040)
        call BlzFrameSetSize(PSU_Body, 0.390, 0.080)
        call BlzFrameSetTextAlignment(PSU_Body, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetEnable(PSU_Body, false)

        set PSU_NewGameButton = PSU_CreateButton("PotSSaveUINewGame", "New Game", 0.095, -0.225, 0.150, PSU_NewGameTrigger)
        set PSU_LoadSavedButton = PSU_CreateButton("PotSSaveUILoadSaved", "Load Saved", 0.265, -0.225, 0.150, PSU_LoadSavedTrigger)
        set PSU_BackButton = PSU_CreateButton("PotSSaveUIBack", "Back", 0.020, -0.335, 0.080, PSU_BackTrigger)
        set PSU_ReturnButton = PSU_CreateButton("PotSSaveUIReturn", "Return", 0.020, -0.335, 0.080, PSU_ReturnTrigger)

        loop
            exitwhen i > PSU_SLOT_COUNT
            set y = -0.072 - I2R(i - 1) * 0.043
            set PSU_SlotText[i] = BlzCreateFrameByType("TEXT", "PotSSaveUISlotText" + I2S(i), PSU_Parent, "", 0)
            call BlzFrameSetPoint(PSU_SlotText[i], FRAMEPOINT_TOPLEFT, PSU_Parent, FRAMEPOINT_TOPLEFT, 0.030, y)
            call BlzFrameSetSize(PSU_SlotText[i], 0.285, 0.030)
            call BlzFrameSetTextAlignment(PSU_SlotText[i], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
            call BlzFrameSetEnable(PSU_SlotText[i], false)
            set PSU_SaveButton[i] = PSU_CreateButton("PotSSaveUISave" + I2S(i), "Save", 0.325, y, 0.070, PSU_SaveTrigger)
            set PSU_LoadButton[i] = PSU_CreateButton("PotSSaveUILoad" + I2S(i), "Load", 0.405, y, 0.070, PSU_LoadTrigger)
            set i = i + 1
        endloop
        call PSU_ApplyView()
        call PSU_HideInternal()
    endfunction

    private function PSU_DelayedInit takes nothing returns nothing
        call PSU_CreateFrames()
    endfunction

    public function Init takes nothing returns nothing
        if PSU_Initialized then
            return
        endif
        set PSU_Initialized = true
        set PSU_NewGameTrigger = CreateTrigger()
        call TriggerAddAction(PSU_NewGameTrigger, function PSU_NewGameAction)
        set PSU_LoadSavedTrigger = CreateTrigger()
        call TriggerAddAction(PSU_LoadSavedTrigger, function PSU_LoadSavedAction)
        set PSU_BackTrigger = CreateTrigger()
        call TriggerAddAction(PSU_BackTrigger, function PSU_BackAction)
        set PSU_ReturnTrigger = CreateTrigger()
        call TriggerAddAction(PSU_ReturnTrigger, function PSU_ReturnAction)
        set PSU_SaveTrigger = CreateTrigger()
        call TriggerAddAction(PSU_SaveTrigger, function PSU_SaveAction)
        set PSU_LoadTrigger = CreateTrigger()
        call TriggerAddAction(PSU_LoadTrigger, function PSU_LoadAction)
        set PSU_ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(PSU_ClearFocusTrigger, function PSU_ClearFocusAction)
        call PotSSaveLoad_AddSaveCompleteAction(function PSU_OnOperationFinished)
        call PotSSaveLoad_AddSaveFailedAction(function PSU_OnOperationFinished)
        call PotSSaveLoad_AddLoadFailedAction(function PSU_OnLoadFailed)
        set PSU_InitTrigger = CreateTrigger()
        call TriggerRegisterTimerEvent(PSU_InitTrigger, 0.20, false)
        call TriggerAddAction(PSU_InitTrigger, function PSU_DelayedInit)
    endfunction

    public function AutoInit takes nothing returns nothing
        call Init()
    endfunction
endlibrary
