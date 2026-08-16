/**
    TravelShipB

    Author: Valdemar
    Version:

    Description:
    Owns the Orc Frigate's 87-point PatrolSystem route and connects its
    scheduled dock arrivals to TravelSystem.

    Credits:
    The original TravelShipB GUI triggers and patrol route.

    How to install:
    Import after TravelSystem, TravelUI, and PatrolSystem. Keep TravelShip Init
    enabled so TravelSystem can resolve the placed Orc Frigate binding.

    API:
    - TravelShipB_GetMoknathaStop()
    - TravelShipB_GetFrontbaseStop()
    - TravelShipB_GetFrontlineStop()
    - TravelShipB_GetIronspineStop()
    - TravelShipB_GetFrontlineRoute()
    - TravelShipB_GetIronspineRoute()
    - call TravelShipB_ConfigureHeroModels(...)

**/
library TravelShipB initializer Init requires TravelSystem, TravelUI, PatrolSystem
    globals
        private constant integer TSB_ZONE_MOKNATHA = 1401
        private constant integer TSB_ZONE_IRONSPINE = 1901
        private constant integer TSB_FARE_FRONTLINE = 100
        private constant integer TSB_FARE_IRONSPINE = 175
        private constant integer TSB_SKIP_FEE = 100
        // Orc frigate local deck coordinates: X forward, Y lateral.
        private constant real TSB_DECK_SLOT_1_X = -240.00
        private constant real TSB_DECK_SLOT_1_Y = -140.00
        private constant real TSB_DECK_SLOT_1_HEIGHT = 300.00
        private constant real TSB_DECK_SLOT_2_X = -240.00
        private constant real TSB_DECK_SLOT_2_Y = 140.00
        private constant real TSB_DECK_SLOT_2_HEIGHT = 300.00
        private constant real TSB_DOCK_CHECK_PERIOD = 0.50
        private constant real TSB_PATROL_START_DELAY = 45.00
        private constant integer TSB_PATROL_POINT_COUNT = 87

        private integer TSB_MoknathaStop = 0
        private integer TSB_FrontlineStop = 0
        private integer TSB_IronspineStop = 0
        private integer TSB_FrontlineRoute = 0
        private integer TSB_IronspineRoute = 0
        private integer TSB_FrontlineToMoknathaRoute = 0
        private integer TSB_FrontlineToIronspineRoute = 0
        private integer TSB_IronspineToFrontlineRoute = 0
        private integer TSB_IronspineToMoknathaRoute = 0
        private integer TSB_CurrentDock = 0
        private integer TSB_LastDock = 0
        private timer TSB_InitTimer = null
        private timer TSB_DockTimer = null
        private timer TSB_PatrolTimer = null
        private boolean TSB_Initialized = false
        private boolean TSB_PatrolStarted = false
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

    private function TSB_GetShip takes nothing returns unit
        return TravelSystem_GetTravelShipB()
    endfunction

    private function TSB_GetMaster takes integer index returns unit
        return TravelSystem_GetShipMaster(index)
    endfunction

    private function TSB_GetDock takes nothing returns integer
        local unit ship = TSB_GetShip()
        local integer stopId = 0

        if TSB_UnitInRect(ship, gg_rct_ShipBMoknatha) then
            set stopId = TSB_MoknathaStop
        elseif TSB_UnitInRect(ship, gg_rct_ShipBFrontBase) then
            set stopId = TSB_FrontlineStop
        elseif TSB_UnitInRect(ship, gg_rct_ShipBIronspinePost) then
            set stopId = TSB_IronspineStop
        endif
        set ship = null
        return stopId
    endfunction

    public function GetMoknathaStop takes nothing returns integer
        return TSB_MoknathaStop
    endfunction

    public function GetFrontlineStop takes nothing returns integer
        return TSB_FrontlineStop
    endfunction

    public function GetFrontbaseStop takes nothing returns integer
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
        call TravelSystem_ConfigureShipPassengerEffects(nazgrekModel, nazgrekScale, nazgrekFacingOffset, zulkisModel, zulkisScale, zulkisFacingOffset)
    endfunction

    private function TSB_ConfigureDeckSlots takes integer routeId returns nothing
        call TravelSystem_SetRouteDeckSlotXY(routeId, 1, TSB_DECK_SLOT_1_X, TSB_DECK_SLOT_1_Y, TSB_DECK_SLOT_1_HEIGHT)
        call TravelSystem_SetRouteDeckSlotXY(routeId, 2, TSB_DECK_SLOT_2_X, TSB_DECK_SLOT_2_Y, TSB_DECK_SLOT_2_HEIGHT)
    endfunction

    private function TSB_SetPatrolPoint takes integer index, rect waypoint, real waitTime returns nothing
        call PatrolSystem_SetPoint(TSB_GetShip(), index, TSB_RectCenterX(waypoint), TSB_RectCenterY(waypoint), waitTime)
    endfunction

    private function TSB_StartPatrol takes nothing returns nothing
        local unit ship = TSB_GetShip()

        call PatrolSystem_Begin(ship)
        call TSB_SetPatrolPoint(0, gg_rct_MoknathaShip01, 30.00)
        call TSB_SetPatrolPoint(1, gg_rct_MoknathaShip02a, 0.00)
        call TSB_SetPatrolPoint(2, gg_rct_MoknathaShip02, 0.00)
        call TSB_SetPatrolPoint(3, gg_rct_MoknathaShip03, 0.00)
        call TSB_SetPatrolPoint(4, gg_rct_MoknathaShip04, 0.00)
        call TSB_SetPatrolPoint(5, gg_rct_MoknathaShip05, 0.00)
        call TSB_SetPatrolPoint(6, gg_rct_MoknathaShip06, 0.00)
        call TSB_SetPatrolPoint(7, gg_rct_MoknathaShip07, 0.00)
        call TSB_SetPatrolPoint(8, gg_rct_MoknathaShip77, 0.00)
        call TSB_SetPatrolPoint(9, gg_rct_MoknathaShip09, 0.00)
        call TSB_SetPatrolPoint(10, gg_rct_MoknathaShip10, 0.00)
        call TSB_SetPatrolPoint(11, gg_rct_MoknathaShip11, 0.00)
        call TSB_SetPatrolPoint(12, gg_rct_MoknathaShip12, 0.00)
        call TSB_SetPatrolPoint(13, gg_rct_MoknathaShip13, 0.00)
        call TSB_SetPatrolPoint(14, gg_rct_MoknathaShip14, 0.00)
        call TSB_SetPatrolPoint(15, gg_rct_MoknathaShip15, 0.00)
        call TSB_SetPatrolPoint(16, gg_rct_MoknathaShip16, 0.00)
        call TSB_SetPatrolPoint(17, gg_rct_MoknathaShip17, 0.00)
        call TSB_SetPatrolPoint(18, gg_rct_MoknathaShip18, 0.00)
        call TSB_SetPatrolPoint(19, gg_rct_MoknathaShip19, 0.00)
        call TSB_SetPatrolPoint(20, gg_rct_MoknathaShip20, 0.00)
        call TSB_SetPatrolPoint(21, gg_rct_MoknathaShip21, 0.00)
        call TSB_SetPatrolPoint(22, gg_rct_MoknathaShip22, 0.00)
        call TSB_SetPatrolPoint(23, gg_rct_MoknathaShip23, 0.00)
        call TSB_SetPatrolPoint(24, gg_rct_MoknathaShip24, 30.00)
        call TSB_SetPatrolPoint(25, gg_rct_MoknathaShip032, 0.00)
        call TSB_SetPatrolPoint(26, gg_rct_MoknathaShip033, 0.00)
        call TSB_SetPatrolPoint(27, gg_rct_MoknathaShip034, 0.00)
        call TSB_SetPatrolPoint(28, gg_rct_MoknathaShip035, 0.00)
        call TSB_SetPatrolPoint(29, gg_rct_MoknathaShip036, 0.00)
        call TSB_SetPatrolPoint(30, gg_rct_MoknathaShip037, 0.00)
        call TSB_SetPatrolPoint(31, gg_rct_MoknathaShip038, 0.00)
        call TSB_SetPatrolPoint(32, gg_rct_MoknathaShip039, 0.00)
        call TSB_SetPatrolPoint(33, gg_rct_MoknathaShip040, 0.00)
        call TSB_SetPatrolPoint(34, gg_rct_MoknathaShip041, 0.00)
        call TSB_SetPatrolPoint(35, gg_rct_MoknathaShip042, 0.00)
        call TSB_SetPatrolPoint(36, gg_rct_MoknathaShip043, 0.00)
        call TSB_SetPatrolPoint(37, gg_rct_MoknathaShip044, 0.00)
        call TSB_SetPatrolPoint(38, gg_rct_MoknathaShip045, 0.00)
        call TSB_SetPatrolPoint(39, gg_rct_MoknathaShip046, 0.00)
        call TSB_SetPatrolPoint(40, gg_rct_MoknathaShip047, 0.00)
        call TSB_SetPatrolPoint(41, gg_rct_MoknathaShip048, 30.00)
        call TSB_SetPatrolPoint(42, gg_rct_MoknathaShip045, 0.00)
        call TSB_SetPatrolPoint(43, gg_rct_MoknathaShip044, 0.00)
        call TSB_SetPatrolPoint(44, gg_rct_MoknathaShip043, 0.00)
        call TSB_SetPatrolPoint(45, gg_rct_MoknathaShip042, 0.00)
        call TSB_SetPatrolPoint(46, gg_rct_MoknathaShip041, 0.00)
        call TSB_SetPatrolPoint(47, gg_rct_MoknathaShip040, 0.00)
        call TSB_SetPatrolPoint(48, gg_rct_MoknathaShip039, 0.00)
        call TSB_SetPatrolPoint(49, gg_rct_MoknathaShip038, 0.00)
        call TSB_SetPatrolPoint(50, gg_rct_MoknathaShip037, 0.00)
        call TSB_SetPatrolPoint(51, gg_rct_MoknathaShip036, 0.00)
        call TSB_SetPatrolPoint(52, gg_rct_MoknathaShip035, 0.00)
        call TSB_SetPatrolPoint(53, gg_rct_MoknathaShip034, 0.00)
        call TSB_SetPatrolPoint(54, gg_rct_MoknathaShip033, 0.00)
        call TSB_SetPatrolPoint(55, gg_rct_MoknathaShip032, 0.00)
        call TSB_SetPatrolPoint(56, gg_rct_MoknathaShip031, 0.00)
        call TSB_SetPatrolPoint(57, gg_rct_MoknathaShip030, 30.00)
        call TSB_SetPatrolPoint(58, gg_rct_MoknathaShip24, 30.00)
        call TSB_SetPatrolPoint(59, gg_rct_MoknathaShip23, 0.00)
        call TSB_SetPatrolPoint(60, gg_rct_MoknathaShip22, 0.00)
        call TSB_SetPatrolPoint(61, gg_rct_MoknathaShip21, 0.00)
        call TSB_SetPatrolPoint(62, gg_rct_MoknathaShip20, 0.00)
        call TSB_SetPatrolPoint(63, gg_rct_MoknathaShip19, 0.00)
        call TSB_SetPatrolPoint(64, gg_rct_MoknathaShip18, 0.00)
        call TSB_SetPatrolPoint(65, gg_rct_MoknathaShip17, 0.00)
        call TSB_SetPatrolPoint(66, gg_rct_MoknathaShip16, 0.00)
        call TSB_SetPatrolPoint(67, gg_rct_MoknathaShip15, 0.00)
        call TSB_SetPatrolPoint(68, gg_rct_MoknathaShip14, 0.00)
        call TSB_SetPatrolPoint(69, gg_rct_MoknathaShip13, 0.00)
        call TSB_SetPatrolPoint(70, gg_rct_MoknathaShip12, 0.00)
        call TSB_SetPatrolPoint(71, gg_rct_MoknathaShip11, 0.00)
        call TSB_SetPatrolPoint(72, gg_rct_MoknathaShip10, 0.00)
        call TSB_SetPatrolPoint(73, gg_rct_MoknathaShip09, 0.00)
        call TSB_SetPatrolPoint(74, gg_rct_MoknathaShip77, 0.00)
        call TSB_SetPatrolPoint(75, gg_rct_MoknathaShip07, 0.00)
        call TSB_SetPatrolPoint(76, gg_rct_MoknathaShip08, 0.00)
        call TSB_SetPatrolPoint(77, gg_rct_MoknathaShip06, 0.00)
        call TSB_SetPatrolPoint(78, gg_rct_MoknathaShip05, 0.00)
        call TSB_SetPatrolPoint(79, gg_rct_MoknathaShip04, 0.00)
        call TSB_SetPatrolPoint(80, gg_rct_MoknathaShip03, 0.00)
        call TSB_SetPatrolPoint(81, gg_rct_MoknathaShip02, 0.00)
        call TSB_SetPatrolPoint(82, gg_rct_MoknathaShip025, 0.00)
        call TSB_SetPatrolPoint(83, gg_rct_MoknathaShip026, 0.00)
        call TSB_SetPatrolPoint(84, gg_rct_MoknathaShip027, 0.00)
        call TSB_SetPatrolPoint(85, gg_rct_MoknathaShip028, 0.00)
        call TSB_SetPatrolPoint(86, gg_rct_MoknathaShip029, 0.00)
        call PatrolSystem_StartConfigured(ship, TSB_PATROL_POINT_COUNT, 10.00, PATROL_STYLE_LOOP, true, "move", -1.00)
        set TSB_PatrolStarted = true
        set ship = null
    endfunction

    private function TSB_TryStartPatrol takes nothing returns nothing
        local unit ship = TSB_GetShip()

        if TSB_PatrolStarted then
            set ship = null
            return
        endif
        if ship == null or GetUnitTypeId(ship) == 0 then
            call TimerStart(TSB_PatrolTimer, 1.00, false, function TSB_TryStartPatrol)
            set ship = null
            return
        endif
        call TSB_StartPatrol()
        call PauseTimer(TSB_PatrolTimer)
        set ship = null
    endfunction

    private function TSB_UpdateFrontbaseDirection takes integer previousDock returns nothing
        if previousDock == TSB_MoknathaStop then
            call TravelSystem_SetRouteAvailable(TSB_FrontlineToMoknathaRoute, false)
            call TravelSystem_SetRouteAvailable(TSB_FrontlineToIronspineRoute, true)
        elseif previousDock == TSB_IronspineStop then
            call TravelSystem_SetRouteAvailable(TSB_FrontlineToMoknathaRoute, true)
            call TravelSystem_SetRouteAvailable(TSB_FrontlineToIronspineRoute, false)
        endif
    endfunction

    private function TSB_OnDockCheck takes nothing returns nothing
        local integer newDock
        local integer previousDock = TSB_LastDock
        local unit ship = TSB_GetShip()

        if not TSB_Initialized or ship == null or GetUnitTypeId(ship) == 0 then
            set ship = null
            return
        endif
        set newDock = TSB_GetDock()
        if newDock == TSB_CurrentDock then
            set ship = null
            return
        endif
        set TSB_CurrentDock = newDock
        if newDock > 0 then
            call TravelSystem_NotifyScheduledStop(ship, newDock)
            if newDock == TSB_FrontlineStop then
                call TSB_UpdateFrontbaseDirection(previousDock)
            endif
            set TSB_LastDock = newDock
        else
            call TravelSystem_NotifyScheduledLeave(ship)
        endif
        set ship = null
    endfunction

    private function TSB_RegisterScheduledRoute takes integer startStop, integer endStop, integer fare, unit ship returns integer
        local integer routeId = TravelSystem_RegisterRoute(TRAVEL_METHOD_SHIP_B, startStop, endStop, fare, TSB_SKIP_FEE)

        if routeId > 0 then
            call TravelSystem_SetRouteDiscoveryRequirements(routeId, false, false)
            call TravelSystem_SetRouteVehicle(routeId, ship, true, true)
            call TravelSystem_SetRouteShowPassengers(routeId, true)
            call TravelSystem_SetRouteAvailable(routeId, false)
            call TSB_ConfigureDeckSlots(routeId)
        endif
        return routeId
    endfunction

    private function TSB_RegisterRoutes takes unit ship returns nothing
        set TSB_FrontlineRoute = TSB_RegisterScheduledRoute(TSB_MoknathaStop, TSB_FrontlineStop, TSB_FARE_FRONTLINE, ship)
        set TSB_IronspineRoute = TSB_RegisterScheduledRoute(TSB_MoknathaStop, TSB_IronspineStop, TSB_FARE_IRONSPINE, ship)
        set TSB_FrontlineToMoknathaRoute = TSB_RegisterScheduledRoute(TSB_FrontlineStop, TSB_MoknathaStop, TSB_FARE_FRONTLINE, ship)
        set TSB_FrontlineToIronspineRoute = TSB_RegisterScheduledRoute(TSB_FrontlineStop, TSB_IronspineStop, TSB_FARE_FRONTLINE, ship)
        set TSB_IronspineToFrontlineRoute = TSB_RegisterScheduledRoute(TSB_IronspineStop, TSB_FrontlineStop, TSB_FARE_FRONTLINE, ship)
        set TSB_IronspineToMoknathaRoute = TSB_RegisterScheduledRoute(TSB_IronspineStop, TSB_MoknathaStop, TSB_FARE_IRONSPINE, ship)
        call TravelSystem_AddWaypoint(TSB_FrontlineRoute, 0.00, 0.00, TSB_FrontlineStop)
        call TravelSystem_AddWaypoint(TSB_IronspineRoute, 0.00, 0.00, TSB_FrontlineStop)
        call TravelSystem_AddWaypoint(TSB_IronspineRoute, 0.00, 0.00, TSB_IronspineStop)
        call TravelSystem_AddWaypoint(TSB_FrontlineToMoknathaRoute, 0.00, 0.00, TSB_MoknathaStop)
        call TravelSystem_AddWaypoint(TSB_FrontlineToIronspineRoute, 0.00, 0.00, TSB_IronspineStop)
        call TravelSystem_AddWaypoint(TSB_IronspineToFrontlineRoute, 0.00, 0.00, TSB_FrontlineStop)
        call TravelSystem_AddWaypoint(TSB_IronspineToMoknathaRoute, 0.00, 0.00, TSB_FrontlineStop)
        call TravelSystem_AddWaypoint(TSB_IronspineToMoknathaRoute, 0.00, 0.00, TSB_MoknathaStop)
    endfunction

    private function TSB_TryInitialize takes nothing returns nothing
        local unit ship = TSB_GetShip()
        local unit moknathaMaster = TSB_GetMaster(TRAVEL_SHIP_MASTER_MOKNATHA)
        local unit frontlineMaster = TSB_GetMaster(TRAVEL_SHIP_MASTER_FRONTBASE)
        local unit ironspineMaster = TSB_GetMaster(TRAVEL_SHIP_MASTER_IRONSPINE)

        if TSB_Initialized then
            set ship = null
            set moknathaMaster = null
            set frontlineMaster = null
            set ironspineMaster = null
            return
        endif
        if ship == null or moknathaMaster == null or frontlineMaster == null or ironspineMaster == null then
            call TimerStart(TSB_InitTimer, 1.00, false, function TSB_TryInitialize)
            set ship = null
            set moknathaMaster = null
            set frontlineMaster = null
            set ironspineMaster = null
            return
        endif

        set TSB_MoknathaStop = TravelSystem_RegisterStop(TRAVEL_METHOD_SHIP_B, "Mok'natha", TSB_ZONE_MOKNATHA, moknathaMaster, gg_rct_TravelShipMoknatha, TSB_RectCenterX(gg_rct_TravelShipMoknathaDeck), TSB_RectCenterY(gg_rct_TravelShipMoknathaDeck), false)
        set TSB_FrontlineStop = TravelSystem_RegisterStop(TRAVEL_METHOD_SHIP_B, "Frontbase", 0, frontlineMaster, gg_rct_TravelShipFrontbaseDeck, TSB_RectCenterX(gg_rct_TravelShipFrontbaseDeck), TSB_RectCenterY(gg_rct_TravelShipFrontbaseDeck), false)
        set TSB_IronspineStop = TravelSystem_RegisterStop(TRAVEL_METHOD_SHIP_B, "Ironspine", TSB_ZONE_IRONSPINE, ironspineMaster, gg_rct_TravelShipIronspineDeck, TSB_RectCenterX(gg_rct_TravelShipIronspineDeck), TSB_RectCenterY(gg_rct_TravelShipIronspineDeck), false)

        if TSB_MoknathaStop <= 0 or TSB_FrontlineStop <= 0 or TSB_IronspineStop <= 0 then
            call TimerStart(TSB_InitTimer, 1.00, false, function TSB_TryInitialize)
            set ship = null
            set moknathaMaster = null
            set frontlineMaster = null
            set ironspineMaster = null
            return
        endif

        call TSB_RegisterRoutes(ship)
        set TSB_Initialized = true
        set TSB_CurrentDock = 0
        call TSB_OnDockCheck()
        call TimerStart(TSB_DockTimer, TSB_DOCK_CHECK_PERIOD, true, function TSB_OnDockCheck)
        call PauseTimer(TSB_InitTimer)
        set ship = null
        set moknathaMaster = null
        set frontlineMaster = null
        set ironspineMaster = null
    endfunction

    private function Init takes nothing returns nothing
        set TSB_InitTimer = CreateTimer()
        set TSB_DockTimer = CreateTimer()
        set TSB_PatrolTimer = CreateTimer()
        call TimerStart(TSB_InitTimer, 5.10, false, function TSB_TryInitialize)
        call TimerStart(TSB_PatrolTimer, TSB_PATROL_START_DELAY, false, function TSB_TryStartPatrol)
    endfunction
endlibrary
