/**
    TravelAI

    Author: Valdemar
    Version:

    Description:
    Physical wyvern and zeppelin travel provider for autonomous AI heroes. AI heroes walk
    to a nearby configured flight master, hide during the flight, follow the
    route waypoints on a visible carrier, and return at the destination.

    Credits:
    PotS AI random travel and the original wyvern travel triggers.

    How to install:
    Import after AI and TravelSystem. If no suitable physical route exists,
    AI keeps using its existing abstract timed-travel fallback.

    API:
    TravelAI registers itself through AI_RegisterTravelProvider. No manual
    runtime call is required.

**/
library TravelAI initializer Init requires AI, TravelSystem, TravelWyvern
    globals
        private constant integer TAI_MAX_SESSIONS = 16
        private constant integer TAI_CARRIER_TYPE = 'n602'
        private constant real TAI_UPDATE_PERIOD = 0.25
        private constant real TAI_APPROACH_CHECK_PERIOD = 1.00
        private constant real TAI_MASTER_SEARCH_RANGE = 3000.00
        private constant real TAI_BOARD_RANGE = 300.00
        private constant real TAI_APPROACH_TIMEOUT = 30.00
        private constant real TAI_FLIGHT_TIMEOUT = 180.00
        private constant real TAI_ARRIVAL_RANGE = 110.00
        private constant real TAI_FLY_HEIGHT = 500.00
        private constant real TAI_MOVE_SPEED = 400.00
        private constant real TAI_ASCENT_RATE = 50.00
        private constant real TAI_DESCENT_RATE = 50.00
        private constant real TAI_DESCENT_RANGE = 800.00
        private constant real TAI_LANDED_HEIGHT = 20.00
        private constant real TAI_MAX_DESCENT_DURATION = 12.00

        private unit array TAI_Hero
        private unit array TAI_Carrier
        private integer array TAI_Route
        private integer array TAI_Waypoint
        private integer array TAI_State
        private real array TAI_Elapsed
        private real array TAI_NextApproachCheck
        private boolean array TAI_Descending
        private real array TAI_DescentElapsed
        private timer TAI_UpdateTimer = null
        private boolean TAI_UpdateTimerActive = false
    endglobals

    private function TAI_GetFreeSession takes nothing returns integer
        local integer session = 1

        loop
            exitwhen session > TAI_MAX_SESSIONS
            if TAI_State[session] == 0 then
                return session
            endif
            set session = session + 1
        endloop
        return 0
    endfunction

    private function TAI_ClearSession takes integer session returns nothing
        set TAI_Hero[session] = null
        set TAI_Carrier[session] = null
        set TAI_Route[session] = 0
        set TAI_Waypoint[session] = 0
        set TAI_State[session] = 0
        set TAI_Elapsed[session] = 0.00
        set TAI_NextApproachCheck[session] = 0.00
        set TAI_Descending[session] = false
        set TAI_DescentElapsed[session] = 0.00
    endfunction

    private function TAI_GetTargetX takes integer session returns real
        local integer routeId = TAI_Route[session]
        local integer waypoint = TAI_Waypoint[session]

        if waypoint > 0 and waypoint <= TravelSystem_GetRouteWaypointCount(routeId) then
            return TravelSystem_GetRouteWaypointX(routeId, waypoint)
        endif
        return TravelSystem_GetStopX(TravelSystem_GetRouteEnd(routeId))
    endfunction

    private function TAI_GetTargetY takes integer session returns real
        local integer routeId = TAI_Route[session]
        local integer waypoint = TAI_Waypoint[session]

        if waypoint > 0 and waypoint <= TravelSystem_GetRouteWaypointCount(routeId) then
            return TravelSystem_GetRouteWaypointY(routeId, waypoint)
        endif
        return TravelSystem_GetStopY(TravelSystem_GetRouteEnd(routeId))
    endfunction

    private function TAI_IssueMove takes integer session returns nothing
        if TAI_Carrier[session] != null then
            call IssuePointOrder(TAI_Carrier[session], "move", TAI_GetTargetX(session), TAI_GetTargetY(session))
        endif
    endfunction

    private function TAI_EndAt takes integer session, real x, real y returns nothing
        local unit hero = TAI_Hero[session]
        local unit carrier = TAI_Carrier[session]

        if carrier != null then
            call RemoveUnit(carrier)
        endif
        if hero != null and GetUnitTypeId(hero) != 0 then
            call AI_EndExternalTravel(hero, x, y)
        endif
        call TAI_ClearSession(session)
        set hero = null
        set carrier = null
    endfunction

    private function TAI_CancelApproach takes integer session returns nothing
        local unit hero = TAI_Hero[session]

        if hero != null and GetUnitTypeId(hero) != 0 then
            call AI_EndExternalTravel(hero, GetUnitX(hero), GetUnitY(hero))
        endif
        call TAI_ClearSession(session)
        set hero = null
    endfunction

    private function TAI_BeginFlight takes integer session returns nothing
        local unit hero = TAI_Hero[session]
        local integer routeId = TAI_Route[session]
        local integer carrierType = TAI_CARRIER_TYPE
        local unit carrier
        local unit routeVehicle

        if hero == null or not AI_BeginExternalTravel(hero) then
            call TAI_CancelApproach(session)
            set routeVehicle = null
            set carrier = null
            set hero = null
            return
        endif
        if TravelSystem_GetRouteMethod(routeId) == TRAVEL_METHOD_ZEPPELIN then
            set routeVehicle = TravelSystem_GetRouteVehicle(routeId)
            if routeVehicle != null then
                set carrierType = GetUnitTypeId(routeVehicle)
            endif
        endif
        if carrierType == 0 then
            call TAI_CancelApproach(session)
            set routeVehicle = null
            set carrier = null
            set hero = null
            return
        endif
        set carrier = CreateUnit(GetOwningPlayer(hero), carrierType, GetUnitX(hero), GetUnitY(hero), 0.00)
        if carrier == null then
            call TAI_CancelApproach(session)
            set routeVehicle = null
            set carrier = null
            set hero = null
            return
        endif
        call UnitAddAbility(carrier, 'Aloc')
        call SetUnitPathing(carrier, false)
        call SetUnitInvulnerable(carrier, true)
        if TravelSystem_GetRouteMethod(routeId) == TRAVEL_METHOD_WYVERN then
            call SetUnitFlyHeight(carrier, 0.00, 0.00)
            call SetUnitFlyHeight(carrier, TAI_FLY_HEIGHT, TAI_ASCENT_RATE)
        else
            call SetUnitFlyHeight(carrier, TAI_FLY_HEIGHT, 0.00)
        endif
        call SetUnitMoveSpeed(carrier, TAI_MOVE_SPEED)
        call IssueImmediateOrder(hero, "stop")
        call PauseUnit(hero, true)
        call ShowUnit(hero, false)
        set TAI_Carrier[session] = carrier
        set TAI_State[session] = 2
        set TAI_Elapsed[session] = 0.00
        set TAI_Waypoint[session] = 1
        set TAI_DescentElapsed[session] = 0.00
        call TAI_IssueMove(session)
        set routeVehicle = null
        set carrier = null
        set hero = null
    endfunction

    private function TAI_UpdateApproach takes integer session returns nothing
        local unit hero = TAI_Hero[session]
        local unit master = TravelSystem_GetStopMaster(TravelSystem_GetRouteStart(TAI_Route[session]))
        local unit enemy
        local real dx
        local real dy

        if hero == null or master == null or not AI_IsAlive(hero) or GetUnitTypeId(master) == 0 then
            call TAI_CancelApproach(session)
            set hero = null
            set master = null
            set enemy = null
            return
        endif
        set enemy = AI_FindClosestEnemy(hero, 700.00)
        if enemy != null or TAI_Elapsed[session] >= TAI_APPROACH_TIMEOUT then
            call TAI_CancelApproach(session)
            set hero = null
            set master = null
            set enemy = null
            return
        endif
        set dx = GetUnitX(hero) - GetUnitX(master)
        set dy = GetUnitY(hero) - GetUnitY(master)
        if dx * dx + dy * dy <= TAI_BOARD_RANGE * TAI_BOARD_RANGE then
            call TAI_BeginFlight(session)
        elseif GetUnitCurrentOrder(hero) != OrderId("move") then
            call IssuePointOrder(hero, "move", GetUnitX(master), GetUnitY(master))
        endif
        set hero = null
        set master = null
        set enemy = null
    endfunction

    private function TAI_UpdateFlight takes integer session returns nothing
        local unit carrier = TAI_Carrier[session]
        local integer routeId = TAI_Route[session]
        local real targetX
        local real targetY
        local real dx
        local real dy
        local boolean finalWaypoint

        if carrier == null or GetUnitTypeId(carrier) == 0 then
            call TAI_EndAt(session, TravelSystem_GetStopX(TravelSystem_GetRouteEnd(routeId)), TravelSystem_GetStopY(TravelSystem_GetRouteEnd(routeId)))
            set carrier = null
            return
        endif
        set targetX = TAI_GetTargetX(session)
        set targetY = TAI_GetTargetY(session)
        set dx = GetUnitX(carrier) - targetX
        set dy = GetUnitY(carrier) - targetY
        set finalWaypoint = TravelSystem_GetRouteWaypointCount(routeId) <= 0 or TAI_Waypoint[session] >= TravelSystem_GetRouteWaypointCount(routeId)
        if finalWaypoint and TravelSystem_GetRouteMethod(routeId) == TRAVEL_METHOD_WYVERN and not TAI_Descending[session] and dx * dx + dy * dy <= TAI_DESCENT_RANGE * TAI_DESCENT_RANGE then
            set TAI_Descending[session] = true
            set TAI_DescentElapsed[session] = 0.00
            call SetUnitFlyHeight(carrier, 0.00, TAI_DESCENT_RATE)
        endif
        if TAI_Descending[session] then
            set TAI_DescentElapsed[session] = TAI_DescentElapsed[session] + TAI_UPDATE_PERIOD
        endif
        if dx * dx + dy * dy <= TAI_ARRIVAL_RANGE * TAI_ARRIVAL_RANGE then
            if finalWaypoint then
                if not TAI_Descending[session] or GetUnitFlyHeight(carrier) <= TAI_LANDED_HEIGHT or TAI_DescentElapsed[session] >= TAI_MAX_DESCENT_DURATION then
                    call SetUnitFlyHeight(carrier, 0.00, 0.00)
                    call TAI_EndAt(session, TravelSystem_GetStopX(TravelSystem_GetRouteEnd(routeId)), TravelSystem_GetStopY(TravelSystem_GetRouteEnd(routeId)))
                endif
            else
                set TAI_Waypoint[session] = TAI_Waypoint[session] + 1
                call TAI_IssueMove(session)
            endif
        elseif TAI_Elapsed[session] >= TAI_FLIGHT_TIMEOUT then
            call TAI_EndAt(session, TravelSystem_GetStopX(TravelSystem_GetRouteEnd(routeId)), TravelSystem_GetStopY(TravelSystem_GetRouteEnd(routeId)))
        endif
        set carrier = null
    endfunction

    private function TAI_OnUpdate takes nothing returns nothing
        local integer session = 1
        local boolean hasActiveSession = false

        loop
            exitwhen session > TAI_MAX_SESSIONS
            if TAI_State[session] != 0 then
                set TAI_Elapsed[session] = TAI_Elapsed[session] + TAI_UPDATE_PERIOD
                if TAI_State[session] == 1 then
                    if TAI_Elapsed[session] >= TAI_NextApproachCheck[session] then
                        set TAI_NextApproachCheck[session] = TAI_Elapsed[session] + TAI_APPROACH_CHECK_PERIOD
                        call TAI_UpdateApproach(session)
                    endif
                elseif TAI_State[session] == 2 then
                    call TAI_UpdateFlight(session)
                endif
            endif
            if TAI_State[session] != 0 then
                set hasActiveSession = true
            endif
            set session = session + 1
        endloop
        if not hasActiveSession then
            set TAI_UpdateTimerActive = false
            call PauseTimer(TAI_UpdateTimer)
        endif
    endfunction

    private function TAI_StartUpdateTimer takes nothing returns nothing
        if not TAI_UpdateTimerActive then
            set TAI_UpdateTimerActive = true
            call TimerStart(TAI_UpdateTimer, TAI_UPDATE_PERIOD, true, function TAI_OnUpdate)
        endif
    endfunction

    private function TAI_FindRoute takes unit hero returns integer
        local integer routeId = 1
        local integer selected = 0
        local integer seen = 0
        local integer startStop
        local integer endStop
        local unit startMaster
        local unit endMaster
        local real dx
        local real dy

        loop
            exitwhen routeId > TravelSystem_GetRouteCount()
            // AI intentionally ignores player discovery and sees every flight point.
            if TravelSystem_IsRouteEnabled(routeId) and (TravelSystem_GetRouteMethod(routeId) == TRAVEL_METHOD_WYVERN or TravelSystem_GetRouteMethod(routeId) == TRAVEL_METHOD_ZEPPELIN) then
                set startStop = TravelSystem_GetRouteStart(routeId)
                set endStop = TravelSystem_GetRouteEnd(routeId)
                set startMaster = TravelSystem_GetStopMaster(startStop)
                set endMaster = TravelSystem_GetStopMaster(endStop)
                if startMaster != null and endMaster != null and GetUnitTypeId(startMaster) != 0 and GetUnitTypeId(endMaster) != 0 then
                    set dx = GetUnitX(hero) - GetUnitX(startMaster)
                    set dy = GetUnitY(hero) - GetUnitY(startMaster)
                    if dx * dx + dy * dy <= TAI_MASTER_SEARCH_RANGE * TAI_MASTER_SEARCH_RANGE then
                        set seen = seen + 1
                        if GetRandomInt(1, seen) == 1 then
                            set selected = routeId
                        endif
                    endif
                endif
            endif
            set routeId = routeId + 1
        endloop
        set startMaster = null
        set endMaster = null
        return selected
    endfunction

    private function TAI_OnTravelRequest takes nothing returns nothing
        local unit hero = AI_GetTravelRequestUnit()
        local unit enemy
        local unit master
        local integer session
        local integer routeId

        if hero == null or not AI_IsAlive(hero) then
            set hero = null
            set enemy = null
            set master = null
            return
        endif
        set enemy = AI_FindClosestEnemy(hero, 900.00)
        if enemy != null then
            set hero = null
            set enemy = null
            set master = null
            return
        endif
        set session = TAI_GetFreeSession()
        set routeId = TAI_FindRoute(hero)
        if session <= 0 or routeId <= 0 or not AI_BeginExternalTravelApproach(hero) then
            set hero = null
            set enemy = null
            set master = null
            return
        endif
        set TAI_Hero[session] = hero
        set TAI_Route[session] = routeId
        set TAI_State[session] = 1
        set TAI_Elapsed[session] = 0.00
        set TAI_NextApproachCheck[session] = TAI_APPROACH_CHECK_PERIOD
        set master = TravelSystem_GetStopMaster(TravelSystem_GetRouteStart(routeId))
        call IssuePointOrder(hero, "move", GetUnitX(master), GetUnitY(master))
        call TAI_StartUpdateTimer()
        call AI_MarkTravelRequestHandled()
        set hero = null
        set enemy = null
        set master = null
    endfunction

    private function Init takes nothing returns nothing
        set TAI_UpdateTimer = CreateTimer()
        call AI_RegisterTravelProvider(function TAI_OnTravelRequest)
    endfunction
endlibrary
