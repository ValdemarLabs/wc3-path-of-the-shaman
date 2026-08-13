/**
    TravelShipB

    Author: Valdemar
    Version:

    Description:
    Connects the existing Orc Frigate PatrolSystem route to TravelSystem. The
    ship remains persistent and reports Mok'natha, Frontline Base, and
    Ironspine Post dock arrivals without duplicating its 87-waypoint patrol.

    Credits:
    The original TravelShipB GUI triggers and patrol route.

    How to install:
    Import after TravelSystem and TravelUI. Keep TravelShip Init and
    TravelShipB_MovementStart enabled so udg_TravelShipB and its patrol exist.

    API:
    - TravelShipB_GetMoknathaStop()
    - TravelShipB_GetFrontlineStop()
    - TravelShipB_GetIronspineStop()
    - TravelShipB_GetFrontlineRoute()
    - TravelShipB_GetIronspineRoute()
    - call TravelShipB_ConfigureHeroModels(...)

**/
library TravelShipB initializer Init requires TravelSystem, TravelUI
    globals
        private constant integer TSB_ZONE_MOKNATHA = 1401
        private constant integer TSB_ZONE_IRONSPINE = 1901
        private constant integer TSB_FARE_FRONTLINE = 100
        private constant integer TSB_FARE_IRONSPINE = 175
        private constant integer TSB_SKIP_FEE = 100
        private constant real TSB_DOCK_CHECK_PERIOD = 0.50

        private integer TSB_MoknathaStop = 0
        private integer TSB_FrontlineStop = 0
        private integer TSB_IronspineStop = 0
        private integer TSB_FrontlineRoute = 0
        private integer TSB_IronspineRoute = 0
        private integer TSB_CurrentDock = 0
        private timer TSB_InitTimer = null
        private timer TSB_DockTimer = null
        private boolean TSB_Initialized = false
    endglobals

    private function TSB_RectCenterX takes rect whichRect returns real
        return (GetRectMinX(whichRect) + GetRectMaxX(whichRect)) * 0.50
    endfunction

    private function TSB_RectCenterY takes rect whichRect returns real
        return (GetRectMinY(whichRect) + GetRectMaxY(whichRect)) * 0.50
    endfunction

    private function TSB_UnitInRect takes unit whichUnit, rect whichRect returns boolean
        local real x
        local real y

        if whichUnit == null or whichRect == null then
            return false
        endif
        set x = GetUnitX(whichUnit)
        set y = GetUnitY(whichUnit)
        return x >= GetRectMinX(whichRect) and x <= GetRectMaxX(whichRect) and y >= GetRectMinY(whichRect) and y <= GetRectMaxY(whichRect)
    endfunction

    private function TSB_GetDock takes nothing returns integer
        if TSB_UnitInRect(udg_TravelShipB, gg_rct_ShipBMoknatha) then
            return TSB_MoknathaStop
        elseif TSB_UnitInRect(udg_TravelShipB, gg_rct_ShipBFrontBase) then
            return TSB_FrontlineStop
        elseif TSB_UnitInRect(udg_TravelShipB, gg_rct_ShipBIronspinePost) then
            return TSB_IronspineStop
        endif
        return 0
    endfunction

    public function GetMoknathaStop takes nothing returns integer
        return TSB_MoknathaStop
    endfunction

    public function GetFrontlineStop takes nothing returns integer
        return TSB_FrontlineStop
    endfunction

    public function GetIronspineStop takes nothing returns integer
        return TSB_IronspineStop
    endfunction

    public function GetFrontlineRoute takes nothing returns integer
        return TSB_FrontlineRoute
    endfunction

    public function GetIronspineRoute takes nothing returns integer
        return TSB_IronspineRoute
    endfunction

    public function ConfigureHeroModels takes string nazgrekModel, real nazgrekScale, real nazgrekFacingOffset, string zulkisModel, real zulkisScale, real zulkisFacingOffset returns nothing
        if udg_Nazgrek != null then
            call TravelSystem_RegisterPassengerEffect(GetUnitTypeId(udg_Nazgrek), nazgrekModel, nazgrekScale, nazgrekFacingOffset)
        endif
        if udg_Zulkis != null then
            call TravelSystem_RegisterPassengerEffect(GetUnitTypeId(udg_Zulkis), zulkisModel, zulkisScale, zulkisFacingOffset)
        endif
    endfunction

    private function TSB_OnDockCheck takes nothing returns nothing
        local integer newDock

        if not TSB_Initialized or udg_TravelShipB == null or GetUnitTypeId(udg_TravelShipB) == 0 then
            return
        endif
        set newDock = TSB_GetDock()
        if newDock == TSB_CurrentDock then
            return
        endif
        set TSB_CurrentDock = newDock
        if newDock > 0 then
            call TravelSystem_NotifyScheduledStop(udg_TravelShipB, newDock)
            if newDock == TSB_MoknathaStop then
                call TravelSystem_SetRouteAvailable(TSB_FrontlineRoute, true)
                call TravelSystem_SetRouteAvailable(TSB_IronspineRoute, true)
            endif
        else
            call TravelSystem_NotifyScheduledLeave(udg_TravelShipB)
        endif
    endfunction

    private function TSB_TryInitialize takes nothing returns nothing
        if TSB_Initialized then
            return
        endif
        if udg_TravelShipB == null or udg_Shipmaster[1] == null then
            call TimerStart(TSB_InitTimer, 1.00, false, function TSB_TryInitialize)
            return
        endif

        set TSB_MoknathaStop = TravelSystem_RegisterStop(TRAVEL_METHOD_SHIP_B, "Mok'natha", TSB_ZONE_MOKNATHA, udg_Shipmaster[1], gg_rct_TravelShipMoknatha, TSB_RectCenterX(gg_rct_TravelShipMoknathaDeck), TSB_RectCenterY(gg_rct_TravelShipMoknathaDeck), false)
        set TSB_FrontlineStop = TravelSystem_RegisterStop(TRAVEL_METHOD_SHIP_B, "Frontline Base", 0, null, gg_rct_TravelShipFrontbaseDeck, TSB_RectCenterX(gg_rct_TravelShipFrontbaseDeck), TSB_RectCenterY(gg_rct_TravelShipFrontbaseDeck), false)
        set TSB_IronspineStop = TravelSystem_RegisterStop(TRAVEL_METHOD_SHIP_B, "Ironspine Post", TSB_ZONE_IRONSPINE, null, gg_rct_TravelShipIronspineDeck, TSB_RectCenterX(gg_rct_TravelShipIronspineDeck), TSB_RectCenterY(gg_rct_TravelShipIronspineDeck), false)

        if TSB_MoknathaStop <= 0 or TSB_FrontlineStop <= 0 or TSB_IronspineStop <= 0 then
            call TimerStart(TSB_InitTimer, 1.00, false, function TSB_TryInitialize)
            return
        endif

        set TSB_FrontlineRoute = TravelSystem_RegisterRoute(TRAVEL_METHOD_SHIP_B, TSB_MoknathaStop, TSB_FrontlineStop, TSB_FARE_FRONTLINE, TSB_SKIP_FEE)
        set TSB_IronspineRoute = TravelSystem_RegisterRoute(TRAVEL_METHOD_SHIP_B, TSB_MoknathaStop, TSB_IronspineStop, TSB_FARE_IRONSPINE, TSB_SKIP_FEE)
        call TravelSystem_SetRouteDiscoveryRequirements(TSB_FrontlineRoute, false, false)
        call TravelSystem_SetRouteDiscoveryRequirements(TSB_IronspineRoute, false, false)
        call TravelSystem_SetRouteVehicle(TSB_FrontlineRoute, udg_TravelShipB, true, true)
        call TravelSystem_SetRouteVehicle(TSB_IronspineRoute, udg_TravelShipB, true, true)
        call TravelSystem_SetRouteShowPassengers(TSB_FrontlineRoute, true)
        call TravelSystem_SetRouteShowPassengers(TSB_IronspineRoute, true)
        call TravelSystem_AddWaypoint(TSB_FrontlineRoute, 0.00, 0.00, TSB_FrontlineStop)
        call TravelSystem_AddWaypoint(TSB_IronspineRoute, 0.00, 0.00, TSB_FrontlineStop)
        call TravelSystem_AddWaypoint(TSB_IronspineRoute, 0.00, 0.00, TSB_IronspineStop)

        // Object Editor model paths can be supplied later without creating dummy units.
        call ConfigureHeroModels("", 1.00, 0.00, "", 1.00, 0.00)

        set TSB_Initialized = true
        set TSB_CurrentDock = 0
        call TSB_OnDockCheck()
        call TimerStart(TSB_DockTimer, TSB_DOCK_CHECK_PERIOD, true, function TSB_OnDockCheck)
        call PauseTimer(TSB_InitTimer)
    endfunction

    private function Init takes nothing returns nothing
        set TSB_InitTimer = CreateTimer()
        set TSB_DockTimer = CreateTimer()
        call TimerStart(TSB_InitTimer, 5.10, false, function TSB_TryInitialize)
    endfunction
endlibrary
