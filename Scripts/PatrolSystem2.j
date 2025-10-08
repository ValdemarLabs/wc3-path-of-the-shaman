library PatrolSystem initializer Init requires Table, TimerUtils
//===========================================================================
// PatrolSystem - Briebe Table + TimerUtils Version
//===========================================================================

globals
    private constant real EPSILON = 32.00

    // Path styles
    constant integer PATROL_STYLE_LOOP = 0
    constant integer PATROL_STYLE_PINGPONG = 1

    private trigger orderTrig
    private trigger deathTrig
    private trigger damageTrig

    // Patrol data table (unit handle -> key -> value)
    private hashtable tPatrol = InitHashtable()
endglobals

// ===================== UTIL ===========================

// Calculate distance between unit and point
private function DistanceToPoint takes unit u, real x, real y returns real
    local real dx = x - GetUnitX(u)
    local real dy = y - GetUnitY(u)
    return SquareRoot(dx*dx + dy*dy)
endfunction

// Calculate travel time to point based on unit speed
private function MoveTime takes unit u, real x, real y returns real
    local real spd = GetUnitMoveSpeed(u)
    if spd < 1.00 then set spd = 220.0 endif
    return DistanceToPoint(u, x, y) / spd
endfunction

// Compute next waypoint index according to style
private function NextIndex takes integer id, integer idx returns integer
    local integer count = Table.Get(tPatrol, id, "count")
    local integer style = Table.Get(tPatrol, id, "style")
    local integer dir = Table.Get(tPatrol, id, "dir")

    if style == PATROL_STYLE_LOOP then
        set idx = ModuloInteger(idx + 1, count)
    else
        set idx = idx + dir
        if idx >= count then
            set idx = count - 2
            set dir = -1
        elseif idx < 0 then
            set idx = 1
            set dir = 1
        endif
        Table.Set(tPatrol, id, "dir", dir)
    endif
    return idx
endfunction

// ===================== TIMER CALLBACK =====================

// Handles patrol logic transitions
private function TimerExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local unit u = TimerUtils.GetUnit(t)
    local integer id
    local integer state
    local integer idx
    local real x
    local real y
    local real wait
    local string order
    local real patrolSpd

    if u == null or GetUnitTypeId(u) == 0 then return endif
    set id = GetHandleId(u)
    if not Table.HasKey(tPatrol, id, "state") then return endif

    set state = Table.Get(tPatrol, id, "state")
    set idx = Table.Get(tPatrol, id, "index")
    set order = Table.Get(tPatrol, id, "order")
    set patrolSpd = Table.Get(tPatrol, id, "speed")

    if state == 0 then return endif // paused

    // Apply patrol speed
    if patrolSpd > 0 then
        call SetUnitMoveSpeed(u, patrolSpd)
    else
        call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
    endif

    // Determine behavior based on state
    if state == 1 then
        // moving → arrived?
        set x = Table.Get(tPatrol, id, 1000 + idx)
        set y = Table.Get(tPatrol, id, 2000 + idx)
        if DistanceToPoint(u, x, y) <= EPSILON then
            // reached → wait
            set wait = Table.Get(tPatrol, id, 3000 + idx)
            if wait < 0.01 then
                set idx = NextIndex(id, idx)
                Table.Set(tPatrol, id, "index", idx)
                set x = Table.Get(tPatrol, id, 1000 + idx)
                set y = Table.Get(tPatrol, id, 2000 + idx)
                call IssuePointOrder(u, order, x, y)
                call StartTimerFor(u, MoveTime(u, x, y) + 0.25, 1)
            else
                call StartTimerFor(u, wait, 2) // waiting
            endif
        else
            // not arrived → re-issue move
            call IssuePointOrder(u, order, x, y)
            call StartTimerFor(u, 0.5, 1) // check again
        endif
    elseif state == 2 then
        // finished waiting → next waypoint
        set idx = NextIndex(id, idx)
        Table.Set(tPatrol, id, "index", idx)
        set x = Table.Get(tPatrol, id, 1000 + idx)
        set y = Table.Get(tPatrol, id, 2000 + idx)
        call IssuePointOrder(u, order, x, y)
        call StartTimerFor(u, MoveTime(u, x, y), 1)
    elseif state == 3 then
        // reset state done
        if Table.Get(tPatrol, id, "auto") then
            set x = Table.Get(tPatrol, id, 1000 + idx)
            set y = Table.Get(tPatrol, id, 2000 + idx)
            call IssuePointOrder(u, order, x, y)
            call StartTimerFor(u, MoveTime(u, x, y), 1)
        else
            Table.Set(tPatrol, id, "state", 0)
        endif
    endif
endfunction

// Helper to start timer for unit
private function StartTimerFor takes unit u, real dur, integer newState returns nothing
    local integer id = GetHandleId(u)
    local timer t = null
    if Table.HasKey(tPatrol, id, "timer") then
        set t = Table.Get(tPatrol, id, "timer")
    endif
    if t == null then
        set t = TimerUtils.Create()
        TimerUtils.SetUnit(t, u)
        Table.Set(tPatrol, id, "timer", t)
    endif
    Table.Set(tPatrol, id, "state", newState)
    TimerUtils.Start(t, dur, false, function TimerExpire)
endfunction

// ===================== INTERRUPT HANDLER =====================
private function HandlePatrolInterrupt takes unit u returns nothing
    local integer id = GetHandleId(u)
    if u == null or not Table.HasKey(tPatrol, id, "state") then return endif

    local timer t = null
    if Table.HasKey(tPatrol, id, "timer") then
        set t = Table.Get(tPatrol, id, "timer")
        TimerUtils.Pause(t)
        TimerUtils.Destroy(t)
        Table.Set(tPatrol, id, "timer", null)
    endif

    call IssueImmediateOrder(u, "stop")
    call IssueImmediateOrder(u, "holdposition")
    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))

    local real resetTime = Table.Get(tPatrol, id, "reset")
    local boolean autoResume = Table.Get(tPatrol, id, "auto")
    if autoResume and resetTime > 0.0 then
        call StartTimerFor(u, resetTime, 3)
    else
        Table.Set(tPatrol, id, "state", 0)
    endif
endfunction

private function OnDamage takes nothing returns nothing
    if udg_DamageEventTarget != null then
        call HandlePatrolInterrupt(udg_DamageEventTarget)
    endif
    if udg_DamageEventSource != null then
        call HandlePatrolInterrupt(udg_DamageEventSource)
    endif
endfunction

// ===================== DEATH CLEANUP =====================
private function OnDeath takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer id = GetHandleId(u)
    if Table.HasKey(tPatrol, id, "timer") then
        TimerUtils.Destroy(Table.Get(tPatrol, id, "timer"))
    endif
    Table.Remove(tPatrol, id)
endfunction

// ===================== PUBLIC API =====================

// Set waypoint for unit
function PatrolSystem_SetPoint takes unit u, integer index, real x, real y, real waitT returns nothing
    local integer id = GetHandleId(u)
    Table.Set(tPatrol, id, 1000 + index, x)
    Table.Set(tPatrol, id, 2000 + index, y)
    Table.Set(tPatrol, id, 3000 + index, waitT)
endfunction

// Start patrol
function PatrolSystem_Start takes unit u, integer count, real resetTime, integer style, boolean autoResume, string moveOrder, real patrolSpeed returns nothing
    local integer id = GetHandleId(u)
    local integer i = 0
    local real x
    local real y

    if u == null or count <= 0 then return endif

    // Flush old patrol
    call PatrolSystem_Stop(u)

    // Save settings
    Table.Set(tPatrol, id, "count", count)
    Table.Set(tPatrol, id, "index", 0)
    Table.Set(tPatrol, id, "dir", 1)
    Table.Set(tPatrol, id, "style", style)
    Table.Set(tPatrol, id, "reset", resetTime)
    Table.Set(tPatrol, id, "auto", autoResume)
    Table.Set(tPatrol, id, "order", moveOrder)
    Table.Set(tPatrol, id, "speed", patrolSpeed)
    Table.Set(tPatrol, id, "state", 1)

    if patrolSpeed > 0 then
        call SetUnitMoveSpeed(u, patrolSpeed)
    else
        call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
    endif

    // Kick off first waypoint
    loop
        exitwhen i >= count
        set x = GetLocationX(udg_PatrolSystem_Point[i])
        set y = GetLocationY(udg_PatrolSystem_Point[i])
        call PatrolSystem_SetPoint(u, i, x, y, udg_PatrolSystem_Wait[i])
        set i = i + 1
    endloop

    set x = Table.Get(tPatrol, id, 1000 + 0)
    set y = Table.Get(tPatrol, id, 2000 + 0)
    call IssuePointOrder(u, moveOrder, x, y)
    call StartTimerFor(u, MoveTime(u, x, y) + 0.25, 1)
endfunction

// Pause patrol
function PatrolSystem_Pause takes unit u returns nothing
    local integer id = GetHandleId(u)
    if not Table.HasKey(tPatrol, id, "state") then return endif
    if Table.HasKey(tPatrol, id, "timer") then
        TimerUtils.Pause(Table.Get(tPatrol, id, "timer"))
        TimerUtils.Destroy(Table.Get(tPatrol, id, "timer"))
        Table.Set(tPatrol, id, "timer", null)
    endif
    call IssueImmediateOrder(u, "stop")
    call IssueImmediateOrder(u, "holdposition")
    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
    Table.Set(tPatrol, id, "state", 0)
endfunction

// Resume patrol
function PatrolSystem_Resume takes unit u returns nothing
    local integer id = GetHandleId(u)
    if not Table.HasKey(tPatrol, id, "state") then return endif
    if Table.Get(tPatrol, id, "state") != 0 then return endif
    local integer idx = Table.Get(tPatrol, id, "index")
    local real x = Table.Get(tPatrol, id, 1000 + idx)
    local real y = Table.Get(tPatrol, id, 2000 + idx)
    local string order = Table.Get(tPatrol, id, "order")
    call IssuePointOrder(u, order, x, y)
    call StartTimerFor(u, MoveTime(u, x, y), 1)
endfunction

// Stop patrol and flush data
function PatrolSystem_Stop takes unit u returns nothing
    local integer id = GetHandleId(u)
    if u == null then return endif
    call IssueImmediateOrder(u, "stop")
    call IssueImmediateOrder(u, "holdposition")
    if Table.HasKey(tPatrol, id, "timer") then
        TimerUtils.Destroy(Table.Get(tPatrol, id, "timer"))
    endif
    Table.Remove(tPatrol, id)
endfunction

// Change patrol move order
function PatrolSystem_Movestyle takes unit u, string newOrder returns nothing
    local integer id = GetHandleId(u)
    if Table.HasKey(tPatrol, id, "state") then
        Table.Set(tPatrol, id, "order", newOrder)
    endif
endfunction

// Continue patrol after manual stop/pause
function PatrolSystem_Continue takes unit u returns nothing
    local integer id = GetHandleId(u)
    if not Table.HasKey(tPatrol, id, "state") then return endif
    local integer idx = Table.Get(tPatrol, id, "index")
    local real x = Table.Get(tPatrol, id, 1000 + idx)
    local real y = Table.Get(tPatrol, id, 2000 + idx)
    local string order = Table.Get(tPatrol, id, "order")
    call IssuePointOrder(u, order, x, y)
    call StartTimerFor(u, MoveTime(u, x, y), 1)
endfunction

// ===================== EVENTS INIT =====================
private function OnIssuedOrder takes nothing returns nothing
    // Optional: suppression logic similar to old library can be added here
endfunction

private function Init takes nothing returns nothing
    set orderTrig = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
    call TriggerAddAction(orderTrig, function OnIssuedOrder)

    set deathTrig = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(deathTrig, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(deathTrig, function OnDeath)

    set damageTrig = CreateTrigger()
    call TriggerRegisterVariableEvent(damageTrig, "udg_DamageEvent", EQUAL, 1.0)
    call TriggerAddAction(damageTrig, function OnDamage)
endfunction

endlibrary
