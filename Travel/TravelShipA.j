/**
    TravelShipA

    Author: Valdemar
    Version:

    Description:
    Owns the neutral transport ship's Sirensong-Dawnhold-Stormhaven patrol
    and connects its scheduled dock arrivals to TravelSystem.

    Credits:
    The original PotS neutral travel-ship route.

    How to install:
    Import after TravelSystem, TravelUI, and PatrolSystem. Keep the documented
    ShipA dock, boarding, deck, and SirensongShip waypoint rects in the map.

    API:
    - TravelShipA_GetSirensongStop()
    - TravelShipA_GetDawnholdStop()
    - TravelShipA_GetStormhavenStop()
    - set stopId = TravelShipA_RegisterStop(...)
    - set routeId = TravelShipA_RegisterScheduledRoute(...)

**/
library TravelShipA initializer Init requires TravelSystem, TravelUI, PatrolSystem
    globals
        private constant integer TSA_ZONE_SIRENSONG = 14
        private constant integer TSA_ZONE_DAWNHOLD = 20
        private constant integer TSA_ZONE_STORMHAVEN = 13
        // Adjacent-leg and full-route fares remain easy to tune here.
        private constant integer TSA_FARE_ADJACENT = 100
        private constant integer TSA_FARE_FULL = 175
        private constant integer TSA_SKIP_FEE = 100
        private constant real TSA_DOCK_WAIT = 30.00
        private constant real TSA_DOCK_CHECK_PERIOD = 0.50
        private constant real TSA_PATROL_START_DELAY = 45.00
        private constant integer TSA_PATROL_POINT_COUNT = 64

        private integer TSA_SirensongStop = 0
        private integer TSA_DawnholdStop = 0
        private integer TSA_StormhavenStop = 0
        private integer TSA_SirensongToDawnhold = 0
        private integer TSA_SirensongToStormhaven = 0
        private integer TSA_DawnholdToSirensong = 0
        private integer TSA_DawnholdToStormhaven = 0
        private integer TSA_StormhavenToDawnhold = 0
        private integer TSA_StormhavenToSirensong = 0
        private integer TSA_CurrentDock = 0
        private integer TSA_LastDock = 0
        private timer TSA_InitTimer = null
        private timer TSA_DockTimer = null
        private timer TSA_PatrolTimer = null
        private boolean TSA_Initialized = false
        private boolean TSA_PatrolStarted = false
    endglobals

    private function TSA_RectCenterX takes rect whichRect returns real
        return (GetRectMinX(whichRect) + GetRectMaxX(whichRect)) * 0.50
    endfunction

    private function TSA_RectCenterY takes rect whichRect returns real
        return (GetRectMinY(whichRect) + GetRectMaxY(whichRect)) * 0.50
    endfunction

    private function TSA_UnitInRect takes unit whichUnit, rect whichRect returns boolean
        local real x
        local real y

        if whichUnit == null or whichRect == null then
            return false
        endif
        set x = GetUnitX(whichUnit)
        set y = GetUnitY(whichUnit)
        return x >= GetRectMinX(whichRect) and x <= GetRectMaxX(whichRect) and y >= GetRectMinY(whichRect) and y <= GetRectMaxY(whichRect)
    endfunction

    private function TSA_GetShip takes nothing returns unit
        return TravelSystem_GetTravelShipA()
    endfunction

    private function TSA_GetDock takes nothing returns integer
        local unit ship = TSA_GetShip()
        local integer stopId = 0

        if TSA_UnitInRect(ship, gg_rct_ShipSirensong) then
            set stopId = TSA_SirensongStop
        elseif TSA_UnitInRect(ship, gg_rct_ShipADawnhold) then
            set stopId = TSA_DawnholdStop
        elseif TSA_UnitInRect(ship, gg_rct_ShipAStormhaven) then
            set stopId = TSA_StormhavenStop
        endif
        set ship = null
        return stopId
    endfunction

    public function GetSirensongStop takes nothing returns integer
        return TSA_SirensongStop
    endfunction

    public function GetDawnholdStop takes nothing returns integer
        return TSA_DawnholdStop
    endfunction

    public function GetStormhavenStop takes nothing returns integer
        return TSA_StormhavenStop
    endfunction

    public function RegisterStopEx takes string name, integer zoneId, unit master, rect boardingArea, real dropX, real dropY, boolean requiresDiscovery returns integer
        if boardingArea == null then
            return 0
        endif
        return TravelSystem_RegisterStop(TRAVEL_METHOD_SHIP_A, name, zoneId, master, boardingArea, dropX, dropY, requiresDiscovery)
    endfunction

    public function RegisterStop takes string name, integer zoneId, unit master, rect boardingArea, real dropX, real dropY returns integer
        return RegisterStopEx(name, zoneId, master, boardingArea, dropX, dropY, false)
    endfunction

    public function RegisterDirectRoute takes integer startStop, integer endStop, integer fare, unit ship returns integer
        local integer routeId

        if ship == null then
            return 0
        endif
        set routeId = TravelSystem_RegisterRoute(TRAVEL_METHOD_SHIP_A, startStop, endStop, fare, TSA_SKIP_FEE)
        if routeId > 0 then
            call TravelSystem_SetRouteDiscoveryRequirements(routeId, false, false)
            call TravelSystem_SetRouteShowPassengers(routeId, true)
            call TravelSystem_SetRouteVehicle(routeId, ship, false, false)
        endif
        return routeId
    endfunction

    public function RegisterScheduledRoute takes integer startStop, integer endStop, integer fare, unit ship, boolean usesPatrolSystem returns integer
        local integer routeId

        if ship == null then
            return 0
        endif
        set routeId = TravelSystem_RegisterRoute(TRAVEL_METHOD_SHIP_A, startStop, endStop, fare, TSA_SKIP_FEE)
        if routeId > 0 then
            call TravelSystem_SetRouteDiscoveryRequirements(routeId, false, false)
            call TravelSystem_SetRouteShowPassengers(routeId, true)
            call TravelSystem_SetRouteVehicle(routeId, ship, true, usesPatrolSystem)
            call TravelSystem_SetRouteAvailable(routeId, false)
        endif
        return routeId
    endfunction

    public function AddWaypoint takes integer routeId, real x, real y, integer stopId returns boolean
        return TravelSystem_AddWaypoint(routeId, x, y, stopId)
    endfunction

    private function TSA_SetPatrolPoint takes integer index, rect waypoint, real waitTime returns nothing
        call PatrolSystem_SetPoint(TSA_GetShip(), index, TSA_RectCenterX(waypoint), TSA_RectCenterY(waypoint), waitTime)
    endfunction

    private function TSA_StartPatrol takes nothing returns nothing
        local unit ship = TSA_GetShip()

        if ship == null or TSA_PatrolStarted then
            set ship = null
            return
        endif
        call PatrolSystem_Begin(ship)
        call TSA_SetPatrolPoint(0, gg_rct_SirensongShip001, TSA_DOCK_WAIT)
        call TSA_SetPatrolPoint(1, gg_rct_SirensongShip002, 0.00)
        call TSA_SetPatrolPoint(2, gg_rct_SirensongShip003, 0.00)
        call TSA_SetPatrolPoint(3, gg_rct_SirensongShip004, 0.00)
        call TSA_SetPatrolPoint(4, gg_rct_SirensongShip005, 0.00)
        call TSA_SetPatrolPoint(5, gg_rct_SirensongShip006, 0.00)
        call TSA_SetPatrolPoint(6, gg_rct_SirensongShip007, 0.00)
        call TSA_SetPatrolPoint(7, gg_rct_SirensongShip008, 0.00)
        call TSA_SetPatrolPoint(8, gg_rct_SirensongShip009, 0.00)
        call TSA_SetPatrolPoint(9, gg_rct_SirensongShip010, 0.00)
        call TSA_SetPatrolPoint(10, gg_rct_SirensongShip011, 0.00)
        call TSA_SetPatrolPoint(11, gg_rct_SirensongShip012, TSA_DOCK_WAIT)
        call TSA_SetPatrolPoint(12, gg_rct_SirensongShip013, 0.00)
        call TSA_SetPatrolPoint(13, gg_rct_SirensongShip014, 0.00)
        call TSA_SetPatrolPoint(14, gg_rct_SirensongShip015, 0.00)
        call TSA_SetPatrolPoint(15, gg_rct_SirensongShip016, 0.00)
        call TSA_SetPatrolPoint(16, gg_rct_SirensongShip017, 0.00)
        call TSA_SetPatrolPoint(17, gg_rct_SirensongShip018, 0.00)
        call TSA_SetPatrolPoint(18, gg_rct_SirensongShip019, 0.00)
        call TSA_SetPatrolPoint(19, gg_rct_SirensongShip020, 0.00)
        call TSA_SetPatrolPoint(20, gg_rct_SirensongShip021, 0.00)
        call TSA_SetPatrolPoint(21, gg_rct_SirensongShip022, 0.00)
        call TSA_SetPatrolPoint(22, gg_rct_SirensongShip023, 0.00)
        call TSA_SetPatrolPoint(23, gg_rct_SirensongShip024, 0.00)
        call TSA_SetPatrolPoint(24, gg_rct_SirensongShip025, 0.00)
        call TSA_SetPatrolPoint(25, gg_rct_SirensongShip026, 0.00)
        call TSA_SetPatrolPoint(26, gg_rct_SirensongShip027, 0.00)
        call TSA_SetPatrolPoint(27, gg_rct_SirensongShip028, 0.00)
        call TSA_SetPatrolPoint(28, gg_rct_SirensongShip029, 0.00)
        call TSA_SetPatrolPoint(29, gg_rct_SirensongShip030, 0.00)
        call TSA_SetPatrolPoint(30, gg_rct_SirensongShip031, 0.00)
        call TSA_SetPatrolPoint(31, gg_rct_SirensongShip032, TSA_DOCK_WAIT)
        call TSA_SetPatrolPoint(32, gg_rct_SirensongShip0033, 0.00)
        call TSA_SetPatrolPoint(33, gg_rct_SirensongShip029, 0.00)
        call TSA_SetPatrolPoint(34, gg_rct_SirensongShip028, 0.00)
        call TSA_SetPatrolPoint(35, gg_rct_SirensongShip027, 0.00)
        call TSA_SetPatrolPoint(36, gg_rct_SirensongShip026, 0.00)
        call TSA_SetPatrolPoint(37, gg_rct_SirensongShip025, 0.00)
        call TSA_SetPatrolPoint(38, gg_rct_SirensongShip024, 0.00)
        call TSA_SetPatrolPoint(39, gg_rct_SirensongShip023, 0.00)
        call TSA_SetPatrolPoint(40, gg_rct_SirensongShip022, 0.00)
        call TSA_SetPatrolPoint(41, gg_rct_SirensongShip021, 0.00)
        call TSA_SetPatrolPoint(42, gg_rct_SirensongShip020, 0.00)
        call TSA_SetPatrolPoint(43, gg_rct_SirensongShip019, 0.00)
        call TSA_SetPatrolPoint(44, gg_rct_SirensongShip018, 0.00)
        call TSA_SetPatrolPoint(45, gg_rct_SirensongShip017, 0.00)
        call TSA_SetPatrolPoint(46, gg_rct_SirensongShip016, 0.00)
        call TSA_SetPatrolPoint(47, gg_rct_SirensongShip015, 0.00)
        call TSA_SetPatrolPoint(48, gg_rct_SirensongShip014, 0.00)
        call TSA_SetPatrolPoint(49, gg_rct_SirensongShip013, 0.00)
        call TSA_SetPatrolPoint(50, gg_rct_SirensongShip012, TSA_DOCK_WAIT)
        call TSA_SetPatrolPoint(51, gg_rct_SirensongShip011, 0.00)
        call TSA_SetPatrolPoint(52, gg_rct_SirensongShip010, 0.00)
        call TSA_SetPatrolPoint(53, gg_rct_SirensongShip009, 0.00)
        call TSA_SetPatrolPoint(54, gg_rct_SirensongShip008, 0.00)
        call TSA_SetPatrolPoint(55, gg_rct_SirensongShip007, 0.00)
        call TSA_SetPatrolPoint(56, gg_rct_SirensongShip006, 0.00)
        call TSA_SetPatrolPoint(57, gg_rct_SirensongShip005, 0.00)
        call TSA_SetPatrolPoint(58, gg_rct_SirensongShip004, 0.00)
        call TSA_SetPatrolPoint(59, gg_rct_SirensongShip034, 0.00)
        call TSA_SetPatrolPoint(60, gg_rct_SirensongShip035, 0.00)
        call TSA_SetPatrolPoint(61, gg_rct_SirensongShip036, 0.00)
        call TSA_SetPatrolPoint(62, gg_rct_SirensongShip037, 0.00)
        call TSA_SetPatrolPoint(63, gg_rct_SirensongShip038, 0.00)
        call PatrolSystem_StartConfigured(ship, TSA_PATROL_POINT_COUNT, 10.00, PATROL_STYLE_LOOP, true, "move", -1.00)
        set TSA_PatrolStarted = true
        set ship = null
    endfunction

    private function TSA_TryStartPatrol takes nothing returns nothing
        local unit ship = TSA_GetShip()

        if TSA_PatrolStarted then
            set ship = null
            return
        endif
        if ship == null or GetUnitTypeId(ship) == 0 then
            call TimerStart(TSA_PatrolTimer, 1.00, false, function TSA_TryStartPatrol)
            set ship = null
            return
        endif
        call TSA_StartPatrol()
        call PauseTimer(TSA_PatrolTimer)
        set ship = null
    endfunction

    private function TSA_UpdateDawnholdDirection takes integer previousDock returns nothing
        if previousDock == TSA_SirensongStop then
            call TravelSystem_SetRouteAvailable(TSA_DawnholdToSirensong, false)
            call TravelSystem_SetRouteAvailable(TSA_DawnholdToStormhaven, true)
        elseif previousDock == TSA_StormhavenStop then
            call TravelSystem_SetRouteAvailable(TSA_DawnholdToSirensong, true)
            call TravelSystem_SetRouteAvailable(TSA_DawnholdToStormhaven, false)
        endif
    endfunction

    private function TSA_OnDockCheck takes nothing returns nothing
        local integer newDock
        local integer previousDock = TSA_LastDock
        local unit ship = TSA_GetShip()

        if not TSA_Initialized or ship == null or GetUnitTypeId(ship) == 0 then
            set ship = null
            return
        endif
        set newDock = TSA_GetDock()
        if newDock == TSA_CurrentDock then
            set ship = null
            return
        endif
        set TSA_CurrentDock = newDock
        if newDock > 0 then
            call TravelSystem_NotifyScheduledStop(ship, newDock)
            if newDock == TSA_DawnholdStop then
                call TSA_UpdateDawnholdDirection(previousDock)
            endif
            set TSA_LastDock = newDock
        else
            call TravelSystem_NotifyScheduledLeave(ship)
        endif
        set ship = null
    endfunction

    private function TSA_RegisterRoutes takes unit ship returns nothing
        set TSA_SirensongToDawnhold = RegisterScheduledRoute(TSA_SirensongStop, TSA_DawnholdStop, TSA_FARE_ADJACENT, ship, true)
        set TSA_SirensongToStormhaven = RegisterScheduledRoute(TSA_SirensongStop, TSA_StormhavenStop, TSA_FARE_FULL, ship, true)
        set TSA_DawnholdToSirensong = RegisterScheduledRoute(TSA_DawnholdStop, TSA_SirensongStop, TSA_FARE_ADJACENT, ship, true)
        set TSA_DawnholdToStormhaven = RegisterScheduledRoute(TSA_DawnholdStop, TSA_StormhavenStop, TSA_FARE_ADJACENT, ship, true)
        set TSA_StormhavenToDawnhold = RegisterScheduledRoute(TSA_StormhavenStop, TSA_DawnholdStop, TSA_FARE_ADJACENT, ship, true)
        set TSA_StormhavenToSirensong = RegisterScheduledRoute(TSA_StormhavenStop, TSA_SirensongStop, TSA_FARE_FULL, ship, true)
        call AddWaypoint(TSA_SirensongToDawnhold, 0.00, 0.00, TSA_DawnholdStop)
        call AddWaypoint(TSA_SirensongToStormhaven, 0.00, 0.00, TSA_DawnholdStop)
        call AddWaypoint(TSA_SirensongToStormhaven, 0.00, 0.00, TSA_StormhavenStop)
        call AddWaypoint(TSA_DawnholdToSirensong, 0.00, 0.00, TSA_SirensongStop)
        call AddWaypoint(TSA_DawnholdToStormhaven, 0.00, 0.00, TSA_StormhavenStop)
        call AddWaypoint(TSA_StormhavenToDawnhold, 0.00, 0.00, TSA_DawnholdStop)
        call AddWaypoint(TSA_StormhavenToSirensong, 0.00, 0.00, TSA_DawnholdStop)
        call AddWaypoint(TSA_StormhavenToSirensong, 0.00, 0.00, TSA_SirensongStop)
    endfunction

    private function TSA_TryInitialize takes nothing returns nothing
        local unit ship = TSA_GetShip()
        local unit sirensongMaster = TravelSystem_GetShipMaster(TRAVEL_SHIP_MASTER_SIRENSONG)
        local unit dawnholdMaster = TravelSystem_GetShipMaster(TRAVEL_SHIP_MASTER_DAWNHOLD)
        local unit stormhavenMaster = TravelSystem_GetShipMaster(TRAVEL_SHIP_MASTER_STORMHAVEN)

        if TSA_Initialized then
            set ship = null
            set sirensongMaster = null
            set dawnholdMaster = null
            set stormhavenMaster = null
            return
        endif
        if ship == null or sirensongMaster == null or dawnholdMaster == null or stormhavenMaster == null then
            call TimerStart(TSA_InitTimer, 1.00, false, function TSA_TryInitialize)
            set ship = null
            set sirensongMaster = null
            set dawnholdMaster = null
            set stormhavenMaster = null
            return
        endif

        set TSA_SirensongStop = RegisterStop("Sirensong", TSA_ZONE_SIRENSONG, sirensongMaster, gg_rct_TravelShipSirensong, TSA_RectCenterX(gg_rct_TravelShipSirensongDeck), TSA_RectCenterY(gg_rct_TravelShipSirensongDeck))
        set TSA_DawnholdStop = RegisterStop("Dawnhold", TSA_ZONE_DAWNHOLD, dawnholdMaster, gg_rct_TravelShipDawnhold, TSA_RectCenterX(gg_rct_TravelShipDawnholdDeck), TSA_RectCenterY(gg_rct_TravelShipDawnholdDeck))
        set TSA_StormhavenStop = RegisterStop("Stormhaven", TSA_ZONE_STORMHAVEN, stormhavenMaster, gg_rct_TravelShipStormhaven, TSA_RectCenterX(gg_rct_TravelShipStormhavenDeck), TSA_RectCenterY(gg_rct_TravelShipStormhavenDeck))
        if TSA_SirensongStop <= 0 or TSA_DawnholdStop <= 0 or TSA_StormhavenStop <= 0 then
            call TimerStart(TSA_InitTimer, 1.00, false, function TSA_TryInitialize)
            set ship = null
            set sirensongMaster = null
            set dawnholdMaster = null
            set stormhavenMaster = null
            return
        endif

        call TSA_RegisterRoutes(ship)
        set TSA_Initialized = true
        call TSA_OnDockCheck()
        call TimerStart(TSA_DockTimer, TSA_DOCK_CHECK_PERIOD, true, function TSA_OnDockCheck)
        call PauseTimer(TSA_InitTimer)
        set ship = null
        set sirensongMaster = null
        set dawnholdMaster = null
        set stormhavenMaster = null
    endfunction

    private function Init takes nothing returns nothing
        set TSA_InitTimer = CreateTimer()
        set TSA_DockTimer = CreateTimer()
        set TSA_PatrolTimer = CreateTimer()
        call TimerStart(TSA_InitTimer, 5.00, false, function TSA_TryInitialize)
        call TimerStart(TSA_PatrolTimer, TSA_PATROL_START_DELAY, false, function TSA_TryStartPatrol)
    endfunction
endlibrary
