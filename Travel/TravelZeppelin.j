/**
    TravelZeppelin

    Author: Valdemar
    Version:

    Description:
    Registers the Sereneglade-Sirensong zeppelin service from the shared
    TravelSystem bindings and its two World Editor boarding areas.

    Credits:
    The original PotS travel design.

    How to install:
    Import after TravelSystem and TravelUI. Assign FlightMaster[1..2] and
    ZeppelinA/ZeppelinB in Init Travel Units, and keep ZeppelinSerenegladeArea and
    ZeppelinSirensongArea in the Region Palette.

    API:
    - set success = TravelZeppelin_Bind(...)
    - set success = TravelZeppelin_BindTwoWay(...)
    - set success = TravelZeppelin_BindShared()
    - TravelZeppelin_IsBound()
    - set stopId = TravelZeppelin_RegisterStation(...)
    - set routeId = TravelZeppelin_RegisterDirectedRoute(...)
    - call TravelZeppelin_AddWaypoint(...)

**/
library TravelZeppelin initializer Init requires TravelSystem, TravelUI
    globals
        private constant integer TZ_ZONE_SERENEGLADE = 2
        private constant integer TZ_ZONE_SIRENSONG = 14
        private constant integer TZ_SKIP_FEE = 100
        // Configure fares here until final zeppelin pricing is known.
        private constant integer TZ_FARE_TO_SERENEGLADE = 0
        private constant integer TZ_FARE_TO_SIRENSONG = 0

        private integer TZ_SirensongStop = 0
        private integer TZ_SerenegladeStop = 0
        private integer TZ_ToSerenegladeRoute = 0
        private integer TZ_ToSirensongRoute = 0
        private timer TZ_InitTimer = null
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

    public function IsBound takes nothing returns boolean
        return TZ_Bound
    endfunction

    public function BindTwoWay takes unit serenegladeZeppelin, unit sirensongZeppelin, unit sirensongMaster, rect sirensongArea, real sirensongX, real sirensongY, unit serenegladeMaster, rect serenegladeArea, real serenegladeX, real serenegladeY, integer fareToSereneglade, integer fareToSirensong returns boolean
        if TZ_Bound or serenegladeZeppelin == null or sirensongZeppelin == null or sirensongMaster == null or sirensongArea == null or serenegladeMaster == null or serenegladeArea == null then
            return false
        endif
        set TZ_SirensongStop = RegisterStation("Sirensong Forest", TZ_ZONE_SIRENSONG, sirensongMaster, sirensongArea, sirensongX, sirensongY)
        set TZ_SerenegladeStop = RegisterStation("Sereneglade", TZ_ZONE_SERENEGLADE, serenegladeMaster, serenegladeArea, serenegladeX, serenegladeY)
        if TZ_SirensongStop <= 0 or TZ_SerenegladeStop <= 0 then
            return false
        endif
        set TZ_ToSerenegladeRoute = RegisterDirectedRoute(TZ_SirensongStop, TZ_SerenegladeStop, fareToSereneglade, sirensongZeppelin)
        set TZ_ToSirensongRoute = RegisterDirectedRoute(TZ_SerenegladeStop, TZ_SirensongStop, fareToSirensong, serenegladeZeppelin)
        if TZ_ToSerenegladeRoute <= 0 or TZ_ToSirensongRoute <= 0 then
            return false
        endif
        call AddWaypoint(TZ_ToSerenegladeRoute, serenegladeX, serenegladeY)
        call AddWaypoint(TZ_ToSirensongRoute, sirensongX, sirensongY)
        set TZ_Bound = true
        return true
    endfunction

    public function Bind takes unit zeppelin, unit sirensongMaster, rect sirensongArea, real sirensongX, real sirensongY, unit serenegladeMaster, rect serenegladeArea, real serenegladeX, real serenegladeY, integer fareToSereneglade, integer fareToSirensong returns boolean
        return BindTwoWay(zeppelin, zeppelin, sirensongMaster, sirensongArea, sirensongX, sirensongY, serenegladeMaster, serenegladeArea, serenegladeX, serenegladeY, fareToSereneglade, fareToSirensong)
    endfunction

    public function BindShared takes nothing returns boolean
        local unit serenegladeZeppelin = TravelSystem_GetZeppelin(TRAVEL_ZEPPELIN_SERENEGLADE)
        local unit sirensongZeppelin = TravelSystem_GetZeppelin(TRAVEL_ZEPPELIN_SIRENSONG)
        local unit sirensongMaster = TravelSystem_GetFlightMaster(TRAVEL_FLIGHT_MASTER_SIRENSONG)
        local unit serenegladeMaster = TravelSystem_GetFlightMaster(TRAVEL_FLIGHT_MASTER_SERENEGLADE)
        local boolean success = BindTwoWay(serenegladeZeppelin, sirensongZeppelin, sirensongMaster, gg_rct_ZeppelinSirensongArea, GetRectCenterX(gg_rct_ZeppelinSirensongArea), GetRectCenterY(gg_rct_ZeppelinSirensongArea), serenegladeMaster, gg_rct_ZeppelinSerenegladeArea, GetRectCenterX(gg_rct_ZeppelinSerenegladeArea), GetRectCenterY(gg_rct_ZeppelinSerenegladeArea), TZ_FARE_TO_SERENEGLADE, TZ_FARE_TO_SIRENSONG)

        set serenegladeZeppelin = null
        set sirensongZeppelin = null
        set sirensongMaster = null
        set serenegladeMaster = null
        return success
    endfunction

    private function TZ_StopInitTimer takes nothing returns nothing
        call PauseTimer(TZ_InitTimer)
        call DestroyTimer(TZ_InitTimer)
        set TZ_InitTimer = null
    endfunction

    private function TZ_TryInitialize takes nothing returns nothing
        local unit serenegladeZeppelin = TravelSystem_GetZeppelin(TRAVEL_ZEPPELIN_SERENEGLADE)
        local unit sirensongZeppelin = TravelSystem_GetZeppelin(TRAVEL_ZEPPELIN_SIRENSONG)
        local unit serenegladeMaster = TravelSystem_GetFlightMaster(TRAVEL_FLIGHT_MASTER_SERENEGLADE)
        local unit sirensongMaster = TravelSystem_GetFlightMaster(TRAVEL_FLIGHT_MASTER_SIRENSONG)

        if TZ_Bound then
            call TZ_StopInitTimer()
        elseif serenegladeZeppelin == null or sirensongZeppelin == null or serenegladeMaster == null or sirensongMaster == null then
            call TimerStart(TZ_InitTimer, 1.00, false, function TZ_TryInitialize)
        else
            call BindShared()
            call TZ_StopInitTimer()
        endif
        set serenegladeZeppelin = null
        set sirensongZeppelin = null
        set serenegladeMaster = null
        set sirensongMaster = null
    endfunction

    private function Init takes nothing returns nothing
        set TZ_InitTimer = CreateTimer()
        call TimerStart(TZ_InitTimer, 0.10, false, function TZ_TryInitialize)
    endfunction
endlibrary
