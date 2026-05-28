library PatrolSystem initializer Init requires Table, UnitDeathEvent
//===========================================================================
/*
    Unified PatrolSystem
    Author: [Valdemar]
    
    A complete patrol system supporting both single units and unit groups,
    unified under one library using Bribe's Table for all data storage.

    Features:
    - Single unit patrols
    - Group patrols with formation maintenance
    - Ping-pong or loop patrol styles
    - Per-waypoint wait times
    - Auto-resume after interruption
    - Configurable patrol speeds
    - Event-driven architecture
    - No hashtable/Table mixing issues

    SINGLE UNIT PATROL USAGE:
    -------------------------
    1. Set waypoints in GUI variables:
        Set PatrolSystem_Point[0] = (Center of wp01 <gen>)
        Set PatrolSystem_Wait[0] = 3.00
        Set PatrolSystem_Point[1] = (Center of wp02 <gen>)
        Set PatrolSystem_Wait[1] = 5.00
        
    2. Start patrol:
        call PatrolSystem_Start(udg_TempUnit, 2, 10.00, PATROL_STYLE_PINGPONG, true, "move", 250.0)
        
    3. Control functions:
        call PatrolSystem_Stop(udg_TempUnit)      // Complete stop
        call PatrolSystem_Pause(udg_TempUnit)     // Pause (can resume)
        call PatrolSystem_Resume(udg_TempUnit)    // Resume if paused
        call PatrolSystem_Continue(udg_TempUnit)  // Force continue
        
    GROUP PATROL USAGE:
    ------------------
    1. Set waypoints (same as single unit)
    
    2. Start group patrol:
        Set udg_TempGroup = (Units in region matching condition)
        Set udg_TempInteger = PatrolSystem_GroupStart(udg_TempGroup, 3, 10.00, PATROL_STYLE_LOOP, true, "move", 250.0)
        
    3. Control group:
        call PatrolSystem_GroupPause(udg_TempInteger)
        call PatrolSystem_GroupResume(udg_TempInteger)
        call PatrolSystem_GroupStop(udg_TempInteger)
        call PatrolSystem_GroupContinue(udg_TempInteger)

    HIGH-LEVEL GROUP PATROL (with spawning/respawning):
    ---------------------------------------------------
    Use the PatrolGroup struct for complete patrol group management:
    
    local PatrolGroup pg = PatrolGroup.create()
    set pg.owner = Player(0)
    set pg.unitType = 'hfoo'
    set pg.unitCount = 4
    set pg.respawnTime = 120.0
    set pg.patrolRegion = gg_rct_PatrolArea
    set pg.spawnRegion = gg_rct_SpawnPoint
    call pg.start()
    
*/ 
//===========================================================================

globals
    // Path styles
    constant integer PATROL_STYLE_LOOP = 0
    constant integer PATROL_STYLE_PINGPONG = 1
    
    // Main data storage
    private Table PatrolData        // Main patrol data table
    private Table GroupData         // Group patrol data
    
    // Constants
    private constant real EPSILON = 32.00
    private constant real GROUP_EPSILON = 300.00
    
    // Patrol states
    private constant integer STATE_PAUSED = 0
    private constant integer STATE_TRAVEL = 1
    private constant integer STATE_WAIT = 2
    private constant integer STATE_RESET = 3
    
    // Triggers
    private trigger orderTrig
    private trigger damageTrig
    
    // Group ID counter
    private integer nextGroupId = 1
    
    // Instance tracking for high-level PatrolGroup
    private PatrolGroup array PatrolGroup_instances
    private integer PatrolGroup_instanceCount = 0
endglobals

//===========================================================================
// UTILITY FUNCTIONS
//===========================================================================

// Helper function for inline if-then-else (returns integer for boolean values)
private function ITE takes boolean condition, integer trueVal, integer falseVal returns integer
    if condition then
        return trueVal
    endif
    return falseVal
endfunction

private function GetOrCreateTable takes Table parent, integer key returns Table
    local Table t = parent[key]
    if t == 0 then
        set t = Table.create()
        set parent[key] = t
    endif
    return t
endfunction

private function MoveTime takes unit u, real x, real y returns real
    local real dx = x - GetUnitX(u)
    local real dy = y - GetUnitY(u)
    local real dist = SquareRoot(dx*dx + dy*dy)
    local real spd = GetUnitMoveSpeed(u)
    
    if spd < 1.00 then
        set spd = 220.00
    endif
    return dist / spd
endfunction

private function NextIndex takes integer currentIdx, integer count, integer direction, integer style returns integer
    local integer idx = currentIdx
    local integer dir = direction
    
    if style == PATROL_STYLE_LOOP then
        set idx = ModuloInteger(idx + 1, count)
    else // PINGPONG
        set idx = idx + dir
        if idx >= count then
            set idx = count - 2
            set dir = -1
        elseif idx < 0 then
            set idx = 1
            set dir = 1
        endif
    endif
    return idx
endfunction

private function GetDirection takes integer currentIdx, integer count, integer direction, integer style returns integer
    local integer idx = currentIdx
    local integer dir = direction
    
    if style == PATROL_STYLE_PINGPONG then
        set idx = idx + dir
        if idx >= count then
            set dir = -1
        elseif idx < 0 then
            set dir = 1
        endif
    endif
    return dir
endfunction

//===========================================================================
// SINGLE UNIT PATROL SYSTEM
//===========================================================================

private function GetUnitPatrolData takes unit u returns Table
    local integer id = GetHandleId(u)
    return PatrolData[id]
endfunction

private function FlushUnitPatrol takes unit u returns nothing
    local integer id = GetHandleId(u)
    local Table data = PatrolData[id]
    local Table waypoints
    local timer t
    
    if data != 0 then
        set t = data.timer[0]
        if t != null then
            call PauseTimer(t)
            call DestroyTimer(t)
        endif
        
        set waypoints = data[1000]
        if waypoints != 0 then
            call waypoints.destroy()
        endif
        
        call data.destroy()
        call PatrolData.remove(id)
    endif
endfunction

private function StartUnitTimer takes unit u, real duration, integer newState, code callback returns nothing
    local integer id = GetHandleId(u)
    local Table data = PatrolData[id]
    local timer t = data.timer[0]
    
    if t == null then
        set t = CreateTimer()
        set data.timer[0] = t
    endif
    
    set data[4] = newState // state
    set data.unit[99] = u  // backref from timer
    set PatrolData[GetHandleId(t)] = data
    call TimerStart(t, duration, false, callback)
endfunction

// Timer callback for single unit patrol
private function UnitTimerExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local Table data = PatrolData[GetHandleId(t)]
    local unit u
    local integer id
    local integer state
    local integer idx
    local integer count
    local integer dir
    local integer style
    local Table waypoints
    local real x
    local real y
    local real wait
    local string moveOrder
    local real patrolSpeed
    local real dx
    local real dy
    local real dist
    
    if data == 0 then
        return
    endif
    
    set u = data.unit[99]
    if u == null or GetUnitTypeId(u) == 0 then
        return
    endif
    
    set id = GetHandleId(u)
    set state = data[4]
    
    if state == STATE_PAUSED then
        return
    endif
    
    set idx = data[2]
    set count = data[6]
    set dir = data[5]
    set style = data[8]
    set waypoints = data[1000]
    set moveOrder = data.string[9]
    set patrolSpeed = data.real[10]
    
    // Apply patrol speed
    if patrolSpeed > 0 then
        call SetUnitMoveSpeed(u, patrolSpeed)
    else
        call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
    endif
    
    if state == STATE_TRAVEL then
        // Check if arrived at waypoint
        set x = waypoints.real[idx * 3 + 0]
        set y = waypoints.real[idx * 3 + 1]
        set dx = GetUnitX(u) - x
        set dy = GetUnitY(u) - y
        set dist = SquareRoot(dx*dx + dy*dy)
        
        if dist <= EPSILON then
            // Arrived - start waiting
            set wait = waypoints.real[idx * 3 + 2]
            if wait < 0.01 then
                // No wait, move to next immediately
                set idx = NextIndex(idx, count, dir, style)
                set dir = GetDirection(idx, count, dir, style)
                set data[2] = idx
                set data[5] = dir
                
                set x = waypoints.real[idx * 3 + 0]
                set y = waypoints.real[idx * 3 + 1]
                set data[50] = 1 // suppress flag
                call IssuePointOrder(u, moveOrder, x, y)
                call StartUnitTimer(u, MoveTime(u, x, y) + 0.25, STATE_TRAVEL, function UnitTimerExpire)
            else
                call StartUnitTimer(u, wait, STATE_WAIT, function UnitTimerExpire)
            endif
        else
            // Not arrived yet, re-issue order
            set data[50] = 1
            call IssuePointOrder(u, moveOrder, x, y)
            call StartUnitTimer(u, 0.5, STATE_TRAVEL, function UnitTimerExpire)
        endif
    elseif state == STATE_WAIT then
        // Finished waiting, move to next waypoint
        set idx = NextIndex(idx, count, dir, style)
        set dir = GetDirection(idx, count, dir, style)
        set data[2] = idx
        set data[5] = dir
        
        set x = waypoints.real[idx * 3 + 0]
        set y = waypoints.real[idx * 3 + 1]
        set data[50] = 1
        call IssuePointOrder(u, moveOrder, x, y)
        call StartUnitTimer(u, MoveTime(u, x, y), STATE_TRAVEL, function UnitTimerExpire)
    elseif state == STATE_RESET then
        // Reset complete
        if data[7] != 0 then // autoContinue
            set x = waypoints.real[idx * 3 + 0]
            set y = waypoints.real[idx * 3 + 1]
            set data[50] = 1
            call IssuePointOrder(u, moveOrder, x, y)
            call StartUnitTimer(u, MoveTime(u, x, y), STATE_TRAVEL, function UnitTimerExpire)
        else
            set data[4] = STATE_PAUSED
        endif
    endif
endfunction

//===========================================================================
// PUBLIC API - SINGLE UNIT PATROL
//===========================================================================

function PatrolSystem_Start takes unit u, integer waypointCount, real resetTime, integer pathStyle, boolean autoContinue, string moveOrder, real patrolSpeed returns nothing
    local integer id = GetHandleId(u)
    local Table data
    local Table waypoints
    local integer i
    local real x
    local real y
    
    // Clean up existing patrol if any
    call FlushUnitPatrol(u)
    
    // Create new patrol data
    set data = Table.create()
    set PatrolData[id] = data
    
    // Store basic settings
    set data[2] = 0                    // current waypoint
    set data.real[3] = resetTime       // resetTime (stored as real)
    set data[4] = STATE_PAUSED         // state
    set data[5] = 1                    // direction
    set data[6] = waypointCount        // count
    set data[7] = ITE(autoContinue, 1, 0)
    set data[8] = pathStyle
    set data.string[9] = moveOrder
    set data.real[10] = patrolSpeed
    set data[50] = 0                   // suppress flag
    set data[100] = 0                  // groupId (0 = not in group)
    
    // Store waypoints
    set waypoints = Table.create()
    set data[1000] = waypoints
    
    set i = 0
    loop
        exitwhen i >= waypointCount
        set x = GetLocationX(udg_PatrolSystem_Point[i])
        set y = GetLocationY(udg_PatrolSystem_Point[i])
        set waypoints.real[i * 3 + 0] = x
        set waypoints.real[i * 3 + 1] = y
        set waypoints.real[i * 3 + 2] = udg_PatrolSystem_Wait[i]
        set i = i + 1
    endloop
    
    // Start patrol
    set x = waypoints.real[0]
    set y = waypoints.real[1]
    set data[50] = 1
    call IssuePointOrder(u, moveOrder, x, y)
    call StartUnitTimer(u, MoveTime(u, x, y), STATE_TRAVEL, function UnitTimerExpire)
endfunction

function PatrolSystem_Stop takes unit u returns nothing
    call FlushUnitPatrol(u)
    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
endfunction

function PatrolSystem_Pause takes unit u returns nothing
    local Table data = GetUnitPatrolData(u)
    local timer t
    
    if data != 0 then
        set t = data.timer[0]
        if t != null then
            call PauseTimer(t)
        endif
        set data[4] = STATE_PAUSED
        call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
        call IssueImmediateOrder(u, "stop")
    endif
endfunction

function PatrolSystem_Resume takes unit u returns nothing
    local Table data = GetUnitPatrolData(u)
    local Table waypoints
    local integer idx
    local real x
    local real y
    local string moveOrder
    
    if data != 0 then
        if data[4] == STATE_PAUSED then
            set waypoints = data[1000]
            set idx = data[2]
            set moveOrder = data.string[9]
            
            set x = waypoints.real[idx * 3 + 0]
            set y = waypoints.real[idx * 3 + 1]
            set data[50] = 1
            call IssuePointOrder(u, moveOrder, x, y)
            call StartUnitTimer(u, MoveTime(u, x, y), STATE_TRAVEL, function UnitTimerExpire)
        endif
    endif
endfunction

function PatrolSystem_Continue takes unit u returns nothing
    local Table data = GetUnitPatrolData(u)
    local Table waypoints
    local integer idx
    local real x
    local real y
    local string moveOrder
    
    if data != 0 then
        set waypoints = data[1000]
        set idx = data[2]
        set moveOrder = data.string[9]
        
        set x = waypoints.real[idx * 3 + 0]
        set y = waypoints.real[idx * 3 + 1]
        set data[50] = 1
        call IssuePointOrder(u, moveOrder, x, y)
        call StartUnitTimer(u, MoveTime(u, x, y), STATE_TRAVEL, function UnitTimerExpire)
    endif
endfunction

function PatrolSystem_SetMoveStyle takes unit u, string moveOrder returns nothing
    local Table data = GetUnitPatrolData(u)
    if data != 0 then
        set data.string[9] = moveOrder
    endif
endfunction

//===========================================================================
// GROUP PATROL SYSTEM
//===========================================================================

private function FlushGroupPatrol takes integer groupId returns nothing
    local Table data = GroupData[groupId]
    local Table waypoints
    local Table formation
    local Table unitData
    local timer t
    local integer i
    local integer unitCount
    local unit u
    local integer uid
    
    if data != 0 then
        set t = data.timer[0]
        if t != null then
            call PauseTimer(t)
            call DestroyTimer(t)
        endif
        
        set waypoints = data[1000]
        if waypoints != 0 then
            call waypoints.destroy()
        endif
        
        set formation = data[2000]
        if formation != 0 then
            call formation.destroy()
        endif
        
        // Clear group membership from units
        set unitCount = data[11]
        set i = 0
        loop
            exitwhen i >= unitCount
            set u = data.unit[10000 + i]
            if u != null then
                set uid = GetHandleId(u)
                set unitData = PatrolData[uid]
                if unitData != 0 then
                    set unitData[100] = 0
                endif
            endif
            set i = i + 1
        endloop
        
        call data.destroy()
        call GroupData.remove(groupId)
    endif
endfunction

// Helper to set suppress flag for all units in group
private function SetGroupSuppressFlag takes integer groupId, integer value returns nothing
    local Table data = GroupData[groupId]
    local integer unitCount
    local integer i
    local unit u
    local Table unitData
    
    if data == 0 then
        return
    endif
    
    set unitCount = data[11]
    set i = 0
    loop
        exitwhen i >= unitCount
        set u = data.unit[10000 + i]
        if u != null then
            set unitData = PatrolData[GetHandleId(u)]
            if unitData != 0 then
                set unitData[50] = value
            endif
        endif
        set i = i + 1
    endloop
endfunction

private function CalculateGroupFormation takes integer groupId returns nothing
    local Table data = GroupData[groupId]
    local Table formation
    local integer unitCount = data[11]
    local real centerX = 0
    local real centerY = 0
    local integer i
    local unit u
    
    if data == 0 then
        return
    endif
    
    set formation = data[2000]
    if formation == 0 then
        set formation = Table.create()
        set data[2000] = formation
    endif
    
    // Calculate center point
    set i = 0
    loop
        exitwhen i >= unitCount
        set u = data.unit[10000 + i]
        if u != null and GetUnitTypeId(u) != 0 then
            set centerX = centerX + GetUnitX(u)
            set centerY = centerY + GetUnitY(u)
        endif
        set i = i + 1
    endloop
    
    if unitCount > 0 then
        set centerX = centerX / unitCount
        set centerY = centerY / unitCount
    endif
    
    // Store offsets relative to center
    set i = 0
    loop
        exitwhen i >= unitCount
        set u = data.unit[10000 + i]
        if u != null and GetUnitTypeId(u) != 0 then
            set formation.real[i * 2 + 0] = GetUnitX(u) - centerX
            set formation.real[i * 2 + 1] = GetUnitY(u) - centerY
        endif
        set i = i + 1
    endloop
endfunction

// Timer callback for group patrol
private function GroupTimerExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local Table data = GroupData[GetHandleId(t)]
    local integer groupId
    local integer state
    local integer idx
    local integer count
    local integer dir
    local integer style
    local integer unitCount
    local Table waypoints
    local Table formation
    local real x
    local real y
    local real wait
    local string moveOrder
    local real patrolSpeed
    local integer i
    local unit u
    local real offsetX
    local real offsetY
    local real dx
    local real dy
    local real dist
    local boolean allArrived
    
    if data == 0 then
        return
    endif
    
    set groupId = data[999] // groupId stored at key 999
    set state = data[4]
    
    if state == STATE_PAUSED then
        return
    endif
    
    set idx = data[2]
    set count = data[6]
    set dir = data[5]
    set style = data[8]
    set unitCount = data[11]
    set waypoints = data[1000]
    set formation = data[2000]
    set moveOrder = data.string[9]
    set patrolSpeed = data.real[10]
    
    if state == STATE_TRAVEL then
        // Check if ALL units in group arrived at waypoint
        set x = waypoints.real[idx * 3 + 0]
        set y = waypoints.real[idx * 3 + 1]
        
        // Check all ALIVE units to see if they've arrived
        set allArrived = true
        set i = 0
        loop
            exitwhen i >= unitCount
            set u = data.unit[10000 + i]
            if u != null and GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD) then
                set offsetX = formation.real[i * 2 + 0]
                set offsetY = formation.real[i * 2 + 1]
                set dx = GetUnitX(u) - (x + offsetX)
                set dy = GetUnitY(u) - (y + offsetY)
                set dist = SquareRoot(dx*dx + dy*dy)
                
                if dist > GROUP_EPSILON then
                    set allArrived = false
                    exitwhen true
                endif
            endif
            set i = i + 1
        endloop
        
        if allArrived then
            // Arrived - start waiting
            set wait = waypoints.real[idx * 3 + 2]
            if wait < 0.01 then
                // No wait, move to next immediately
                set idx = NextIndex(idx, count, dir, style)
                set dir = GetDirection(idx, count, dir, style)
                set data[2] = idx
                set data[5] = dir
                
                set x = waypoints.real[idx * 3 + 0]
                set y = waypoints.real[idx * 3 + 1]
                
                // Set suppress flag for all units before issuing orders
                call SetGroupSuppressFlag(groupId, 1)
                
                // Order all units
                set i = 0
                loop
                    exitwhen i >= unitCount
                    set u = data.unit[10000 + i]
                    if u != null and GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD) then
                        if patrolSpeed > 0 then
                            call SetUnitMoveSpeed(u, patrolSpeed)
                        else
                            call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
                        endif
                        set offsetX = formation.real[i * 2 + 0]
                        set offsetY = formation.real[i * 2 + 1]
                        call IssuePointOrder(u, moveOrder, x + offsetX, y + offsetY)
                    endif
                    set i = i + 1
                endloop
                
                // Find first alive unit for move time calculation
                set u = null
                set i = 0
                loop
                    exitwhen i >= unitCount
                    if data.unit[10000 + i] != null and GetUnitTypeId(data.unit[10000 + i]) != 0 and not IsUnitType(data.unit[10000 + i], UNIT_TYPE_DEAD) then
                        set u = data.unit[10000 + i]
                        exitwhen true
                    endif
                    set i = i + 1
                endloop
                
                if u != null then
                    call TimerStart(t, MoveTime(u, x, y) + 0.25, false, function GroupTimerExpire)
                else
                    // All units dead, shouldn't happen but fallback
                    call TimerStart(t, 1.0, false, function GroupTimerExpire)
                endif
            else
                set data[4] = STATE_WAIT
                call TimerStart(t, wait, false, function GroupTimerExpire)
            endif
        else
            // Not arrived yet, re-issue orders
            call SetGroupSuppressFlag(groupId, 1)
            set i = 0
            loop
                exitwhen i >= unitCount
                set u = data.unit[10000 + i]
                if u != null and GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD) then
                    if patrolSpeed > 0 then
                        call SetUnitMoveSpeed(u, patrolSpeed)
                    else
                        call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
                    endif
                    set offsetX = formation.real[i * 2 + 0]
                    set offsetY = formation.real[i * 2 + 1]
                    call IssuePointOrder(u, moveOrder, x + offsetX, y + offsetY)
                endif
                set i = i + 1
            endloop
            call TimerStart(t, 0.5, false, function GroupTimerExpire)
        endif
    elseif state == STATE_WAIT then
        // Finished waiting, move to next waypoint
        set idx = NextIndex(idx, count, dir, style)
        set dir = GetDirection(idx, count, dir, style)
        set data[2] = idx
        set data[5] = dir
        
        set x = waypoints.real[idx * 3 + 0]
        set y = waypoints.real[idx * 3 + 1]
        
        call SetGroupSuppressFlag(groupId, 1)
        
        set i = 0
        loop
            exitwhen i >= unitCount
            set u = data.unit[10000 + i]
            if u != null and GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD) then
                if patrolSpeed > 0 then
                    call SetUnitMoveSpeed(u, patrolSpeed)
                else
                    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
                endif
                set offsetX = formation.real[i * 2 + 0]
                set offsetY = formation.real[i * 2 + 1]
                call IssuePointOrder(u, moveOrder, x + offsetX, y + offsetY)
            endif
            set i = i + 1
        endloop
        
        // Find first alive unit for move time calculation
        set u = null
        set i = 0
        loop
            exitwhen i >= unitCount
            if data.unit[10000 + i] != null and GetUnitTypeId(data.unit[10000 + i]) != 0 and not IsUnitType(data.unit[10000 + i], UNIT_TYPE_DEAD) then
                set u = data.unit[10000 + i]
                exitwhen true
            endif
            set i = i + 1
        endloop
        
        set data[4] = STATE_TRAVEL
        if u != null then
            call TimerStart(t, MoveTime(u, x, y), false, function GroupTimerExpire)
        else
            call TimerStart(t, 1.0, false, function GroupTimerExpire)
        endif
    elseif state == STATE_RESET then
        // Reset complete
        if data[7] != 0 then // autoContinue
            set x = waypoints.real[idx * 3 + 0]
            set y = waypoints.real[idx * 3 + 1]
            
            call SetGroupSuppressFlag(groupId, 1)
            
            set i = 0
            loop
                exitwhen i >= unitCount
                set u = data.unit[10000 + i]
                if u != null and GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD) then
                    if patrolSpeed > 0 then
                        call SetUnitMoveSpeed(u, patrolSpeed)
                    else
                        call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
                    endif
                    set offsetX = formation.real[i * 2 + 0]
                    set offsetY = formation.real[i * 2 + 1]
                    call IssuePointOrder(u, moveOrder, x + offsetX, y + offsetY)
                endif
                set i = i + 1
            endloop
            
            // Find first alive unit for move time calculation
            set u = null
            set i = 0
            loop
                exitwhen i >= unitCount
                if data.unit[10000 + i] != null and GetUnitTypeId(data.unit[10000 + i]) != 0 and not IsUnitType(data.unit[10000 + i], UNIT_TYPE_DEAD) then
                    set u = data.unit[10000 + i]
                    exitwhen true
                endif
                set i = i + 1
            endloop
            
            set data[4] = STATE_TRAVEL
            if u != null then
                call TimerStart(t, MoveTime(u, x, y), false, function GroupTimerExpire)
            else
                call TimerStart(t, 1.0, false, function GroupTimerExpire)
            endif
        else
            set data[4] = STATE_PAUSED
        endif
    endif
endfunction

//===========================================================================
// PUBLIC API - GROUP PATROL
//===========================================================================

function PatrolSystem_GroupInit takes group g, integer waypointCount, real resetTime, integer pathStyle, boolean autoResume, string moveOrder, real patrolSpeed returns integer
    local integer groupId = nextGroupId
    local Table data = Table.create()
    local Table unitData
    local unit u
    local integer i = 0
    local integer uid
    
    set nextGroupId = nextGroupId + 1
    set GroupData[groupId] = data
    
    // Store group ID in data
    set data[999] = groupId
    
    // Store settings
    set data[2] = 0  // current waypoint
    set data.real[3] = resetTime  // Store as real, not integer
    set data[4] = STATE_PAUSED
    set data[5] = 1  // direction
    set data[6] = waypointCount
    set data[7] = ITE(autoResume, 1, 0)
    set data[8] = pathStyle
    set data.string[9] = moveOrder
    set data.real[10] = patrolSpeed
    set data[50] = 0 // suppress flag
    
    // Store units
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null
        call GroupRemoveUnit(g, u)
        
        if GetUnitTypeId(u) != 0 then
            set data.unit[10000 + i] = u
            // Mark unit as belonging to group (create minimal data just to track group membership)
            set uid = GetHandleId(u)
            set unitData = PatrolData[uid]
            if unitData == 0 then
                set unitData = Table.create()
                set PatrolData[uid] = unitData
            endif
            set unitData[100] = groupId  // Store group ID
            set unitData[50] = 0         // Suppress flag per unit
            set i = i + 1
        endif
    endloop
    
    set data[11] = i // unit count
    
    return groupId
endfunction

function PatrolSystem_GroupSetWaypoint takes integer groupId, integer index, real x, real y, real waitTime returns nothing
    local Table data = GroupData[groupId]
    local Table waypoints
    
    if data == 0 then
        return
    endif
    
    set waypoints = data[1000]
    if waypoints == 0 then
        set waypoints = Table.create()
        set data[1000] = waypoints
    endif
    
    set waypoints.real[index * 3 + 0] = x
    set waypoints.real[index * 3 + 1] = y
    set waypoints.real[index * 3 + 2] = waitTime
endfunction

function PatrolSystem_GroupStart takes integer groupId returns nothing
    local Table data = GroupData[groupId]
    local Table waypoints
    local Table formation
    local timer t
    local integer unitCount
    local string moveOrder
    local real patrolSpeed
    local real x
    local real y
    local integer i
    local unit u
    local real offsetX
    local real offsetY
    local integer waypointCount
    
    if data == 0 then
        return
    endif
    
    set unitCount = data[11]
    set waypoints = data[1000]
    set moveOrder = data.string[9]
    set patrolSpeed = data.real[10]
    set waypointCount = data[6]
    
    // Verify waypoints exist
    if waypointCount <= 0 then
        return
    endif
    
    // Verify first waypoint is valid
    set x = waypoints.real[0]
    set y = waypoints.real[1]
    
    if x == 0 and y == 0 then
        return
    endif
    
    // Calculate formation offsets based on current unit positions
    call CalculateGroupFormation(groupId)
    set formation = data[2000]
    
    // Create timer
    set t = data.timer[0]
    if t == null then
        set t = CreateTimer()
        set data.timer[0] = t
        set GroupData[GetHandleId(t)] = data
    endif
    
    // Get first waypoint again (after validation)
    set x = waypoints.real[0]
    set y = waypoints.real[1]
    
    // Set suppress flag for all units before issuing orders
    call SetGroupSuppressFlag(groupId, 1)
    
    // Order all units to first waypoint with offsets
    set i = 0
    loop
        exitwhen i >= unitCount
        set u = data.unit[10000 + i]
        if u != null and GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD) then
            if patrolSpeed > 0 then
                call SetUnitMoveSpeed(u, patrolSpeed)
            else
                call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
            endif
            set offsetX = formation.real[i * 2 + 0]
            set offsetY = formation.real[i * 2 + 1]
            call IssuePointOrder(u, moveOrder, x + offsetX, y + offsetY)
        endif
        set i = i + 1
    endloop
    
    // Find first alive unit for move time calculation
    set u = null
    set i = 0
    loop
        exitwhen i >= unitCount
        if data.unit[10000 + i] != null and GetUnitTypeId(data.unit[10000 + i]) != 0 and not IsUnitType(data.unit[10000 + i], UNIT_TYPE_DEAD) then
            set u = data.unit[10000 + i]
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    // Start timer
    set data[4] = STATE_TRAVEL
    if u != null then
        call TimerStart(t, MoveTime(u, x, y) + 0.25, false, function GroupTimerExpire)
    else
        call TimerStart(t, 1.0, false, function GroupTimerExpire)
    endif
endfunction

function PatrolSystem_GroupPause takes integer groupId returns nothing
    local Table data = GroupData[groupId]
    local timer t
    local integer unitCount
    local integer i
    local unit u
    
    if data == 0 then
        return
    endif
    
    set t = data.timer[0]
    if t != null then
        call PauseTimer(t)
    endif
    
    set data[4] = STATE_PAUSED
    set unitCount = data[11]
    
    set i = 0
    loop
        exitwhen i >= unitCount
        set u = data.unit[10000 + i]
        if u != null and GetUnitTypeId(u) != 0 then
            call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
            call IssueImmediateOrder(u, "stop")
        endif
        set i = i + 1
    endloop
endfunction

function PatrolSystem_GroupResume takes integer groupId returns nothing
    local Table data = GroupData[groupId]
    local Table waypoints
    local Table formation
    local timer t
    local integer idx
    local integer unitCount
    local string moveOrder
    local real patrolSpeed
    local real x
    local real y
    local integer i
    local unit u
    local real offsetX
    local real offsetY
    
    if data == 0 then
        return
    endif
    
    if data[4] != STATE_PAUSED then
        return
    endif
    
    set idx = data[2]
    set unitCount = data[11]
    set waypoints = data[1000]
    set formation = data[2000]
    set moveOrder = data.string[9]
    set patrolSpeed = data.real[10]
    set t = data.timer[0]
    
    set x = waypoints.real[idx * 3 + 0]
    set y = waypoints.real[idx * 3 + 1]
    
    call SetGroupSuppressFlag(groupId, 1)
    
    set i = 0
    loop
        exitwhen i >= unitCount
        set u = data.unit[10000 + i]
        if u != null and GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD) then
            if patrolSpeed > 0 then
                call SetUnitMoveSpeed(u, patrolSpeed)
            else
                call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
            endif
            set offsetX = formation.real[i * 2 + 0]
            set offsetY = formation.real[i * 2 + 1]
            call IssuePointOrder(u, moveOrder, x + offsetX, y + offsetY)
        endif
        set i = i + 1
    endloop
    
    // Find first alive unit for move time calculation
    set u = null
    set i = 0
    loop
        exitwhen i >= unitCount
        if data.unit[10000 + i] != null and GetUnitTypeId(data.unit[10000 + i]) != 0 and not IsUnitType(data.unit[10000 + i], UNIT_TYPE_DEAD) then
            set u = data.unit[10000 + i]
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    set data[4] = STATE_TRAVEL
    if u != null then
        call TimerStart(t, MoveTime(u, x, y), false, function GroupTimerExpire)
    else
        call TimerStart(t, 1.0, false, function GroupTimerExpire)
    endif
endfunction

function PatrolSystem_GroupContinue takes integer groupId returns nothing
    call PatrolSystem_GroupResume(groupId) // Same implementation
endfunction

function PatrolSystem_GroupStop takes integer groupId returns nothing
    local Table data = GroupData[groupId]
    local integer unitCount
    local integer i
    local unit u
    
    if data == 0 then
        return
    endif
    
    set unitCount = data[11]
    
    set i = 0
    loop
        exitwhen i >= unitCount
        set u = data.unit[10000 + i]
        if u != null and GetUnitTypeId(u) != 0 then
            call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
            call IssueImmediateOrder(u, "stop")
        endif
        set i = i + 1
    endloop
    
    call FlushGroupPatrol(groupId)
endfunction

//===========================================================================
// HIGH-LEVEL PATROL GROUP STRUCT (with spawning/respawning)
//===========================================================================

struct PatrolGroup
    // Configuration
    player owner
    integer unitType
    integer unitCount
    real respawnTime
    integer waypointCount
    real patrolSpeed
    real waypointWait
    real resetTime
    rect patrolRegion
    rect spawnRegion
    integer pathStyle
    string moveOrder
    
    // Runtime tracking
    group unitGroup
    integer currentGroupId
    timer respawnTimer
    boolean isActive
    Table instanceData
    
    static method create takes nothing returns thistype
        local thistype this = allocate()
        
        // Default configuration
        set this.owner = Player(0)
        set this.unitType = 'hfoo'
        set this.unitCount = 4
        set this.respawnTime = 120.0
        set this.waypointCount = 5
        set this.patrolSpeed = 250.0
        set this.waypointWait = 2.0
        set this.resetTime = 15.0
        set this.pathStyle = PATROL_STYLE_PINGPONG
        set this.moveOrder = "move"
        
        // Runtime initialization
        set this.unitGroup = CreateGroup()
        set this.currentGroupId = 0
        set this.respawnTimer = CreateTimer()
        set this.isActive = false
        set this.instanceData = Table.create()
        
        // Register instance
        set PatrolGroup_instances[PatrolGroup_instanceCount] = this
        set PatrolGroup_instanceCount = PatrolGroup_instanceCount + 1
        
        return this
    endmethod
    
    method destroy takes nothing returns nothing
        call this.stop()
        call DestroyGroup(this.unitGroup)
        call DestroyTimer(this.respawnTimer)
        call this.instanceData.destroy()
        call deallocate()
    endmethod
    
    private method areAllUnitsDead takes nothing returns boolean
        local unit u
        local integer deadCount = 0
        local integer aliveCount = 0
        local group tempGroup = CreateGroup()
        
        loop
            set u = FirstOfGroup(this.unitGroup)
            exitwhen u == null
            call GroupRemoveUnit(this.unitGroup, u)
            
            if GetUnitTypeId(u) == 0 or IsUnitType(u, UNIT_TYPE_DEAD) then
                set deadCount = deadCount + 1
            else
                set aliveCount = aliveCount + 1
                call GroupAddUnit(tempGroup, u)
            endif
        endloop
        
        loop
            set u = FirstOfGroup(tempGroup)
            exitwhen u == null
            call GroupRemoveUnit(tempGroup, u)
            call GroupAddUnit(this.unitGroup, u)
        endloop
        
        call DestroyGroup(tempGroup)
        return aliveCount == 0
    endmethod
    
    private method generateRandomWaypoints takes nothing returns nothing
        local integer i = 0
        local real x
        local real y
        local real minX = GetRectMinX(this.patrolRegion)
        local real maxX = GetRectMaxX(this.patrolRegion)
        local real minY = GetRectMinY(this.patrolRegion)
        local real maxY = GetRectMaxY(this.patrolRegion)
        
        loop
            exitwhen i >= this.waypointCount
            set x = GetRandomReal(minX, maxX)
            set y = GetRandomReal(minY, maxY)
            call PatrolSystem_GroupSetWaypoint(this.currentGroupId, i, x, y, this.waypointWait)
            set i = i + 1
        endloop
    endmethod
    
    private method spawnUnits takes nothing returns nothing
        local integer i = 0
        local unit u
        local real spawnX = (GetRectMinX(this.spawnRegion) + GetRectMaxX(this.spawnRegion)) / 2
        local real spawnY = (GetRectMinY(this.spawnRegion) + GetRectMaxY(this.spawnRegion)) / 2
        local real offsetX
        local real offsetY
        
        call GroupClear(this.unitGroup)
        
        loop
            exitwhen i >= this.unitCount
            set offsetX = ModuloInteger(i, 2) * 128.0 - 64.0
            set offsetY = (i / 2) * 128.0 - 64.0
            set u = CreateUnit(this.owner, this.unitType, spawnX + offsetX, spawnY + offsetY, 270.0)
            if u != null then
                call GroupAddUnit(this.unitGroup, u)
            endif
            set i = i + 1
        endloop
    endmethod
    
    private method startPatrol takes nothing returns nothing
        local group tempGroup = CreateGroup()
        local unit u
        
        if this.currentGroupId > 0 then
            call PatrolSystem_GroupStop(this.currentGroupId)
            set this.currentGroupId = 0
        endif
        
        call BlzGroupAddGroupFast(this.unitGroup, tempGroup)
        
        set this.currentGroupId = PatrolSystem_GroupInit(tempGroup, this.waypointCount, this.resetTime, this.pathStyle, true, this.moveOrder, this.patrolSpeed)
        
        if this.currentGroupId > 0 then
            call this.generateRandomWaypoints()
            call PatrolSystem_GroupStart(this.currentGroupId)
        endif
        
        call DestroyGroup(tempGroup)
    endmethod
    
    private static method delayedPatrolStart takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local Table lookup = PatrolData[GetHandleId(t)]
        local thistype this
        
        if lookup != 0 then
            set this = lookup[0]
            if this != 0 then
                if this.isActive then
                    call this.startPatrol()
                endif
            endif
            call lookup.destroy()
            call PatrolData.remove(GetHandleId(t))
        endif
        
        call DestroyTimer(t)
    endmethod
    
    private method spawnAndStartPatrol takes nothing returns nothing
        local timer delayTimer
        local Table lookup
        
        if this.isActive == false then
            return
        endif
        
        call this.spawnUnits()
        
        set delayTimer = CreateTimer()
        set lookup = Table.create()
        set lookup[0] = this
        set PatrolData[GetHandleId(delayTimer)] = lookup
        call TimerStart(delayTimer, 2.0, false, function thistype.delayedPatrolStart)
    endmethod
    
    private static method respawnTimerCallback takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local Table lookup = PatrolData[GetHandleId(t)]
        local thistype this
        
        if lookup != 0 then
            set this = lookup[0]
            if this != 0 then
                call this.spawnAndStartPatrol()
            endif
        endif
    endmethod
    
    private method checkUnitStatus takes nothing returns nothing
        local Table lookup
        
        if this.isActive == false then
            return
        endif
        
        if this.areAllUnitsDead() then
            if this.currentGroupId > 0 then
                call PatrolSystem_GroupStop(this.currentGroupId)
                set this.currentGroupId = 0
            endif
            
            set lookup = Table.create()
            set lookup[0] = this
            set PatrolData[GetHandleId(this.respawnTimer)] = lookup
            call TimerStart(this.respawnTimer, this.respawnTime, false, function thistype.respawnTimerCallback)
        endif
    endmethod
    
    private static method checkUnitStatusDelayed takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local Table lookup = PatrolData[GetHandleId(t)]
        local thistype this
        
        if lookup != 0 then
            set this = lookup[0]
            if this != 0 then
                call this.checkUnitStatus()
            endif
            call lookup.destroy()
            call PatrolData.remove(GetHandleId(t))
        endif
        
        call DestroyTimer(t)
    endmethod
    
    private static method onUnitDeath takes nothing returns nothing
        local unit dying = GetDyingUnit()
        local player dyingOwner = GetOwningPlayer(dying)
        local integer dyingType = GetUnitTypeId(dying)
        local integer i = 0
        local thistype pg
        local timer delayTimer
        local Table lookup
        
        loop
            exitwhen i >= PatrolGroup_instanceCount
            set pg = PatrolGroup_instances[i]
            
            if pg != 0 and pg.isActive then
                if dyingOwner == pg.owner and dyingType == pg.unitType then
                    if IsUnitInGroup(dying, pg.unitGroup) then
                        set delayTimer = CreateTimer()
                        set lookup = Table.create()
                        set lookup[0] = pg
                        set PatrolData[GetHandleId(delayTimer)] = lookup
                        call TimerStart(delayTimer, 1.0, false, function thistype.checkUnitStatusDelayed)
                        exitwhen true
                    endif
                endif
            endif
            
            set i = i + 1
        endloop
    endmethod
    
    method start takes nothing returns nothing
        if this.patrolRegion == null then
            return
        endif
        
        if this.spawnRegion == null then
            return
        endif
        
        set this.isActive = true
        call this.spawnAndStartPatrol()
    endmethod
    
    method stop takes nothing returns nothing
        local unit u
        
        set this.isActive = false
        
        if this.currentGroupId > 0 then
            call PatrolSystem_GroupStop(this.currentGroupId)
            set this.currentGroupId = 0
        endif
        
        call PauseTimer(this.respawnTimer)
        
        loop
            set u = FirstOfGroup(this.unitGroup)
            exitwhen u == null
            call GroupRemoveUnit(this.unitGroup, u)
            call RemoveUnit(u)
        endloop
    endmethod
    
    private static method onInit takes nothing returns nothing
        call UnitDeathEvent_Register(function thistype.onUnitDeath)
    endmethod
endstruct

//===========================================================================
// EVENT HANDLERS
//===========================================================================

private function OnIssuedOrder takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer id = GetHandleId(u)
    local Table data = PatrolData[id]
    local integer groupId
    local Table groupData
    local timer t
    local real resetTime
    local integer i
    local integer unitCount
    local unit grpUnit
    local integer orderId
    
    if data == 0 then
        return
    endif
    
    // Check if this is a suppressed order (issued by the system)
    if data[50] != 0 then
        set data[50] = 0
        return
    endif
    
    // Get the order ID to check what type of order was issued
    set orderId = GetIssuedOrderId()
    
    // Ignore attack orders - units should only retaliate when damaged, not when player issues attack
    if orderId == 851983 or orderId == 851984 then // attack and attack-ground orders
        return
    endif
    
    // Check if unit belongs to a group
    set groupId = data[100]
    if groupId > 0 then
        // Unit belongs to a group - pause group patrol and set reset timer
        set groupData = GroupData[groupId]
        if groupData != 0 then
            // Pause group timer
            set t = groupData.timer[0]
            if t != null then
                call PauseTimer(t)
            endif
            
            // Reset all units to default speed and stop them
            set unitCount = groupData[11]
            set i = 0
            loop
                exitwhen i >= unitCount
                set grpUnit = groupData.unit[10000 + i]
                if grpUnit != null and GetUnitTypeId(grpUnit) != 0 then
                    call SetUnitMoveSpeed(grpUnit, GetUnitDefaultMoveSpeed(grpUnit))
                endif
                set i = i + 1
            endloop
            
            // Set group to reset state and start reset timer
            set groupData[4] = STATE_RESET
            set resetTime = groupData.real[3]
            call TimerStart(t, resetTime, false, function GroupTimerExpire)
        endif
        return
    endif
    
    // Player issued order to single-unit patrol - pause and start reset timer
    set t = data.timer[0]
    if t != null then
        call PauseTimer(t)
    endif
    
    call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u))
    set data[4] = STATE_RESET
    
    set resetTime = data.real[3]
    call StartUnitTimer(u, resetTime, STATE_RESET, function UnitTimerExpire)
endfunction

private function OnDamage takes nothing returns nothing
    local unit target = udg_DamageEventTarget
    local integer id
    local Table data
    local integer groupId
    local Table groupData
    local timer t
    local real resetTime
    local integer i
    local integer unitCount
    local unit grpUnit
    
    if target == null then
        return
    endif
    
    set id = GetHandleId(target)
    set data = PatrolData[id]
    
    if data == 0 then
        return
    endif
    
    // Check if unit belongs to a group
    set groupId = data[100]
    if groupId > 0 then
        // Unit belongs to a group - pause group patrol and set reset timer
        set groupData = GroupData[groupId]
        if groupData != 0 then
            // Pause group timer
            set t = groupData.timer[0]
            if t != null then
                call PauseTimer(t)
            endif
            
            // Reset all units to default speed
            set unitCount = groupData[11]
            set i = 0
            loop
                exitwhen i >= unitCount
                set grpUnit = groupData.unit[10000 + i]
                if grpUnit != null and GetUnitTypeId(grpUnit) != 0 then
                    call SetUnitMoveSpeed(grpUnit, GetUnitDefaultMoveSpeed(grpUnit))
                endif
                set i = i + 1
            endloop
            
            // Set group to reset state and start reset timer
            set groupData[4] = STATE_RESET
            set resetTime = groupData.real[3]
            call TimerStart(t, resetTime, false, function GroupTimerExpire)
        endif
        return
    endif
    
    // Pause single-unit patrol and start reset timer
    set t = data.timer[0]
    if t != null then
        call PauseTimer(t)
    endif
    
    call SetUnitMoveSpeed(target, GetUnitDefaultMoveSpeed(target))
    set data[4] = STATE_RESET
    
    set resetTime = data.real[3]
    call StartUnitTimer(target, resetTime, STATE_RESET, function UnitTimerExpire)
endfunction

private function OnDeath takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer id = GetHandleId(u)
    local Table data = PatrolData[id]
    local integer groupId
    
    if data == 0 then
        return
    endif
    
    set groupId = data[100]
    
    // If unit belongs to group, let group handle it
    if groupId == 0 then
        call FlushUnitPatrol(u)
    endif
endfunction

private function Init takes nothing returns nothing
    // Initialize tables
    set PatrolData = Table.create()
    set GroupData = Table.create()
    
    // Register order events
    set orderTrig = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
    call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
    call TriggerAddAction(orderTrig, function OnIssuedOrder)
    
    // Register damage events
    set damageTrig = CreateTrigger()
    call TriggerRegisterVariableEvent(damageTrig, "udg_DamageEvent", EQUAL, 1.00)
    call TriggerAddAction(damageTrig, function OnDamage)
    
    // Register death events
    call UnitDeathEvent_Register(function OnDeath)
endfunction

endlibrary
