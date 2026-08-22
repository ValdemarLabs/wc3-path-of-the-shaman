/**
    TravelWyvern

    Author: Valdemar
    Version: 1.1.0

    Description:
    Registers all six placed Wind Rider Masters and the directed flight
    network between them. Temporary wyvern and bat carriers are configured
    here while TravelSystem owns flight presentation and movement.

    Credits:
    The original Wind Rider Master GUI triggers.

    How to install:
    Import after TravelSystem and TravelUI. Keep the three legacy boarding
    areas, FlyHere rects, and configured FPRoute rects. Masters 4..6 use their
    placed unit positions.

    API:
    - set stopId = TravelWyvern_RegisterStation(...)
    - set routeId = TravelWyvern_RegisterDirectedRoute(...)
    - call TravelWyvern_AddWaypoint(...)
    - TravelWyvern_GetScoutBaseStop()
    - TravelWyvern_GetLumberMillStop()
    - TravelWyvern_GetGoldMineStop()
    - TravelWyvern_GetVerdantPlainsStop()
    - TravelWyvern_GetAshfangOutpostStop()
    - TravelWyvern_GetSirensongStop()
    - call TravelWyvern_DiscoverVerdantPlains(...)

**/
library TravelWyvern initializer Init requires TravelSystem, TravelUI
    globals
        private constant integer TW_ZONE_HORDE_SCOUT_BASE = 8810
        private constant integer TW_ZONE_VERDANT_PLAINS = 17
        private constant integer TW_ZONE_ASHFANG_OUTPOST = 401
        private constant integer TW_ZONE_SIRENSONG = 14
        private constant integer TW_LEGACY_FARE = 350
        private constant integer TW_SKIP_FEE = 100
        private constant integer TW_NAZGREK_CARRIER = 'o60L'
        private constant integer TW_ZULKIS_CARRIER = 'o613'
        private constant real TW_FLY_HEIGHT = 500.00
        private constant real TW_MOVE_SPEED = 400.00

        private integer array TW_Stop
        private integer array TW_Waypoint
        private integer array TW_FlightWaypoint
        private integer TW_ScoutBaseStop = 0
        private integer TW_LumberMillStop = 0
        private integer TW_GoldMineStop = 0
        private integer TW_VerdantPlainsStop = 0
        private integer TW_AshfangOutpostStop = 0
        private integer TW_SirensongStop = 0
        private boolean TW_DiscoverVerdantOnInit = false
        private boolean TW_ShowVerdantDiscoveryOnInit = false
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
        if master == null then
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

    public function GetVerdantPlainsStop takes nothing returns integer
        return TW_VerdantPlainsStop
    endfunction

    public function GetAshfangOutpostStop takes nothing returns integer
        return TW_AshfangOutpostStop
    endfunction

    public function GetSirensongStop takes nothing returns integer
        return TW_SirensongStop
    endfunction

    public function DiscoverVerdantPlains takes boolean showMessage returns nothing
        if TW_VerdantPlainsStop > 0 then
            call TravelSystem_DiscoverStop(TW_VerdantPlainsStop, showMessage)
        else
            set TW_DiscoverVerdantOnInit = true
            set TW_ShowVerdantDiscoveryOnInit = TW_ShowVerdantDiscoveryOnInit or showMessage
        endif
    endfunction

    private function TW_RegisterFlightWaypoint takes integer index, rect waypointRect returns nothing
        set TW_FlightWaypoint[index] = TravelSystem_RegisterWaypoint(TW_RectCenterX(waypointRect), TW_RectCenterY(waypointRect))
    endfunction

    private function TW_CreateWaypoints takes nothing returns boolean
        local integer index = 1

        loop
            exitwhen index > 6
            set TW_Waypoint[index] = TravelSystem_RegisterWaypoint(TravelSystem_GetStopX(TW_Stop[index]), TravelSystem_GetStopY(TW_Stop[index]))
            if TW_Waypoint[index] <= 0 then
                return false
            endif
            set index = index + 1
        endloop

        call TW_RegisterFlightWaypoint(1, gg_rct_FPRoute001)
        call TW_RegisterFlightWaypoint(2, gg_rct_FPRoute002)
        call TW_RegisterFlightWaypoint(3, gg_rct_FPRoute003)
        call TW_RegisterFlightWaypoint(4, gg_rct_FPRoute004)
        call TW_RegisterFlightWaypoint(5, gg_rct_FPRoute005)
        call TW_RegisterFlightWaypoint(6, gg_rct_FPRoute006)
        call TW_RegisterFlightWaypoint(7, gg_rct_FPRoute007)
        call TW_RegisterFlightWaypoint(8, gg_rct_FPRoute008)
        call TW_RegisterFlightWaypoint(9, gg_rct_FPRoute009)
        call TW_RegisterFlightWaypoint(10, gg_rct_FPRoute010)
        call TW_RegisterFlightWaypoint(11, gg_rct_FPRoute011)
        call TW_RegisterFlightWaypoint(12, gg_rct_FPRoute012)
        call TW_RegisterFlightWaypoint(13, gg_rct_FPRoute013)
        call TW_RegisterFlightWaypoint(14, gg_rct_FPRoute014)
        call TW_RegisterFlightWaypoint(15, gg_rct_FPRoute015)
        call TW_RegisterFlightWaypoint(16, gg_rct_FPRoute016)
        call TW_RegisterFlightWaypoint(17, gg_rct_FPRoute017)
        call TW_RegisterFlightWaypoint(18, gg_rct_FPRoute018)
        call TW_RegisterFlightWaypoint(19, gg_rct_FPRoute019)
        call TW_RegisterFlightWaypoint(20, gg_rct_FPRoute020)
        call TW_RegisterFlightWaypoint(21, gg_rct_FPRoute021)
        call TW_RegisterFlightWaypoint(22, gg_rct_FPRoute022)
        call TW_RegisterFlightWaypoint(23, gg_rct_FPRoute023)
        call TW_RegisterFlightWaypoint(24, gg_rct_FPRoute024)
        call TW_RegisterFlightWaypoint(25, gg_rct_FPRoute025)
        call TW_RegisterFlightWaypoint(26, gg_rct_FPRoute026)
        call TW_RegisterFlightWaypoint(27, gg_rct_FPRoute027)
        call TW_RegisterFlightWaypoint(28, gg_rct_FPRoute028)

        set index = 1
        loop
            exitwhen index > 28
            if TW_FlightWaypoint[index] <= 0 then
                return false
            endif
            set index = index + 1
        endloop
        return true
    endfunction

    private function TW_AddWaypointRange takes integer routeId, integer firstIndex, integer lastIndex returns nothing
        local integer step = 1

        if firstIndex > lastIndex then
            set step = -1
        endif
        loop
            call TravelSystem_AddRegisteredWaypoint(routeId, TW_FlightWaypoint[firstIndex], 0)
            exitwhen firstIndex == lastIndex
            set firstIndex = firstIndex + step
        endloop
    endfunction

    private function TW_AddConfiguredRouteWaypoints takes integer routeId, integer startIndex, integer endIndex returns nothing
        if startIndex == TRAVEL_WINDRIDER_MASTER_SIRENSONG and endIndex == TRAVEL_WINDRIDER_MASTER_HORDE_SCOUT_BASE then
            call TW_AddWaypointRange(routeId, 1, 19)
        elseif startIndex == TRAVEL_WINDRIDER_MASTER_HORDE_SCOUT_BASE and endIndex == TRAVEL_WINDRIDER_MASTER_SIRENSONG then
            call TW_AddWaypointRange(routeId, 19, 1)
        elseif startIndex == TRAVEL_WINDRIDER_MASTER_HORDE_SCOUT_BASE and endIndex == TRAVEL_WINDRIDER_MASTER_ASHFANG_OUTPOST then
            call TW_AddWaypointRange(routeId, 19, 15)
            call TW_AddWaypointRange(routeId, 20, 28)
        elseif startIndex == TRAVEL_WINDRIDER_MASTER_ASHFANG_OUTPOST and endIndex == TRAVEL_WINDRIDER_MASTER_HORDE_SCOUT_BASE then
            call TW_AddWaypointRange(routeId, 28, 20)
            call TW_AddWaypointRange(routeId, 15, 19)
        endif
    endfunction

    private function TW_CreateNetwork takes nothing returns nothing
        local integer startIndex = 1
        local integer endIndex
        local integer fare
        local integer routeId

        loop
            exitwhen startIndex > 6
            set endIndex = 1
            loop
                exitwhen endIndex > 6
                if startIndex != endIndex then
                    set fare = TW_LEGACY_FARE
                    if endIndex == TRAVEL_WINDRIDER_MASTER_HORDE_SCOUT_BASE then
                        set fare = 0
                    endif
                    set routeId = RegisterDirectedRoute(TW_Stop[startIndex], TW_Stop[endIndex], fare)
                    if routeId > 0 then
                        call TW_AddConfiguredRouteWaypoints(routeId, startIndex, endIndex)
                        // Keep the stop drop point last so the carrier lands after all route rects.
                        call TravelSystem_AddRegisteredWaypoint(routeId, TW_Waypoint[endIndex], 0)
                    endif
                endif
                set endIndex = endIndex + 1
            endloop
            set startIndex = startIndex + 1
        endloop
    endfunction

    private function TW_TryInitialize takes nothing returns nothing
        local unit scoutMaster = TW_GetMaster(TRAVEL_WINDRIDER_MASTER_HORDE_SCOUT_BASE)
        local unit lumberMaster = TW_GetMaster(TRAVEL_WINDRIDER_MASTER_HORDE_LUMBER_MILL)
        local unit goldMaster = TW_GetMaster(TRAVEL_WINDRIDER_MASTER_HORDE_GOLD_MINE)
        local unit verdantMaster = TW_GetMaster(TRAVEL_WINDRIDER_MASTER_VERDANT_PLAINS)
        local unit ashfangMaster = TW_GetMaster(TRAVEL_WINDRIDER_MASTER_ASHFANG_OUTPOST)
        local unit sirensongMaster = TW_GetMaster(TRAVEL_WINDRIDER_MASTER_SIRENSONG)

        if TW_Initialized then
            set scoutMaster = null
            set lumberMaster = null
            set goldMaster = null
            set verdantMaster = null
            set ashfangMaster = null
            set sirensongMaster = null
            return
        endif
        if scoutMaster == null or lumberMaster == null or goldMaster == null or verdantMaster == null or ashfangMaster == null or sirensongMaster == null then
            call TimerStart(TW_InitTimer, 1.00, false, function TW_TryInitialize)
            set scoutMaster = null
            set lumberMaster = null
            set goldMaster = null
            set verdantMaster = null
            set ashfangMaster = null
            set sirensongMaster = null
            return
        endif

        set TW_ScoutBaseStop = RegisterStation("Horde Scout Base", TW_ZONE_HORDE_SCOUT_BASE, scoutMaster, gg_rct_HordeScoutBaseWindRiderArea, TW_RectCenterX(gg_rct_FlyHere01), TW_RectCenterY(gg_rct_FlyHere01))
        set TW_LumberMillStop = RegisterStation("Horde Lumber Mill", 0, lumberMaster, gg_rct_HordeLumberMillWindRiderArea, TW_RectCenterX(gg_rct_FlyHere02), TW_RectCenterY(gg_rct_FlyHere02))
        set TW_GoldMineStop = RegisterStation("Horde Gold Mine", 0, goldMaster, gg_rct_HordeGoldMineWindRiderArea, TW_RectCenterX(gg_rct_FlyHere03), TW_RectCenterY(gg_rct_FlyHere03))
        set TW_VerdantPlainsStop = RegisterStation("Verdant Plains", TW_ZONE_VERDANT_PLAINS, verdantMaster, null, GetUnitX(verdantMaster), GetUnitY(verdantMaster))
        set TW_AshfangOutpostStop = RegisterStation("Ashfang Outpost", TW_ZONE_ASHFANG_OUTPOST, ashfangMaster, null, GetUnitX(ashfangMaster), GetUnitY(ashfangMaster))
        set TW_SirensongStop = RegisterStation("Sirensong", TW_ZONE_SIRENSONG, sirensongMaster, null, GetUnitX(sirensongMaster), GetUnitY(sirensongMaster))

        set TW_Stop[1] = TW_ScoutBaseStop
        set TW_Stop[2] = TW_LumberMillStop
        set TW_Stop[3] = TW_GoldMineStop
        set TW_Stop[4] = TW_VerdantPlainsStop
        set TW_Stop[5] = TW_AshfangOutpostStop
        set TW_Stop[6] = TW_SirensongStop
        if TW_Stop[1] <= 0 or TW_Stop[2] <= 0 or TW_Stop[3] <= 0 or TW_Stop[4] <= 0 or TW_Stop[5] <= 0 or TW_Stop[6] <= 0 then
            call TimerStart(TW_InitTimer, 1.00, false, function TW_TryInitialize)
            set scoutMaster = null
            set lumberMaster = null
            set goldMaster = null
            set verdantMaster = null
            set ashfangMaster = null
            set sirensongMaster = null
            return
        endif
        if not TW_CreateWaypoints() then
            call TimerStart(TW_InitTimer, 1.00, false, function TW_TryInitialize)
            set scoutMaster = null
            set lumberMaster = null
            set goldMaster = null
            set verdantMaster = null
            set ashfangMaster = null
            set sirensongMaster = null
            return
        endif

        call TW_CreateNetwork()
        if TW_DiscoverVerdantOnInit then
            call TravelSystem_DiscoverStop(TW_VerdantPlainsStop, TW_ShowVerdantDiscoveryOnInit)
        endif
        set TW_Initialized = true
        call PauseTimer(TW_InitTimer)
        call DestroyTimer(TW_InitTimer)
        set TW_InitTimer = null
        set scoutMaster = null
        set lumberMaster = null
        set goldMaster = null
        set verdantMaster = null
        set ashfangMaster = null
        set sirensongMaster = null
    endfunction

    private function Init takes nothing returns nothing
        set TW_InitTimer = CreateTimer()
        call TimerStart(TW_InitTimer, 0.10, false, function TW_TryInitialize)
    endfunction
endlibrary
