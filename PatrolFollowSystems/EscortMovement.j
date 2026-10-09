/**
    EscortMovement

    Author: Valdemar
    Version: 1.0.1

    Description:
    Moves an escorted unit toward a destination while requiring its assigned
    leader to remain nearby. Routes use Warcraft pathing automatically and may
    include an ordered waypoint list for roads or other difficult paths.

    Credits:

    How to install:
    Import after Table, SpeciFX, IconQuery, and FallenHeroState. Import before
    quest libraries that configure autonomous escort routes.

    API:
    - EscortMovement_Begin prepares an escort and its leader.
    - EscortMovement_AddWaypoint appends an optional route point.
    - EscortMovement_Start sets the final destination and begins movement.
    - EscortMovement_UpdateDestination moves a dynamic final destination.
    - EscortMovement_Stop removes an escort and cleans its route indicators.
    - EscortMovement_IsActive/IsPaused/HasArrived expose route state.

**/
library EscortMovement initializer Init requires Table, SpeciFX, IconQuery, FallenHeroState
    globals
        private constant integer EM_MAX_ACTIVE_ROUTES = 32
        private constant integer EM_MAX_WAYPOINTS = 128
        private constant real EM_UPDATE_INTERVAL = 0.50
        private constant real EM_DEFAULT_LEADER_RANGE = 2400.00
        private constant real EM_DEFAULT_POINT_RADIUS = 160.00
        private constant integer EM_ORDER_REISSUE_TICKS = 4
        private constant integer EM_PING_TICKS = 10
        private constant string EM_STOPPED_EFFECT_PATH = "war3mapImported\\QuestMarking.mdl"
        private constant string EM_STOPPED_EFFECT_ATTACH = "origin"

        private timer EM_UpdateTimer = null
        private Table EM_SlotByUnit = 0
        private boolean array EM_Active
        private unit array EM_Escort
        private unit array EM_Leader
        private minimapicon array EM_MapIcon
        private effect array EM_StoppedEffect
        private real array EM_LeaderRange
        private real array EM_DestinationX
        private real array EM_DestinationY
        private real array EM_DestinationRadius
        private integer array EM_WaypointCount
        private integer array EM_CurrentWaypoint
        private real array EM_WaypointX
        private real array EM_WaypointY
        private real array EM_WaypointRadius
        private boolean array EM_Started
        private boolean array EM_Paused
        private boolean array EM_Arrived
        private integer array EM_OrderTicks
        private integer array EM_PingTicks
    endglobals

    private function EM_GetWaypointSlot takes integer routeSlot, integer waypointIndex returns integer
        return routeSlot*EM_MAX_WAYPOINTS + waypointIndex
    endfunction

    private function EM_IsUnitValid takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and FallenHeroState_IsAlive(whichUnit)
    endfunction

    private function EM_DestroyStoppedEffect takes integer routeSlot returns nothing
        if EM_StoppedEffect[routeSlot] != null then
            call DestroyEffect(EM_StoppedEffect[routeSlot])
            set EM_StoppedEffect[routeSlot] = null
        endif
    endfunction

    private function EM_ShowStoppedEffect takes integer routeSlot returns nothing
        if EM_StoppedEffect[routeSlot] == null and EM_Escort[routeSlot] != null then
            set EM_StoppedEffect[routeSlot] = AddSpecialEffectTarget(EM_STOPPED_EFFECT_PATH, EM_Escort[routeSlot], EM_STOPPED_EFFECT_ATTACH)
            if EM_StoppedEffect[routeSlot] != null then
                call SpeciFX_MarkAsExcluded(EM_StoppedEffect[routeSlot])
            endif
        endif
    endfunction

    private function EM_ClearSlot takes integer routeSlot returns nothing
        local integer unitId

        if routeSlot <= 0 or routeSlot > EM_MAX_ACTIVE_ROUTES or not EM_Active[routeSlot] then
            return
        endif
        if EM_Escort[routeSlot] != null then
            set unitId = GetHandleId(EM_Escort[routeSlot])
            if EM_SlotByUnit.integer[unitId] == routeSlot then
                call EM_SlotByUnit.integer.remove(unitId)
            endif
        endif
        if EM_MapIcon[routeSlot] != null then
            call IconQuery_UnregisterIcon(EM_MapIcon[routeSlot])
            set EM_MapIcon[routeSlot] = null
        endif
        call EM_DestroyStoppedEffect(routeSlot)
        set EM_Active[routeSlot] = false
        set EM_Escort[routeSlot] = null
        set EM_Leader[routeSlot] = null
        set EM_LeaderRange[routeSlot] = 0.00
        set EM_DestinationX[routeSlot] = 0.00
        set EM_DestinationY[routeSlot] = 0.00
        set EM_DestinationRadius[routeSlot] = 0.00
        set EM_WaypointCount[routeSlot] = 0
        set EM_CurrentWaypoint[routeSlot] = 0
        set EM_Started[routeSlot] = false
        set EM_Paused[routeSlot] = false
        set EM_Arrived[routeSlot] = false
        set EM_OrderTicks[routeSlot] = 0
        set EM_PingTicks[routeSlot] = 0
    endfunction

    private function EM_GetFreeSlot takes nothing returns integer
        local integer routeSlot = 1

        loop
            exitwhen routeSlot > EM_MAX_ACTIVE_ROUTES or not EM_Active[routeSlot]
            set routeSlot = routeSlot + 1
        endloop
        if routeSlot > EM_MAX_ACTIVE_ROUTES then
            return 0
        endif
        return routeSlot
    endfunction

    private function EM_GetCurrentX takes integer routeSlot returns real
        local integer waypointIndex = EM_CurrentWaypoint[routeSlot]

        if waypointIndex > 0 and waypointIndex <= EM_WaypointCount[routeSlot] then
            return EM_WaypointX[EM_GetWaypointSlot(routeSlot, waypointIndex)]
        endif
        return EM_DestinationX[routeSlot]
    endfunction

    private function EM_GetCurrentY takes integer routeSlot returns real
        local integer waypointIndex = EM_CurrentWaypoint[routeSlot]

        if waypointIndex > 0 and waypointIndex <= EM_WaypointCount[routeSlot] then
            return EM_WaypointY[EM_GetWaypointSlot(routeSlot, waypointIndex)]
        endif
        return EM_DestinationY[routeSlot]
    endfunction

    private function EM_GetCurrentRadius takes integer routeSlot returns real
        local integer waypointIndex = EM_CurrentWaypoint[routeSlot]

        if waypointIndex > 0 and waypointIndex <= EM_WaypointCount[routeSlot] then
            return EM_WaypointRadius[EM_GetWaypointSlot(routeSlot, waypointIndex)]
        endif
        return EM_DestinationRadius[routeSlot]
    endfunction

    private function EM_IssueCurrentOrder takes integer routeSlot returns nothing
        if EM_Active[routeSlot] and EM_Started[routeSlot] and not EM_Paused[routeSlot] and not EM_Arrived[routeSlot] then
            call IssuePointOrderById(EM_Escort[routeSlot], OrderId("move"), EM_GetCurrentX(routeSlot), EM_GetCurrentY(routeSlot))
            set EM_OrderTicks[routeSlot] = 0
        endif
    endfunction

    private function EM_PingStoppedEscort takes integer routeSlot returns nothing
        local location pingPoint = Location(GetUnitX(EM_Escort[routeSlot]), GetUnitY(EM_Escort[routeSlot]))

        call PingMinimapLocForForceEx(GetPlayersAll(), pingPoint, 1.00, bj_MINIMAPPINGSTYLE_SIMPLE, 255, 255, 0)
        call RemoveLocation(pingPoint)
        set pingPoint = null
    endfunction

    private function EM_UpdateSlot takes integer routeSlot returns nothing
        local real dx
        local real dy
        local real radius

        if not EM_IsUnitValid(EM_Escort[routeSlot]) or not EM_IsUnitValid(EM_Leader[routeSlot]) then
            call EM_ClearSlot(routeSlot)
            return
        endif
        set dx = GetUnitX(EM_Leader[routeSlot]) - GetUnitX(EM_Escort[routeSlot])
        set dy = GetUnitY(EM_Leader[routeSlot]) - GetUnitY(EM_Escort[routeSlot])
        if dx*dx + dy*dy > EM_LeaderRange[routeSlot]*EM_LeaderRange[routeSlot] then
            if not EM_Paused[routeSlot] then
                set EM_Paused[routeSlot] = true
                set EM_PingTicks[routeSlot] = 0
                call IssueImmediateOrder(EM_Escort[routeSlot], "stop")
                call EM_ShowStoppedEffect(routeSlot)
            elseif GetUnitCurrentOrder(EM_Escort[routeSlot]) != OrderId("stop") then
                call IssueImmediateOrder(EM_Escort[routeSlot], "stop")
            endif
            set EM_PingTicks[routeSlot] = EM_PingTicks[routeSlot] + 1
            if EM_PingTicks[routeSlot] >= EM_PING_TICKS then
                call EM_PingStoppedEscort(routeSlot)
                set EM_PingTicks[routeSlot] = 0
            endif
            return
        endif
        if EM_Paused[routeSlot] then
            set EM_Paused[routeSlot] = false
            set EM_PingTicks[routeSlot] = 0
            call EM_DestroyStoppedEffect(routeSlot)
            call EM_IssueCurrentOrder(routeSlot)
        endif
        if not EM_Started[routeSlot] or EM_Arrived[routeSlot] then
            return
        endif

        set dx = EM_GetCurrentX(routeSlot) - GetUnitX(EM_Escort[routeSlot])
        set dy = EM_GetCurrentY(routeSlot) - GetUnitY(EM_Escort[routeSlot])
        set radius = EM_GetCurrentRadius(routeSlot)
        if dx*dx + dy*dy <= radius*radius then
            if EM_CurrentWaypoint[routeSlot] <= EM_WaypointCount[routeSlot] then
                set EM_CurrentWaypoint[routeSlot] = EM_CurrentWaypoint[routeSlot] + 1
                call EM_IssueCurrentOrder(routeSlot)
            else
                set EM_Arrived[routeSlot] = true
                call IssueImmediateOrder(EM_Escort[routeSlot], "stop")
            endif
        else
            set EM_OrderTicks[routeSlot] = EM_OrderTicks[routeSlot] + 1
            if GetUnitCurrentOrder(EM_Escort[routeSlot]) != OrderId("move") or EM_OrderTicks[routeSlot] >= EM_ORDER_REISSUE_TICKS then
                call EM_IssueCurrentOrder(routeSlot)
            endif
        endif
    endfunction

    private function EM_OnUpdate takes nothing returns nothing
        local integer routeSlot = 1

        loop
            exitwhen routeSlot > EM_MAX_ACTIVE_ROUTES
            if EM_Active[routeSlot] then
                call EM_UpdateSlot(routeSlot)
            endif
            set routeSlot = routeSlot + 1
        endloop
    endfunction

    public function Begin takes unit escortUnit, unit leader, real leaderRange returns nothing
        local integer routeSlot
        local integer oldSlot

        if not EM_IsUnitValid(escortUnit) or not EM_IsUnitValid(leader) or escortUnit == leader then
            set escortUnit = null
            set leader = null
            return
        endif
        set oldSlot = EM_SlotByUnit.integer[GetHandleId(escortUnit)]
        if oldSlot > 0 then
            call EM_ClearSlot(oldSlot)
        endif
        set routeSlot = EM_GetFreeSlot()
        if routeSlot <= 0 then
            set escortUnit = null
            set leader = null
            return
        endif
        if leaderRange <= 0.00 then
            set leaderRange = EM_DEFAULT_LEADER_RANGE
        endif
        set EM_Active[routeSlot] = true
        set EM_Escort[routeSlot] = escortUnit
        set EM_Leader[routeSlot] = leader
        set EM_LeaderRange[routeSlot] = leaderRange
        set EM_SlotByUnit.integer[GetHandleId(escortUnit)] = routeSlot
        set EM_MapIcon[routeSlot] = IconQuery_RegisterCompanionFollowerUnitIcon(escortUnit)
        set escortUnit = null
        set leader = null
    endfunction

    public function AddWaypoint takes unit escortUnit, real x, real y, real radius returns boolean
        local integer routeSlot
        local integer waypointIndex

        if escortUnit == null then
            set escortUnit = null
            return false
        endif
        set routeSlot = EM_SlotByUnit.integer[GetHandleId(escortUnit)]
        if routeSlot <= 0 or not EM_Active[routeSlot] or EM_WaypointCount[routeSlot] >= EM_MAX_WAYPOINTS then
            set escortUnit = null
            return false
        endif
        if radius <= 0.00 then
            set radius = EM_DEFAULT_POINT_RADIUS
        endif
        set waypointIndex = EM_WaypointCount[routeSlot] + 1
        set EM_WaypointCount[routeSlot] = waypointIndex
        set EM_WaypointX[EM_GetWaypointSlot(routeSlot, waypointIndex)] = x
        set EM_WaypointY[EM_GetWaypointSlot(routeSlot, waypointIndex)] = y
        set EM_WaypointRadius[EM_GetWaypointSlot(routeSlot, waypointIndex)] = radius
        set escortUnit = null
        return true
    endfunction

    public function Start takes unit escortUnit, real destinationX, real destinationY, real arrivalRadius returns nothing
        local integer routeSlot
        local real dx
        local real dy

        if escortUnit == null then
            set escortUnit = null
            return
        endif
        set routeSlot = EM_SlotByUnit.integer[GetHandleId(escortUnit)]
        if routeSlot <= 0 or not EM_Active[routeSlot] then
            set escortUnit = null
            return
        endif
        if arrivalRadius <= 0.00 then
            set arrivalRadius = EM_DEFAULT_POINT_RADIUS
        endif
        set EM_DestinationX[routeSlot] = destinationX
        set EM_DestinationY[routeSlot] = destinationY
        set EM_DestinationRadius[routeSlot] = arrivalRadius
        set EM_CurrentWaypoint[routeSlot] = 1
        set EM_Started[routeSlot] = true
        set EM_Paused[routeSlot] = false
        set EM_Arrived[routeSlot] = false
        set EM_OrderTicks[routeSlot] = 0
        set EM_PingTicks[routeSlot] = 0
        call EM_DestroyStoppedEffect(routeSlot)
        set dx = GetUnitX(EM_Leader[routeSlot]) - GetUnitX(EM_Escort[routeSlot])
        set dy = GetUnitY(EM_Leader[routeSlot]) - GetUnitY(EM_Escort[routeSlot])
        if dx*dx + dy*dy > EM_LeaderRange[routeSlot]*EM_LeaderRange[routeSlot] then
            set EM_Paused[routeSlot] = true
            call IssueImmediateOrder(EM_Escort[routeSlot], "stop")
            call EM_ShowStoppedEffect(routeSlot)
        else
            call EM_IssueCurrentOrder(routeSlot)
        endif
        set escortUnit = null
    endfunction

    public function UpdateDestination takes unit escortUnit, real destinationX, real destinationY returns nothing
        local integer routeSlot
        local real dx
        local real dy

        if escortUnit == null then
            set escortUnit = null
            return
        endif
        set routeSlot = EM_SlotByUnit.integer[GetHandleId(escortUnit)]
        if routeSlot > 0 and EM_Active[routeSlot] then
            set EM_DestinationX[routeSlot] = destinationX
            set EM_DestinationY[routeSlot] = destinationY
            if EM_Arrived[routeSlot] then
                set dx = destinationX - GetUnitX(EM_Escort[routeSlot])
                set dy = destinationY - GetUnitY(EM_Escort[routeSlot])
                if dx*dx + dy*dy > EM_DestinationRadius[routeSlot]*EM_DestinationRadius[routeSlot] then
                    set EM_Arrived[routeSlot] = false
                    call EM_IssueCurrentOrder(routeSlot)
                endif
            endif
        endif
        set escortUnit = null
    endfunction

    public function Stop takes unit escortUnit returns nothing
        local integer routeSlot

        if escortUnit == null then
            set escortUnit = null
            return
        endif
        set routeSlot = EM_SlotByUnit.integer[GetHandleId(escortUnit)]
        if routeSlot > 0 then
            call IssueImmediateOrder(escortUnit, "stop")
            call EM_ClearSlot(routeSlot)
        endif
        set escortUnit = null
    endfunction

    public function IsActive takes unit escortUnit returns boolean
        local integer routeSlot

        if escortUnit == null then
            set escortUnit = null
            return false
        endif
        set routeSlot = EM_SlotByUnit.integer[GetHandleId(escortUnit)]
        set escortUnit = null
        return routeSlot > 0 and EM_Active[routeSlot]
    endfunction

    public function IsPaused takes unit escortUnit returns boolean
        local integer routeSlot

        if escortUnit == null then
            set escortUnit = null
            return false
        endif
        set routeSlot = EM_SlotByUnit.integer[GetHandleId(escortUnit)]
        set escortUnit = null
        return routeSlot > 0 and EM_Active[routeSlot] and EM_Paused[routeSlot]
    endfunction

    public function HasArrived takes unit escortUnit returns boolean
        local integer routeSlot

        if escortUnit == null then
            set escortUnit = null
            return false
        endif
        set routeSlot = EM_SlotByUnit.integer[GetHandleId(escortUnit)]
        set escortUnit = null
        return routeSlot > 0 and EM_Active[routeSlot] and EM_Arrived[routeSlot]
    endfunction

    private function Init takes nothing returns nothing
        set EM_SlotByUnit = Table.create()
        set EM_UpdateTimer = CreateTimer()
        call TimerStart(EM_UpdateTimer, EM_UPDATE_INTERVAL, true, function EM_OnUpdate)
    endfunction
endlibrary
