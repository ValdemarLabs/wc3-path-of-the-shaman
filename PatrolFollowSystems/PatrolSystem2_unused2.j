library PatrolSystem initializer Init requires Table, TimerUtils

//===========================================================================
/*
    PatrolSystem 2.0 - Improved with Table and TimerUtils
    Author: [Valdemar] (Refactored)

    Description:
    Event-driven patrol system using Bribe's Table and TimerUtils for better
    performance and cleaner code organization.

    Features:
    - Ping-pong style waypoint loop
    - Per-waypoint wait times
    - Reset timer after interruption (auto/manual resume)
    - Reverts to default movement speed when attacked/attacking
    - Scales to hundreds of NPCs without lag
    - Uses Bribe's Table for data storage
    - Uses TimerUtils for efficient timer recycling

    Path Styles:
        PATROL_STYLE_LOOP (0):
            Loops back to first waypoint after reaching the last.
            Example: A → B → C → A → B → C → ...

        PATROL_STYLE_PINGPONG (1):
            Bounces back and forth through waypoints.
            Example: A → B → C → B → A → B → C → ...

    Usage from GUI:
    1. Set waypoint variables:
        Set udg_PatrolSystem_Point[0] = (Center of wp01 <gen>)
        Set udg_PatrolSystem_Wait[0] = 3.00
        Set udg_PatrolSystem_Point[1] = (Center of wp02 <gen>)
        Set udg_PatrolSystem_Wait[1] = 5.00

    2. Start patrol:
        call PatrolSystem_Start(udg_Unit, 2, 10.00, 0, true, "move", 0)
        Parameters:
        - unit: the unit to patrol
        - count: number of waypoints
        - resetTime: seconds before auto-resuming after interrupt
        - pathStyle: 0 (loop) or 1 (ping-pong)
        - autoResume: auto-continue after reset
        - moveOrder: "move", "patrol", or "attack"
        - patrolSpeed: movement speed (0 = use default)

    3. Control functions:
        - PatrolSystem_Stop(unit) - completely stop and clear data
        - PatrolSystem_Pause(unit) - pause (can resume with Resume)
        - PatrolSystem_Resume(unit) - resume if paused
        - PatrolSystem_Continue(unit) - force continue (works even if stopped)
        - PatrolSystem_Movestyle(unit, "order") - change movement order type
*/ 
//===========================================================================

globals
    // Constants
    private constant real EPSILON = 32.00           // Arrival distance tolerance
    private constant real ARRIVAL_BUFFER = 0.25     // Time buffer for arrival
    private constant real RECHECK_INTERVAL = 0.5    // Recheck interval if not arrived
    
    // Path styles (public)
    constant integer PATROL_STYLE_LOOP = 0
    constant integer PATROL_STYLE_PINGPONG = 1
    
    // State constants
    private constant integer STATE_PAUSED = 0
    private constant integer STATE_TRAVELING = 1
    private constant integer STATE_WAITING = 2
    private constant integer STATE_RESETTING = 3
    
    // Data storage keys
    private constant integer KEY_CURRENT_IDX = 2
    private constant integer KEY_RESET_TIME = 3
    private constant integer KEY_STATE = 4
    private constant integer KEY_DIRECTION = 5
    private constant integer KEY_COUNT = 6
    private constant integer KEY_AUTO_RESUME = 7
    private constant integer KEY_PATH_STYLE = 8
    private constant integer KEY_MOVE_ORDER = 9
    private constant integer KEY_PATROL_SPEED = 10
    private constant integer KEY_SUPPRESS = 50
    
    // Waypoint data offsets
    private constant integer WAYPOINT_X_OFFSET = 1000
    private constant integer WAYPOINT_Y_OFFSET = 2000
    private constant integer WAYPOINT_WAIT_OFFSET = 3000
    
    // Main data table (per unit)
    private Table patrolData
    
    // Unit handle storage (unitId -> unit)
    private Table unitHandles
    
    // Event triggers
    private trigger orderTrig
    private trigger deathTrig
    private trigger damageTrig
endglobals

//===========================================================================
// UTILITY FUNCTIONS
//===========================================================================

/**
 * Checks if unit is tracked by patrol system
 */
private function IsTracked takes integer unitId returns boolean
    return patrolData[unitId].has(KEY_COUNT)
endfunction

/**
 * Calculates squared distance (avoids SquareRoot)
 */
private function GetDistanceSq takes real x1, real y1, real x2, real y2 returns real
    local real dx = x2 - x1
    local real dy = y2 - y1
    return dx * dx + dy * dy
endfunction

/**
 * Checks if unit has arrived at waypoint
 */
private function HasArrived takes unit u, integer unitId, integer idx returns boolean
    local Table data = patrolData[unitId]
    local real ux = GetUnitX(u)
    local real uy = GetUnitY(u)
    local real wx = data.real[WAYPOINT_X_OFFSET + idx]
    local real wy = data.real[WAYPOINT_Y_OFFSET + idx]
    
    return GetDistanceSq(ux, uy, wx, wy) <= (EPSILON * EPSILON)
endfunction

/**
 * Calculates time to move to target position
 */
private function CalculateMoveTime takes unit u, real x, real y returns real
    local real dx = x - GetUnitX(u)
    local real dy = y - GetUnitY(u)
    local real dist = SquareRoot(dx * dx + dy * dy)
    local real speed = GetUnitMoveSpeed(u)
    
    if speed < 1.0 then
        set speed = 220.0
    endif
    
    return dist / speed
endfunction

/**
 * Calculates next waypoint index based on path style
 */
private function GetNextIndex takes integer unitId, integer currentIdx returns integer
    local Table data = patrolData[unitId]
    local integer count = data.integer[KEY_COUNT]
    local integer style = data.integer[KEY_PATH_STYLE]
    local integer dir = data.integer[KEY_DIRECTION]
    local integer nextIdx
    
    if style == PATROL_STYLE_LOOP then
        // Loop style
        set nextIdx = ModuloInteger(currentIdx + 1, count)
    else
        // Ping-pong style
        set nextIdx = currentIdx + dir
        
        if nextIdx >= count then
            set nextIdx = count - 2
            set dir = -1
            set data.integer[KEY_DIRECTION] = dir
        elseif nextIdx < 0 then
            set nextIdx = 1
            set dir = 1
            set data.integer[KEY_DIRECTION] = dir
        endif
    endif
    
    return nextIdx
endfunction

/**
 * Issues patrol movement order with suppression flag
 */
private function IssuePatrolOrder takes unit u, integer unitId, real x, real y returns nothing
    local Table data = patrolData[unitId]
    local string moveOrder = data.string[KEY_MOVE_ORDER]
    
    set data.boolean[KEY_SUPPRESS] = true
    call IssuePointOrder(u, moveOrder, x, y)
endfunction

/**
 * Applies patrol speed to unit
 */
private function ApplyPatrolSpeed takes unit u, integer unitId returns nothing
    local real speed = patrolData[unitId].real[KEY_PATROL_SPEED]
    
    if speed > 0 then
        call SetUnitMoveSpeed(u, speed)
    else
        call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
    endif
endfunction

//===========================================================================
// FORWARD DECLARATIONS (Stub Functions)
//===========================================================================

// These stub functions allow circular dependencies between functions
// The actual implementation follows below

/**
 * Timer callback stub
 */
function PatrolSystem_OnTimerExpire takes nothing returns nothing
endfunction

/**
 * Start patrol timer stub
 */
private function StartPatrolTimer takes unit u, integer unitId, real duration, integer newState returns nothing
endfunction

/**
 * Stop patrol stub
 */
function PatrolSystem_Stop takes unit u returns nothing
endfunction

//===========================================================================
// TIMER SYSTEM (using TimerUtils)
//===========================================================================

/**
 * Starts a timer for the unit with specified duration and state
 */
function StartPatrolTimer takes unit u, integer unitId, real duration, integer newState returns nothing
    local timer t = NewTimerEx(unitId)
    
    set patrolData[unitId].integer[KEY_STATE] = newState
    call TimerStart(t, duration, false, function PatrolSystem_OnTimerExpire)
endfunction

/**
 * Main timer callback - handles state transitions
 */
function PatrolSystem_OnTimerExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer unitId = GetTimerData(t)
    local unit u
    local Table data
    local integer state
    local integer currentIdx
    local integer nextIdx
    local real x
    local real y
    local real waitTime
    local real moveTime
    
    // Release timer
    call ReleaseTimer(t)
    
    // Check if still tracked
    if not IsTracked(unitId) then
        return
    endif
    
    set data = patrolData[unitId]
    
    // Get unit from stored handle
    set u = unitHandles[unitId].unit[0]
    if u == null or GetUnitTypeId(u) == 0 then
        return
    endif
    
    set state = data.integer[KEY_STATE]
    
    // Exit if paused
    if state == STATE_PAUSED then
        set u = null
        return
    endif
    
    set currentIdx = data.integer[KEY_CURRENT_IDX]
    
    // Apply patrol speed
    call ApplyPatrolSpeed(u, unitId)
    
    // Handle state transitions
    if state == STATE_TRAVELING then
        // Check if arrived at waypoint
        if HasArrived(u, unitId, currentIdx) then
            set waitTime = data.real[WAYPOINT_WAIT_OFFSET + currentIdx]
            
            if waitTime < 0.01 then
                // No wait - move to next immediately
                set nextIdx = GetNextIndex(unitId, currentIdx)
                set data.integer[KEY_CURRENT_IDX] = nextIdx
                
                set x = data.real[WAYPOINT_X_OFFSET + nextIdx]
                set y = data.real[WAYPOINT_Y_OFFSET + nextIdx]
                
                call IssuePatrolOrder(u, unitId, x, y)
                set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
                call StartPatrolTimer(u, unitId, moveTime, STATE_TRAVELING)
            else
                // Wait at waypoint
                call StartPatrolTimer(u, unitId, waitTime, STATE_WAITING)
            endif
        else
            // Not arrived yet - re-issue order
            set x = data.real[WAYPOINT_X_OFFSET + currentIdx]
            set y = data.real[WAYPOINT_Y_OFFSET + currentIdx]
            
            call IssuePatrolOrder(u, unitId, x, y)
            call StartPatrolTimer(u, unitId, RECHECK_INTERVAL, STATE_TRAVELING)
        endif
        
    elseif state == STATE_WAITING then
        // Finished waiting - move to next
        set nextIdx = GetNextIndex(unitId, currentIdx)
        set data.integer[KEY_CURRENT_IDX] = nextIdx
        
        set x = data.real[WAYPOINT_X_OFFSET + nextIdx]
        set y = data.real[WAYPOINT_Y_OFFSET + nextIdx]
        
        call IssuePatrolOrder(u, unitId, x, y)
        set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
        call StartPatrolTimer(u, unitId, moveTime, STATE_TRAVELING)
        
    elseif state == STATE_RESETTING then
        // Reset complete
        if data.boolean[KEY_AUTO_RESUME] then
            // Auto-resume enabled
            set x = data.real[WAYPOINT_X_OFFSET + currentIdx]
            set y = data.real[WAYPOINT_Y_OFFSET + currentIdx]
            
            call IssuePatrolOrder(u, unitId, x, y)
            set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
            call StartPatrolTimer(u, unitId, moveTime, STATE_TRAVELING)
        else
            // Stay paused
            set data.integer[KEY_STATE] = STATE_PAUSED
        endif
    endif
    
    set u = null
endfunction

//===========================================================================
// INTERRUPT HANDLING
//===========================================================================

/**
 * Handles patrol interruption
 */
private function InterruptPatrol takes unit u, integer unitId returns nothing
    local Table data = patrolData[unitId]
    local real resetTime
    
    // Stop unit
    set data.boolean[KEY_SUPPRESS] = true
    call IssueImmediateOrder(u, "stop")
    
    // Revert to default speed
    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
    
    // Handle reset
    if data.boolean[KEY_AUTO_RESUME] then
        set resetTime = data.real[KEY_RESET_TIME]
        if resetTime > 0.0 then
            call StartPatrolTimer(u, unitId, resetTime, STATE_RESETTING)
        else
            set data.integer[KEY_STATE] = STATE_PAUSED
        endif
    else
        set data.integer[KEY_STATE] = STATE_PAUSED
    endif
endfunction

//===========================================================================
// EVENT HANDLERS
//===========================================================================

/**
 * Handles unit order events
 */
private function OnUnitOrder takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer unitId = GetUnitUserData(u)
    local Table data
    local integer orderId
    local integer savedOrderId
    local integer state
    local boolean suppress
    
    if not IsTracked(unitId) then
        set u = null
        return
    endif
    
    set data = patrolData[unitId]
    set state = data.integer[KEY_STATE]
    
    // Ignore if paused
    if state == STATE_PAUSED then
        set u = null
        return
    endif
    
    // Check suppression flag
    set suppress = data.boolean[KEY_SUPPRESS]
    if suppress then
        set data.boolean[KEY_SUPPRESS] = false
        set u = null
        return
    endif
    
    // Check if order matches patrol order
    set orderId = GetIssuedOrderId()
    set savedOrderId = OrderId(data.string[KEY_MOVE_ORDER])
    
    if orderId == savedOrderId then
        set u = null
        return
    endif
    
    // External order - could interrupt
    // Currently only interrupt on damage
    
    set u = null
endfunction

/**
 * Handles damage events
 */
private function OnDamage takes nothing returns nothing
    local unit victim = udg_DamageEventTarget
    local unit attacker = udg_DamageEventSource
    local integer victimId
    local integer attackerId
    
    if victim != null then
        set victimId = GetUnitUserData(victim)
        if IsTracked(victimId) then
            call InterruptPatrol(victim, victimId)
        endif
    endif
    
    if attacker != null then
        set attackerId = GetUnitUserData(attacker)
        if IsTracked(attackerId) then
            call InterruptPatrol(attacker, attackerId)
        endif
    endif
    
    set victim = null
    set attacker = null
endfunction

//===========================================================================
// PUBLIC API
//===========================================================================

/**
 * Stops patrol and clears data
 */
function PatrolSystem_Stop takes unit u returns nothing
    local integer unitId = GetUnitUserData(u)
    local Table data
    
    if u == null then
        return
    endif
    
    if IsTracked(unitId) then
        set data = patrolData[unitId]
        
        set data.boolean[KEY_SUPPRESS] = true
        call IssueImmediateOrder(u, "stop")
        call IssueImmediateOrder(u, "holdposition")
        
        call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
        
        // Clear data
        call data.flush()
        call unitHandles[unitId].flush()
    endif
    
    set u = null
endfunction

/**
 * Handles unit death - cleanup
 */
private function OnDeath takes nothing returns nothing
    call PatrolSystem_Stop(GetTriggerUnit())
endfunction

/**
 * Sets a waypoint for a unit
 */
function PatrolSystem_SetPoint takes unit u, integer index, real x, real y, real waitT returns nothing
    local integer unitId = GetUnitUserData(u)
    local Table data
    
    if u == null then
        return
    endif
    
    set data = patrolData[unitId]
    set data.real[WAYPOINT_X_OFFSET + index] = x
    set data.real[WAYPOINT_Y_OFFSET + index] = y
    set data.real[WAYPOINT_WAIT_OFFSET + index] = waitT
    
    set u = null
endfunction

/**
 * Starts patrol for a unit
 */
function PatrolSystem_Start takes unit u, integer count, real resetTime, integer pathStyle, boolean autoResume, string moveOrder, real patrolSpeed returns nothing
    local integer unitId = GetUnitUserData(u)
    local Table data
    local integer i = 0
    local real x
    local real y
    local real moveTime
    
    if u == null or count <= 0 then
        return
    endif
    
    // Stop any existing patrol
    call PatrolSystem_Stop(u)
    
    set data = patrolData[unitId]
    
    // Store unit handle (using custom value from Unit Indexer)
    set unitHandles[unitId].unit[0] = u
    
    // Initialize data
    set data.integer[KEY_CURRENT_IDX] = 0
    set data.integer[KEY_COUNT] = count
    set data.integer[KEY_PATH_STYLE] = pathStyle
    set data.integer[KEY_DIRECTION] = 1
    set data.integer[KEY_STATE] = STATE_TRAVELING
    set data.boolean[KEY_AUTO_RESUME] = autoResume
    set data.boolean[KEY_SUPPRESS] = false
    set data.real[KEY_RESET_TIME] = resetTime
    set data.real[KEY_PATROL_SPEED] = patrolSpeed
    set data.string[KEY_MOVE_ORDER] = moveOrder
    
    // Apply patrol speed
    call ApplyPatrolSpeed(u, unitId)
    
    // Load waypoints from GUI arrays
    loop
        exitwhen i >= count
        call PatrolSystem_SetPoint(u, i, GetLocationX(udg_PatrolSystem_Point[i]), GetLocationY(udg_PatrolSystem_Point[i]), udg_PatrolSystem_Wait[i])
        set i = i + 1
    endloop
    
    // Start patrol
    set x = data.real[WAYPOINT_X_OFFSET]
    set y = data.real[WAYPOINT_Y_OFFSET]
    
    call IssuePatrolOrder(u, unitId, x, y)
    set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
    call StartPatrolTimer(u, unitId, moveTime, STATE_TRAVELING)
    
    set u = null
endfunction

/**
 * Pauses patrol
 */
function PatrolSystem_Pause takes unit u returns nothing
    local integer unitId = GetUnitUserData(u)
    local Table data
    
    if not IsTracked(unitId) then
        return
    endif
    
    set data = patrolData[unitId]
    
    set data.boolean[KEY_SUPPRESS] = true
    call IssueImmediateOrder(u, "stop")
    call IssueImmediateOrder(u, "holdposition")
    
    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
    set data.integer[KEY_STATE] = STATE_PAUSED
    
    set u = null
endfunction

/**
 * Resumes patrol if paused
 */
function PatrolSystem_Resume takes unit u returns nothing
    local integer unitId = GetUnitUserData(u)
    local Table data
    local integer state
    local integer currentIdx
    local real x
    local real y
    local real moveTime
    
    if not IsTracked(unitId) then
        return
    endif
    
    set data = patrolData[unitId]
    set state = data.integer[KEY_STATE]
    
    if state == STATE_PAUSED then
        set currentIdx = data.integer[KEY_CURRENT_IDX]
        set x = data.real[WAYPOINT_X_OFFSET + currentIdx]
        set y = data.real[WAYPOINT_Y_OFFSET + currentIdx]
        
        call IssuePatrolOrder(u, unitId, x, y)
        set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
        call StartPatrolTimer(u, unitId, moveTime, STATE_TRAVELING)
    endif
    
    set u = null
endfunction

/**
 * Forces patrol to continue
 */
function PatrolSystem_Continue takes unit u returns nothing
    local integer unitId = GetUnitUserData(u)
    local Table data
    local integer currentIdx
    local real x
    local real y
    local real moveTime
    
    if not IsTracked(unitId) then
        return
    endif
    
    set data = patrolData[unitId]
    set currentIdx = data.integer[KEY_CURRENT_IDX]
    set x = data.real[WAYPOINT_X_OFFSET + currentIdx]
    set y = data.real[WAYPOINT_Y_OFFSET + currentIdx]
    
    call IssuePatrolOrder(u, unitId, x, y)
    set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
    call StartPatrolTimer(u, unitId, moveTime, STATE_TRAVELING)
    
    set u = null
endfunction

/**
 * Changes move order style
 */
function PatrolSystem_Movestyle takes unit u, string newOrder returns nothing
    local integer unitId = GetUnitUserData(u)
    
    if IsTracked(unitId) then
        set patrolData[unitId].string[KEY_MOVE_ORDER] = newOrder
    endif
    
    set u = null
endfunction

//===========================================================================
// INITIALIZATION
//===========================================================================

private function Init takes nothing returns nothing
    set patrolData = Table.create()
    set unitHandles = Table.create()
    
    // Register events
    set orderTrig = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
    call TriggerAddAction(orderTrig, function OnUnitOrder)
    
    set deathTrig = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(deathTrig, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(deathTrig, function OnDeath)
    
    set damageTrig = CreateTrigger()
    call TriggerRegisterVariableEvent(damageTrig, "udg_DamageEvent", EQUAL, 1.00)
    call TriggerAddAction(damageTrig, function OnDamage)
endfunction

endlibrary
