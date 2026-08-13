/**
    TravelZeppelin

    Author: Valdemar
    Version:

    Description:
    Binding layer for the Sirensong Forest and Sereneglade zeppelin route.
    The route stays disabled until its placed vehicle, both masters, boarding
    areas, and arrival points are supplied.

    Credits:
    The original PotS travel design.

    How to install:
    Import after TravelSystem. Call TravelZeppelin_Bind after map globals are
    available, or use the station and route wrappers for a custom waypoint path.

    API:
    - set success = TravelZeppelin_Bind(...)
    - set stopId = TravelZeppelin_RegisterStation(...)
    - set routeId = TravelZeppelin_RegisterDirectedRoute(...)
    - call TravelZeppelin_AddWaypoint(...)

**/
library TravelZeppelin requires TravelSystem, TravelUI
    globals
        private constant integer TZ_ZONE_SERENGLADE = 2
        private constant integer TZ_ZONE_SIRENSONG = 14
        private constant integer TZ_SKIP_FEE = 100

        private integer TZ_SirensongStop = 0
        private integer TZ_SerenegladeStop = 0
        private integer TZ_ToSerenegladeRoute = 0
        private integer TZ_ToSirensongRoute = 0
        private boolean TZ_Bound = false
    endglobals

    public function RegisterStation takes string name, integer zoneId, unit master, rect boardingArea, real dropX, real dropY returns integer
        if master == null or boardingArea == null then
            return 0
        endif
        return TravelSystem_RegisterStop(TRAVEL_METHOD_ZEPPELIN, name, zoneId, master, boardingArea, dropX, dropY, true)
    endfunction

    public function RegisterDirectedRoute takes integer startStop, integer endStop, integer fare, unit zeppelin returns integer
        local integer routeId

        if zeppelin == null then
            return 0
        endif
        set routeId = TravelSystem_RegisterRoute(TRAVEL_METHOD_ZEPPELIN, startStop, endStop, fare, TZ_SKIP_FEE)
        if routeId > 0 then
            call TravelSystem_SetRouteDiscoveryRequirements(routeId, true, true)
            call TravelSystem_SetRouteShowPassengers(routeId, false)
            call TravelSystem_SetRouteVehicle(routeId, zeppelin, false, false)
        endif
        return routeId
    endfunction

    public function AddWaypoint takes integer routeId, real x, real y returns boolean
        return TravelSystem_AddWaypoint(routeId, x, y, 0)
    endfunction

    public function GetSirensongStop takes nothing returns integer
        return TZ_SirensongStop
    endfunction

    public function GetSerenegladeStop takes nothing returns integer
        return TZ_SerenegladeStop
    endfunction

    public function GetToSerenegladeRoute takes nothing returns integer
        return TZ_ToSerenegladeRoute
    endfunction

    public function GetToSirensongRoute takes nothing returns integer
        return TZ_ToSirensongRoute
    endfunction

    public function Bind takes unit zeppelin, unit sirensongMaster, rect sirensongArea, real sirensongX, real sirensongY, unit serenegladeMaster, rect serenegladeArea, real serenegladeX, real serenegladeY, integer fareToSereneglade, integer fareToSirensong returns boolean
        if TZ_Bound or zeppelin == null or sirensongMaster == null or sirensongArea == null or serenegladeMaster == null or serenegladeArea == null then
            return false
        endif
        set TZ_SirensongStop = RegisterStation("Sirensong Forest", TZ_ZONE_SIRENSONG, sirensongMaster, sirensongArea, sirensongX, sirensongY)
        set TZ_SerenegladeStop = RegisterStation("Sereneglade", TZ_ZONE_SERENGLADE, serenegladeMaster, serenegladeArea, serenegladeX, serenegladeY)
        if TZ_SirensongStop <= 0 or TZ_SerenegladeStop <= 0 then
            return false
        endif
        set TZ_ToSerenegladeRoute = RegisterDirectedRoute(TZ_SirensongStop, TZ_SerenegladeStop, fareToSereneglade, zeppelin)
        set TZ_ToSirensongRoute = RegisterDirectedRoute(TZ_SerenegladeStop, TZ_SirensongStop, fareToSirensong, zeppelin)
        if TZ_ToSerenegladeRoute <= 0 or TZ_ToSirensongRoute <= 0 then
            return false
        endif
        call AddWaypoint(TZ_ToSerenegladeRoute, serenegladeX, serenegladeY)
        call AddWaypoint(TZ_ToSirensongRoute, sirensongX, sirensongY)
        set TZ_Bound = true
        return true
    endfunction
endlibrary
