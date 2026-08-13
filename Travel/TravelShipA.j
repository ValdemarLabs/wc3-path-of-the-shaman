/**
    TravelShipA

    Author: Valdemar
    Version:

    Description:
    Configurable neutral-ship binding layer. No route is exposed until placed
    masters, stops, vehicle, fares, and path data are registered by the map.

    Credits:
    The original PotS travel design.

    How to install:
    Import after TravelSystem. Register stops and directed routes after the
    neutral travel ship and its Object Editor references are available.

    API:
    - set stopId = TravelShipA_RegisterStop(...)
    - set stopId = TravelShipA_RegisterStopEx(...)
    - set routeId = TravelShipA_RegisterDirectRoute(...)
    - set routeId = TravelShipA_RegisterScheduledRoute(...)
    - call TravelShipA_AddWaypoint(...)

**/
library TravelShipA requires TravelSystem, TravelUI
    globals
        private constant integer TSA_SKIP_FEE = 100
    endglobals

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
endlibrary
