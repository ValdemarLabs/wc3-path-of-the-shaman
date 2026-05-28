library PatrolSystem initializer Init requires UnitDeathEvent
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

    GROUP PATROL USAGE:
    -------------------
    Group patrol allows multiple units to patrol together while maintaining formation.

    1. Create a unit group and set waypoints (same as single unit patrol)
        Set Variable udg_PatrolSystem_Point[0] = (Center of wp01 <gen>)
        Set Variable udg_PatrolSystem_Wait[0] = 3.00
        ...

    2. Start group patrol:
        Set udg_TempGroup = (Units in (Playable map area) matching ((Unit-type of (Matching unit)) Equal to Footman))
        Set udg_TempInteger = PatrolSystem_GroupStart(udg_TempGroup, 3, 10.00, 0, true, "move", 250.00)
        // Returns a groupId (store in variable for later control)
        // Parameters: group, waypointCount, resetTime, pathStyle, autoResume, moveOrder, patrolSpeed

    3. Control group patrol:
        call PatrolSystem_GroupPause(udg_TempInteger)    // Pause the group
        call PatrolSystem_GroupResume(udg_TempInteger)   // Resume the group
        call PatrolSystem_GroupStop(udg_TempInteger)     // Stop and cleanup
        call PatrolSystem_GroupContinue(udg_TempInteger) // Force continue

    Features:
    - Units maintain their relative formation throughout patrol
    - When one unit is attacked, the entire group pauses/resets together
    - Group acts as a cohesive unit during patrol
    - Individual units that die are automatically removed from the group

*/ 
//===========================================================================

globals
    private hashtable ht = InitHashtable()
    private hashtable grpHt = InitHashtable()  // Group patrol hashtable
    private constant real EPSILON = 32.00
    private constant real GROUP_EPSILON = 300.00  // Larger threshold for group patrols

    // Path styles
    constant integer PATROL_STYLE_LOOP = 0
    constant integer PATROL_STYLE_PINGPONG = 1

    private trigger orderTrig
    private trigger damageTrig
    
    // Group patrol tracking
    private integer nextGroupId = 1
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
//   100: groupId (integer) — if unit belongs to a patrol group
// Per-waypoint data (0..N-1)
//   1000+idx : x
//   2000+idx : y
//   3000+idx : wait
//
// Group patrol hashtable keys (child = groupId)
//   0  : group handle
//   1  : timer handle
//   2  : current waypoint index
//   3  : resetTime
//   4  : state (0=paused,1=travel,2=wait,3=reset)
//   5  : direction (+1 / -1)
//   6  : count (num waypoints)
//   7  : autoContinue (boolean)
//   8  : pathStyle (0=loop,1=pingpong)
//   9  : move order string
//   10 : patrol speed
//   11 : unit count (number of units in group)
//   50 : suppress (boolean)
//   1000+idx : x (waypoint)
//   2000+idx : y (waypoint)
//   3000+idx : wait (waypoint)
//   10000+unitIdx : unit handle (for each unit in group)
//   11000+unitIdx : offset x (relative to group center)
//   12000+unitIdx : offset y (relative to group center)
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

    // Apply patrol speed only when actively patrolling (state 1, 2, or 3)
    if state == 1 or state == 2 or state == 3 then
        if patrolSpd > 0 then
            call SetUnitMoveSpeed(u, patrolSpd)
        else
            call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
        endif
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

// ===================== GROUP PATROL HELPERS ============
// Adapted NextIndex for groups
private function NextIndexGroup takes integer groupId, integer idx returns integer
    local integer count = LoadInteger(grpHt, groupId, 6)
    local integer style = LoadInteger(grpHt, groupId, 8)
    local integer dir = LoadInteger(grpHt, groupId, 5)

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
        call SaveInteger(grpHt, groupId, 5, dir)
    endif
    return idx
endfunction

// Timer callback for group patrol
private function GroupTimerExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer groupId = LoadInteger(ht, GetHandleId(t), 0)
    local integer state
    local integer idx
    local real x
    local real y
    local real wait
    local string order
    local real patrolSpd
    local integer unitCount
    local integer i
    local unit u
    local real offsetX
    local real offsetY
    local real dist
    
    call BJDebugMsg("[GroupTimerExpire] === CALLBACK FIRED ===")
    
    if groupId <= 0 then
        call BJDebugMsg("[GroupTimerExpire] ERROR: Invalid groupId=" + I2S(groupId))
        return
    endif
    
    call BJDebugMsg("[GroupTimerExpire] GroupID=" + I2S(groupId))
    
    set state = LoadInteger(grpHt, groupId, 4)
    set idx = LoadInteger(grpHt, groupId, 2)
    set patrolSpd = LoadReal(grpHt, groupId, 10)
    set unitCount = LoadInteger(grpHt, groupId, 11)  // Get unit count from key 11
    set order = LoadStr(grpHt, groupId, 9)
    
    call BJDebugMsg("[GroupTimerExpire] State=" + I2S(state) + ", WaypointIdx=" + I2S(idx) + ", UnitCount=" + I2S(unitCount))
    
    // Exit if paused
    if state == 0 then
        call BJDebugMsg("[GroupTimerExpire] PAUSED - exiting")
        return
    endif
    
    // Apply patrol speed to all units when actively patrolling
    if state == 1 or state == 2 or state == 3 then
        set i = 0
        loop
            exitwhen i >= unitCount
            set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
            if u != null and GetUnitTypeId(u) != 0 then
                if patrolSpd > 0 then
                    call SetUnitMoveSpeed(u, patrolSpd)
                else
                    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
                endif
            endif
            set i = i + 1
        endloop
    endif
    
    // Handle state transitions (similar to single unit patrol)
    if state == 1 then
        call BJDebugMsg("[GroupTimerExpire] STATE 1: Traveling to waypoint")
        // Check if group has arrived at waypoint
        set x = LoadReal(grpHt, groupId, 1000 + idx)
        set y = LoadReal(grpHt, groupId, 2000 + idx)
        set wait = LoadReal(grpHt, groupId, 3000 + idx)
        
        call BJDebugMsg("[GroupTimerExpire] Target waypoint: (" + R2S(x) + ", " + R2S(y) + "), wait=" + R2S(wait))
        
        // Validate waypoint before proceeding
        if x == 0 and y == 0 then
            call BJDebugMsg("[GroupTimerExpire] ERROR: Waypoint " + I2S(idx) + " is (0,0), patrol data corrupted! Pausing.")
            call SaveInteger(grpHt, groupId, 4, 0)
            return
        endif
        
        // For simplicity, check if first unit is close enough
        set u = LoadUnitHandle(grpHt, groupId, 10000 + 0)
        if u != null then
            set dist = SquareRoot((GetUnitX(u) - x) * (GetUnitX(u) - x) + (GetUnitY(u) - y) * (GetUnitY(u) - y))
            call BJDebugMsg("[GroupTimerExpire] First unit distance: " + R2S(dist) + ", threshold=" + R2S(GROUP_EPSILON))
        else
            call BJDebugMsg("[GroupTimerExpire] ERROR: First unit is null!")
            return
        endif
        
        if dist <= GROUP_EPSILON then
            call BJDebugMsg("[GroupTimerExpire] ARRIVED at waypoint!")
            if wait < 0.01 then
                call BJDebugMsg("[GroupTimerExpire] No wait time, moving to next waypoint")
                // Move to next waypoint immediately
                set idx = NextIndexGroup(groupId, idx)
                call SaveInteger(grpHt, groupId, 2, idx)
                set x = LoadReal(grpHt, groupId, 1000 + idx)
                set y = LoadReal(grpHt, groupId, 2000 + idx)
                
                call BJDebugMsg("[GroupTimerExpire] Next waypoint: (" + R2S(x) + ", " + R2S(y) + ")")
                
                // Order all units with formation offset
                call SaveBoolean(grpHt, groupId, 50, true)
                set i = 0
                loop
                    exitwhen i >= unitCount
                    set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
                    if u != null and GetUnitTypeId(u) != 0 then
                        set offsetX = LoadReal(grpHt, groupId, 11000 + i)
                        set offsetY = LoadReal(grpHt, groupId, 12000 + i)
                        call SaveBoolean(ht, GetHandleId(u), 50, true)
                        call IssuePointOrder(u, order, x + offsetX, y + offsetY)
                    endif
                    set i = i + 1
                endloop
                
                call TimerStart(t, MoveTime(u, x, y) + 0.25, false, function GroupTimerExpire)
                call SaveInteger(grpHt, groupId, 4, 1)
                call BJDebugMsg("[GroupTimerExpire] Timer restarted for travel")
            else
                call BJDebugMsg("[GroupTimerExpire] Waiting at waypoint for " + R2S(wait) + " seconds")
                // Wait at waypoint
                call SaveInteger(grpHt, groupId, 4, 2)
                call TimerStart(t, wait, false, function GroupTimerExpire)
            endif
        else
            call BJDebugMsg("[GroupTimerExpire] Not arrived yet, re-checking in 0.5s")
            // Re-check arrival
            call TimerStart(t, 0.5, false, function GroupTimerExpire)
        endif
    elseif state == 2 then
        call BJDebugMsg("[GroupTimerExpire] STATE 2: Finished waiting, moving to next")
        // Finished waiting, move to next
        set idx = NextIndexGroup(groupId, idx)
        call SaveInteger(grpHt, groupId, 2, idx)
        set x = LoadReal(grpHt, groupId, 1000 + idx)
        set y = LoadReal(grpHt, groupId, 2000 + idx)
        
        call BJDebugMsg("[GroupTimerExpire] Next waypoint after wait: (" + R2S(x) + ", " + R2S(y) + ")")
        
        // Validate waypoint
        if x == 0 and y == 0 then
            call BJDebugMsg("[GroupTimerExpire] ERROR: Next waypoint " + I2S(idx) + " is (0,0), patrol data corrupted! Pausing.")
            call SaveInteger(grpHt, groupId, 4, 0)
            return
        endif
        
        call SaveBoolean(grpHt, groupId, 50, true)
        set i = 0
        loop
            exitwhen i >= unitCount
            set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
            if u != null and GetUnitTypeId(u) != 0 then
                set offsetX = LoadReal(grpHt, groupId, 11000 + i)
                set offsetY = LoadReal(grpHt, groupId, 12000 + i)
                call SaveBoolean(ht, GetHandleId(u), 50, true)
                call IssuePointOrder(u, order, x + offsetX, y + offsetY)
            endif
            set i = i + 1
        endloop
        
        call TimerStart(t, MoveTime(LoadUnitHandle(grpHt, groupId, 10000 + 0), x, y), false, function GroupTimerExpire)
        call SaveInteger(grpHt, groupId, 4, 1)
    elseif state == 3 then
        call BJDebugMsg("[GroupTimerExpire] STATE 3: Reset done, auto-continuing...")
        // Reset done
        if LoadBoolean(grpHt, groupId, 7) then
            // Auto-continue
            set idx = LoadInteger(grpHt, groupId, 2)
            set x = LoadReal(grpHt, groupId, 1000 + idx)
            set y = LoadReal(grpHt, groupId, 2000 + idx)
            
            call BJDebugMsg("[GroupTimerExpire] Continuing to waypoint " + I2S(idx) + ": (" + R2S(x) + ", " + R2S(y) + ")")
            
            // Validate waypoint is not (0,0) before issuing orders
            if x == 0 and y == 0 then
                call BJDebugMsg("[GroupTimerExpire] ERROR: Waypoint is (0,0), patrol data may be corrupted! Pausing patrol.")
                call SaveInteger(grpHt, groupId, 4, 0)
                return
            endif
            
            call SaveBoolean(grpHt, groupId, 50, true)
            set i = 0
            loop
                exitwhen i >= unitCount
                set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
                if u != null and GetUnitTypeId(u) != 0 then
                    set offsetX = LoadReal(grpHt, groupId, 11000 + i)
                    set offsetY = LoadReal(grpHt, groupId, 12000 + i)
                    call SaveBoolean(ht, GetHandleId(u), 50, true)
                    call IssuePointOrder(u, order, x + offsetX, y + offsetY)
                endif
                set i = i + 1
            endloop
            
            call TimerStart(t, MoveTime(LoadUnitHandle(grpHt, groupId, 10000 + 0), x, y), false, function GroupTimerExpire)
            call SaveInteger(grpHt, groupId, 4, 1)
        else
            call SaveInteger(grpHt, groupId, 4, 0)
        endif
    endif
endfunction

// ===================== DAMAGE EVENTS ====================
// This is used to pause patrol if unit is damaged
private function OnDamage takes nothing returns nothing
    local integer id
    local timer t
    local real resetTime
    local unit victim = udg_DamageEventTarget
    local unit attacker = udg_DamageEventSource
    local integer groupId
    local timer groupTimer
    local integer unitCount
    local integer i
    local unit u

    // Check both victim and attacker for patrol interruption
    // -------------------
    // VICTIM
    // -------------------
    // If victim is the patrolling Unit, pause it
    if victim != null then
        set id = GetHandleId(victim)
        
        // Check if unit belongs to a group patrol
        set groupId = LoadInteger(ht, id, 100)
        if groupId > 0 then
            // Pause entire group
            set groupTimer = LoadTimerHandle(grpHt, groupId, 1)
            if groupTimer != null then
                call PauseTimer(groupTimer)
            endif
            
            // Stop all units in group and revert speeds
            set unitCount = LoadInteger(grpHt, groupId, 11)  // Get unit count from key 11
            set i = 0
            loop
                exitwhen i >= unitCount
                set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
                if u != null and GetUnitTypeId(u) != 0 then
                    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
                    call SaveBoolean(ht, GetHandleId(u), 50, true)
                    call IssueImmediateOrder(u, "stop")
                endif
                set i = i + 1
            endloop
            
            // Handle reset
            if LoadBoolean(grpHt, groupId, 7) then
                set resetTime = LoadReal(grpHt, groupId, 3)
                if resetTime > 0.0 then
                    call SaveInteger(grpHt, groupId, 4, 3)
                    call TimerStart(groupTimer, resetTime, false, function GroupTimerExpire)
                else
                    call SaveInteger(grpHt, groupId, 4, 0)
                endif
            else
                call SaveInteger(grpHt, groupId, 4, 0)
            endif
        elseif HaveSavedHandle(ht, id, 0) then
            // Single unit patrol
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
        
        // Check if unit belongs to a group patrol
        set groupId = LoadInteger(ht, id, 100)
        if groupId > 0 then
            // Pause entire group
            set groupTimer = LoadTimerHandle(grpHt, groupId, 1)
            if groupTimer != null then
                call PauseTimer(groupTimer)
            endif
            
            // Stop all units in group and revert speeds
            set unitCount = LoadInteger(grpHt, groupId, 11)  // Get unit count from key 11
            set i = 0
            loop
                exitwhen i >= unitCount
                set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
                if u != null and GetUnitTypeId(u) != 0 then
                    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
                    call SaveBoolean(ht, GetHandleId(u), 50, true)
                    call IssueImmediateOrder(u, "stop")
                endif
                set i = i + 1
            endloop
            
            // Handle reset
            if LoadBoolean(grpHt, groupId, 7) then
                set resetTime = LoadReal(grpHt, groupId, 3)
                if resetTime > 0.0 then
                    call SaveInteger(grpHt, groupId, 4, 3)
                    call TimerStart(groupTimer, resetTime, false, function GroupTimerExpire)
                else
                    call SaveInteger(grpHt, groupId, 4, 0)
                endif
            else
                call SaveInteger(grpHt, groupId, 4, 0)
            endif
        elseif HaveSavedHandle(ht, id, 0) then
            // Single unit patrol
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

// Get group center position
private function GetGroupCenter takes integer groupId returns nothing
    local integer unitCount = LoadInteger(grpHt, groupId, 11)  // Get unit count from key 11
    local integer i = 0
    local unit u
    local real sumX = 0
    local real sumY = 0
    local real centerX
    local real centerY
    
    loop
        exitwhen i >= unitCount
        set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
        if u != null and GetUnitTypeId(u) != 0 then
            set sumX = sumX + GetUnitX(u)
            set sumY = sumY + GetUnitY(u)
        endif
        set i = i + 1
    endloop
    
    if unitCount > 0 then
        set centerX = sumX / unitCount
        set centerY = sumY / unitCount
    endif
endfunction

// Calculate and store initial formation offsets
private function CalculateFormationOffsets takes integer groupId returns nothing
    local integer unitCount = LoadInteger(grpHt, groupId, 11)  // Get unit count from key 11
    local integer i = 0
    local unit u
    local real sumX = 0
    local real sumY = 0
    local real centerX
    local real centerY
    
    // Calculate center
    loop
        exitwhen i >= unitCount
        set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
        if u != null and GetUnitTypeId(u) != 0 then
            set sumX = sumX + GetUnitX(u)
            set sumY = sumY + GetUnitY(u)
        endif
        set i = i + 1
    endloop
    
    if unitCount > 0 then
        set centerX = sumX / unitCount
        set centerY = sumY / unitCount
        
        // Store offsets
        set i = 0
        loop
            exitwhen i >= unitCount
            set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
            if u != null and GetUnitTypeId(u) != 0 then
                call SaveReal(grpHt, groupId, 11000 + i, GetUnitX(u) - centerX)
                call SaveReal(grpHt, groupId, 12000 + i, GetUnitY(u) - centerY)
            endif
            set i = i + 1
        endloop
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

    // Revert to default move speed before pausing
    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))

    // Suppress our own order event before issuing stop
    call SaveBoolean(ht, id, 50, true)
    call IssueImmediateOrder(u, "stop")
    call IssueImmediateOrder(u, "holdposition")

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

    // Revert to default move speed before stopping
    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))

    // Suppress so the "stop" order doesn't trigger OnIssuedOrder logic
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

// ===================== GROUP PATROL PUBLIC API =========
// Set waypoint for a group (must be called before PatrolSystem_GroupStart)
function PatrolSystem_GroupSetWaypoint takes integer groupId, integer index, real x, real y, real waitT returns nothing
    call BJDebugMsg("[PatrolSystem_GroupSetWaypoint] GroupID=" + I2S(groupId) + ", Index=" + I2S(index) + ", Pos=(" + R2S(x) + "," + R2S(y) + "), Wait=" + R2S(waitT))
    
    if groupId <= 0 then
        call BJDebugMsg("[PatrolSystem_GroupSetWaypoint] ERROR: Invalid groupId!")
        return
    endif
    
    call SaveReal(grpHt, groupId, 1000 + index, x)
    call SaveReal(grpHt, groupId, 2000 + index, y)
    call SaveReal(grpHt, groupId, 3000 + index, waitT)
    
    call BJDebugMsg("[PatrolSystem_GroupSetWaypoint] Saved to hashtable successfully")
endfunction

// Initialize group patrol (allocates groupId and stores units, but doesn't start movement)
// Returns the groupId for later reference
function PatrolSystem_GroupInit takes group g, integer waypointCount, real resetTime, integer pathStyle, boolean autoResume, string moveOrder, real patrolSpeed returns integer
    local integer groupId = nextGroupId
    local integer unitCount = 0
    local unit u
    local integer i
    
    call BJDebugMsg("[PatrolSystem_GroupInit] Called with waypointCount=" + I2S(waypointCount))
    
    if g == null or waypointCount <= 0 then
        call BJDebugMsg("[PatrolSystem_GroupInit] ERROR: group is null or waypointCount <= 0")
        return 0
    endif
    
    set nextGroupId = nextGroupId + 1
    
    call BJDebugMsg("[PatrolSystem_GroupInit] Assigned GroupID: " + I2S(groupId))
    
    // Count and store units
    set i = 0
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null
        call GroupRemoveUnit(g, u)
        
        // Store unit in group data
        call SaveUnitHandle(grpHt, groupId, 10000 + i, u)
        
        // Mark unit as belonging to this group
        call SaveInteger(ht, GetHandleId(u), 100, groupId)
        
        call BJDebugMsg("[PatrolSystem_GroupInit] Stored unit " + I2S(i) + ": " + GetUnitName(u))
        set i = i + 1
    endloop
    set unitCount = i
    
    call BJDebugMsg("[PatrolSystem_GroupInit] Total units stored: " + I2S(unitCount))
    
    // Save group settings
    call SaveInteger(grpHt, groupId, 6, waypointCount)  // Waypoint count
    call SaveInteger(grpHt, groupId, 11, unitCount)     // Unit count
    call SaveInteger(grpHt, groupId, 2, 0)              // current waypoint = 0
    call SaveInteger(grpHt, groupId, 5, 1)              // direction = forward
    call SaveInteger(grpHt, groupId, 8, pathStyle)
    call SaveReal(grpHt, groupId, 3, resetTime)
    call SaveBoolean(grpHt, groupId, 7, autoResume)
    call SaveStr(grpHt, groupId, 9, moveOrder)
    call SaveReal(grpHt, groupId, 10, patrolSpeed)
    call SaveInteger(grpHt, groupId, 4, 0)              // state = paused (not started yet)
    
    call BJDebugMsg("[PatrolSystem_GroupInit] Returning groupId: " + I2S(groupId))
    
    return groupId
endfunction

// Start patrol for a group of units (starts actual movement)
// Must be called after GroupInit and GroupSetWaypoint
function PatrolSystem_GroupStart takes integer groupId returns nothing
    local integer unitCount
    local timer t
    local integer i
    local real x
    local real y
    local real offsetX
    local real offsetY
    local unit u
    local string moveOrder
    local real patrolSpeed
    local integer waypointCount
    
    call BJDebugMsg("[PatrolSystem_GroupStart] Called with groupId=" + I2S(groupId))
    
    if groupId <= 0 then
        call BJDebugMsg("[PatrolSystem_GroupStart] ERROR: Invalid groupId")
        return
    endif
    
    set unitCount = LoadInteger(grpHt, groupId, 11)
    set moveOrder = LoadStr(grpHt, groupId, 9)
    set patrolSpeed = LoadReal(grpHt, groupId, 10)
    set waypointCount = LoadInteger(grpHt, groupId, 6)
    
    // Verify waypoints exist
    if waypointCount <= 0 then
        call BJDebugMsg("[PatrolSystem_GroupStart] ERROR: No waypoints set")
        return
    endif
    
    // Get first waypoint and verify it's valid (not 0,0)
    set x = LoadReal(grpHt, groupId, 1000 + 0)
    set y = LoadReal(grpHt, groupId, 2000 + 0)
    
    if x == 0 and y == 0 then
        call BJDebugMsg("[PatrolSystem_GroupStart] ERROR: First waypoint is (0,0) - waypoints not properly set!")
        return
    endif
    
    // Debug waypoints
    set i = 0
    loop
        exitwhen i >= 3 or i >= waypointCount
        set x = LoadReal(grpHt, groupId, 1000 + i)
        set y = LoadReal(grpHt, groupId, 2000 + i)
        call BJDebugMsg("[PatrolSystem_GroupStart] Waypoint " + I2S(i) + ": (" + R2S(x) + ", " + R2S(y) + ")")
        set i = i + 1
    endloop
    
    // Calculate formation offsets based on current unit positions
    call CalculateFormationOffsets(groupId)
    
    // Create timer if not exists
    set t = LoadTimerHandle(grpHt, groupId, 1)
    if t == null then
        set t = CreateTimer()
        call SaveTimerHandle(grpHt, groupId, 1, t)
        call SaveInteger(ht, GetHandleId(t), 0, groupId)
    endif
    
    // Get first waypoint coordinates again (after validation)
    set x = LoadReal(grpHt, groupId, 1000 + 0)
    set y = LoadReal(grpHt, groupId, 2000 + 0)
    
    call BJDebugMsg("[PatrolSystem_GroupStart] Starting patrol to first waypoint: (" + R2S(x) + ", " + R2S(y) + ")")
    
    // Apply patrol speed and order all units to first waypoint
    call SaveBoolean(grpHt, groupId, 50, true)
    set i = 0
    loop
        exitwhen i >= unitCount
        set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
        if u != null and GetUnitTypeId(u) != 0 then
            if patrolSpeed > 0 then
                call SetUnitMoveSpeed(u, patrolSpeed)
            else
                call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
            endif
            
            set offsetX = LoadReal(grpHt, groupId, 11000 + i)
            set offsetY = LoadReal(grpHt, groupId, 12000 + i)
            call SaveBoolean(ht, GetHandleId(u), 50, true)
            call IssuePointOrder(u, moveOrder, x + offsetX, y + offsetY)
            call BJDebugMsg("[PatrolSystem_GroupStart] Ordered unit " + I2S(i) + " to (" + R2S(x + offsetX) + ", " + R2S(y + offsetY) + ")")
        endif
        set i = i + 1
    endloop
    
    // Start timer
    call SaveInteger(grpHt, groupId, 4, 1)
    set u = LoadUnitHandle(grpHt, groupId, 10000 + 0)
    if u != null then
        call TimerStart(t, MoveTime(u, x, y) + 0.25, false, function GroupTimerExpire)
        call BJDebugMsg("[PatrolSystem_GroupStart] Timer started")
    endif
endfunction

// Pause group patrol
function PatrolSystem_GroupPause takes integer groupId returns nothing
    local timer t = LoadTimerHandle(grpHt, groupId, 1)
    local integer unitCount = LoadInteger(grpHt, groupId, 11)  // Get unit count from key 11
    local integer i = 0
    local unit u
    
    if groupId <= 0 then
        return
    endif
    
    if t != null then
        call PauseTimer(t)
    endif
    
    // Revert all units to default speed and stop them
    loop
        exitwhen i >= unitCount
        set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
        if u != null and GetUnitTypeId(u) != 0 then
            call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
            call SaveBoolean(ht, GetHandleId(u), 50, true)
            call IssueImmediateOrder(u, "stop")
            call IssueImmediateOrder(u, "holdposition")
        endif
        set i = i + 1
    endloop
    
    call SaveInteger(grpHt, groupId, 4, 0)
endfunction

// Resume group patrol
function PatrolSystem_GroupResume takes integer groupId returns nothing
    local integer state = LoadInteger(grpHt, groupId, 4)
    local timer t = LoadTimerHandle(grpHt, groupId, 1)
    local integer idx = LoadInteger(grpHt, groupId, 2)
    local integer unitCount = LoadInteger(grpHt, groupId, 11)  // Get unit count from key 11
    local string moveOrder = LoadStr(grpHt, groupId, 9)
    local real x
    local real y
    local real offsetX
    local real offsetY
    local integer i
    local unit u
    
    if groupId <= 0 or state != 0 then
        return
    endif
    
    set x = LoadReal(grpHt, groupId, 1000 + idx)
    set y = LoadReal(grpHt, groupId, 2000 + idx)
    
    call SaveBoolean(grpHt, groupId, 50, true)
    set i = 0
    loop
        exitwhen i >= unitCount
        set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
        if u != null and GetUnitTypeId(u) != 0 then
            set offsetX = LoadReal(grpHt, groupId, 11000 + i)
            set offsetY = LoadReal(grpHt, groupId, 12000 + i)
            call SaveBoolean(ht, GetHandleId(u), 50, true)
            call IssuePointOrder(u, moveOrder, x + offsetX, y + offsetY)
        endif
        set i = i + 1
    endloop
    
    call SaveInteger(grpHt, groupId, 4, 1)
    call TimerStart(t, MoveTime(LoadUnitHandle(grpHt, groupId, 10000 + 0), x, y), false, function GroupTimerExpire)
endfunction

// Stop group patrol completely
function PatrolSystem_GroupStop takes integer groupId returns nothing
    local timer t = LoadTimerHandle(grpHt, groupId, 1)
    local integer unitCount = LoadInteger(grpHt, groupId, 11)  // Get unit count from key 11
    local integer i = 0
    local unit u
    
    if groupId <= 0 then
        return
    endif
    
    // Revert all units to default speed and stop them
    loop
        exitwhen i >= unitCount
        set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
        if u != null and GetUnitTypeId(u) != 0 then
            call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
            call SaveBoolean(ht, GetHandleId(u), 50, true)
            call IssueImmediateOrder(u, "stop")
            call IssueImmediateOrder(u, "holdposition")
            
            // Remove group membership
            call RemoveSavedInteger(ht, GetHandleId(u), 100)
        endif
        set i = i + 1
    endloop
    
    // Cleanup timer
    if t != null then
        call PauseTimer(t)
        call DestroyTimer(t)
    endif
    
    // Flush group data
    call FlushChildHashtable(grpHt, groupId)
endfunction

// Continue group patrol (force continue)
function PatrolSystem_GroupContinue takes integer groupId returns nothing
    local timer t = LoadTimerHandle(grpHt, groupId, 1)
    local integer idx = LoadInteger(grpHt, groupId, 2)
    local integer unitCount = LoadInteger(grpHt, groupId, 11)  // Get unit count from key 11
    local string moveOrder = LoadStr(grpHt, groupId, 9)
    local real x
    local real y
    local real offsetX
    local real offsetY
    local integer i
    local unit u
    
    if groupId <= 0 then
        return
    endif
    
    set x = LoadReal(grpHt, groupId, 1000 + idx)
    set y = LoadReal(grpHt, groupId, 2000 + idx)
    
    call SaveBoolean(grpHt, groupId, 50, true)
    set i = 0
    loop
        exitwhen i >= unitCount
        set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
        if u != null and GetUnitTypeId(u) != 0 then
            set offsetX = LoadReal(grpHt, groupId, 11000 + i)
            set offsetY = LoadReal(grpHt, groupId, 12000 + i)
            call SaveBoolean(ht, GetHandleId(u), 50, true)
            call IssuePointOrder(u, moveOrder, x + offsetX, y + offsetY)
        endif
        set i = i + 1
    endloop
    
    call SaveInteger(grpHt, groupId, 4, 1)
    call TimerStart(t, MoveTime(LoadUnitHandle(grpHt, groupId, 10000 + 0), x, y), false, function GroupTimerExpire)
endfunction

// ===================== CLEANUP =========================
private function OnDeath takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer id = GetHandleId(u)
    local integer groupId = LoadInteger(ht, id, 100)
    
    call BJDebugMsg("[PatrolSystem OnDeath] Unit died: " + GetUnitName(u))
    
    // If unit belongs to a group, mark it for removal but don't disrupt the patrol
    if groupId > 0 then
        call BJDebugMsg("[PatrolSystem OnDeath] Unit belonged to groupId: " + I2S(groupId))
        call RemoveSavedInteger(ht, id, 100)
        // Note: We don't remove the unit from grpHt storage as it would mess up indices
        // The unit handle will become null naturally, and we rely on null checks when iterating
        // The patrol will continue with remaining living units
    endif
    
    // Clean up single unit patrol data (but not group patrol data)
    if HaveSavedHandle(ht, id, 0) and groupId == 0 then
        call BJDebugMsg("[PatrolSystem OnDeath] Cleaning up single unit patrol")
        call FlushUnit(u)
    endif
endfunction

private function Init takes nothing returns nothing
    // Orders (any type)
    set orderTrig = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
    call TriggerAddAction(orderTrig, function OnIssuedOrder)

    // Register with centralized death event system
    call UnitDeathEvent_Register(function OnDeath)

    // Requires Damage Engine
    set damageTrig = CreateTrigger()
    call TriggerRegisterVariableEvent(damageTrig, "udg_DamageEvent", EQUAL, 1.00)
    call TriggerAddAction(damageTrig, function OnDamage)
    
    call BJDebugMsg("[PatrolSystem] Initialized and registered with UnitDeathEvent")
endfunction

endlibrary
