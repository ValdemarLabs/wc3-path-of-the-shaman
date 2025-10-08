library PatrolSystem initializer Init
//===========================================================================
/*
    PatrolSystem
    Author: [Valdemar]

    Description:
    Event-driven patrol system with per-unit timers. 

    Features:
    - Ping-pong style waypoint loop
    - Per-waypoint wait times
    - Reset timer after interruption (auto/manual resume)
    - When attacked or attacking, it reverts to its default movement speed.
    - Scales to hundreds of NPCs without lag

    Difference in PATH STYLE behavior:

        PATROL_STYLE_LOOP (0):

            When the unit reaches the last waypoint, it loops back to the first waypoint.

            Example with waypoints [A → B → C]:
            Patrol goes A → B → C → A → B → C → ...

        PATROL_STYLE_PINGPONG (1):

            The unit "bounces" back and forth through the waypoints.

            Example with waypoints [A → B → C]:
            Patrol goes A → B → C → B → A → B → C → ...

    Usage from GUI:
    1. Set variable "PatrolSystem_Point[index]" to your waypoint points
    2. Set variable "PatrolSystem_Wait[index]" to the wait time for each waypoint
        example:
        Set Variable udg_PatrolSystem_Point[0] = (Center of wp01 <gen>)
        Set Variable udg_PatrolSystem_Wait[0] = 3.00
        Set Variable udg_PatrolSystem_Point[1] = (Center of wp02 <gen>)
        Set Variable udg_PatrolSystem_Wait[1] = 5.00
        ...
    3.T To start the patrol:
        call PatrolSystem_Start(udg_TempUnit, 2, 10.00, 1, true, "move")
        // where udg_TempUnit is the unit to patrol, 2 is the number of waypoints,
        // 10.00 is the reset time after interruption, and 0 or 1 is the path style.
        // true = auto-continue after reset, false = pause after reset
        // 9 : moveStyle (string order ID, e.g., "move", "patrol", "attack")

    4.1 To manually stop patrol:
        call PatrolSystem_Stop(udg_TempUnit)
        - This clears all data. To resume, you must call Start again.

    4.2 To manually pause patrol (can be resumed with Resume):
        call PatrolSystem_Pause(udg_TempUnit)

    5. To manually continue patrol after reset:
        call PatrolSystem_Continue(udg_TempUnit)

    6. To change the move style (e.g., "move", "patrol", "attack"):
        call PatrolSystem_Movestyle(udg_TempUnit, "patrol")

    Resume = conditional continue.
    - Works only if the unit is paused by the patrol system (state = 0).

    Continue = force continue.
    - Always tries to move to the current waypoint, ignoring state.
    - Works even if the unit was manually stopped (state = 3).

*/ 
//===========================================================================

globals
    private hashtable ht = InitHashtable()
    private constant real EPSILON = 32.00

    // Path styles
    constant integer PATROL_STYLE_LOOP = 0
    constant integer PATROL_STYLE_PINGPONG = 1

    private trigger orderTrig
    private trigger deathTrig
    private trigger damageTrig
endglobals

// ------------------------------------------------------
// Internal hashtable keys per unit (child = GetHandleId(u))
//   0  : unit handle
//   1  : timer handle (reused)
//   2  : current waypoint index
//   3  : resetTime
//   4  : state (0=paused,1=travel,2=wait,3=reset)
//   5  : direction (+1 / -1)
//   6  : count (num waypoints)
//   7  : autoContinue (boolean)
//   8  : pathStyle (0=loop,1=pingpong)
//   50 : suppress (boolean) — ignore order event when system issues orders
// Per-waypoint data (0..N-1)
//   1000+idx : x
//   2000+idx : y
//   3000+idx : wait
// ------------------------------------------------------

// ===================== UTIL ===========================
// Get or create timer for unit
private function GetTimerFor takes integer id returns timer
    local timer t = LoadTimerHandle(ht, id, 1)

    if t == null then
        set t = CreateTimer()
        call SaveTimerHandle(ht, id, 1, t)
    endif
    return t
endfunction

// Calculate next waypoint index based on style
private function NextIndex takes integer id, integer idx returns integer
    local integer count = LoadInteger(ht, id, 6)
    local integer style = LoadInteger(ht, id, 8)
    local integer dir = LoadInteger(ht, id, 5)

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
        call SaveInteger(ht, id, 5, dir)
    endif
    return idx
endfunction

// Calculate time to move to point (x,y)
private function MoveTime takes unit u, real x, real y returns real
    local real dx = x - GetUnitX(u)
    local real dy = y - GetUnitY(u)
    local real dist = SquareRoot(dx*dx + dy*dy)
    local real spd = GetUnitMoveSpeed(u)

    if spd < 1.00 then
        set spd = 220.00 // sensible fallback
    endif
    return dist / spd
endfunction

// Clear all data for unit
private function FlushUnit takes unit u returns nothing
    local integer id = GetHandleId(u)
    local timer t = LoadTimerHandle(ht, id, 1)

    if t != null then
        call PauseTimer(t)
        call DestroyTimer(t)
        call RemoveSavedHandle(ht, id, 1)
    endif
    call FlushChildHashtable(ht, id)
endfunction

// Start timer for unit with backref and state
private function StartUnitTimer takes unit u, real dur, integer state, code callback returns nothing
    local integer id = GetHandleId(u)
    local timer t = GetTimerFor(id)
    
    call SaveUnitHandle(ht, GetHandleId(t), 0, u)
    call SaveInteger(ht, id, 4, state)
    call TimerStart(t, dur, false, callback)
endfunction

// Timer callback: handle state transitions
private function TimerExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local unit u = LoadUnitHandle(ht, GetHandleId(t), 0)
    local integer id
    local integer state
    local integer idx
    local real x
    local real y
    local real wait
    local string order = LoadStr(ht, GetHandleId(u), 9)
    local real patrolSpd

    // Exit if unit is invalid
    if u == null or GetUnitTypeId(u) == 0 then
        return
    endif

    set id = GetHandleId(u)

    // Exit if unit is not tracked
    if not HaveSavedHandle(ht, id, 0) then
        return
    endif

    set state = LoadInteger(ht, id, 4)
    set idx = LoadInteger(ht, id, 2)
    set patrolSpd = LoadReal(ht, id, 10)

    // Exit immediately if paused
    if state == 0 then
        return
    endif

    // Apply patrol speed while moving
    if patrolSpd > 0 then
        call SetUnitMoveSpeed(u, patrolSpd)
    else
        call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
    endif

    // Handle state transitions
    if state == 1 then
        // arrived → wait
        if SquareRoot((GetUnitX(u) - LoadReal(ht, id, 1000 + idx)) * (GetUnitX(u) - LoadReal(ht, id, 1000 + idx)) + (GetUnitY(u) - LoadReal(ht, id, 2000 + idx)) * (GetUnitY(u) - LoadReal(ht, id, 2000 + idx))) <= EPSILON then
            // Within tolerance → proceed
            set wait = LoadReal(ht, id, 3000 + idx)
            if wait < 0.01 then
                set idx = NextIndex(id, idx)
                call SaveInteger(ht, id, 2, idx)
                set x = LoadReal(ht, id, 1000 + idx)
                set y = LoadReal(ht, id, 2000 + idx)
                call SaveBoolean(ht, id, 50, true)
                call IssuePointOrder(u, order, x, y)
                call StartUnitTimer(u, MoveTime(u, x, y) + 0.25, 1, function TimerExpire)
            else
                call StartUnitTimer(u, wait, 2, function TimerExpire)
            endif
        else
            // Not close enough → re-issue move
            set x = LoadReal(ht, id, 1000 + idx)
            set y = LoadReal(ht, id, 2000 + idx)
            call SaveBoolean(ht, id, 50, true)
            call IssuePointOrder(u, order, x, y)
            call StartUnitTimer(u, 0.5, 1, function TimerExpire) // check again soon
        endif
    elseif state == 2 then
        // finished waiting → move to next
        set idx = NextIndex(id, idx)
        call SaveInteger(ht, id, 2, idx)
        set x = LoadReal(ht, id, 1000 + idx)
        set y = LoadReal(ht, id, 2000 + idx)
        call SaveBoolean(ht, id, 50, true)
        call IssuePointOrder(u, order, x, y)
        call StartUnitTimer(u, MoveTime(u, x, y), 1, function TimerExpire)
    elseif state == 3 then
        // reset done
        if LoadBoolean(ht, id, 7) then
            // auto-continue
            set x = LoadReal(ht, id, 1000 + idx)
            set y = LoadReal(ht, id, 2000 + idx)
            call SaveBoolean(ht, id, 50, true)
            call IssuePointOrder(u, order, x, y)
            call StartUnitTimer(u, MoveTime(u, x, y), 1, function TimerExpire)
        else
            // paused until manual resume
            call SaveInteger(ht, id, 4, 0)
        endif
    endif
endfunction

// We use a tiny helper to (re)start timer and keep backref
private function StartTimerFor takes unit u, real dur, integer newState returns nothing
    local integer id = GetHandleId(u)
    local timer t = GetTimerFor(id)

    call SaveUnitHandle(ht, GetHandleId(t), 0, u) // timer→unit backref
    call SaveInteger(ht, id, 4, newState)
    call TimerStart(t, dur, false, function TimerExpire)
endfunction

// ===================== CORE ===========================
// Issue move order with suppression flag and start travel timer
private function OrderMove takes unit u, real x, real y returns nothing
    local integer id = GetHandleId(u)
    local timer t = GetTimerFor(id)
    local real travel = MoveTime(u, x, y)
    local string moveOrder = LoadStr(ht, id, 9)

    call SaveBoolean(ht, id, 50, true) // suppress own order event
    call IssuePointOrder(u, moveOrder, x, y)
    call SaveInteger(ht, id, 4, 1) // state travel
    call TimerStart(t, travel, false, function TimerExpire) // start travel timer
endfunction

// ===================== ORDER EVENTS ====================
private function OnIssuedOrder takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer id = GetHandleId(u)
    local integer ord = GetIssuedOrderId()
    local boolean tracked = HaveSavedHandle(ht, id, 0)
    local boolean suppress
    local timer t
    local real resetTime
    local integer state
    local string moveOrder
    local integer moveOrderId

    if not tracked then
        return
    endif

    // Current patrol state & saved move order
    set state = LoadInteger(ht, id, 4)      // current patrol state 0=paused,1=travel,2=wait,3=reset 
    set moveOrder = LoadStr(ht, id, 9)      // saved move order
    set moveOrderId = OrderId(moveOrder)    // saved move order ID

    // If paused, ignore ALL patrol logic
    if state == 0 then
        return
    endif

    // Suppression flag for our own issued orders
    set suppress = LoadBoolean(ht, id, 50)
    if suppress then
        // clear suppression set during our own IssuePointOrder
        call SaveBoolean(ht, id, 50, false)
        return
    endif

    // If the order is the same as the patrol move order, ignore it
    if ord == moveOrderId then
        return // still on patrol path
    endif
    
    // Otherwise, ignore all other orders here
    // Combat interrupts will be handled in OnDamage
    // Any external order interrupts patrol unless it's another move order
    //if ord != OrderId("move") then
    //    set t = LoadTimerHandle(ht, id, 1)
    //    if t != null then
    //        call PauseTimer(t)
    //    endif
    //    if LoadBoolean(ht, id, 7) then
    //        set resetTime = LoadReal(ht, id, 3)
    //        if resetTime > 0.0 then
    //            call StartTimerFor(u, resetTime, 3) // auto-continue after reset time
    //        else
    //            // stay paused
    //            call SaveInteger(ht, id, 4, 0)
    //        endif
    //    endif
    //endif
endfunction

// ===================== DAMAGE EVENTS ====================
// This is used to pause patrol if unit is damaged
private function OnDamage takes nothing returns nothing
    local integer id
    local timer t
    local real resetTime
    local unit victim = udg_DamageEventTarget
    local unit attacker = udg_DamageEventSource

    // Check both victim and attacker for patrol interruption
    // -------------------
    // VICTIM
    // -------------------
    // If victim is the patrolling Unit, pause it
    if victim != null then
        set id = GetHandleId(victim)
        if HaveSavedHandle(ht, id, 0) then
            set t = LoadTimerHandle(ht, id, 1)
            if t != null then
                call PauseTimer(t)
            endif
            // Force stop current action so unit halts
            call SaveBoolean(ht, id, 50, true) // suppress our own order event
            call IssueImmediateOrder(victim, "stop")

            // revert to default move speed
            call SetUnitMoveSpeed(victim, GetUnitDefaultMoveSpeed(victim))

            if LoadBoolean(ht, id, 7) then
                set resetTime = LoadReal(ht, id, 3)
                if resetTime > 0.0 then
                    call StartTimerFor(victim, resetTime, 3) // auto-continue after reset
                else
                    call SaveInteger(ht, id, 4, 0)
                endif
            else
                call SaveInteger(ht, id, 4, 0)
            endif
        endif
    endif

    // -------------------
    // ATTACKER
    // -------------------
    // If attacker is the patrolling Unit, pause it
    if attacker != null then
        set id = GetHandleId(attacker)
        if HaveSavedHandle(ht, id, 0) then
            set t = LoadTimerHandle(ht, id, 1)
            if t != null then
                call PauseTimer(t)
            endif
            // Force stop current action so unit halts
            call SaveBoolean(ht, id, 50, true)  // suppress our own order event
            call IssueImmediateOrder(attacker, "stop")  

            // revert to default move speed
            call SetUnitMoveSpeed(attacker, GetUnitDefaultMoveSpeed(attacker))

            if LoadBoolean(ht, id, 7) then
                set resetTime = LoadReal(ht, id, 3)
                if resetTime > 0.0 then
                    call StartTimerFor(attacker, resetTime, 3)  // auto-continue after reset
                else
                    call SaveInteger(ht, id, 4, 0)
                endif
            else
                call SaveInteger(ht, id, 4, 0)
            endif
        endif
    endif

endfunction

// ===================== PUBLIC API ======================
// ===================== Setpoint =======================
// Call this multiple times to set up waypoints before starting patrol
function PatrolSystem_SetPoint takes unit u, integer index, real x, real y, real waitT returns nothing
    local integer id = GetHandleId(u)

    if u == null then
        return
    endif

    call SaveReal(ht, id, 1000 + index, x)
    call SaveReal(ht, id, 2000 + index, y)
    call SaveReal(ht, id, 3000 + index, waitT)
    // call BJDebugMsg("Saved WP " + I2S(index) + ": " + R2S(x) + ", " + R2S(y))

endfunction

// ===================== Pause =======================
// Call to pause patrol (can be resumed with PatrolSystem_Resume)
function PatrolSystem_Pause takes unit u returns nothing
    local integer id = GetHandleId(u)
    local timer t = LoadTimerHandle(ht, id, 1)
    local integer state = 0

    if not HaveSavedHandle(ht, id, 0) then
        return
    endif

    // Pause & destroy any active timer so it cannot later resume the unit
    if t != null then
        call PauseTimer(t)
        // destroy to be safe (we'll recreate on resume)
        call DestroyTimer(t)
        call RemoveSavedHandle(ht, id, 1)
    endif

    // Suppress our own order event before issuing stop
    call SaveBoolean(ht, id, 50, true)
    call IssueImmediateOrder(u, "stop")
    call IssueImmediateOrder(u, "holdposition")

    // revert to default move speed
    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))

    // mark paused
    call SaveInteger(ht, id, 4, 0) // state = paused
endfunction

// ===================== Resume =======================
// Call to resume paused patrol
function PatrolSystem_Resume takes unit u returns nothing
    local integer id = GetHandleId(u)
    local integer state = LoadInteger(ht, id, 4)
    local integer idx = LoadInteger(ht, id, 2)
    local real x
    local real y
    local string moveOrder = LoadStr(ht, id, 9)

    if not HaveSavedHandle(ht, id, 0) then
        return
    endif

    if state == 0 then
        set x = LoadReal(ht, id, 1000 + idx)
        set y = LoadReal(ht, id, 2000 + idx)
        call SaveBoolean(ht, id, 50, true)
        call IssuePointOrder(u, moveOrder, x, y)
        call StartTimerFor(u, MoveTime(u, x, y), 1)
    endif

endfunction

// ===================== Stop =======================
// Call to completely stop and clear patrol data
function PatrolSystem_Stop takes unit u returns nothing
    local integer id = GetHandleId(u)

    if u == null then
        return
    endif

    // Suppress so the "stop" order doesn’t trigger OnIssuedOrder logic
    call SaveBoolean(ht, id, 50, true)
    call IssueImmediateOrder(u, "stop")
    call IssueImmediateOrder(u, "holdposition")

    // Flush all patrol data & timers
    call FlushUnit(u)
endfunction

// ===================== Movestyle =======================
// Call to change move style (e.g., "move", "patrol", "attack")
function PatrolSystem_Movestyle takes unit u, string newOrder returns nothing
    local integer id = GetHandleId(u)
    if HaveSavedHandle(ht, id, 0) then
        call SaveStr(ht, id, 9, newOrder)
    endif
endfunction

// ==========================================================
//  Patrol System - Start Patrol
//  Initializes patrol waypoints, style, reset time, etc.
// ==========================================================
function PatrolSystem_Start takes unit u, integer count, real resetTime, integer PATROL_STYLE_LOOP, boolean autoResume, string moveOrder, real patrolSpeed returns nothing
    local integer id = GetHandleId(u)
    local integer i = 0
    local real x
    local real y
    local string autoText = "false"

    if u == null then
        // call BJDebugMsg("[PatrolSystem] ERROR: Tried to start patrol with a null unit.")
        return
    endif

    if count <= 0 then
        // call BJDebugMsg("[PatrolSystem] ERROR: Waypoint count <= 0 for " + GetUnitName(u))
        return
    endif

    // Fresh start for this unit
    call FlushUnit(u) 

    // Get unit ID
    set id = GetHandleId(u)

    // Save tracking + settings (match your key map!)
    call SaveUnitHandle(ht, id, 0, u)                   // KEY 0: unit handle   (DO NOT use SaveBoolean here)
    call SaveInteger(ht, id, 6, count)                  // KEY 6: waypoint count
    call SaveInteger(ht, id, 2, 0)                      // KEY 2: current waypoint index = 0
    call SaveInteger(ht, id, 5, 1)                      // KEY 5: direction = +1 (forward)
    call SaveInteger(ht, id, 8, PATROL_STYLE_LOOP)      // KEY 8: path style (default loop)
    call SaveReal(ht, id, 3, resetTime)                 // KEY 3: resetTime
    call SaveBoolean(ht, id, 7, autoResume)             // KEY 7: auto-resume flag
    call SaveStr(ht, id, 9, moveOrder)                  // KEY 9: move order
    call SaveReal(ht, id, 10, patrolSpeed)              // KEY 10: patrol speed
    
    // Set movement speed of the unit, if set as 0 then use default speed of the unit
    if patrolSpeed > 0 then
        call SetUnitMoveSpeed(u, patrolSpeed)
    else
        call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
    endif

    // Debug header
    if autoResume then
        set autoText = "true"
    else
        set autoText = "false"
    endif

    // call BJDebugMsg("[PatrolSystem] Initializing patrol for " + GetUnitName(u))
    // call BJDebugMsg("   Waypoint count = " + I2S(count))
    // call BJDebugMsg("   Reset time     = " + R2S(resetTime))
    // call BJDebugMsg("   Path style     = " + I2S(PATROL_STYLE_LOOP))
    // call BJDebugMsg("   AutoResume     = " + autoText)

    // Load points from GUI arrays → store with SetPoint (x,y,wait)
    loop
        exitwhen i >= count
        // call BJDebugMsg("Waypoint[" + I2S(i) + "] = " + R2S(GetLocationX(udg_PatrolSystem_Point[i])) + ", " + R2S(GetLocationY(udg_PatrolSystem_Point[i])))
        call PatrolSystem_SetPoint(u, i, GetLocationX(udg_PatrolSystem_Point[i]), GetLocationY(udg_PatrolSystem_Point[i]), udg_PatrolSystem_Wait[i])
        set i = i + 1
    endloop

    // Kick off: order move to first point and start travel timer
    set x = LoadReal(ht, id, 1000 + 0)
    set y = LoadReal(ht, id, 2000 + 0)
    call SaveBoolean(ht, id, 50, true) // suppress our own order event
    call IssuePointOrder(u, moveOrder, x, y)
    // Add +0.25s buffer to avoid arriving slightly before timer due to EPSILON tolerance
    call StartTimerFor(u, MoveTime(u, x, y) + 0.25, 1) 

    // call BJDebugMsg("[PatrolSystem] Patrol started for " + GetUnitName(u) + " with " + I2S(count) + " waypoints.")

endfunction

// ===================== Continue =======================
// Call to continue patrol after manual stop or pause
function PatrolSystem_Continue takes unit u returns nothing
    local integer id = GetHandleId(u)
    local integer idx = LoadInteger(ht, id, 2)  // current waypoint index
    local timer t = LoadTimerHandle(ht, id, 1)
    local real x = LoadReal(ht, id, 1000 + idx)
    local real y = LoadReal(ht, id, 2000 + idx)
    local string moveOrder = LoadStr(ht, id, 9)

    if t != null then
        call ResumeTimer(t)
        call SaveInteger(ht, id, 4, 1) // state = traveling
    endif

    call SaveBoolean(ht, id, 50, true)
    call IssuePointOrder(u, moveOrder, x, y)
    call StartTimerFor(u, MoveTime(u, x, y), 1)

endfunction

// ===================== CLEANUP =========================
private function OnDeath takes nothing returns nothing
    call FlushUnit(GetTriggerUnit())
endfunction

private function Init takes nothing returns nothing
    // Orders (any type)
    set orderTrig = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
    call TriggerAddAction(orderTrig, function OnIssuedOrder)

    // Deaths cleanup
    set deathTrig = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(deathTrig, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(deathTrig, function OnDeath)

    // Requires Damage Engine
    set damageTrig = CreateTrigger()
    call TriggerRegisterVariableEvent(damageTrig, "udg_DamageEvent", EQUAL, 1.00)
    call TriggerAddAction(damageTrig, function OnDamage)
endfunction

endlibrary
