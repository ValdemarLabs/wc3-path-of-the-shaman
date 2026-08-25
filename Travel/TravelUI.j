/**
    TravelUI

    Author: Valdemar
    Version:

    Description:
    ShopUI-styled destination and passenger selection panel for TravelSystem.
    It presents destination zone icons plus discovery, vehicle, fare, party,
    and gold requirements before committing a journey.

    Credits:
    PotS ShopUI frame layout and interaction conventions.

    How to install:
    Import after TravelSystem, ZonesCore, Table, Interface, and DialogSystem.

    API:
    - call TravelUI_ShowForStop(integer stopId)
    - call TravelUI_Hide()
    - call TravelUI_Refresh()
    - set visible = TravelUI_IsVisible()

**/
library TravelUI initializer Init requires TravelSystem, ZonesCore, Table, Interface, DialogSystem
    globals
        private constant integer TUI_MAX_ROUTE_ROWS = 7
        private constant integer TUI_MAX_PASSENGER_ROWS = 10

        private boolean TUI_Initialized = false
        private integer TUI_StopId = 0
        private integer TUI_SelectedRoute = 0
        private string TUI_Status = ""

        private framehandle TUI_Parent = null
        private framehandle TUI_Backdrop = null
        private framehandle TUI_Title = null
        private framehandle TUI_Subtitle = null
        private framehandle TUI_CloseButton = null
        private framehandle TUI_LeftPane = null
        private framehandle TUI_RightPane = null
        private framehandle array TUI_RouteButton
        private framehandle array TUI_RouteIcon
        private framehandle array TUI_RouteText
        private framehandle array TUI_RoutePrice
        private framehandle array TUI_RouteHighlight
        private framehandle TUI_DetailTitle = null
        private framehandle TUI_DetailInfo = null
        private framehandle TUI_PassengerHeading = null
        private framehandle array TUI_PassengerButton
        private framehandle array TUI_PassengerText
        private framehandle TUI_Warning = null
        private framehandle TUI_StatusText = null
        private framehandle TUI_GoldText = null
        private framehandle TUI_ActionButton = null

        // Compact prompt shown over fullscreen travel presentation.
        private framehandle TUI_PromptParent = null
        private framehandle TUI_PromptBackdrop = null
        private framehandle TUI_PromptTitle = null
        private framehandle TUI_PromptText = null
        private framehandle TUI_PromptConfirmButton = null
        private framehandle TUI_PromptCancelButton = null

        private integer array TUI_RowRoute
        private integer array TUI_RowPassenger
        private Table TUI_RouteFrameRow = 0
        private Table TUI_PassengerFrameRow = 0

        private trigger TUI_CloseTrigger = null
        private trigger TUI_RouteTrigger = null
        private trigger TUI_PassengerTrigger = null
        private trigger TUI_ActionTrigger = null
        private trigger TUI_ClearFocusTrigger = null
        private trigger TUI_EscapeTrigger = null
        private trigger TUI_PromptConfirmTrigger = null
        private trigger TUI_PromptCancelTrigger = null

        private dialog TUI_LeaveDialog = null
        private button TUI_LeaveConfirmButton = null
        private button TUI_LeaveCancelButton = null
        private boolean TUI_LeaveDialogVisible = false

        private string TUI_PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
        private string TUI_HighlightModel = "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx"
    endglobals

    public function IsVisible takes nothing returns boolean
        return TUI_Parent != null and BlzFrameIsVisible(TUI_Parent)
    endfunction

    private function TUI_GetMethodName takes integer methodId returns string
        if methodId == TRAVEL_METHOD_WYVERN then
            return "Wyvern"
        elseif methodId == TRAVEL_METHOD_ZEPPELIN then
            return "Zeppelin"
        elseif methodId == TRAVEL_METHOD_SHIP_A then
            return "Neutral ship"
        elseif methodId == TRAVEL_METHOD_SHIP_B then
            return "Orcish ship"
        endif
        return "Travel"
    endfunction

    private function TUI_GetPassengerRole takes integer index returns string
        if TravelSystem_IsPassengerHero(index) then
            return "Hero"
        elseif TravelSystem_IsPassengerPet(index) then
            return "Pet - free"
        endif
        return "Companion"
    endfunction

    private function TUI_GetFirstRoute takes integer stopId returns integer
        local integer row = 1
        local integer routeId
        local integer firstRoute = 0

        loop
            exitwhen row > TravelSystem_GetRouteCountAtStop(stopId)
            set routeId = TravelSystem_GetRouteAtStop(stopId, row)
            if firstRoute == 0 then
                set firstRoute = routeId
            endif
            if TravelSystem_IsRouteAvailable(routeId) then
                return routeId
            endif
            set row = row + 1
        endloop
        return firstRoute
    endfunction

    private function TUI_UpdateRouteRows takes nothing returns nothing
        local integer row = 1
        local integer routeId
        local integer endStop
        local string routeText
        local string priceText
        local string iconPath

        loop
            exitwhen row > TUI_MAX_ROUTE_ROWS
            set routeId = TravelSystem_GetRouteAtStop(TUI_StopId, row)
            set TUI_RowRoute[row] = routeId
            if routeId > 0 then
                set endStop = TravelSystem_GetRouteEnd(routeId)
                if not TravelSystem_IsRouteDiscovered(routeId) then
                    set routeText = "|cff9f9f9fUndiscovered travel point|r"
                    set priceText = "|cff9f9f9fLocked|r"
                    set iconPath = ""
                else
                    set routeText = TravelSystem_GetStopName(endStop)
                    set iconPath = ZonesCore_GetEffectiveZoneIconPath(TravelSystem_GetStopZoneId(endStop))
                    if TravelSystem_GetRouteFare(routeId) > 0 then
                        set priceText = I2S(TravelSystem_GetRouteFare(routeId)) + "g each"
                    else
                        set priceText = "Free"
                    endif
                    if not TravelSystem_IsRouteAvailable(routeId) then
                        set priceText = "|cffff8040Unavailable|r"
                    endif
                endif
                if iconPath != null and iconPath != "" then
                    call BlzFrameSetTexture(TUI_RouteIcon[row], iconPath, 0, true)
                    call BlzFrameSetVisible(TUI_RouteIcon[row], true)
                else
                    call BlzFrameSetVisible(TUI_RouteIcon[row], false)
                endif
                call BlzFrameSetText(TUI_RouteText[row], routeText)
                call BlzFrameSetText(TUI_RoutePrice[row], priceText)
                call BlzFrameSetVisible(TUI_RouteButton[row], true)
                call BlzFrameSetVisible(TUI_RouteHighlight[row], routeId == TUI_SelectedRoute)
            else
                call BlzFrameSetVisible(TUI_RouteIcon[row], false)
                call BlzFrameSetVisible(TUI_RouteButton[row], false)
                call BlzFrameSetVisible(TUI_RouteHighlight[row], false)
            endif
            set row = row + 1
        endloop
    endfunction

    private function TUI_UpdatePassengerRows takes nothing returns nothing
        local integer row = 1
        local unit passenger
        local string marker
        local string color

        loop
            exitwhen row > TUI_MAX_PASSENGER_ROWS
            set TUI_RowPassenger[row] = row
            if row <= TravelSystem_GetPassengerCount() then
                set passenger = TravelSystem_GetPassenger(row)
                if TravelSystem_IsPassengerPet(row) then
                    set marker = "[+]"
                    set color = "|cff80ff80"
                elseif TravelSystem_IsPassengerSelected(row) then
                    set marker = "[x]"
                    set color = "|cffffffff"
                else
                    set marker = "[ ]"
                    set color = "|cff9f9f9f"
                endif
                call BlzFrameSetText(TUI_PassengerText[row], color + marker + " " + GetObjectName(GetUnitTypeId(passenger)) + "|r  |cffc0c0c0" + TUI_GetPassengerRole(row) + "|r")
                call BlzFrameSetVisible(TUI_PassengerButton[row], true)
            else
                call BlzFrameSetVisible(TUI_PassengerButton[row], false)
            endif
            set row = row + 1
        endloop
        set passenger = null
    endfunction

    private function TUI_UpdateDetails takes nothing returns nothing
        local integer startStop
        local integer endStop
        local integer fare
        local integer skipFee
        local integer gold = GetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD)
        local string info

        if TUI_SelectedRoute <= 0 then
            call BlzFrameSetText(TUI_DetailTitle, "No destination")
            call BlzFrameSetText(TUI_DetailInfo, "No routes are configured from this travel point.")
            call BlzFrameSetText(TUI_Warning, "")
            call BlzFrameSetText(TUI_StatusText, TUI_Status)
            call BlzFrameSetText(TUI_GoldText, "Gold: " + I2S(gold))
            return
        endif
        set startStop = TravelSystem_GetRouteStart(TUI_SelectedRoute)
        set endStop = TravelSystem_GetRouteEnd(TUI_SelectedRoute)
        set fare = TravelSystem_GetTotalFare(TUI_SelectedRoute)
        set skipFee = TravelSystem_GetTotalSkipFee(TUI_SelectedRoute)
        if TravelSystem_IsRouteDiscovered(TUI_SelectedRoute) then
            call BlzFrameSetText(TUI_DetailTitle, TravelSystem_GetStopName(startStop) + "  >  " + TravelSystem_GetStopName(endStop))
        else
            call BlzFrameSetText(TUI_DetailTitle, "Undiscovered route")
        endif
        set info = TUI_GetMethodName(TravelSystem_GetRouteMethod(TUI_SelectedRoute)) + "|n"
        set info = info + "Start zone: " + TravelSystem_GetStopZoneName(startStop) + "|n"
        if TravelSystem_IsRouteDiscovered(TUI_SelectedRoute) then
            set info = info + "End zone: " + TravelSystem_GetStopZoneName(endStop) + "|n"
        else
            set info = info + "End zone: Undiscovered|n"
        endif
        set info = info + "Fare: " + I2S(fare) + " gold  |  ESC skip: " + I2S(skipFee) + " gold"
        call BlzFrameSetText(TUI_DetailInfo, info)
        if TravelSystem_HasUnselectedCompanions() then
            call BlzFrameSetText(TUI_Warning, "|cffff8040Unselected companions will leave your party. Unselected heroes stay behind.|r")
        else
            call BlzFrameSetText(TUI_Warning, "|cff80ff80Nearby pets travel automatically for free.|r")
        endif
        call BlzFrameSetText(TUI_StatusText, TUI_Status)
        if gold < fare then
            call BlzFrameSetText(TUI_GoldText, "|cffff8040Gold: " + I2S(gold) + " / " + I2S(fare) + "|r")
        else
            call BlzFrameSetText(TUI_GoldText, "Gold: " + I2S(gold) + " / " + I2S(fare))
        endif
    endfunction

    private function TUI_Update takes nothing returns nothing
        call TUI_UpdateRouteRows()
        call TUI_UpdatePassengerRows()
        call TUI_UpdateDetails()
    endfunction

    public function Refresh takes nothing returns nothing
        if IsVisible() then
            call TUI_Update()
        endif
    endfunction

    private function TUI_HideInternal takes boolean releaseVehicle returns nothing
        if not IsVisible() then
            return
        endif
        if TUI_LeaveDialogVisible then
            call DialogSystem_HideDialog(TUI_LeaveDialog, Player(0))
            set TUI_LeaveDialogVisible = false
        endif
        call BlzFrameSetVisible(TUI_Parent, false)
        if releaseVehicle then
            call TravelSystem_ReleaseHeldVehicle(false)
        endif
        set TUI_StopId = 0
        set TUI_SelectedRoute = 0
        set TUI_Status = ""
    endfunction

    public function Hide takes nothing returns nothing
        call TUI_HideInternal(true)
    endfunction

    private function TUI_CommitTravel takes nothing returns nothing
        if TravelSystem_Start(TUI_SelectedRoute) then
            call TUI_HideInternal(false)
        else
            set TUI_Status = "|cffff8040Travel could not begin. Check the route, party, and gold requirements.|r"
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
            call TUI_Update()
        endif
    endfunction

    private function TUI_OnLeaveConfirmed takes nothing returns nothing
        call DialogSystem_HideDialog(TUI_LeaveDialog, Player(0))
        set TUI_LeaveDialogVisible = false
        call TUI_CommitTravel()
    endfunction

    private function TUI_OnLeaveCancelled takes nothing returns nothing
        call DialogSystem_HideDialog(TUI_LeaveDialog, Player(0))
        set TUI_LeaveDialogVisible = false
    endfunction

    private function TUI_RequestTravel takes nothing returns nothing
        if TUI_SelectedRoute <= 0 then
            set TUI_Status = "|cffff8040Choose a destination first.|r"
        elseif not TravelSystem_IsRouteDiscovered(TUI_SelectedRoute) then
            set TUI_Status = "|cffff8040Both endpoint travel masters must be discovered before this route can be used.|r"
        elseif not TravelSystem_IsRouteAvailable(TUI_SelectedRoute) then
            set TUI_Status = "|cffff8040The travel vehicle is not currently available here.|r"
        elseif TravelSystem_GetSelectedHeroCount() <= 0 then
            set TUI_Status = "|cffff8040At least one player hero must travel.|r"
        elseif TravelSystem_HasUnselectedCompanions() then
            call DialogSystem_SetTitle(TUI_LeaveDialog, "Unselected companions will leave your party. Begin travel?")
            call DialogSystem_SetContext(TravelSystem_GetStopMaster(TUI_StopId), Player(0))
            call DialogSystem_ShowDialog(TUI_LeaveDialog, Player(0))
            set TUI_LeaveDialogVisible = true
            return
        else
            call TUI_CommitTravel()
            return
        endif
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
        call TUI_Update()
    endfunction

    private function TUI_ClearFocus takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            call BlzFrameSetFocus(BlzGetTriggerFrame(), false)
        endif
    endfunction

    private function TUI_OnClose takes nothing returns nothing
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_DIALOG_BUTTON_CLOSE, GetTriggerPlayer())
        call Hide()
    endfunction

    private function TUI_OnEscape takes nothing returns nothing
        if IsVisible() and GetTriggerPlayer() == Player(0) then
            if TUI_LeaveDialogVisible then
                call TUI_OnLeaveCancelled()
            else
                call Hide()
            endif
        endif
    endfunction

    private function TUI_OnRouteClicked takes nothing returns nothing
        local integer row = TUI_RouteFrameRow.integer[GetHandleId(BlzGetTriggerFrame())]
        local integer routeId = TUI_RowRoute[row]

        if routeId > 0 then
            set TUI_SelectedRoute = routeId
            set TUI_Status = ""
            call TravelSystem_BuildPassengerList(routeId)
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_DIALOG_BUTTON_NORMAL, GetTriggerPlayer())
            call TUI_Update()
        endif
    endfunction

    private function TUI_OnPassengerClicked takes nothing returns nothing
        local integer row = TUI_PassengerFrameRow.integer[GetHandleId(BlzGetTriggerFrame())]
        local integer passengerIndex = TUI_RowPassenger[row]
        local boolean selected

        if passengerIndex <= 0 or passengerIndex > TravelSystem_GetPassengerCount() or TravelSystem_IsPassengerPet(passengerIndex) then
            return
        endif
        set selected = TravelSystem_IsPassengerSelected(passengerIndex)
        if selected and TravelSystem_IsPassengerHero(passengerIndex) and TravelSystem_GetSelectedHeroCount() <= 1 then
            set TUI_Status = "|cffff8040At least one player hero must remain selected.|r"
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, GetTriggerPlayer())
        else
            call TravelSystem_SetPassengerSelected(passengerIndex, not selected)
            set TUI_Status = ""
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_DIALOG_BUTTON_NORMAL, GetTriggerPlayer())
        endif
        call TUI_Update()
    endfunction

    private function TUI_OnAction takes nothing returns nothing
        call TUI_RequestTravel()
    endfunction

    public function ShowForStop takes integer stopId returns nothing
        local integer routeId

        if stopId <= 0 or TravelSystem_IsActive() then
            return
        endif
        if IsVisible() then
            call TUI_HideInternal(true)
        endif
        set TUI_StopId = stopId
        set TUI_SelectedRoute = TUI_GetFirstRoute(stopId)
        set TUI_Status = ""
        set routeId = TUI_SelectedRoute
        if routeId > 0 then
            call TravelSystem_BuildPassengerList(routeId)
        endif
        call TravelSystem_HoldStopVehicle(stopId)
        call BlzFrameSetText(TUI_Title, "Travel")
        call BlzFrameSetText(TUI_Subtitle, "Departing from " + TravelSystem_GetStopName(stopId))
        call TUI_Update()
        call BlzFrameSetVisible(TUI_Parent, true)
    endfunction

    private function TUI_OnMasterSelected takes nothing returns nothing
        call ShowForStop(TravelSystem_GetSelectedStop())
    endfunction

    private function TUI_ReleasePromptFocus takes nothing returns nothing
        if GetLocalPlayer() == Player(0) then
            call BlzFrameSetFocus(TUI_PromptConfirmButton, false)
            call BlzFrameSetFocus(TUI_PromptCancelButton, false)
        endif
    endfunction

    private function TUI_UpdatePrompt takes nothing returns nothing
        local integer promptType = TravelSystem_GetPromptType()
        local integer routeId = TravelSystem_GetActiveRoute()
        local integer stopId

        if promptType == TRAVEL_PROMPT_NONE or routeId <= 0 then
            call BlzFrameSetVisible(TUI_PromptParent, false)
            call TUI_ReleasePromptFocus()
            return
        endif
        if promptType == TRAVEL_PROMPT_SKIP then
            call BlzFrameSetText(TUI_PromptTitle, "Skip to " + TravelSystem_GetStopName(TravelSystem_GetRouteEnd(routeId)) + "?")
            call BlzFrameSetText(TUI_PromptText, "Skipping this journey costs " + I2S(TravelSystem_GetTotalSkipFee(routeId)) + " gold.")
            call BlzFrameSetText(TUI_PromptConfirmButton, "Skip travel")
            call BlzFrameSetText(TUI_PromptCancelButton, "Continue journey")
        else
            set stopId = TravelSystem_GetPromptStop()
            call BlzFrameSetText(TUI_PromptTitle, "Disembark at " + TravelSystem_GetStopName(stopId) + "?")
            call BlzFrameSetText(TUI_PromptText, "You can leave here or continue to " + TravelSystem_GetStopName(TravelSystem_GetRouteEnd(routeId)) + ".")
            call BlzFrameSetText(TUI_PromptConfirmButton, "Drop out here")
            call BlzFrameSetText(TUI_PromptCancelButton, "Continue journey")
        endif
        call BlzFrameSetVisible(TUI_PromptParent, true)
    endfunction

    private function TUI_OnPromptChanged takes nothing returns nothing
        call TUI_UpdatePrompt()
    endfunction

    private function TUI_OnPromptConfirmed takes nothing returns nothing
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_DIALOG_BUTTON_NORMAL, GetTriggerPlayer())
        call TravelSystem_ConfirmPrompt()
    endfunction

    private function TUI_OnPromptCancelled takes nothing returns nothing
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_DIALOG_BUTTON_CLOSE, GetTriggerPlayer())
        call TravelSystem_CancelPrompt()
    endfunction

    private function TUI_CreateFrames takes nothing returns nothing
        local integer row = 1
        local real rowY = -0.012

        set TUI_Parent = BlzCreateFrameByType("BACKDROP", "TravelUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetAbsPoint(TUI_Parent, FRAMEPOINT_TOPLEFT, 0.105, 0.565)
        call BlzFrameSetAbsPoint(TUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.640, 0.145)

        set TUI_Backdrop = BlzCreateFrameByType("BACKDROP", "TravelUIBackdrop", TUI_Parent, "", 0)
        call BlzFrameSetTexture(TUI_Backdrop, TUI_PanelTexture, 0, false)
        call BlzFrameSetPoint(TUI_Backdrop, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.010, -0.010)
        call BlzFrameSetPoint(TUI_Backdrop, FRAMEPOINT_BOTTOMRIGHT, TUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.010)
        call BlzFrameSetVertexColor(TUI_Backdrop, BlzConvertColor(255, 0, 0, 0))
        call BlzFrameSetEnable(TUI_Backdrop, false)

        set TUI_Title = BlzCreateFrameByType("TEXT", "TravelUITitle", TUI_Parent, "", 0)
        call BlzFrameSetPoint(TUI_Title, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
        call BlzFrameSetSize(TUI_Title, 0.300, 0.020)
        call BlzFrameSetScale(TUI_Title, 1.10)
        call BlzFrameSetEnable(TUI_Title, false)

        set TUI_Subtitle = BlzCreateFrameByType("TEXT", "TravelUISubtitle", TUI_Parent, "", 0)
        call BlzFrameSetPoint(TUI_Subtitle, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.047)
        call BlzFrameSetSize(TUI_Subtitle, 0.360, 0.018)
        call BlzFrameSetScale(TUI_Subtitle, 0.94)
        call BlzFrameSetEnable(TUI_Subtitle, false)

        set TUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TravelUIClose", TUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_CloseButton, 0.030, 0.030)
        call BlzFrameSetText(TUI_CloseButton, "X")
        call BlzFrameSetPoint(TUI_CloseButton, FRAMEPOINT_TOPRIGHT, TUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
        call BlzTriggerRegisterFrameEvent(TUI_CloseTrigger, TUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

        set TUI_LeftPane = BlzCreateFrameByType("BACKDROP", "TravelUILeftPane", TUI_Parent, "", 0)
        call BlzFrameSetTexture(TUI_LeftPane, TUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(TUI_LeftPane, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.078)
        call BlzFrameSetPoint(TUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, TUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.220, 0.014)

        set TUI_RightPane = BlzCreateFrameByType("BACKDROP", "TravelUIRightPane", TUI_Parent, "", 0)
        call BlzFrameSetTexture(TUI_RightPane, TUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(TUI_RightPane, FRAMEPOINT_TOPLEFT, TUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.010, 0.0)
        call BlzFrameSetPoint(TUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, TUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.014)

        loop
            exitwhen row > TUI_MAX_ROUTE_ROWS
            set TUI_RouteButton[row] = BlzCreateFrameByType("GLUEBUTTON", "TravelUIRoute" + I2S(row), TUI_LeftPane, "ScoreScreenTabButtonTemplate", 0)
            call BlzFrameSetPoint(TUI_RouteButton[row], FRAMEPOINT_TOPLEFT, TUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.006, rowY)
            call BlzFrameSetSize(TUI_RouteButton[row], 0.194, 0.036)
            call BlzTriggerRegisterFrameEvent(TUI_RouteTrigger, TUI_RouteButton[row], FRAMEEVENT_CONTROL_CLICK)
            call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_RouteButton[row], FRAMEEVENT_CONTROL_CLICK)
            set TUI_RouteFrameRow.integer[GetHandleId(TUI_RouteButton[row])] = row

            set TUI_RouteIcon[row] = BlzCreateFrameByType("BACKDROP", "TravelUIRouteIcon" + I2S(row), TUI_RouteButton[row], "IconButtonTemplate", 0)
            call BlzFrameSetPoint(TUI_RouteIcon[row], FRAMEPOINT_LEFT, TUI_RouteButton[row], FRAMEPOINT_LEFT, 0.005, 0.0)
            call BlzFrameSetSize(TUI_RouteIcon[row], 0.026, 0.026)
            call BlzFrameSetEnable(TUI_RouteIcon[row], false)

            set TUI_RouteText[row] = BlzCreateFrameByType("TEXT", "TravelUIRouteText" + I2S(row), TUI_RouteButton[row], "", 0)
            call BlzFrameSetPoint(TUI_RouteText[row], FRAMEPOINT_TOPLEFT, TUI_RouteButton[row], FRAMEPOINT_TOPLEFT, 0.036, -0.004)
            call BlzFrameSetPoint(TUI_RouteText[row], FRAMEPOINT_BOTTOMRIGHT, TUI_RouteButton[row], FRAMEPOINT_BOTTOMRIGHT, -0.055, 0.004)
            call BlzFrameSetTextAlignment(TUI_RouteText[row], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
            call BlzFrameSetScale(TUI_RouteText[row], 0.86)
            call BlzFrameSetEnable(TUI_RouteText[row], false)

            set TUI_RoutePrice[row] = BlzCreateFrameByType("TEXT", "TravelUIRoutePrice" + I2S(row), TUI_RouteButton[row], "", 0)
            call BlzFrameSetPoint(TUI_RoutePrice[row], FRAMEPOINT_TOPRIGHT, TUI_RouteButton[row], FRAMEPOINT_TOPRIGHT, -0.007, -0.004)
            call BlzFrameSetPoint(TUI_RoutePrice[row], FRAMEPOINT_BOTTOMRIGHT, TUI_RouteButton[row], FRAMEPOINT_BOTTOMRIGHT, -0.007, 0.004)
            call BlzFrameSetTextAlignment(TUI_RoutePrice[row], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
            call BlzFrameSetScale(TUI_RoutePrice[row], 0.76)
            call BlzFrameSetEnable(TUI_RoutePrice[row], false)

            set TUI_RouteHighlight[row] = BlzCreateFrameByType("SPRITE", "TravelUIRouteHighlight" + I2S(row), TUI_RouteButton[row], "", 0)
            call BlzFrameSetAllPoints(TUI_RouteHighlight[row], TUI_RouteButton[row])
            call BlzFrameSetModel(TUI_RouteHighlight[row], TUI_HighlightModel, 0)
            call BlzFrameSetScale(TUI_RouteHighlight[row], 0.76)
            call BlzFrameSetEnable(TUI_RouteHighlight[row], false)
            call BlzFrameSetVisible(TUI_RouteHighlight[row], false)

            set rowY = rowY - 0.042
            set row = row + 1
        endloop

        set TUI_DetailTitle = BlzCreateFrameByType("TEXT", "TravelUIDetailTitle", TUI_RightPane, "", 0)
        call BlzFrameSetPoint(TUI_DetailTitle, FRAMEPOINT_TOPLEFT, TUI_RightPane, FRAMEPOINT_TOPLEFT, 0.014, -0.014)
        call BlzFrameSetSize(TUI_DetailTitle, 0.275, 0.020)
        call BlzFrameSetScale(TUI_DetailTitle, 1.00)
        call BlzFrameSetEnable(TUI_DetailTitle, false)

        set TUI_DetailInfo = BlzCreateFrameByType("TEXT", "TravelUIDetailInfo", TUI_RightPane, "", 0)
        call BlzFrameSetPoint(TUI_DetailInfo, FRAMEPOINT_TOPLEFT, TUI_DetailTitle, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.008)
        call BlzFrameSetSize(TUI_DetailInfo, 0.275, 0.064)
        call BlzFrameSetTextAlignment(TUI_DetailInfo, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(TUI_DetailInfo, 0.82)
        call BlzFrameSetEnable(TUI_DetailInfo, false)

        set TUI_PassengerHeading = BlzCreateFrameByType("TEXT", "TravelUIPassengerHeading", TUI_RightPane, "", 0)
        call BlzFrameSetPoint(TUI_PassengerHeading, FRAMEPOINT_TOPLEFT, TUI_RightPane, FRAMEPOINT_TOPLEFT, 0.014, -0.103)
        call BlzFrameSetSize(TUI_PassengerHeading, 0.275, 0.016)
        call BlzFrameSetText(TUI_PassengerHeading, "Passengers - click to include or leave behind")
        call BlzFrameSetScale(TUI_PassengerHeading, 0.84)
        call BlzFrameSetEnable(TUI_PassengerHeading, false)

        set row = 1
        set rowY = -0.124
        loop
            exitwhen row > TUI_MAX_PASSENGER_ROWS
            set TUI_PassengerButton[row] = BlzCreateFrameByType("GLUEBUTTON", "TravelUIPassenger" + I2S(row), TUI_RightPane, "ScoreScreenTabButtonTemplate", 0)
            call BlzFrameSetPoint(TUI_PassengerButton[row], FRAMEPOINT_TOPLEFT, TUI_RightPane, FRAMEPOINT_TOPLEFT, 0.014, rowY)
            call BlzFrameSetSize(TUI_PassengerButton[row], 0.275, 0.021)
            call BlzTriggerRegisterFrameEvent(TUI_PassengerTrigger, TUI_PassengerButton[row], FRAMEEVENT_CONTROL_CLICK)
            call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_PassengerButton[row], FRAMEEVENT_CONTROL_CLICK)
            set TUI_PassengerFrameRow.integer[GetHandleId(TUI_PassengerButton[row])] = row

            set TUI_PassengerText[row] = BlzCreateFrameByType("TEXT", "TravelUIPassengerText" + I2S(row), TUI_PassengerButton[row], "", 0)
            call BlzFrameSetPoint(TUI_PassengerText[row], FRAMEPOINT_TOPLEFT, TUI_PassengerButton[row], FRAMEPOINT_TOPLEFT, 0.006, -0.002)
            call BlzFrameSetPoint(TUI_PassengerText[row], FRAMEPOINT_BOTTOMRIGHT, TUI_PassengerButton[row], FRAMEPOINT_BOTTOMRIGHT, -0.006, 0.002)
            call BlzFrameSetTextAlignment(TUI_PassengerText[row], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
            call BlzFrameSetScale(TUI_PassengerText[row], 0.75)
            call BlzFrameSetEnable(TUI_PassengerText[row], false)

            set rowY = rowY - 0.023
            set row = row + 1
        endloop

        set TUI_Warning = BlzCreateFrameByType("TEXT", "TravelUIWarning", TUI_RightPane, "", 0)
        call BlzFrameSetPoint(TUI_Warning, FRAMEPOINT_BOTTOMLEFT, TUI_RightPane, FRAMEPOINT_BOTTOMLEFT, 0.014, 0.075)
        call BlzFrameSetSize(TUI_Warning, 0.275, 0.032)
        call BlzFrameSetTextAlignment(TUI_Warning, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(TUI_Warning, 0.74)
        call BlzFrameSetEnable(TUI_Warning, false)

        set TUI_StatusText = BlzCreateFrameByType("TEXT", "TravelUIStatus", TUI_RightPane, "", 0)
        call BlzFrameSetPoint(TUI_StatusText, FRAMEPOINT_BOTTOMLEFT, TUI_RightPane, FRAMEPOINT_BOTTOMLEFT, 0.014, 0.045)
        call BlzFrameSetSize(TUI_StatusText, 0.275, 0.026)
        call BlzFrameSetTextAlignment(TUI_StatusText, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(TUI_StatusText, 0.74)
        call BlzFrameSetEnable(TUI_StatusText, false)

        set TUI_GoldText = BlzCreateFrameByType("TEXT", "TravelUIGold", TUI_RightPane, "", 0)
        call BlzFrameSetPoint(TUI_GoldText, FRAMEPOINT_BOTTOMLEFT, TUI_RightPane, FRAMEPOINT_BOTTOMLEFT, 0.014, 0.017)
        call BlzFrameSetSize(TUI_GoldText, 0.150, 0.018)
        call BlzFrameSetScale(TUI_GoldText, 0.82)
        call BlzFrameSetEnable(TUI_GoldText, false)

        set TUI_ActionButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TravelUIAction", TUI_RightPane, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_ActionButton, 0.086, 0.030)
        call BlzFrameSetText(TUI_ActionButton, "Travel")
        call BlzFrameSetPoint(TUI_ActionButton, FRAMEPOINT_BOTTOMRIGHT, TUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.012)
        call BlzTriggerRegisterFrameEvent(TUI_ActionTrigger, TUI_ActionButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_ActionButton, FRAMEEVENT_CONTROL_CLICK)

        set TUI_PromptParent = BlzCreateFrameByType("BACKDROP", "TravelUIPrompt", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetAbsPoint(TUI_PromptParent, FRAMEPOINT_TOPLEFT, 0.215, 0.390)
        call BlzFrameSetAbsPoint(TUI_PromptParent, FRAMEPOINT_BOTTOMRIGHT, 0.585, 0.245)

        set TUI_PromptBackdrop = BlzCreateFrameByType("BACKDROP", "TravelUIPromptBackdrop", TUI_PromptParent, "", 0)
        call BlzFrameSetTexture(TUI_PromptBackdrop, TUI_PanelTexture, 0, false)
        call BlzFrameSetPoint(TUI_PromptBackdrop, FRAMEPOINT_TOPLEFT, TUI_PromptParent, FRAMEPOINT_TOPLEFT, 0.010, -0.010)
        call BlzFrameSetPoint(TUI_PromptBackdrop, FRAMEPOINT_BOTTOMRIGHT, TUI_PromptParent, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.010)
        call BlzFrameSetVertexColor(TUI_PromptBackdrop, BlzConvertColor(255, 0, 0, 0))
        call BlzFrameSetEnable(TUI_PromptBackdrop, false)

        set TUI_PromptTitle = BlzCreateFrameByType("TEXT", "TravelUIPromptTitle", TUI_PromptParent, "", 0)
        call BlzFrameSetPoint(TUI_PromptTitle, FRAMEPOINT_TOPLEFT, TUI_PromptParent, FRAMEPOINT_TOPLEFT, 0.020, -0.022)
        call BlzFrameSetSize(TUI_PromptTitle, 0.330, 0.022)
        call BlzFrameSetTextAlignment(TUI_PromptTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(TUI_PromptTitle, 1.05)
        call BlzFrameSetEnable(TUI_PromptTitle, false)

        set TUI_PromptText = BlzCreateFrameByType("TEXT", "TravelUIPromptText", TUI_PromptParent, "", 0)
        call BlzFrameSetPoint(TUI_PromptText, FRAMEPOINT_TOPLEFT, TUI_PromptTitle, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.008)
        call BlzFrameSetSize(TUI_PromptText, 0.330, 0.030)
        call BlzFrameSetTextAlignment(TUI_PromptText, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(TUI_PromptText, 0.86)
        call BlzFrameSetEnable(TUI_PromptText, false)

        set TUI_PromptConfirmButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TravelUIPromptConfirm", TUI_PromptParent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_PromptConfirmButton, 0.130, 0.032)
        call BlzFrameSetPoint(TUI_PromptConfirmButton, FRAMEPOINT_BOTTOMLEFT, TUI_PromptParent, FRAMEPOINT_BOTTOMLEFT, 0.035, 0.018)
        call BlzTriggerRegisterFrameEvent(TUI_PromptConfirmTrigger, TUI_PromptConfirmButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_PromptConfirmButton, FRAMEEVENT_CONTROL_CLICK)

        set TUI_PromptCancelButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TravelUIPromptCancel", TUI_PromptParent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(TUI_PromptCancelButton, 0.130, 0.032)
        call BlzFrameSetPoint(TUI_PromptCancelButton, FRAMEPOINT_BOTTOMRIGHT, TUI_PromptParent, FRAMEPOINT_BOTTOMRIGHT, -0.035, 0.018)
        call BlzTriggerRegisterFrameEvent(TUI_PromptCancelTrigger, TUI_PromptCancelButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, TUI_PromptCancelButton, FRAMEEVENT_CONTROL_CLICK)

        call BlzFrameSetVisible(TUI_Parent, false)
        call BlzFrameSetVisible(TUI_PromptParent, false)
    endfunction

    private function Init takes nothing returns nothing
        set TUI_RouteFrameRow = Table.create()
        set TUI_PassengerFrameRow = Table.create()
        set TUI_CloseTrigger = CreateTrigger()
        set TUI_RouteTrigger = CreateTrigger()
        set TUI_PassengerTrigger = CreateTrigger()
        set TUI_ActionTrigger = CreateTrigger()
        set TUI_ClearFocusTrigger = CreateTrigger()
        set TUI_EscapeTrigger = CreateTrigger()
        set TUI_PromptConfirmTrigger = CreateTrigger()
        set TUI_PromptCancelTrigger = CreateTrigger()
        call TriggerAddAction(TUI_CloseTrigger, function TUI_OnClose)
        call TriggerAddAction(TUI_RouteTrigger, function TUI_OnRouteClicked)
        call TriggerAddAction(TUI_PassengerTrigger, function TUI_OnPassengerClicked)
        call TriggerAddAction(TUI_ActionTrigger, function TUI_OnAction)
        call TriggerAddAction(TUI_ClearFocusTrigger, function TUI_ClearFocus)
        call TriggerAddAction(TUI_PromptConfirmTrigger, function TUI_OnPromptConfirmed)
        call TriggerAddAction(TUI_PromptCancelTrigger, function TUI_OnPromptCancelled)
        call TriggerRegisterPlayerEventEndCinematic(TUI_EscapeTrigger, Player(0))
        call TriggerAddAction(TUI_EscapeTrigger, function TUI_OnEscape)

        set TUI_LeaveDialog = DialogSystem_CreateDialog("")
        set TUI_LeaveConfirmButton = DialogSystem_AddButton(TUI_LeaveDialog, "Travel and leave them", 1)
        set TUI_LeaveCancelButton = DialogSystem_AddButton(TUI_LeaveDialog, "Go back", 2)
        call DialogSystem_BindButtonCode(TUI_LeaveConfirmButton, function TUI_OnLeaveConfirmed)
        call DialogSystem_BindButtonCode(TUI_LeaveCancelButton, function TUI_OnLeaveCancelled)

        call TUI_CreateFrames()
        call TravelSystem_RegisterMasterSelectedHandler(function TUI_OnMasterSelected)
        call TravelSystem_RegisterPromptChangedHandler(function TUI_OnPromptChanged)
        set TUI_Initialized = true
    endfunction
endlibrary
