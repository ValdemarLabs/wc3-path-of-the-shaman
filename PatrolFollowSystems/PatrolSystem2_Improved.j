library PatrolSystem2 initializer Init requires Table, TimerUtils

//===========================================================================
/*
    PatrolSystem - Improved Version with Table and TimerUtils
    Author: [Valdemar] (Refactored)

    Description:
    Event-driven patrol system with per-unit timers using Bribe's Table and TimerUtils.

    Features:
    - Ping-pong style waypoint loop
    - Per-waypoint wait times
    - Reset timer after interruption (auto/manual resume)
    - When attacked or attacking, it reverts to its default movement speed
    - Scales to hundreds of NPCs without lag
    - Uses Bribe's Table for efficient data storage
    - Uses TimerUtils for timer recycling

    Path Styles:
        PATROL_STYLE_LOOP (0):
            When the unit reaches the last waypoint, it loops back to the first waypoint.
            Example: A → B → C → A → B → C → ...

        PATROL_STYLE_PINGPONG (1):
            The unit "bounces" back and forth through the waypoints.
            Example: A → B → C → B → A → B → C → ...

    Usage from GUI:
    1. Set variable "PatrolSystem_Point[index]" to your waypoint points
    2. Set variable "PatrolSystem_Wait[index]" to the wait time for each waypoint
        Example:
        Set Variable udg_PatrolSystem_Point[0] = (Center of wp01 <gen>)
        Set Variable udg_PatrolSystem_Wait[0] = 3.00
        Set Variable udg_PatrolSystem_Point[1] = (Center of wp02 <gen>)
        Set Variable udg_PatrolSystem_Wait[1] = 5.00
        ...
    3. To start the patrol:
        call PatrolSystem_Start(udg_TempUnit, 2, 10.00, 1, true, "move", 0)
        // Parameters:
        // - unit u: the unit to patrol
        // - integer count: number of waypoints
        // - real resetTime: time before auto-resuming after interruption
        // - integer pathStyle: 0 (loop) or 1 (ping-pong)
        // - boolean autoResume: auto-continue after reset
        // - string moveOrder: order type ("move", "patrol", "attack")
        // - real patrolSpeed: movement speed (0 = use default)

    4.1 To manually stop patrol:
        call PatrolSystem_Stop(udg_TempUnit)
        - This clears all data. To resume, you must call Start again.

    4.2 To manually pause patrol (can be resumed with Resume):
        call PatrolSystem_Pause(udg_TempUnit)

    5. To manually continue patrol after reset:
        call PatrolSystem_Continue(udg_TempUnit)

    6. To change the move style:
        call PatrolSystem_Movestyle(udg_TempUnit, "patrol")

    Resume = conditional continue (only works if paused).
    Continue = force continue (always works, even if stopped).
*/ 
//===========================================================================

globals
    // Constants
    private constant real EPSILON = 32.00           // Distance tolerance for waypoint arrival
    private constant real ARRIVAL_BUFFER = 0.25     // Extra time buffer for arrival detection
    private constant real RECHECK_INTERVAL = 0.5    // How often to recheck if not arrived
    
    // Path styles (public constants)
    constant integer PATROL_STYLE_LOOP = 0
    constant integer PATROL_STYLE_PINGPONG = 1
    
    // State constants
    private constant integer STATE_PAUSED = 0
    private constant integer STATE_TRAVELING = 1
    private constant integer STATE_WAITING = 2
    private constant integer STATE_RESETTING = 3
    
    // Data storage using Table
    private Table unitData          // Main unit data
    private Table waypointX         // Waypoint X coordinates per unit
    private Table waypointY         // Waypoint Y coordinates per unit
    private Table waypointWait      // Wait times per unit
    private Table moveOrderStr      // Move order strings per unit
    
    // Event triggers
    private trigger orderTrig
    private trigger deathTrig
    private trigger damageTrig
endglobals

//===========================================================================
// DATA ORGANIZATION (using Bribe's Table)
// unitData[unitId] is a Table containing:
//   [0] = isTracked (boolean) - whether unit is being tracked
//   [1] = currentIndex (integer) - current waypoint index
//   [2] = waypointCount (integer) - total number of waypoints
//   [3] = pathStyle (integer) - 0=loop, 1=pingpong
//   [4] = direction (integer) - +1 or -1 for pingpong
//   [5] = state (integer) - current state (paused/traveling/waiting/resetting)
//   [6] = autoResume (boolean) - whether to auto-resume after reset
//   [7] = suppressOrder (boolean) - suppress order event flag
//   [8] = moveOrderId (integer) - the order ID for movement
//   [10] = resetTime (real) - time before auto-resuming
//   [11] = patrolSpeed (real) - patrol movement speed
//
// waypointX[unitId] is a Table containing [index] = x coordinate
// waypointY[unitId] is a Table containing [index] = y coordinate
// waypointWait[unitId] is a Table containing [index] = wait time
// moveOrderStr[unitId] = move order string ("move", "patrol", etc.)
//===========================================================================

//===========================================================================
// UTILITY FUNCTIONS
//===========================================================================

/**
 * Checks if a unit is tracked by the patrol system
 */
private function IsTracked takes integer unitId returns boolean
    return unitData[unitId].boolean[0]
endfunction

/**
 * Calculates squared distance to avoid SquareRoot
 */
private function GetDistanceSq takes real x1, real y1, real x2, real y2 returns real
    local real dx = x2 - x1
    local real dy = y2 - y1
    return dx * dx + dy * dy
endfunction

/**
 * Checks if unit has arrived at waypoint (within EPSILON distance)
 */
private function HasArrived takes unit u, integer unitId, integer waypointIdx returns boolean
    local real ux = GetUnitX(u)
    local real uy = GetUnitY(u)
    local real wx = waypointX[unitId].real[waypointIdx]
    local real wy = waypointY[unitId].real[waypointIdx]
    
    return GetDistanceSq(ux, uy, wx, wy) <= (EPSILON * EPSILON)
endfunction

/**
 * Calculates time needed to move from unit's position to target point
 */
private function CalculateMoveTime takes unit u, real targetX, real targetY returns real
    local real dx = targetX - GetUnitX(u)
    local real dy = targetY - GetUnitY(u)
    local real dist = SquareRoot(dx * dx + dy * dy)
    local real speed = GetUnitMoveSpeed(u)
    
    if speed < 1.0 then
        set speed = 220.0  // Fallback speed
    endif
    
    return dist / speed
endfunction

/**
 * Calculates the next waypoint index based on patrol style
 */
private function GetNextIndex takes integer unitId, integer currentIdx returns integer
    local Table data = unitData[unitId]
    local integer count = data[2]
    local integer style = data[3]
    local integer dir = data[4]
    local integer nextIdx = currentIdx
    
    if style == PATROL_STYLE_LOOP then
        // Loop style: cycle through waypoints
        set nextIdx = ModuloInteger(currentIdx + 1, count)
    else
        // Ping-pong style: bounce back and forth
        set nextIdx = currentIdx + dir
        
        if nextIdx >= count then
            // Hit the end, reverse direction
            set nextIdx = count - 2
            set dir = -1
            set data[4] = dir
        elseif nextIdx < 0 then
            // Hit the start, reverse direction
            set nextIdx = 1
            set dir = 1
            set data[4] = dir
        endif
    endif
    
    return nextIdx
endfunction

/**
 * Issues move order to unit with suppression flag
 */
private function IssuePatrolOrder takes unit u, integer unitId, real x, real y returns nothing
    local string moveOrder = moveOrderStr[unitId].string[0]
    
    // Set suppression flag to ignore our own order event
    set unitData[unitId].boolean[7] = true
    call IssuePointOrder(u, moveOrder, x, y)
endfunction

/**
 * Applies patrol speed to unit
 */
private function ApplyPatrolSpeed takes unit u, integer unitId returns nothing
    local real speed = unitData[unitId].real[11]
    
    if speed > 0 then
        call SetUnitMoveSpeed(u, speed)
    else
        call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
    endif
endfunction

/**
 * Reverts unit to default movement speed
 */
private function RevertToDefaultSpeed takes unit u returns nothing
    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
endfunction

//===========================================================================
// TIMER SYSTEM (using TimerUtils)
//===========================================================================

/**
 * Main timer callback - handles state transitions
 */
private function OnPatrolTimer takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer unitId = GetTimerData(t)  // TimerUtils: retrieve attached unitId
    local unit u
    local Table data = unitData[unitId]
    local integer state
    local integer currentIdx
    local integer nextIdx
    local real x
    local real y
    local real waitTime
    local real moveTime
    
    // Release timer back to pool
    call ReleaseTimer(t)
    
    // Check if unit is still tracked
    if not IsTracked(unitId) then
        return
    endif
    
    // Get unit handle from ID (assumes handle ID is valid)
    set u = GetUnitById(unitId)
    
    // Validate unit
    if u == null or GetUnitTypeId(u) == 0 then
        return
    endif
    
    set state = data[5]
    set currentIdx = data[1]
    
    // Handle paused state (do nothing)
    if state == STATE_PAUSED then
        return
    endif
    
    // Apply patrol speed
    call ApplyPatrolSpeed(u, unitId)
    
    // Handle state-specific logic
    if state == STATE_TRAVELING then
        //===== TRAVELING STATE: Check if arrived at waypoint =====
        if HasArrived(u, unitId, currentIdx) then
            // Arrived! Check if we need to wait
            set waitTime = waypointWait[unitId].real[currentIdx]
            
            if waitTime < 0.01 then
                // No wait time - immediately move to next waypoint
                set nextIdx = GetNextIndex(unitId, currentIdx)
                set data[1] = nextIdx
                
                set x = waypointX[unitId].real[nextIdx]
                set y = waypointY[unitId].real[nextIdx]
                
                call IssuePatrolOrder(u, unitId, x, y)
                set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
                
                set data[5] = STATE_TRAVELING
                set t = NewTimerEx(unitId)
                call TimerStart(t, moveTime, false, function OnPatrolTimer)
            else
                // Wait at this waypoint
                set data[5] = STATE_WAITING
                set t = NewTimerEx(unitId)
                call TimerStart(t, waitTime, false, function OnPatrolTimer)
            endif
        else
            // Not arrived yet - re-issue order and check again soon
            set x = waypointX[unitId].real[currentIdx]
            set y = waypointY[unitId].real[currentIdx]
            
            call IssuePatrolOrder(u, unitId, x, y)
            
            set data[5] = STATE_TRAVELING
            set t = NewTimerEx(unitId)
            call TimerStart(t, RECHECK_INTERVAL, false, function OnPatrolTimer)
        endif
        
    elseif state == STATE_WAITING then
        //===== WAITING STATE: Wait time expired, move to next waypoint =====
        set nextIdx = GetNextIndex(unitId, currentIdx)
        set data[1] = nextIdx
        
        set x = waypointX[unitId].real[nextIdx]
        set y = waypointY[unitId].real[nextIdx]
        
        call IssuePatrolOrder(u, unitId, x, y)
        set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
        
        set data[5] = STATE_TRAVELING
        set t = NewTimerEx(unitId)
        call TimerStart(t, moveTime, false, function OnPatrolTimer)
        
    elseif state == STATE_RESETTING then
        //===== RESETTING STATE: Reset time expired =====
        if data.boolean[6] then
            // Auto-resume enabled - continue patrol
            set x = waypointX[unitId].real[currentIdx]
            set y = waypointY[unitId].real[currentIdx]
            
            call IssuePatrolOrder(u, unitId, x, y)
            set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
            
            set data[5] = STATE_TRAVELING
            set t = NewTimerEx(unitId)
            call TimerStart(t, moveTime, false, function OnPatrolTimer)
        else
            // Auto-resume disabled - stay paused
            set data[5] = STATE_PAUSED
        endif
    endif
    
    set u = null
endfunction

/**
 * Starts a patrol timer with specified state
 */
private function StartPatrolTimer takes unit u, integer unitId, real duration, integer newState returns nothing
    local timer t = NewTimerEx(unitId)  // TimerUtils: attach unitId to timer
    
    set unitData[unitId].integer[5] = newState
    call TimerStart(t, duration, false, function OnPatrolTimer)
endfunction

//===========================================================================
// INTERRUPT HANDLING
//===========================================================================

/**
 * Handles patrol interruption (damage, orders, etc.)
 */
private function InterruptPatrol takes unit u, integer unitId returns nothing
    local Table data = unitData[unitId]
    local real resetTime
    
    // Stop current action
    set data.boolean[7] = true
    call IssueImmediateOrder(u, "stop")
    
    // Revert to default speed
    call RevertToDefaultSpeed(u)
    
    // Handle reset based on auto-resume setting
    if data.boolean[6] then
        // Auto-resume enabled
        set resetTime = data.real[10]
        if resetTime > 0.0 then
            call StartPatrolTimer(u, unitId, resetTime, STATE_RESETTING)
        else
            set data[5] = STATE_PAUSED
        endif
    else
        // Auto-resume disabled - pause
        set data[5] = STATE_PAUSED
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
    local integer unitId = GetHandleId(u)
    local Table data
    local integer orderId
    local integer savedOrderId
    local integer state
    local boolean suppress
    
    // Check if unit is tracked
    if not IsTracked(unitId) then
        return
    endif
    
    set data = unitData[unitId]
    set state = data[5]
    
    // If paused, ignore all order events
    if state == STATE_PAUSED then
        return
    endif
    
    // Check suppression flag (our own orders)
    set suppress = data.boolean[7]
    if suppress then
        set data.boolean[7] = false
        return
    endif
    
    // Check if order matches patrol move order
    set orderId = GetIssuedOrderId()
    set savedOrderId = data[8]
    
    if orderId == savedOrderId then
        return  // Same as patrol order - allow it
    endif
    
    // External order detected - could interrupt patrol
    // Currently we only interrupt on damage (see OnDamage)
    // Uncomment below to interrupt on any non-patrol order:
    // call InterruptPatrol(u, unitId)
    
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
    
    // Check victim
    if victim != null then
        set victimId = GetHandleId(victim)
        if IsTracked(victimId) then
            call InterruptPatrol(victim, victimId)
        endif
    endif
    
    // Check attacker
    if attacker != null then
        set attackerId = GetHandleId(attacker)
        if IsTracked(attackerId) then
            call InterruptPatrol(attacker, attackerId)
        endif
    endif
    
    set victim = null
    set attacker = null
endfunction

/**
 * Handles unit death - cleanup
 */
private function OnDeath takes nothing returns nothing
    call PatrolSystem_Stop(GetTriggerUnit())
endfunction

//===========================================================================
// PUBLIC API
//===========================================================================

/**
 * Sets a waypoint for a unit
 */
function PatrolSystem_SetPoint takes unit u, integer index, real x, real y, real waitT returns nothing
    local integer unitId = GetHandleId(u)
    
    if u == null then
        return
    endif
    
    set waypointX[unitId].real[index] = x
    set waypointY[unitId].real[index] = y
    set waypointWait[unitId].real[index] = waitT
    
    set u = null
endfunction

/**
 * Starts patrol for a unit
 */
function PatrolSystem_Start takes unit u, integer count, real resetTime, integer pathStyle, boolean autoResume, string moveOrder, real patrolSpeed returns nothing
    local integer unitId = GetHandleId(u)
    local Table data
    local integer i = 0
    local real x
    local real y
    local real moveTime
    
    if u == null then
        return
    endif
    
    if count <= 0 then
        return
    endif
    
    // Stop any existing patrol
    call PatrolSystem_Stop(u)
    
    // Initialize unit data table
    set data = unitData[unitId]
    
    set data.boolean[0] = true              // isTracked
    set data[1] = 0                         // currentIndex
    set data[2] = count                     // waypointCount
    set data[3] = pathStyle                 // pathStyle
    set data[4] = 1                         // direction (+1)
    set data[5] = STATE_TRAVELING           // state
    set data.boolean[6] = autoResume        // autoResume
    set data.boolean[7] = false             // suppressOrder
    set data[8] = OrderId(moveOrder)        // moveOrderId
    set data.real[10] = resetTime           // resetTime
    set data.real[11] = patrolSpeed         // patrolSpeed
    
    set moveOrderStr[unitId].string[0] = moveOrder
    
    // Apply patrol speed
    call ApplyPatrolSpeed(u, unitId)
    
    // Load waypoints from GUI arrays
    loop
        exitwhen i >= count
        call PatrolSystem_SetPoint(u, i, GetLocationX(udg_PatrolSystem_Point[i]), GetLocationY(udg_PatrolSystem_Point[i]), udg_PatrolSystem_Wait[i])
        set i = i + 1
    endloop
    
    // Start patrol - move to first waypoint
    set x = waypointX[unitId].real[0]
    set y = waypointY[unitId].real[0]
    
    call IssuePatrolOrder(u, unitId, x, y)
    set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
    call StartPatrolTimer(u, unitId, moveTime, STATE_TRAVELING)
    
    set u = null
endfunction

/**
 * Pauses patrol for a unit
 */
function PatrolSystem_Pause takes unit u returns nothing
    local integer unitId = GetHandleId(u)
    local Table data
    
    if not IsTracked(unitId) then
        return
    endif
    
    set data = unitData[unitId]
    
    // Stop unit
    set data.boolean[7] = true
    call IssueImmediateOrder(u, "stop")
    call IssueImmediateOrder(u, "holdposition")
    
    // Revert speed
    call RevertToDefaultSpeed(u)
    
    // Set state to paused
    set data[5] = STATE_PAUSED
    
    set u = null
endfunction

/**
 * Resumes patrol for a paused unit
 */
function PatrolSystem_Resume takes unit u returns nothing
    local integer unitId = GetHandleId(u)
    local Table data
    local integer state
    local integer currentIdx
    local real x
    local real y
    local real moveTime
    
    if not IsTracked(unitId) then
        return
    endif
    
    set data = unitData[unitId]
    set state = data[5]
    
    // Only resume if paused
    if state == STATE_PAUSED then
        set currentIdx = data[1]
        set x = waypointX[unitId].real[currentIdx]
        set y = waypointY[unitId].real[currentIdx]
        
        call IssuePatrolOrder(u, unitId, x, y)
        set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
        call StartPatrolTimer(u, unitId, moveTime, STATE_TRAVELING)
    endif
    
    set u = null
endfunction

/**
 * Forces unit to continue patrol (even if not paused)
 */
function PatrolSystem_Continue takes unit u returns nothing
    local integer unitId = GetHandleId(u)
    local Table data
    local integer currentIdx
    local real x
    local real y
    local real moveTime
    
    if not IsTracked(unitId) then
        return
    endif
    
    set data = unitData[unitId]
    set currentIdx = data[1]
    set x = waypointX[unitId].real[currentIdx]
    set y = waypointY[unitId].real[currentIdx]
    
    call IssuePatrolOrder(u, unitId, x, y)
    set moveTime = CalculateMoveTime(u, x, y) + ARRIVAL_BUFFER
    call StartPatrolTimer(u, unitId, moveTime, STATE_TRAVELING)
    
    set u = null
endfunction

/**
 * Stops patrol and clears all data for a unit
 */
function PatrolSystem_Stop takes unit u returns nothing
    local integer unitId = GetHandleId(u)
    local Table data
    
    if u == null then
        return
    endif
    
    // Only clear if tracked
    if IsTracked(unitId) then
        set data = unitData[unitId]
        
        // Stop unit
        set data.boolean[7] = true
        call IssueImmediateOrder(u, "stop")
        call IssueImmediateOrder(u, "holdposition")
        
        // Revert speed
        call RevertToDefaultSpeed(u)
        
        // Clear all data for this unit
        call data.flush()
        call waypointX[unitId].flush()
        call waypointY[unitId].flush()
        call waypointWait[unitId].flush()
        call moveOrderStr[unitId].flush()
    endif
    
    set u = null
endfunction

/**
 * Changes the move order style for a unit
 */
function PatrolSystem_Movestyle takes unit u, string newOrder returns nothing
    local integer unitId = GetHandleId(u)
    local Table data
    
    if IsTracked(unitId) then
        set data = unitData[unitId]
        set moveOrderStr[unitId].string[0] = newOrder
        set data[8] = OrderId(newOrder)
    endif
    
    set u = null
endfunction

//===========================================================================
// INITIALIZATION
//===========================================================================

private function Init takes nothing returns nothing
    // Initialize tables
    set unitData = Table.create()
    set waypointX = Table.create()
    set waypointY = Table.create()
    set waypointWait = Table.create()
    set moveOrderStr = Table.create()
    
    // Register order events
    set orderTrig = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
    call TriggerAddAction(orderTrig, function OnUnitOrder)
    
    // Register death event
    set deathTrig = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(deathTrig, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(deathTrig, function OnDeath)
    
    // Register damage event (requires Damage Engine)
    set damageTrig = CreateTrigger()
    call TriggerRegisterVariableEvent(damageTrig, "udg_DamageEvent", EQUAL, 1.00)
    call TriggerAddAction(damageTrig, function OnDamage)
endfunction

endlibrary
