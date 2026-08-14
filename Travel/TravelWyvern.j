/**
    TravelWyvern

    Author: Valdemar
    Version:

    Description:
    Registers the three legacy Horde wyvern stations and their directed fares.
    Additional stations and routes can be registered without changing the
    travel runtime.

    Credits:
    The original Wind Rider Master GUI triggers.

    How to install:
    Import after TravelSystem and TravelUI. Keep the three legacy master,
    boarding-area, and FlyHere rect globals in the map.

    API:
    - set stopId = TravelWyvern_RegisterStation(...)
    - set routeId = TravelWyvern_RegisterDirectedRoute(...)
    - call TravelWyvern_AddWaypoint(...)
    - TravelWyvern_GetScoutBaseStop()
    - TravelWyvern_GetLumberMillStop()
    - TravelWyvern_GetGoldMineStop()

**/
library TravelWyvern initializer Init requires TravelSystem, TravelUI
    globals
        private constant integer TW_ZONE_HORDE_SCOUT_BASE = 8810
        private constant integer TW_LEGACY_FARE = 350
        private constant integer TW_SKIP_FEE = 100
        private constant integer TW_NAZGREK_CARRIER = 'o60L'
        private constant integer TW_ZULKIS_CARRIER = 'o613'
        private constant real TW_FLY_HEIGHT = 500.00
        private constant real TW_MOVE_SPEED = 400.00

        private integer TW_ScoutBaseStop = 0
        private integer TW_LumberMillStop = 0
        private integer TW_GoldMineStop = 0
        private timer TW_InitTimer = null
        private boolean TW_Initialized = false
    endglobals

    private function TW_RectCenterX takes rect whichRect returns real
        return (GetRectMinX(whichRect) + GetRectMaxX(whichRect)) * 0.50
    endfunction

    private function TW_RectCenterY takes rect whichRect returns real
        return (GetRectMinY(whichRect) + GetRectMaxY(whichRect)) * 0.50
    endfunction

    private function TW_GetMaster takes integer index returns unit
        return TravelSystem_GetWindRiderMaster(index)
    endfunction

    public function RegisterStation takes string name, integer zoneId, unit master, rect boardingArea, real dropX, real dropY returns integer
        if master == null or boardingArea == null then
            return 0
        endif
        return TravelSystem_RegisterStop(TRAVEL_METHOD_WYVERN, name, zoneId, master, boardingArea, dropX, dropY, true)
    endfunction

    public function RegisterDirectedRoute takes integer startStop, integer endStop, integer fare returns integer
        local integer routeId = TravelSystem_RegisterRoute(TRAVEL_METHOD_WYVERN, startStop, endStop, fare, TW_SKIP_FEE)

        if routeId > 0 then
            call TravelSystem_SetRouteDiscoveryRequirements(routeId, true, true)
            call TravelSystem_SetRouteShowPassengers(routeId, false)
            call TravelSystem_SetRouteCarrierTypes(routeId, TW_NAZGREK_CARRIER, TW_ZULKIS_CARRIER, TW_FLY_HEIGHT, TW_MOVE_SPEED)
        endif
        return routeId
    endfunction

    public function AddWaypoint takes integer routeId, real x, real y returns boolean
        return TravelSystem_AddWaypoint(routeId, x, y, 0)
    endfunction

    public function GetScoutBaseStop takes nothing returns integer
        return TW_ScoutBaseStop
    endfunction

    public function GetLumberMillStop takes nothing returns integer
        return TW_LumberMillStop
    endfunction

    public function GetGoldMineStop takes nothing returns integer
        return TW_GoldMineStop
    endfunction

    private function TW_CreateLegacyRoute takes integer startStop, integer endStop, integer fare, rect destination returns nothing
        local integer routeId = RegisterDirectedRoute(startStop, endStop, fare)

        if routeId > 0 then
            call AddWaypoint(routeId, TW_RectCenterX(destination), TW_RectCenterY(destination))
        endif
    endfunction

    private function TW_TryInitialize takes nothing returns nothing
        local unit scoutMaster
        local unit lumberMaster
        local unit goldMaster

        if TW_Initialized then
            set scoutMaster = null
            set lumberMaster = null
            set goldMaster = null
            return
        endif
        set scoutMaster = TW_GetMaster(TRAVEL_WINDRIDER_MASTER_HORDE_SCOUT_BASE)
        set lumberMaster = TW_GetMaster(TRAVEL_WINDRIDER_MASTER_HORDE_LUMBER_MILL)
        set goldMaster = TW_GetMaster(TRAVEL_WINDRIDER_MASTER_HORDE_GOLD_MINE)
        if scoutMaster == null or lumberMaster == null or goldMaster == null then
            call TimerStart(TW_InitTimer, 1.00, false, function TW_TryInitialize)
            set scoutMaster = null
            set lumberMaster = null
            set goldMaster = null
            return
        endif

        set TW_ScoutBaseStop = RegisterStation("Horde Scout Base", TW_ZONE_HORDE_SCOUT_BASE, scoutMaster, gg_rct_HordeScoutBaseWindRiderArea, TW_RectCenterX(gg_rct_FlyHere01), TW_RectCenterY(gg_rct_FlyHere01))
        set TW_LumberMillStop = RegisterStation("Horde Lumber Mill", 0, lumberMaster, gg_rct_HordeLumberMillWindRiderArea, TW_RectCenterX(gg_rct_FlyHere02), TW_RectCenterY(gg_rct_FlyHere02))
        set TW_GoldMineStop = RegisterStation("Horde Gold Mine", 0, goldMaster, gg_rct_HordeGoldMineWindRiderArea, TW_RectCenterX(gg_rct_FlyHere03), TW_RectCenterY(gg_rct_FlyHere03))

        if TW_ScoutBaseStop <= 0 or TW_LumberMillStop <= 0 or TW_GoldMineStop <= 0 then
            call TimerStart(TW_InitTimer, 1.00, false, function TW_TryInitialize)
            set scoutMaster = null
            set lumberMaster = null
            set goldMaster = null
            return
        endif

        call TW_CreateLegacyRoute(TW_ScoutBaseStop, TW_LumberMillStop, TW_LEGACY_FARE, gg_rct_FlyHere02)
        call TW_CreateLegacyRoute(TW_ScoutBaseStop, TW_GoldMineStop, TW_LEGACY_FARE, gg_rct_FlyHere03)
        call TW_CreateLegacyRoute(TW_LumberMillStop, TW_ScoutBaseStop, 0, gg_rct_FlyHere01)
        call TW_CreateLegacyRoute(TW_LumberMillStop, TW_GoldMineStop, TW_LEGACY_FARE, gg_rct_FlyHere03)
        call TW_CreateLegacyRoute(TW_GoldMineStop, TW_ScoutBaseStop, 0, gg_rct_FlyHere01)
        call TW_CreateLegacyRoute(TW_GoldMineStop, TW_LumberMillStop, TW_LEGACY_FARE, gg_rct_FlyHere02)

        set TW_Initialized = true
        call PauseTimer(TW_InitTimer)
        call DestroyTimer(TW_InitTimer)
        set TW_InitTimer = null
        set scoutMaster = null
        set lumberMaster = null
        set goldMaster = null
    endfunction

    private function Init takes nothing returns nothing
        set TW_InitTimer = CreateTimer()
        call TimerStart(TW_InitTimer, 0.10, false, function TW_TryInitialize)
    endfunction
endlibrary
