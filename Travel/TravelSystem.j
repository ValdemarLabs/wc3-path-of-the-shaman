/**
    TravelSystem

    Author: Valdemar
    Version:

    Description:
    Configurable travel-stop, route, passenger, discovery, movement, camera,
    and interruption framework. Direct routes use ordered waypoints while
    scheduled vehicles report their dock arrivals through the public API.

    Credits:
    The original PotS GUI wyvern and ship travel triggers.

    How to install:
    Import after the required camera, dialog, companion, zone, patrol, sound,
    and icon-query libraries. Method libraries register their content after
    map globals have been initialized.

    World Editor shared-unit bindings:
    Travel masters:
    - udg_WindRiderMaster[1] = Horde Scout Base, unit 0025 (active).
    - udg_WindRiderMaster[2] = Horde Lumber Mill, unit 0208 (active).
    - udg_WindRiderMaster[3] = Horde Gold Mine, unit 0427 (active).
    - udg_WindRiderMaster[4] = Verdant Plains neutral master, Ursa 2424 (active).
    - udg_WindRiderMaster[5] = Ashfang Outpost master, unit 1978 (active).
    - udg_WindRiderMaster[6] = Sirensong Wind Rider Master 1239 (active).
    - udg_FlightMaster[1] = Sereneglade Flightmaster 2617 (active).
    - udg_FlightMaster[2] = Sirensong Shipmaster 0613 (active).
    - udg_Shipmaster[1] = Mok'natha Shipmaster 0996 (active).
    - udg_Shipmaster[2] = Sirensong shipmaster 2230 (Ship A).
    - udg_Shipmaster[3] = Ironspine shipmaster 2228 (Ship B).
    - udg_Shipmaster[4] = Stormhaven shipmaster 2229 (Ship A).
    - udg_Shipmaster[5] = Dawnhold shipmaster (Ship A).
    - udg_Shipmaster[6] = Frontbase shipmaster (Ship B).

    Travel vehicles:
    - udg_TravelShipA = Transport Ship 0923 (active scheduled patrol).
    - udg_TravelShipB = Orc Frigate 0061 (active scheduled patrol).
    - udg_ZeppelinA = Zeppelin 2226 at Sereneglade (active outbound vehicle).
    - udg_ZeppelinB = Zeppelin 0922 at Sirensong (active outbound vehicle).

    Shared passengers:
    - udg_Nazgrek and udg_Zulkis = selectable player heroes.
    - udg_TamedUnit and udg_Shadowclaw = optional pet passengers.

    "Active" bindings are consumed automatically by their method libraries.
    Other bindings must be supplied to the relevant Bind/Register API;
    declaring or assigning the GUI variable alone does not register a stop.
    Do not register master IconQuery icons in the GUI initializer. TravelSystem
    registers each icon when its stop is discovered.

    API:
    - TravelSystem_RegisterStop(...)
    - TravelSystem_RegisterRoute(...)
    - TravelSystem_GetRouteStartName(...) / TravelSystem_GetRouteEndName(...)
    - TravelSystem_GetRouteStartZoneId(...) / TravelSystem_GetRouteEndZoneId(...)
    - TravelSystem_AddWaypoint(...)
    - TravelSystem_SetRouteVehicle(...)
    - TravelSystem_GetRouteVehicle(...)
    - TravelSystem_SetRouteFare(...)
    - TravelSystem_SetRouteSkipFee(...)
    - TravelSystem_SetRouteDiscoveryRequirements(...)
    - TravelSystem_DiscoverStop(...)
    - TravelSystem_IsStopDiscovered(...)
    - TravelSystem_BuildPassengerList(...)
    - TravelSystem_Start(...)
    - TravelSystem_NotifyScheduledStop(...)
    - TravelSystem_GetWindRiderMaster(...) / TravelSystem_GetFlightMaster(...)
    - TravelSystem_GetShipMaster(...) / TravelSystem_GetZeppelin(...)
    - TravelSystem_GetTravelShipA() / TravelSystem_GetTravelShipB()
    - TravelSystem_GetNazgrek() / TravelSystem_GetZulkis()
    - Set TRAVEL_HIDE_MASTER_UI_GAME_BUTTON to configure the travel Game button.

**/
library TravelSystem initializer Init requires Table, DialogInteraction, DialogSystem, IconQuery, RegionTitles, FullscreenUI, MasterUI, CameraControl, FixedCameraLock, Companions, Pet, ZonesCore, ZoneEvent, PatrolSystem, ExSound, FallenHeroState
    globals
        constant integer TRAVEL_METHOD_WYVERN = 1
        constant integer TRAVEL_METHOD_ZEPPELIN = 2
        constant integer TRAVEL_METHOD_SHIP_A = 3
        constant integer TRAVEL_METHOD_SHIP_B = 4

        constant integer TRAVEL_WINDRIDER_MASTER_HORDE_SCOUT_BASE = 1
        constant integer TRAVEL_WINDRIDER_MASTER_HORDE_LUMBER_MILL = 2
        constant integer TRAVEL_WINDRIDER_MASTER_HORDE_GOLD_MINE = 3
        constant integer TRAVEL_WINDRIDER_MASTER_VERDANT_PLAINS = 4
        constant integer TRAVEL_WINDRIDER_MASTER_ASHFANG_OUTPOST = 5
        constant integer TRAVEL_WINDRIDER_MASTER_SIRENSONG = 6

        constant integer TRAVEL_FLIGHT_MASTER_SERENEGLADE = 1
        constant integer TRAVEL_FLIGHT_MASTER_SIRENSONG = 2

        constant integer TRAVEL_SHIP_MASTER_MOKNATHA = 1
        constant integer TRAVEL_SHIP_MASTER_SIRENSONG = 2
        constant integer TRAVEL_SHIP_MASTER_IRONSPINE = 3
        constant integer TRAVEL_SHIP_MASTER_STORMHAVEN = 4
        constant integer TRAVEL_SHIP_MASTER_DAWNHOLD = 5
        constant integer TRAVEL_SHIP_MASTER_FRONTBASE = 6

        constant integer TRAVEL_ZEPPELIN_SERENEGLADE = 1
        constant integer TRAVEL_ZEPPELIN_SIRENSONG = 2

        // Travel presentation configuration.
        constant boolean TRAVEL_HIDE_MASTER_UI_GAME_BUTTON = true

        private constant integer TS_MAX_STOPS = 32
        private constant integer TS_MAX_ROUTES = 64
        private constant integer TS_MAX_WAYPOINTS = 32
        private constant integer TS_MAX_PASSENGERS = 12
        private constant integer TS_MAX_PROXY_MODELS = 8
        private constant integer TS_MAX_MASTER_EFFECTS = 16
        private constant integer TS_TRAVEL_UNIT_OWNER_ID = 5
        private constant real TS_DISCOVERY_RANGE = 600.00
        private constant real TS_DISCOVERY_PERIOD = 1.00
        private constant real TS_ARRIVAL_RANGE = 96.00
        private constant real TS_UPDATE_PERIOD = 0.03
        private constant real TS_TRAVEL_TIMEOUT = 180.00
        private constant real TS_STOP_PROMPT_DURATION = 10.00
        private constant real TS_SECOND_CARRIER_OFFSET = 160.00
        private constant real TS_CAMERA_DISTANCE = 750.00
        private constant real TS_CAMERA_FAR_Z = 20000.00
        private constant real TS_CAMERA_FOV = 80.00
        private constant real TS_CAMERA_ANGLE_FLIGHT = 330.00
        private constant real TS_CAMERA_ANGLE_SHIP = 335.00
        private constant real TS_FADE_DURATION = 0.50
        private constant real TS_FLIGHT_ASCENT_RATE = 50.00
        private constant real TS_FLIGHT_DESCENT_RATE = 50.00
        private constant real TS_FLIGHT_DESCENT_RANGE = 800.00
        private constant real TS_FLIGHT_LANDED_HEIGHT = 20.00
        private constant integer TS_SKIP_FEE_DEFAULT = 100
        private constant string TS_DISCOVERED_PREFIX = "|cFF32CD32Discovered |n|r"
        private constant string TS_DISCOVERED_NAME_COLOR = "|cFF32CD32"
        private constant string TS_MASTER_EFFECT_MODEL = "war3campImported\\ExcMark_Green_FlightPath.mdx"
        private constant string TS_FADE_TEXTURE = "ReplaceableTextures\\CameraMasks\\Black_mask.blp"

        private integer TS_StopCount = 0
        private integer array TS_StopMethod
        private string array TS_StopName
        private integer array TS_StopZoneId
        private unit array TS_StopMaster
        private rect array TS_StopBoardArea
        private real array TS_StopX
        private real array TS_StopY
        private boolean array TS_StopRequiresDiscovery
        private boolean array TS_StopDiscovered
        private boolean array TS_StopIconRegistered
        private minimapicon array TS_StopIcon

        private integer TS_MasterEffectCount = 0
        private unit array TS_MasterEffectUnit
        private effect array TS_MasterEffect

        private integer TS_RouteCount = 0
        private integer array TS_RouteMethod
        private integer array TS_RouteStart
        private integer array TS_RouteEnd
        private integer array TS_RouteFare
        private integer array TS_RouteSkipFee
        private boolean array TS_RouteRequireStartDiscovered
        private boolean array TS_RouteRequireEndDiscovered
        private boolean array TS_RouteEnabled
        private boolean array TS_RouteShowPassengers
        private boolean array TS_RouteScheduled
        private boolean array TS_RouteUsesPatrol
        private boolean array TS_RouteAvailable
        private unit array TS_RouteVehicle
        private integer array TS_RouteCarrierTypeA
        private integer array TS_RouteCarrierTypeB
        private real array TS_RouteFlyHeight
        private real array TS_RouteMoveSpeed
        private integer array TS_RouteWaypointCount
        private real array TS_WaypointX
        private real array TS_WaypointY
        private integer array TS_WaypointStop
        private real array TS_DeckOffset
        private real array TS_DeckAngle
        private real array TS_DeckHeight

        private integer TS_ProxyCount = 0
        private integer array TS_ProxyUnitType
        private string array TS_ProxyModel
        private real array TS_ProxyScale
        private real array TS_ProxyFacingOffset

        private integer TS_PassengerCount = 0
        private integer TS_PassengerRoute = 0
        private unit array TS_Passenger
        private boolean array TS_PassengerSelected
        private boolean array TS_PassengerHero
        private boolean array TS_PassengerCompanion
        private boolean array TS_PassengerPet
        private boolean array TS_PassengerWasInvulnerable

        private boolean TS_Active = false
        private boolean TS_Starting = false
        private boolean TS_Ending = false
        private integer TS_ActiveRoute = 0
        private integer TS_ActiveWaypoint = 0
        private real TS_ActiveElapsed = 0.00
        private unit TS_ActiveCarrier = null
        private unit TS_ActiveCarrierB = null
        private boolean TS_ActiveCarrierTemporary = false
        private boolean TS_ActiveDescending = false
        private effect array TS_PassengerEffect
        private real array TS_PassengerEffectFacingOffset
        private integer TS_PassengerEffectCount = 0
        private integer TS_LastSafeStop = 0
        private integer TS_EndStop = 0
        private boolean TS_EndResumeScheduled = false
        private boolean TS_EndSkipCurrentWaypoint = false
        private boolean TS_GameButtonWasVisible = false

        private unit TS_HeldVehicle = null
        private boolean TS_HeldUsesPatrol = false

        private integer TS_SelectedStop = 0
        private trigger TS_MasterSelectedHandlers = null
        private trigger TS_TravelFinishedHandlers = null

        private dialog TS_SkipDialog = null
        private dialog TS_StopDialog = null
        private button TS_SkipButton = null
        private button TS_SkipCancelButton = null
        private button TS_DropButton = null
        private button TS_ContinueButton = null
        private integer TS_PromptStop = 0
        private boolean TS_PromptVisible = false
        private boolean TS_StopPromptVisible = false

        private timer TS_UpdateTimer = null
        private timer TS_DiscoveryTimer = null
        private timer TS_StopPromptTimer = null
        private timer TS_TransitionTimer = null
        private location TS_TerrainLocation = null
    endglobals

    private function TS_IsValidStop takes integer stopId returns boolean
        return stopId > 0 and stopId <= TS_StopCount
    endfunction

    // Central World Editor unit binding access. Method libraries must use these
    // getters instead of depending directly on udg_* globals.
    public function GetWindRiderMaster takes integer index returns unit
        if index < 1 or index > 6 then
            return null
        endif
        return udg_WindRiderMaster[index]
    endfunction

    public function GetFlightMaster takes integer index returns unit
        if index < 1 or index > 2 then
            return null
        endif
        return udg_FlightMaster[index]
    endfunction

    public function GetShipMaster takes integer index returns unit
        if index < 1 or index > 6 then
            return null
        endif
        return udg_Shipmaster[index]
    endfunction

    public function GetTravelShipA takes nothing returns unit
        return udg_TravelShipA
    endfunction

    public function GetTravelShipB takes nothing returns unit
        return udg_TravelShipB
    endfunction

    public function GetZeppelin takes integer index returns unit
        if index == 1 then
            return udg_ZeppelinA
        elseif index == 2 then
            return udg_ZeppelinB
        endif
        return null
    endfunction

    public function GetNazgrek takes nothing returns unit
        return udg_Nazgrek
    endfunction

    public function GetZulkis takes nothing returns unit
        return udg_Zulkis
    endfunction

    public function GetTamedUnit takes nothing returns unit
        return udg_TamedUnit
    endfunction

    public function GetShadowclaw takes nothing returns unit
        return udg_Shadowclaw
    endfunction

    private function TS_RegisterMasterEffect takes unit master returns nothing
        local integer index = 1

        if master == null or GetUnitTypeId(master) == 0 then
            return
        endif
        loop
            exitwhen index > TS_MasterEffectCount
            if TS_MasterEffectUnit[index] == master then
                return
            endif
            set index = index + 1
        endloop
        if TS_MasterEffectCount >= TS_MAX_MASTER_EFFECTS then
            return
        endif
        set TS_MasterEffectCount = TS_MasterEffectCount + 1
        set TS_MasterEffectUnit[TS_MasterEffectCount] = master
        set TS_MasterEffect[TS_MasterEffectCount] = AddSpecialEffectTarget(TS_MASTER_EFFECT_MODEL, master, "overhead")
    endfunction

    private function TS_RegisterSharedMasterEffects takes nothing returns nothing
        local integer index = 1

        loop
            exitwhen index > 6
            call TS_RegisterMasterEffect(GetWindRiderMaster(index))
            set index = index + 1
        endloop
        set index = 1
        loop
            exitwhen index > 2
            call TS_RegisterMasterEffect(GetFlightMaster(index))
            set index = index + 1
        endloop
        set index = 1
        loop
            exitwhen index > 6
            call TS_RegisterMasterEffect(GetShipMaster(index))
            set index = index + 1
        endloop
    endfunction

    private function TS_IsValidRoute takes integer routeId returns boolean
        return routeId > 0 and routeId <= TS_RouteCount
    endfunction

    private function TS_GetWaypointIndex takes integer routeId, integer waypointIndex returns integer
        return (routeId - 1) * TS_MAX_WAYPOINTS + waypointIndex
    endfunction

    private function TS_GetDeckIndex takes integer routeId, integer slot returns integer
        return (routeId - 1) * 2 + slot
    endfunction

    private function TS_PointInRect takes rect whichRect, real x, real y returns boolean
        if whichRect == null then
            return false
        endif
        return x >= GetRectMinX(whichRect) and x <= GetRectMaxX(whichRect) and y >= GetRectMinY(whichRect) and y <= GetRectMaxY(whichRect)
    endfunction

    private function TS_IsUnitAtStop takes unit whichUnit, integer stopId returns boolean
        local real dx
        local real dy

        if whichUnit == null or not TS_IsValidStop(stopId) then
            return false
        endif
        if TS_PointInRect(TS_StopBoardArea[stopId], GetUnitX(whichUnit), GetUnitY(whichUnit)) then
            return true
        endif
        set dx = GetUnitX(whichUnit) - TS_StopX[stopId]
        set dy = GetUnitY(whichUnit) - TS_StopY[stopId]
        return dx * dx + dy * dy <= TS_DISCOVERY_RANGE * TS_DISCOVERY_RANGE
    endfunction

    private function TS_IsUnitNearMaster takes unit whichUnit, integer stopId returns boolean
        local unit master
        local real dx
        local real dy

        if whichUnit == null or not TS_IsValidStop(stopId) then
            set master = null
            return false
        endif
        set master = TS_StopMaster[stopId]
        if master == null or GetUnitTypeId(master) == 0 then
            set master = null
            return false
        endif
        set dx = GetUnitX(whichUnit) - GetUnitX(master)
        set dy = GetUnitY(whichUnit) - GetUnitY(master)
        set master = null
        return dx * dx + dy * dy <= TS_DISCOVERY_RANGE * TS_DISCOVERY_RANGE
    endfunction

    private function TS_GetZoneName takes integer stopId returns string
        local integer zoneId

        if not TS_IsValidStop(stopId) then
            return "Unknown"
        endif
        set zoneId = TS_StopZoneId[stopId]
        if zoneId <= 0 then
            set zoneId = ZonesCore_GetZoneIdAtPoint(TS_StopX[stopId], TS_StopY[stopId])
            set TS_StopZoneId[stopId] = zoneId
        endif
        if zoneId > 0 then
            return ZonesCore_Zones_GetZoneName(zoneId)
        endif
        return "Unknown"
    endfunction

    private function TS_RegisterStopIcon takes integer stopId returns nothing
        if not TS_IsValidStop(stopId) or TS_StopIconRegistered[stopId] or TS_StopMaster[stopId] == null then
            return
        endif
        if TS_StopMethod[stopId] == TRAVEL_METHOD_WYVERN or TS_StopMethod[stopId] == TRAVEL_METHOD_ZEPPELIN then
            set TS_StopIcon[stopId] = IconQuery_RegisterFlightMasterUnitIcon(TS_StopMaster[stopId])
        else
            set TS_StopIcon[stopId] = IconQuery_RegisterShipMasterUnitIcon(TS_StopMaster[stopId])
        endif
        if TS_StopIcon[stopId] != null then
            set TS_StopIconRegistered[stopId] = true
        endif
    endfunction

    public function GetStopCount takes nothing returns integer
        return TS_StopCount
    endfunction

    public function GetRouteCount takes nothing returns integer
        return TS_RouteCount
    endfunction

    public function GetStopMethod takes integer stopId returns integer
        if TS_IsValidStop(stopId) then
            return TS_StopMethod[stopId]
        endif
        return 0
    endfunction

    public function GetStopName takes integer stopId returns string
        if TS_IsValidStop(stopId) then
            return TS_StopName[stopId]
        endif
        return ""
    endfunction

    public function GetStopIdByName takes string name returns integer
        local integer stopId = 1

        loop
            exitwhen stopId > TS_StopCount
            if TS_StopName[stopId] == name then
                return stopId
            endif
            set stopId = stopId + 1
        endloop
        return 0
    endfunction

    public function GetStopZoneId takes integer stopId returns integer
        if TS_IsValidStop(stopId) and TS_StopZoneId[stopId] <= 0 then
            set TS_StopZoneId[stopId] = ZonesCore_GetZoneIdAtPoint(TS_StopX[stopId], TS_StopY[stopId])
        endif
        if TS_IsValidStop(stopId) then
            return TS_StopZoneId[stopId]
        endif
        return 0
    endfunction

    public function GetStopZoneName takes integer stopId returns string
        return TS_GetZoneName(stopId)
    endfunction

    public function GetStopMaster takes integer stopId returns unit
        if TS_IsValidStop(stopId) then
            return TS_StopMaster[stopId]
        endif
        return null
    endfunction

    public function GetStopX takes integer stopId returns real
        if TS_IsValidStop(stopId) then
            return TS_StopX[stopId]
        endif
        return 0.00
    endfunction

    public function GetStopY takes integer stopId returns real
        if TS_IsValidStop(stopId) then
            return TS_StopY[stopId]
        endif
        return 0.00
    endfunction

    public function GetStopIdForMaster takes unit master returns integer
        local integer stopId = 1

        loop
            exitwhen stopId > TS_StopCount
            if TS_StopMaster[stopId] == master then
                return stopId
            endif
            set stopId = stopId + 1
        endloop
        return 0
    endfunction

    public function GetRouteStart takes integer routeId returns integer
        if TS_IsValidRoute(routeId) then
            return TS_RouteStart[routeId]
        endif
        return 0
    endfunction

    public function GetRouteEnd takes integer routeId returns integer
        if TS_IsValidRoute(routeId) then
            return TS_RouteEnd[routeId]
        endif
        return 0
    endfunction

    public function GetRouteStartZoneId takes integer routeId returns integer
        if TS_IsValidRoute(routeId) then
            return GetStopZoneId(TS_RouteStart[routeId])
        endif
        return 0
    endfunction

    public function GetRouteEndZoneId takes integer routeId returns integer
        if TS_IsValidRoute(routeId) then
            return GetStopZoneId(TS_RouteEnd[routeId])
        endif
        return 0
    endfunction

    public function GetRouteStartName takes integer routeId returns string
        if TS_IsValidRoute(routeId) then
            return TS_StopName[TS_RouteStart[routeId]]
        endif
        return ""
    endfunction

    public function GetRouteEndName takes integer routeId returns string
        if TS_IsValidRoute(routeId) then
            return TS_StopName[TS_RouteEnd[routeId]]
        endif
        return ""
    endfunction

    public function GetRouteMethod takes integer routeId returns integer
        if TS_IsValidRoute(routeId) then
            return TS_RouteMethod[routeId]
        endif
        return 0
    endfunction

    public function GetRouteFare takes integer routeId returns integer
        if TS_IsValidRoute(routeId) then
            return TS_RouteFare[routeId]
        endif
        return 0
    endfunction

    public function GetRouteSkipFee takes integer routeId returns integer
        if TS_IsValidRoute(routeId) then
            return TS_RouteSkipFee[routeId]
        endif
        return 0
    endfunction

    public function GetRouteVehicle takes integer routeId returns unit
        if TS_IsValidRoute(routeId) then
            return TS_RouteVehicle[routeId]
        endif
        return null
    endfunction

    public function IsRouteEnabled takes integer routeId returns boolean
        return TS_IsValidRoute(routeId) and TS_RouteEnabled[routeId]
    endfunction

    public function GetRouteWaypointCount takes integer routeId returns integer
        if TS_IsValidRoute(routeId) then
            return TS_RouteWaypointCount[routeId]
        endif
        return 0
    endfunction

    public function GetRouteWaypointX takes integer routeId, integer waypoint returns real
        if TS_IsValidRoute(routeId) and waypoint > 0 and waypoint <= TS_RouteWaypointCount[routeId] then
            return TS_WaypointX[TS_GetWaypointIndex(routeId, waypoint)]
        endif
        return 0.00
    endfunction

    public function GetRouteWaypointY takes integer routeId, integer waypoint returns real
        if TS_IsValidRoute(routeId) and waypoint > 0 and waypoint <= TS_RouteWaypointCount[routeId] then
            return TS_WaypointY[TS_GetWaypointIndex(routeId, waypoint)]
        endif
        return 0.00
    endfunction

    public function RouteRequiresStartDiscovery takes integer routeId returns boolean
        return TS_IsValidRoute(routeId) and TS_RouteRequireStartDiscovered[routeId]
    endfunction

    public function RouteRequiresEndDiscovery takes integer routeId returns boolean
        return TS_IsValidRoute(routeId) and TS_RouteRequireEndDiscovered[routeId]
    endfunction

    public function IsStopDiscovered takes integer stopId returns boolean
        return TS_IsValidStop(stopId) and TS_StopDiscovered[stopId]
    endfunction

    public function SetStopDiscovered takes integer stopId, boolean discovered returns nothing
        if not TS_IsValidStop(stopId) then
            return
        endif
        set TS_StopDiscovered[stopId] = discovered
        if discovered then
            call TS_RegisterStopIcon(stopId)
        elseif TS_StopIconRegistered[stopId] then
            call IconQuery_UnregisterIcon(TS_StopIcon[stopId])
            set TS_StopIcon[stopId] = null
            set TS_StopIconRegistered[stopId] = false
        endif
    endfunction

    public function DiscoverStop takes integer stopId, boolean showMessage returns nothing
        if not TS_IsValidStop(stopId) or TS_StopDiscovered[stopId] then
            return
        endif
        call SetStopDiscovered(stopId, true)
        if showMessage then
            call ShowRegionTitle(TS_DISCOVERED_PREFIX, TS_DISCOVERED_NAME_COLOR + TS_StopName[stopId] + "|r")
            if gg_snd_Interface_ZoneDiscovered != null then
                call StartSound(gg_snd_Interface_ZoneDiscovered)
            endif
        endif
    endfunction

    public function IsRouteDiscovered takes integer routeId returns boolean
        if not TS_IsValidRoute(routeId) then
            return false
        endif
        if TS_RouteRequireStartDiscovered[routeId] and not TS_StopDiscovered[TS_RouteStart[routeId]] then
            return false
        endif
        if TS_RouteRequireEndDiscovered[routeId] and not TS_StopDiscovered[TS_RouteEnd[routeId]] then
            return false
        endif
        return true
    endfunction

    private function TS_OnMasterSelected takes nothing returns nothing
        local unit master = DialogInteraction_SelectedUnit
        local integer stopId = GetStopIdForMaster(master)

        if stopId > 0 and ((FallenHeroState_IsAlive(udg_Nazgrek) and TS_IsUnitNearMaster(udg_Nazgrek, stopId)) or (FallenHeroState_IsAlive(udg_Zulkis) and TS_IsUnitNearMaster(udg_Zulkis, stopId))) then
            call DiscoverStop(stopId, true)
            set TS_SelectedStop = stopId
            if TS_MasterSelectedHandlers != null then
                call TriggerExecute(TS_MasterSelectedHandlers)
            endif
            set TS_SelectedStop = 0
        endif
        set master = null
    endfunction

    public function RegisterMasterSelectedHandler takes code handler returns nothing
        if handler == null then
            return
        endif
        if TS_MasterSelectedHandlers == null then
            set TS_MasterSelectedHandlers = CreateTrigger()
        endif
        call TriggerAddAction(TS_MasterSelectedHandlers, handler)
    endfunction

    public function GetSelectedStop takes nothing returns integer
        return TS_SelectedStop
    endfunction

    public function RegisterTravelFinishedHandler takes code handler returns nothing
        if handler == null then
            return
        endif
        if TS_TravelFinishedHandlers == null then
            set TS_TravelFinishedHandlers = CreateTrigger()
        endif
        call TriggerAddAction(TS_TravelFinishedHandlers, handler)
    endfunction

    public function RegisterStop takes integer methodId, string name, integer zoneId, unit master, rect boardArea, real dropX, real dropY, boolean requiresDiscovery returns integer
        local integer stopId

        if TS_StopCount >= TS_MAX_STOPS or methodId < TRAVEL_METHOD_WYVERN or methodId > TRAVEL_METHOD_SHIP_B or (requiresDiscovery and master == null) then
            return 0
        endif
        set TS_StopCount = TS_StopCount + 1
        set stopId = TS_StopCount
        set TS_StopMethod[stopId] = methodId
        set TS_StopName[stopId] = name
        set TS_StopZoneId[stopId] = zoneId
        set TS_StopMaster[stopId] = master
        set TS_StopBoardArea[stopId] = boardArea
        set TS_StopX[stopId] = dropX
        set TS_StopY[stopId] = dropY
        set TS_StopRequiresDiscovery[stopId] = requiresDiscovery
        if master != null then
            call TS_RegisterMasterEffect(master)
        endif
        if not requiresDiscovery then
            call SetStopDiscovered(stopId, true)
        endif
        return stopId
    endfunction

    public function RegisterRoute takes integer methodId, integer startStop, integer endStop, integer fare, integer skipFee returns integer
        local integer routeId

        if TS_RouteCount >= TS_MAX_ROUTES or not TS_IsValidStop(startStop) or not TS_IsValidStop(endStop) or startStop == endStop then
            return 0
        endif
        if TS_StopMethod[startStop] != methodId or TS_StopMethod[endStop] != methodId then
            return 0
        endif
        set TS_RouteCount = TS_RouteCount + 1
        set routeId = TS_RouteCount
        set TS_RouteMethod[routeId] = methodId
        set TS_RouteStart[routeId] = startStop
        set TS_RouteEnd[routeId] = endStop
        set TS_RouteFare[routeId] = IMaxBJ(0, fare)
        if skipFee < 0 then
            set TS_RouteSkipFee[routeId] = TS_SKIP_FEE_DEFAULT
        else
            set TS_RouteSkipFee[routeId] = skipFee
        endif
        set TS_RouteEnabled[routeId] = true
        set TS_RouteAvailable[routeId] = true
        set TS_RouteShowPassengers[routeId] = methodId == TRAVEL_METHOD_SHIP_A or methodId == TRAVEL_METHOD_SHIP_B
        set TS_RouteRequireStartDiscovered[routeId] = methodId == TRAVEL_METHOD_WYVERN or methodId == TRAVEL_METHOD_ZEPPELIN
        set TS_RouteRequireEndDiscovered[routeId] = TS_RouteRequireStartDiscovered[routeId]
        set TS_RouteFlyHeight[routeId] = 500.00
        set TS_RouteMoveSpeed[routeId] = 400.00
        set TS_DeckOffset[TS_GetDeckIndex(routeId, 1)] = 400.00
        set TS_DeckAngle[TS_GetDeckIndex(routeId, 1)] = 205.00
        set TS_DeckHeight[TS_GetDeckIndex(routeId, 1)] = 500.00
        set TS_DeckOffset[TS_GetDeckIndex(routeId, 2)] = 400.00
        set TS_DeckAngle[TS_GetDeckIndex(routeId, 2)] = 155.00
        set TS_DeckHeight[TS_GetDeckIndex(routeId, 2)] = 500.00
        return routeId
    endfunction

    public function SetRouteEnabled takes integer routeId, boolean enabled returns nothing
        if TS_IsValidRoute(routeId) then
            set TS_RouteEnabled[routeId] = enabled
        endif
    endfunction

    public function SetRouteFare takes integer routeId, integer fare returns nothing
        if TS_IsValidRoute(routeId) then
            set TS_RouteFare[routeId] = IMaxBJ(0, fare)
        endif
    endfunction

    public function SetRouteSkipFee takes integer routeId, integer skipFee returns nothing
        if TS_IsValidRoute(routeId) then
            set TS_RouteSkipFee[routeId] = IMaxBJ(0, skipFee)
        endif
    endfunction

    public function SetRouteDiscoveryRequirements takes integer routeId, boolean requireStart, boolean requireEnd returns nothing
        if TS_IsValidRoute(routeId) then
            set TS_RouteRequireStartDiscovered[routeId] = requireStart
            set TS_RouteRequireEndDiscovered[routeId] = requireEnd
        endif
    endfunction

    public function SetRouteShowPassengers takes integer routeId, boolean showPassengers returns nothing
        if TS_IsValidRoute(routeId) then
            set TS_RouteShowPassengers[routeId] = showPassengers
        endif
    endfunction

    public function SetRouteAvailable takes integer routeId, boolean available returns nothing
        if TS_IsValidRoute(routeId) then
            set TS_RouteAvailable[routeId] = available
        endif
    endfunction

    public function SetRouteVehicle takes integer routeId, unit vehicle, boolean scheduled, boolean usesPatrol returns nothing
        if TS_IsValidRoute(routeId) then
            set TS_RouteVehicle[routeId] = vehicle
            set TS_RouteScheduled[routeId] = scheduled
            set TS_RouteUsesPatrol[routeId] = usesPatrol
            if vehicle == null then
                set TS_RouteAvailable[routeId] = false
            elseif TS_RouteMethod[routeId] == TRAVEL_METHOD_WYVERN or TS_RouteMethod[routeId] == TRAVEL_METHOD_ZEPPELIN then
                call SetUnitOwner(vehicle, Player(TS_TRAVEL_UNIT_OWNER_ID), true)
                call SetUnitInvulnerable(vehicle, true)
            endif
        endif
    endfunction

    public function SetRouteCarrierTypes takes integer routeId, integer carrierTypeA, integer carrierTypeB, real flyHeight, real moveSpeed returns nothing
        if TS_IsValidRoute(routeId) then
            set TS_RouteCarrierTypeA[routeId] = carrierTypeA
            set TS_RouteCarrierTypeB[routeId] = carrierTypeB
            set TS_RouteFlyHeight[routeId] = flyHeight
            set TS_RouteMoveSpeed[routeId] = moveSpeed
        endif
    endfunction

    public function SetRouteDeckSlot takes integer routeId, integer slot, real offset, real angle, real height returns nothing
        local integer index

        if not TS_IsValidRoute(routeId) or slot < 1 or slot > 2 then
            return
        endif
        set index = TS_GetDeckIndex(routeId, slot)
        set TS_DeckOffset[index] = offset
        set TS_DeckAngle[index] = angle
        set TS_DeckHeight[index] = height
    endfunction

    public function AddWaypoint takes integer routeId, real x, real y, integer stopId returns boolean
        local integer waypoint
        local integer index

        if not TS_IsValidRoute(routeId) or TS_RouteWaypointCount[routeId] >= TS_MAX_WAYPOINTS then
            return false
        endif
        set waypoint = TS_RouteWaypointCount[routeId] + 1
        set TS_RouteWaypointCount[routeId] = waypoint
        set index = TS_GetWaypointIndex(routeId, waypoint)
        set TS_WaypointX[index] = x
        set TS_WaypointY[index] = y
        if TS_IsValidStop(stopId) then
            set TS_WaypointStop[index] = stopId
        endif
        return true
    endfunction

    public function RegisterPassengerEffect takes integer unitTypeId, string modelPath, real scale, real facingOffset returns nothing
        local integer existingIndex = 1

        if unitTypeId == 0 then
            return
        endif
        loop
            exitwhen existingIndex > TS_ProxyCount
            if TS_ProxyUnitType[existingIndex] == unitTypeId then
                set TS_ProxyModel[existingIndex] = modelPath
                set TS_ProxyScale[existingIndex] = scale
                set TS_ProxyFacingOffset[existingIndex] = facingOffset
                return
            endif
            set existingIndex = existingIndex + 1
        endloop
        if TS_ProxyCount >= TS_MAX_PROXY_MODELS then
            return
        endif
        set TS_ProxyCount = TS_ProxyCount + 1
        set TS_ProxyUnitType[TS_ProxyCount] = unitTypeId
        set TS_ProxyModel[TS_ProxyCount] = modelPath
        set TS_ProxyScale[TS_ProxyCount] = scale
        set TS_ProxyFacingOffset[TS_ProxyCount] = facingOffset
    endfunction

    public function IsRouteAvailable takes integer routeId returns boolean
        local unit vehicle

        if not TS_IsValidRoute(routeId) or not TS_RouteEnabled[routeId] or not IsRouteDiscovered(routeId) then
            set vehicle = null
            return false
        endif
        set vehicle = TS_RouteVehicle[routeId]
        if TS_RouteScheduled[routeId] then
            set vehicle = null
            return TS_RouteAvailable[routeId]
        endif
        if vehicle != null and not TS_IsUnitAtStop(vehicle, TS_RouteStart[routeId]) then
            set vehicle = null
            return false
        endif
        set vehicle = null
        return true
    endfunction

    public function GetRouteAtStop takes integer stopId, integer listIndex returns integer
        local integer routeId = 1
        local integer found = 0

        loop
            exitwhen routeId > TS_RouteCount
            if TS_RouteEnabled[routeId] and TS_RouteStart[routeId] == stopId then
                set found = found + 1
                if found == listIndex then
                    return routeId
                endif
            endif
            set routeId = routeId + 1
        endloop
        return 0
    endfunction

    public function GetRouteCountAtStop takes integer stopId returns integer
        local integer routeId = 1
        local integer count = 0

        loop
            exitwhen routeId > TS_RouteCount
            if TS_RouteEnabled[routeId] and TS_RouteStart[routeId] == stopId then
                set count = count + 1
            endif
            set routeId = routeId + 1
        endloop
        return count
    endfunction

    private function TS_ClearPassengerList takes nothing returns nothing
        local integer index = 1

        loop
            exitwhen index > TS_PassengerCount
            set TS_Passenger[index] = null
            set TS_PassengerSelected[index] = false
            set TS_PassengerHero[index] = false
            set TS_PassengerCompanion[index] = false
            set TS_PassengerPet[index] = false
            set index = index + 1
        endloop
        set TS_PassengerCount = 0
        set TS_PassengerRoute = 0
    endfunction

    private function TS_HasPassenger takes unit whichUnit returns boolean
        local integer index = 1

        loop
            exitwhen index > TS_PassengerCount
            if TS_Passenger[index] == whichUnit then
                return true
            endif
            set index = index + 1
        endloop
        return false
    endfunction

    private function TS_AddPassenger takes unit whichUnit, boolean isHero, boolean isCompanion, boolean isPet returns nothing
        if whichUnit == null or TS_PassengerCount >= TS_MAX_PASSENGERS or TS_HasPassenger(whichUnit) then
            return
        endif
        set TS_PassengerCount = TS_PassengerCount + 1
        set TS_Passenger[TS_PassengerCount] = whichUnit
        set TS_PassengerSelected[TS_PassengerCount] = true
        set TS_PassengerHero[TS_PassengerCount] = isHero
        set TS_PassengerCompanion[TS_PassengerCount] = isCompanion
        set TS_PassengerPet[TS_PassengerCount] = isPet
    endfunction

    public function BuildPassengerList takes integer routeId returns integer
        local integer index = 1
        local integer stopId
        local unit candidate

        call TS_ClearPassengerList()
        if not TS_IsValidRoute(routeId) then
            set candidate = null
            return 0
        endif
        set TS_PassengerRoute = routeId
        set stopId = TS_RouteStart[routeId]
        if FallenHeroState_IsAlive(udg_Nazgrek) and TS_IsUnitAtStop(udg_Nazgrek, stopId) then
            call TS_AddPassenger(udg_Nazgrek, true, false, false)
        endif
        if FallenHeroState_IsAlive(udg_Zulkis) and TS_IsUnitAtStop(udg_Zulkis, stopId) then
            call TS_AddPassenger(udg_Zulkis, true, false, false)
        endif
        if TS_RouteMethod[routeId] != TRAVEL_METHOD_WYVERN then
            loop
                exitwhen index > Companions_GetControlledDisplayCount()
                set candidate = Companions_GetControlledDisplayUnit(index)
                if candidate != null and TS_IsUnitAtStop(candidate, stopId) then
                    call TS_AddPassenger(candidate, false, true, Pet_IsPetUnit(candidate))
                endif
                set index = index + 1
            endloop
            if udg_TamedUnit != null and not Pet_IsDead(udg_TamedUnit) and TS_IsUnitAtStop(udg_TamedUnit, stopId) then
                call TS_AddPassenger(udg_TamedUnit, false, true, true)
            endif
            if udg_Shadowclaw != null and TS_IsUnitAtStop(udg_Shadowclaw, stopId) then
                call TS_AddPassenger(udg_Shadowclaw, false, true, true)
            endif
        endif
        set candidate = null
        return TS_PassengerCount
    endfunction

    public function GetPassengerCount takes nothing returns integer
        return TS_PassengerCount
    endfunction

    public function GetPassenger takes integer index returns unit
        if index > 0 and index <= TS_PassengerCount then
            return TS_Passenger[index]
        endif
        return null
    endfunction

    public function IsPassengerSelected takes integer index returns boolean
        return index > 0 and index <= TS_PassengerCount and TS_PassengerSelected[index]
    endfunction

    public function IsPassengerHero takes integer index returns boolean
        return index > 0 and index <= TS_PassengerCount and TS_PassengerHero[index]
    endfunction

    public function IsPassengerCompanion takes integer index returns boolean
        return index > 0 and index <= TS_PassengerCount and TS_PassengerCompanion[index]
    endfunction

    public function IsPassengerPet takes integer index returns boolean
        return index > 0 and index <= TS_PassengerCount and TS_PassengerPet[index]
    endfunction

    public function SetPassengerSelected takes integer index, boolean selected returns boolean
        if index <= 0 or index > TS_PassengerCount or TS_PassengerPet[index] then
            return false
        endif
        set TS_PassengerSelected[index] = selected
        return true
    endfunction

    public function GetSelectedHeroCount takes nothing returns integer
        local integer index = 1
        local integer count = 0

        loop
            exitwhen index > TS_PassengerCount
            if TS_PassengerSelected[index] and TS_PassengerHero[index] then
                set count = count + 1
            endif
            set index = index + 1
        endloop
        return count
    endfunction

    public function GetPaidPassengerCount takes nothing returns integer
        local integer index = 1
        local integer count = 0

        loop
            exitwhen index > TS_PassengerCount
            if TS_PassengerSelected[index] and not TS_PassengerPet[index] then
                set count = count + 1
            endif
            set index = index + 1
        endloop
        return count
    endfunction

    public function GetTotalFare takes integer routeId returns integer
        if not TS_IsValidRoute(routeId) then
            return 0
        endif
        return TS_RouteFare[routeId] * GetPaidPassengerCount()
    endfunction

    public function GetTotalSkipFee takes integer routeId returns integer
        if not TS_IsValidRoute(routeId) then
            return 0
        endif
        return TS_RouteSkipFee[routeId] * GetPaidPassengerCount()
    endfunction

    public function HasUnselectedCompanions takes nothing returns boolean
        local integer index = 1

        loop
            exitwhen index > TS_PassengerCount
            if TS_PassengerCompanion[index] and not TS_PassengerPet[index] and not TS_PassengerSelected[index] then
                return true
            endif
            set index = index + 1
        endloop
        return false
    endfunction

    private function TS_FindProxyIndex takes integer unitTypeId returns integer
        local integer index = 1

        loop
            exitwhen index > TS_ProxyCount
            if TS_ProxyUnitType[index] == unitTypeId then
                return index
            endif
            set index = index + 1
        endloop
        return 0
    endfunction

    private function TS_GetTerrainZ takes real x, real y returns real
        call MoveLocation(TS_TerrainLocation, x, y)
        return GetLocationZ(TS_TerrainLocation)
    endfunction

    private function TS_UpdatePassengerEffects takes nothing returns nothing
        local integer slot = 1
        local integer deckIndex
        local real facing
        local real angle
        local real x
        local real y
        local real z

        if TS_ActiveCarrier == null then
            return
        endif
        set facing = GetUnitFacing(TS_ActiveCarrier)
        loop
            exitwhen slot > TS_PassengerEffectCount
            if TS_PassengerEffect[slot] != null then
                set deckIndex = TS_GetDeckIndex(TS_ActiveRoute, slot)
                set angle = (facing + TS_DeckAngle[deckIndex]) * bj_DEGTORAD
                set x = GetUnitX(TS_ActiveCarrier) + TS_DeckOffset[deckIndex] * Cos(angle)
                set y = GetUnitY(TS_ActiveCarrier) + TS_DeckOffset[deckIndex] * Sin(angle)
                set z = TS_GetTerrainZ(x, y) + GetUnitFlyHeight(TS_ActiveCarrier) + TS_DeckHeight[deckIndex]
                call BlzSetSpecialEffectPosition(TS_PassengerEffect[slot], x, y, z)
                call BlzSetSpecialEffectYaw(TS_PassengerEffect[slot], (facing + TS_PassengerEffectFacingOffset[slot]) * bj_DEGTORAD)
            endif
            set slot = slot + 1
        endloop
    endfunction

    private function TS_DestroyPassengerEffects takes nothing returns nothing
        local integer slot = 1

        loop
            exitwhen slot > TS_PassengerEffectCount
            if TS_PassengerEffect[slot] != null then
                call DestroyEffect(TS_PassengerEffect[slot])
                set TS_PassengerEffect[slot] = null
                set TS_PassengerEffectFacingOffset[slot] = 0.00
            endif
            set slot = slot + 1
        endloop
        set TS_PassengerEffectCount = 0
    endfunction

    private function TS_CreatePassengerEffects takes nothing returns nothing
        local integer passengerIndex = 1
        local integer proxyIndex
        local integer slot = 0
        local string modelPath

        if not TS_RouteShowPassengers[TS_ActiveRoute] or TS_ActiveCarrier == null then
            return
        endif
        loop
            exitwhen passengerIndex > TS_PassengerCount or slot >= 2
            if TS_PassengerSelected[passengerIndex] and TS_PassengerHero[passengerIndex] then
                set proxyIndex = TS_FindProxyIndex(GetUnitTypeId(TS_Passenger[passengerIndex]))
                if proxyIndex > 0 then
                    set modelPath = TS_ProxyModel[proxyIndex]
                    if modelPath != "" then
                        set slot = slot + 1
                        set TS_PassengerEffect[slot] = AddSpecialEffect(modelPath, GetUnitX(TS_ActiveCarrier), GetUnitY(TS_ActiveCarrier))
                        call BlzSetSpecialEffectScale(TS_PassengerEffect[slot], TS_ProxyScale[proxyIndex])
                        set TS_PassengerEffectFacingOffset[slot] = TS_ProxyFacingOffset[proxyIndex]
                    endif
                endif
            endif
            set passengerIndex = passengerIndex + 1
        endloop
        set TS_PassengerEffectCount = slot
        call TS_UpdatePassengerEffects()
    endfunction

    private function TS_HideSelectedPassengers takes nothing returns nothing
        local integer index = 1
        local unit passenger

        loop
            exitwhen index > TS_PassengerCount
            if TS_PassengerSelected[index] then
                set passenger = TS_Passenger[index]
                set TS_PassengerWasInvulnerable[index] = BlzIsUnitInvulnerable(passenger)
                if Companions_IsControlled(passenger) then
                    call Companions_Suspend(passenger)
                endif
                call SetUnitInvulnerable(passenger, true)
                call PauseUnit(passenger, true)
                call ShowUnit(passenger, false)
            endif
            set index = index + 1
        endloop
        set passenger = null
    endfunction

    private function TS_RemoveUnselectedCompanions takes nothing returns nothing
        local integer index = 1

        loop
            exitwhen index > TS_PassengerCount
            if TS_PassengerCompanion[index] and not TS_PassengerPet[index] and not TS_PassengerSelected[index] then
                call Companions_Remove(TS_Passenger[index])
            endif
            set index = index + 1
        endloop
    endfunction

    private function TS_RestorePassengersAtStop takes integer stopId returns nothing
        local integer index = 1
        local integer placed = 0
        local unit passenger
        local real angle
        local real distance
        local real x
        local real y

        loop
            exitwhen index > TS_PassengerCount
            if TS_PassengerSelected[index] then
                set passenger = TS_Passenger[index]
                set angle = I2R(placed) * 60.00 * bj_DEGTORAD
                set distance = 96.00 + 24.00 * I2R(ModuloInteger(placed, 2))
                set x = TS_StopX[stopId] + distance * Cos(angle)
                set y = TS_StopY[stopId] + distance * Sin(angle)
                call SetUnitX(passenger, x)
                call SetUnitY(passenger, y)
                call ShowUnit(passenger, true)
                call PauseUnit(passenger, false)
                call SetUnitInvulnerable(passenger, TS_PassengerWasInvulnerable[index])
                if Companions_IsControlled(passenger) then
                    call Companions_Resume(passenger)
                endif
                call ZoneEvent_ForceUpdate(passenger)
                set placed = placed + 1
            endif
            set index = index + 1
        endloop
        set passenger = null
    endfunction

    private function TS_RemoveTemporaryCarriers takes nothing returns nothing
        if TS_ActiveCarrierTemporary then
            if TS_ActiveCarrier != null then
                call RemoveUnit(TS_ActiveCarrier)
            endif
            if TS_ActiveCarrierB != null then
                call RemoveUnit(TS_ActiveCarrierB)
            endif
        endif
        set TS_ActiveCarrier = null
        set TS_ActiveCarrierB = null
        set TS_ActiveCarrierTemporary = false
        set TS_ActiveDescending = false
    endfunction

    private function TS_HidePrompt takes boolean restoreFullscreen returns nothing
        if TS_PromptVisible then
            call DialogSystem_HideDialog(TS_SkipDialog, Player(0))
        endif
        if TS_StopPromptVisible then
            call DialogSystem_HideDialog(TS_StopDialog, Player(0))
        endif
        call PauseTimer(TS_StopPromptTimer)
        set TS_PromptVisible = false
        set TS_StopPromptVisible = false
        set TS_PromptStop = 0
        if restoreFullscreen and TS_Active and not TS_Ending then
            call FullscreenUI_SetEnabled(true)
        endif
    endfunction

    private function TS_ResumeScheduledVehicle takes boolean skipCurrentWaypoint returns nothing
        if TS_ActiveCarrier != null and TS_RouteScheduled[TS_ActiveRoute] and TS_RouteUsesPatrol[TS_ActiveRoute] then
            call PatrolSystem_ResumeFromCurrentPositionEx(TS_ActiveCarrier, skipCurrentWaypoint)
        endif
    endfunction

    private function TS_EndPresentation takes nothing returns nothing
        call DialogSystem_ClearEscapeAction()
        call FCL_Release(Player(0))
        call CameraControl_ResumeQuick(Player(0))
        call FullscreenUI_SetEnabled(false)
        if TRAVEL_HIDE_MASTER_UI_GAME_BUTTON and TS_GameButtonWasVisible then
            call MasterUI_ShowGameButton()
        endif
        set TS_GameButtonWasVisible = false
        set udg_InCinematic = false
    endfunction

    private function TS_CompleteFinish takes nothing returns nothing
        local integer stopId = TS_EndStop

        if not TS_Active or not TS_Ending or not TS_IsValidStop(stopId) then
            return
        endif
        call TS_DestroyPassengerEffects()
        call TS_RestorePassengersAtStop(stopId)
        if TS_EndResumeScheduled then
            call TS_ResumeScheduledVehicle(TS_EndSkipCurrentWaypoint)
        elseif TS_RouteMethod[TS_ActiveRoute] == TRAVEL_METHOD_ZEPPELIN and not TS_ActiveCarrierTemporary and TS_ActiveCarrier != null then
            // Each endpoint owns an outbound zeppelin; reset it while the screen is black.
            call SetUnitX(TS_ActiveCarrier, TS_StopX[TS_RouteStart[TS_ActiveRoute]])
            call SetUnitY(TS_ActiveCarrier, TS_StopY[TS_RouteStart[TS_ActiveRoute]])
        endif
        call TS_EndPresentation()
        call TS_RemoveTemporaryCarriers()
        set TS_Active = false
        set TS_Ending = false
        set TS_ActiveRoute = 0
        set TS_ActiveWaypoint = 0
        set TS_ActiveElapsed = 0.00
        set TS_LastSafeStop = stopId
        set TS_EndStop = 0
        set TS_EndResumeScheduled = false
        set TS_EndSkipCurrentWaypoint = false
        call TS_ClearPassengerList()
        if TS_TravelFinishedHandlers != null then
            call TriggerExecute(TS_TravelFinishedHandlers)
        endif
        call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, TS_FADE_DURATION, TS_FADE_TEXTURE, 0, 0, 0, 0)
    endfunction

    private function TS_FinishAtStop takes integer stopId, boolean resumeScheduled, boolean skipCurrentWaypoint returns nothing
        if not TS_Active or TS_Starting or TS_Ending or not TS_IsValidStop(stopId) then
            return
        endif
        set TS_Ending = true
        set TS_EndStop = stopId
        set TS_EndResumeScheduled = resumeScheduled
        set TS_EndSkipCurrentWaypoint = skipCurrentWaypoint
        call TS_HidePrompt(false)
        call PauseTimer(TS_UpdateTimer)
        if TS_RouteScheduled[TS_ActiveRoute] then
            if TS_RouteUsesPatrol[TS_ActiveRoute] and resumeScheduled then
                call PatrolSystem_Pause(TS_ActiveCarrier)
            endif
        elseif TS_ActiveCarrier != null then
            call IssueImmediateOrder(TS_ActiveCarrier, "stop")
            if TS_ActiveCarrierB != null then
                call IssueImmediateOrder(TS_ActiveCarrierB, "stop")
            endif
        endif
        call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, TS_FADE_DURATION, TS_FADE_TEXTURE, 0, 0, 0, 0)
        call TimerStart(TS_TransitionTimer, TS_FADE_DURATION, false, function TS_CompleteFinish)
    endfunction

    private function TS_IssueCurrentWaypoint takes nothing returns nothing
        local integer waypointIndex
        local real x
        local real y
        local real angle

        if TS_ActiveCarrier == null then
            return
        endif
        if TS_ActiveWaypoint <= 0 then
            set TS_ActiveWaypoint = 1
        endif
        if TS_RouteWaypointCount[TS_ActiveRoute] <= 0 or TS_ActiveWaypoint > TS_RouteWaypointCount[TS_ActiveRoute] then
            set x = TS_StopX[TS_RouteEnd[TS_ActiveRoute]]
            set y = TS_StopY[TS_RouteEnd[TS_ActiveRoute]]
        else
            set waypointIndex = TS_GetWaypointIndex(TS_ActiveRoute, TS_ActiveWaypoint)
            set x = TS_WaypointX[waypointIndex]
            set y = TS_WaypointY[waypointIndex]
        endif
        call IssuePointOrder(TS_ActiveCarrier, "move", x, y)
        if TS_ActiveCarrierB != null then
            set angle = Atan2(y - GetUnitY(TS_ActiveCarrierB), x - GetUnitX(TS_ActiveCarrierB)) + bj_PI * 0.50
            call IssuePointOrder(TS_ActiveCarrierB, "move", x + TS_SECOND_CARRIER_OFFSET * Cos(angle), y + TS_SECOND_CARRIER_OFFSET * Sin(angle))
        endif
    endfunction

    private function TS_ResumeActiveTravel takes boolean skipCurrentWaypoint returns nothing
        if not TS_Active then
            return
        endif
        if TS_RouteScheduled[TS_ActiveRoute] then
            call TS_ResumeScheduledVehicle(skipCurrentWaypoint)
        else
            call TS_IssueCurrentWaypoint()
        endif
    endfunction

    private function TS_OnSkipConfirmed takes nothing returns nothing
        local integer cost
        local integer endStop

        if not TS_Active then
            return
        endif
        set cost = GetTotalSkipFee(TS_ActiveRoute)
        if GetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD) < cost then
            call TS_HidePrompt(true)
            call ExSound_Play("LostGold", "")
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8040Not enough gold to skip this journey.|r")
            call TS_ResumeActiveTravel(false)
            return
        endif
        call SetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD) - cost)
        call ExSound_Play("LostGold", "")
        set endStop = TS_RouteEnd[TS_ActiveRoute]
        if not TS_RouteScheduled[TS_ActiveRoute] and not TS_ActiveCarrierTemporary and TS_ActiveCarrier != null then
            call SetUnitX(TS_ActiveCarrier, TS_StopX[endStop])
            call SetUnitY(TS_ActiveCarrier, TS_StopY[endStop])
        endif
        call TS_FinishAtStop(endStop, TS_RouteScheduled[TS_ActiveRoute], false)
    endfunction

    private function TS_OnSkipCancelled takes nothing returns nothing
        if not TS_Active then
            return
        endif
        call TS_HidePrompt(true)
        call TS_ResumeActiveTravel(false)
    endfunction

    private function TS_OnDropOut takes nothing returns nothing
        local integer stopId = TS_PromptStop

        if not TS_Active or not TS_IsValidStop(stopId) then
            return
        endif
        call TS_FinishAtStop(stopId, true, true)
    endfunction

    private function TS_OnContinueStop takes nothing returns nothing
        if not TS_Active then
            return
        endif
        call TS_HidePrompt(true)
        call TS_ResumeActiveTravel(true)
    endfunction

    private function TS_OnStopPromptTimeout takes nothing returns nothing
        call TS_OnContinueStop()
    endfunction

    private function TS_ShowSkipPrompt takes nothing returns nothing
        local integer cost

        if not TS_Active or TS_Starting or TS_Ending or TS_PromptVisible or TS_StopPromptVisible then
            return
        endif
        if TS_RouteScheduled[TS_ActiveRoute] and TS_RouteUsesPatrol[TS_ActiveRoute] then
            call PatrolSystem_Pause(TS_ActiveCarrier)
        else
            call IssueImmediateOrder(TS_ActiveCarrier, "stop")
            if TS_ActiveCarrierB != null then
                call IssueImmediateOrder(TS_ActiveCarrierB, "stop")
            endif
        endif
        set cost = GetTotalSkipFee(TS_ActiveRoute)
        call FullscreenUI_SetEnabled(false)
        call DialogSystem_SetTitle(TS_SkipDialog, "Skip to " + TS_StopName[TS_RouteEnd[TS_ActiveRoute]] + "? Skipping will cost " + I2S(cost) + " gold.")
        call DialogSystem_SetContext(TS_ActiveCarrier, Player(0))
        call DialogSystem_ShowDialog(TS_SkipDialog, Player(0))
        set TS_PromptVisible = true
    endfunction

    private function TS_ShowStopPrompt takes integer stopId returns nothing
        if not TS_Active or TS_Starting or TS_Ending or not TS_IsValidStop(stopId) then
            return
        endif
        set TS_PromptStop = stopId
        set TS_StopPromptVisible = true
        call FullscreenUI_SetEnabled(false)
        call DialogSystem_SetTitle(TS_StopDialog, "Disembark at " + TS_StopName[stopId] + " or continue to " + TS_StopName[TS_RouteEnd[TS_ActiveRoute]] + "?")
        call DialogSystem_SetContext(TS_ActiveCarrier, Player(0))
        call DialogSystem_ShowDialog(TS_StopDialog, Player(0))
        call TimerStart(TS_StopPromptTimer, TS_STOP_PROMPT_DURATION, false, function TS_OnStopPromptTimeout)
    endfunction

    private function TS_OnEscape takes nothing returns nothing
        if not TS_Active or TS_Starting or TS_Ending then
            return
        endif
        if TS_PromptVisible then
            call TS_OnSkipCancelled()
        elseif TS_StopPromptVisible then
            call TS_OnContinueStop()
        else
            call TS_ShowSkipPrompt()
        endif
    endfunction

    private function TS_UpdateDirectTravel takes nothing returns nothing
        local integer waypointIndex
        local integer waypointStop = 0
        local real targetX
        local real targetY
        local real dx
        local real dy
        local boolean finalWaypoint
        local boolean landed

        if TS_RouteWaypointCount[TS_ActiveRoute] <= 0 or TS_ActiveWaypoint > TS_RouteWaypointCount[TS_ActiveRoute] then
            set targetX = TS_StopX[TS_RouteEnd[TS_ActiveRoute]]
            set targetY = TS_StopY[TS_RouteEnd[TS_ActiveRoute]]
        else
            set waypointIndex = TS_GetWaypointIndex(TS_ActiveRoute, TS_ActiveWaypoint)
            set targetX = TS_WaypointX[waypointIndex]
            set targetY = TS_WaypointY[waypointIndex]
            set waypointStop = TS_WaypointStop[waypointIndex]
        endif
        set dx = GetUnitX(TS_ActiveCarrier) - targetX
        set dy = GetUnitY(TS_ActiveCarrier) - targetY
        set finalWaypoint = TS_RouteWaypointCount[TS_ActiveRoute] <= 0 or TS_ActiveWaypoint >= TS_RouteWaypointCount[TS_ActiveRoute]
        if finalWaypoint and TS_RouteMethod[TS_ActiveRoute] == TRAVEL_METHOD_WYVERN and TS_ActiveCarrierTemporary and not TS_ActiveDescending and dx * dx + dy * dy <= TS_FLIGHT_DESCENT_RANGE * TS_FLIGHT_DESCENT_RANGE then
            set TS_ActiveDescending = true
            call SetUnitFlyHeight(TS_ActiveCarrier, 0.00, TS_FLIGHT_DESCENT_RATE)
            if TS_ActiveCarrierB != null then
                call SetUnitFlyHeight(TS_ActiveCarrierB, 0.00, TS_FLIGHT_DESCENT_RATE)
            endif
        endif
        if dx * dx + dy * dy <= TS_ARRIVAL_RANGE * TS_ARRIVAL_RANGE then
            if finalWaypoint then
                set landed = not TS_ActiveDescending or GetUnitFlyHeight(TS_ActiveCarrier) <= TS_FLIGHT_LANDED_HEIGHT
                if TS_ActiveCarrierB != null and GetUnitFlyHeight(TS_ActiveCarrierB) > TS_FLIGHT_LANDED_HEIGHT then
                    set landed = false
                endif
                if landed then
                    call TS_FinishAtStop(TS_RouteEnd[TS_ActiveRoute], false, false)
                endif
            elseif TS_IsValidStop(waypointStop) and waypointStop != TS_RouteEnd[TS_ActiveRoute] then
                set TS_LastSafeStop = waypointStop
                set TS_ActiveWaypoint = TS_ActiveWaypoint + 1
                call IssueImmediateOrder(TS_ActiveCarrier, "stop")
                if TS_ActiveCarrierB != null then
                    call IssueImmediateOrder(TS_ActiveCarrierB, "stop")
                endif
                call TS_ShowStopPrompt(waypointStop)
            else
                set TS_ActiveWaypoint = TS_ActiveWaypoint + 1
                call TS_IssueCurrentWaypoint()
            endif
        endif
    endfunction

    private function TS_OnUpdate takes nothing returns nothing
        if not TS_Active then
            return
        endif
        if TS_ActiveCarrier == null or GetUnitTypeId(TS_ActiveCarrier) == 0 then
            if TS_RouteScheduled[TS_ActiveRoute] then
                call TS_FinishAtStop(TS_LastSafeStop, false, false)
            else
                call TS_FinishAtStop(TS_RouteEnd[TS_ActiveRoute], false, false)
            endif
            return
        endif
        set TS_ActiveElapsed = TS_ActiveElapsed + TS_UPDATE_PERIOD
        call TS_UpdatePassengerEffects()
        if not TS_RouteScheduled[TS_ActiveRoute] and not TS_PromptVisible and not TS_StopPromptVisible then
            call TS_UpdateDirectTravel()
        endif
        if TS_Active and TS_ActiveElapsed >= TS_TRAVEL_TIMEOUT then
            call TS_FinishAtStop(TS_RouteEnd[TS_ActiveRoute], TS_RouteScheduled[TS_ActiveRoute], false)
        endif
    endfunction

    private function TS_GetCarrierTypeForPassenger takes integer routeId, unit passenger returns integer
        if passenger == udg_Zulkis and TS_RouteCarrierTypeB[routeId] != 0 then
            return TS_RouteCarrierTypeB[routeId]
        endif
        return TS_RouteCarrierTypeA[routeId]
    endfunction

    private function TS_PrepareCarriers takes integer routeId returns boolean
        local integer index = 1
        local integer carrierType
        local integer heroIndex = 0
        local unit carrier

        set TS_ActiveCarrier = TS_RouteVehicle[routeId]
        set TS_ActiveCarrierB = null
        set TS_ActiveCarrierTemporary = false
        set TS_ActiveDescending = false
        if TS_ActiveCarrier != null then
            set carrier = null
            return GetUnitTypeId(TS_ActiveCarrier) != 0
        endif
        if TS_RouteCarrierTypeA[routeId] == 0 then
            set carrier = null
            return false
        endif
        loop
            exitwhen index > TS_PassengerCount or heroIndex >= 2
            if TS_PassengerSelected[index] and TS_PassengerHero[index] then
                set heroIndex = heroIndex + 1
                set carrierType = TS_GetCarrierTypeForPassenger(routeId, TS_Passenger[index])
                set carrier = CreateUnit(Player(TS_TRAVEL_UNIT_OWNER_ID), carrierType, GetUnitX(TS_Passenger[index]), GetUnitY(TS_Passenger[index]), 0.00)
                if carrier == null then
                    call TS_RemoveTemporaryCarriers()
                    set carrier = null
                    return false
                endif
                call UnitAddAbility(carrier, 'Aloc')
                call SetUnitPathing(carrier, false)
                call SetUnitInvulnerable(carrier, true)
                call SetUnitFlyHeight(carrier, 0.00, 0.00)
                call SetUnitFlyHeight(carrier, TS_RouteFlyHeight[routeId], TS_FLIGHT_ASCENT_RATE)
                call SetUnitMoveSpeed(carrier, TS_RouteMoveSpeed[routeId])
                set TS_ActiveCarrierTemporary = true
                if heroIndex == 1 then
                    set TS_ActiveCarrier = carrier
                else
                    set TS_ActiveCarrierB = carrier
                endif
            endif
            set index = index + 1
        endloop
        set carrier = null
        return TS_ActiveCarrier != null
    endfunction

    private function TS_ValidatePassengers takes integer routeId returns boolean
        local integer index = 1
        local integer stopId = TS_RouteStart[routeId]

        if TS_PassengerRoute != routeId or GetSelectedHeroCount() <= 0 then
            return false
        endif
        loop
            exitwhen index > TS_PassengerCount
            if TS_PassengerSelected[index] and (not FallenHeroState_IsAlive(TS_Passenger[index]) or not TS_IsUnitAtStop(TS_Passenger[index], stopId)) then
                return false
            endif
            set index = index + 1
        endloop
        return true
    endfunction

    private function TS_AbortStart takes string message returns nothing
        if TS_HeldVehicle != null and TS_HeldUsesPatrol then
            call PatrolSystem_ResumeFromCurrentPositionEx(TS_HeldVehicle, false)
        endif
        set TS_HeldVehicle = null
        set TS_HeldUsesPatrol = false
        call TS_RemoveTemporaryCarriers()
        set TS_Active = false
        set TS_Starting = false
        set TS_ActiveRoute = 0
        set TS_ActiveWaypoint = 0
        set TS_ActiveElapsed = 0.00
        set TS_LastSafeStop = 0
        set udg_InCinematic = false
        call TS_ClearPassengerList()
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, message)
        call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, TS_FADE_DURATION, TS_FADE_TEXTURE, 0, 0, 0, 0)
    endfunction

    private function TS_CompleteStart takes nothing returns nothing
        local integer routeId = TS_ActiveRoute
        local integer fare
        local real cameraAngle
        local real cameraRotation

        if not TS_Active or not TS_Starting or not TS_IsValidRoute(routeId) then
            return
        endif
        if not TS_PrepareCarriers(routeId) then
            call TS_AbortStart("|cffff8040The travel vehicle is unavailable.|r")
            return
        endif
        set fare = GetTotalFare(routeId)
        if GetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD) < fare then
            call TS_AbortStart("|cffff8040Not enough gold for this journey.|r")
            return
        endif
        call SetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD) - fare)
        if fare > 0 then
            call ExSound_Play("LostGold", "")
        endif
        call TS_RemoveUnselectedCompanions()
        call TS_HideSelectedPassengers()
        set TS_Starting = false
        set TS_HeldVehicle = null
        set TS_HeldUsesPatrol = false
        set TS_GameButtonWasVisible = MasterUI_IsGameButtonVisible()
        if TRAVEL_HIDE_MASTER_UI_GAME_BUTTON then
            call MasterUI_HideGameButton()
        endif
        call FullscreenUI_SetEnabled(true)
        set cameraRotation = GetUnitFacing(TS_ActiveCarrier)
        if TS_RouteMethod[routeId] == TRAVEL_METHOD_WYVERN or TS_RouteMethod[routeId] == TRAVEL_METHOD_ZEPPELIN then
            set cameraAngle = TS_CAMERA_ANGLE_FLIGHT
        else
            set cameraAngle = TS_CAMERA_ANGLE_SHIP
        endif
        call CameraControl_SuspendInteractiveEx(Player(0), TS_CAMERA_DISTANCE, TS_CAMERA_FAR_Z, TS_CAMERA_FOV, cameraAngle, cameraRotation)
        call FCL_Lock(TS_ActiveCarrier, Player(0))
        call TS_CreatePassengerEffects()
        call DialogSystem_SetEscapeAction(function TS_OnEscape)
        if TS_RouteScheduled[routeId] then
            call TS_ResumeScheduledVehicle(true)
        else
            call TS_IssueCurrentWaypoint()
        endif
        call TimerStart(TS_UpdateTimer, TS_UPDATE_PERIOD, true, function TS_OnUpdate)
        call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, TS_FADE_DURATION, TS_FADE_TEXTURE, 0, 0, 0, 0)
    endfunction

    public function Start takes integer routeId returns boolean
        local integer fare

        if TS_Active or not IsRouteAvailable(routeId) or not TS_ValidatePassengers(routeId) or udg_InCinematic then
            return false
        endif
        set fare = GetTotalFare(routeId)
        if GetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD) < fare then
            call ExSound_Play("LostGold", "")
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8040Not enough gold for this journey.|r")
            return false
        endif
        set TS_Active = true
        set TS_Starting = true
        set TS_ActiveRoute = routeId
        set TS_ActiveWaypoint = 1
        set TS_ActiveElapsed = 0.00
        set TS_LastSafeStop = TS_RouteStart[routeId]
        set udg_InCinematic = true
        call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, TS_FADE_DURATION, TS_FADE_TEXTURE, 0, 0, 0, 0)
        call TimerStart(TS_TransitionTimer, TS_FADE_DURATION, false, function TS_CompleteStart)
        return true
    endfunction

    public function IsActive takes nothing returns boolean
        return TS_Active
    endfunction

    public function GetActiveRoute takes nothing returns integer
        return TS_ActiveRoute
    endfunction

    public function ReleaseHeldVehicle takes boolean depart returns nothing
        if TS_HeldVehicle != null and TS_HeldUsesPatrol then
            call PatrolSystem_ResumeFromCurrentPositionEx(TS_HeldVehicle, depart)
        endif
        set TS_HeldVehicle = null
        set TS_HeldUsesPatrol = false
    endfunction

    public function HoldStopVehicle takes integer stopId returns nothing
        local integer routeId = 1

        call ReleaseHeldVehicle(false)
        loop
            exitwhen routeId > TS_RouteCount
            if TS_RouteStart[routeId] == stopId and TS_RouteScheduled[routeId] and TS_RouteAvailable[routeId] and TS_RouteVehicle[routeId] != null then
                set TS_HeldVehicle = TS_RouteVehicle[routeId]
                set TS_HeldUsesPatrol = TS_RouteUsesPatrol[routeId]
                if TS_HeldUsesPatrol then
                    call PatrolSystem_Pause(TS_HeldVehicle)
                endif
                return
            endif
            set routeId = routeId + 1
        endloop
    endfunction

    private function TS_RouteContainsStop takes integer routeId, integer stopId returns boolean
        local integer waypoint = 1

        loop
            exitwhen waypoint > TS_RouteWaypointCount[routeId]
            if TS_WaypointStop[TS_GetWaypointIndex(routeId, waypoint)] == stopId then
                return true
            endif
            set waypoint = waypoint + 1
        endloop
        return false
    endfunction

    public function NotifyScheduledStop takes unit vehicle, integer stopId returns nothing
        local integer routeId = 1

        if vehicle == null or not TS_IsValidStop(stopId) then
            return
        endif
        loop
            exitwhen routeId > TS_RouteCount
            if TS_RouteVehicle[routeId] == vehicle then
                set TS_RouteAvailable[routeId] = TS_RouteStart[routeId] == stopId
            endif
            set routeId = routeId + 1
        endloop
        if not TS_Active or TS_ActiveCarrier != vehicle then
            return
        endif
        if TS_PromptVisible or TS_StopPromptVisible then
            return
        endif
        set TS_LastSafeStop = stopId
        if TS_RouteEnd[TS_ActiveRoute] == stopId then
            call TS_FinishAtStop(stopId, false, false)
        elseif TS_RouteContainsStop(TS_ActiveRoute, stopId) then
            if TS_RouteUsesPatrol[TS_ActiveRoute] then
                call PatrolSystem_Pause(vehicle)
            endif
            call TS_ShowStopPrompt(stopId)
        endif
    endfunction

    public function NotifyScheduledLeave takes unit vehicle returns nothing
        local integer routeId = 1

        loop
            exitwhen routeId > TS_RouteCount
            if TS_RouteVehicle[routeId] == vehicle then
                set TS_RouteAvailable[routeId] = false
            endif
            set routeId = routeId + 1
        endloop
    endfunction

    private function TS_OnDiscoveryPeriod takes nothing returns nothing
        local integer stopId = 1

        call TS_RegisterSharedMasterEffects()
        loop
            exitwhen stopId > TS_StopCount
            if TS_StopDiscovered[stopId] and not TS_StopIconRegistered[stopId] then
                call TS_RegisterStopIcon(stopId)
            elseif TS_StopRequiresDiscovery[stopId] and not TS_StopDiscovered[stopId] then
                if (FallenHeroState_IsAlive(udg_Nazgrek) and TS_IsUnitNearMaster(udg_Nazgrek, stopId)) or (FallenHeroState_IsAlive(udg_Zulkis) and TS_IsUnitNearMaster(udg_Zulkis, stopId)) then
                    call DiscoverStop(stopId, true)
                endif
            endif
            set stopId = stopId + 1
        endloop
    endfunction

    private function InitDialogs takes nothing returns nothing
        set TS_SkipDialog = DialogSystem_CreateDialog("")
        set TS_SkipButton = DialogSystem_AddButton(TS_SkipDialog, "Skip travel", 1)
        set TS_SkipCancelButton = DialogSystem_AddButton(TS_SkipDialog, "Continue journey", 2)
        call DialogSystem_BindButtonCode(TS_SkipButton, function TS_OnSkipConfirmed)
        call DialogSystem_BindButtonCode(TS_SkipCancelButton, function TS_OnSkipCancelled)

        set TS_StopDialog = DialogSystem_CreateDialog("")
        set TS_DropButton = DialogSystem_AddButton(TS_StopDialog, "Drop out here", 1)
        set TS_ContinueButton = DialogSystem_AddButton(TS_StopDialog, "Continue journey", 2)
        call DialogSystem_BindButtonCode(TS_DropButton, function TS_OnDropOut)
        call DialogSystem_BindButtonCode(TS_ContinueButton, function TS_OnContinueStop)
    endfunction

    private function Init takes nothing returns nothing
        set TS_UpdateTimer = CreateTimer()
        set TS_DiscoveryTimer = CreateTimer()
        set TS_StopPromptTimer = CreateTimer()
        set TS_TransitionTimer = CreateTimer()
        set TS_TerrainLocation = Location(0.00, 0.00)
        call InitDialogs()
        call DialogInteraction_RegisterAnySelectionHandler(function TS_OnMasterSelected)
        call TimerStart(TS_DiscoveryTimer, TS_DISCOVERY_PERIOD, true, function TS_OnDiscoveryPeriod)
    endfunction
endlibrary
