library PatrolGroupSystem requires PatrolSystem, Table, UnitDeathEvent

/*
    Generic Patrol Group System
    Author: [Valdemar]
    
    A reusable system for creating patrol groups with automatic spawning and respawning.
    
    Usage:
    1. Create a PatrolGroup instance with CreatePatrolGroup()
    2. Configure it with settings
    3. Call StartPatrolGroup() to begin
    
    See PatrolGroup_*.j files for examples of specific patrol configurations.
*/

globals
    private PatrolGroup array PatrolGroup_instances
    private integer PatrolGroup_instanceCount = 0
    private Table PatrolGroup_table
    
    // Debug flag
    boolean PGS_DEBUG = false  // Set to true to enable debug messages
endglobals

//===========================================================================
// PATROL GROUP STRUCT
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
    boolean useManualWaypoints
    
    // Runtime tracking
    group unitGroup
    integer currentGroupId
    timer respawnTimer
    boolean isActive
    
    // Manual waypoint storage (max 50 waypoints)
    real array waypointX[50]
    real array waypointY[50]
    real array waypointWaitTime[50]
    
    //=======================================================================
    // CREATION & DESTRUCTION
    //=======================================================================
    
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
        set this.useManualWaypoints = false
        
        // Runtime initialization
        set this.unitGroup = CreateGroup()
        set this.currentGroupId = 0
        set this.respawnTimer = CreateTimer()
        set this.isActive = false
        
        // Register instance
        set PatrolGroup_instances[PatrolGroup_instanceCount] = this
        set PatrolGroup_instanceCount = PatrolGroup_instanceCount + 1
        
        return this
    endmethod
    
    method destroy takes nothing returns nothing
        call this.stop()
        call DestroyGroup(this.unitGroup)
        call DestroyTimer(this.respawnTimer)
        call deallocate()
    endmethod
    
    //=======================================================================
    // MANUAL WAYPOINT CONFIGURATION
    //=======================================================================
    
    // Set a manual waypoint at the given index
    // Call this before calling start() to use manual waypoints instead of random generation
    method setWaypoint takes integer index, real x, real y, real waitTime returns nothing
        if index < 0 or index >= 50 then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: Waypoint index " + I2S(index) + " out of range (0-49)")
            endif
            return
        endif
        
        set this.waypointX[index] = x
        set this.waypointY[index] = y
        set this.waypointWaitTime[index] = waitTime
        set this.useManualWaypoints = true
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Manual waypoint [" + I2S(index) + "] set: (" + R2S(x) + ", " + R2S(y) + "), wait=" + R2S(waitTime))
        endif
    endmethod
    
    // Convenience method to set waypoint from a rect center
    method setWaypointFromRect takes integer index, rect r, real waitTime returns nothing
        call this.setWaypoint(index, GetRectCenterX(r), GetRectCenterY(r), waitTime)
    endmethod
    
    // Convenience method to set waypoint from a location (will be cleaned up)
    method setWaypointFromLocation takes integer index, location loc, real waitTime returns nothing
        call this.setWaypoint(index, GetLocationX(loc), GetLocationY(loc), waitTime)
    endmethod
    
    //=======================================================================
    // UTILITY FUNCTIONS
    //=======================================================================
    
    private method getRandomPointInRect takes rect r returns location
        local real minX = GetRectMinX(r)
        local real maxX = GetRectMaxX(r)
        local real minY = GetRectMinY(r)
        local real maxY = GetRectMaxY(r)
        local real x = GetRandomReal(minX, maxX)
        local real y = GetRandomReal(minY, maxY)
        return Location(x, y)
    endmethod
    
    private method areAllUnitsDead takes nothing returns boolean
        local unit u
        local integer deadCount = 0
        local integer aliveCount = 0
        local group tempGroup = CreateGroup()
        
        // Check all units and rebuild the group with only alive ones
        loop
            set u = FirstOfGroup(this.unitGroup)
            exitwhen u == null
            call GroupRemoveUnit(this.unitGroup, u)
            
            if GetUnitTypeId(u) == 0 or IsUnitType(u, UNIT_TYPE_DEAD) then
                set deadCount = deadCount + 1
                // Don't add dead units back to the group
            else
                set aliveCount = aliveCount + 1
                call GroupAddUnit(tempGroup, u)
            endif
        endloop
        
        // Rebuild the group with only alive units
        loop
            set u = FirstOfGroup(tempGroup)
            exitwhen u == null
            call GroupRemoveUnit(tempGroup, u)
            call GroupAddUnit(this.unitGroup, u)
        endloop
        
        call DestroyGroup(tempGroup)
        set tempGroup = null
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Unit status: " + I2S(aliveCount) + " alive, " + I2S(deadCount) + " dead")
        endif
        
        return aliveCount == 0
    endmethod
    
    //=======================================================================
    // SPAWN & PATROL FUNCTIONS
    //=======================================================================
    
    private method setManualWaypoints takes nothing returns nothing
        local integer i = 0
        local real x
        local real y
        local real wait
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] === SETTING MANUAL WAYPOINTS ===")
            call BJDebugMsg("[PatrolGroup] GroupID: " + I2S(this.currentGroupId) + ", WaypointCount: " + I2S(this.waypointCount))
        endif
        
        // Set waypoints from manually configured arrays
        set i = 0
        loop
            exitwhen i >= this.waypointCount
            
            set x = this.waypointX[i]
            set y = this.waypointY[i]
            set wait = this.waypointWaitTime[i]
            
            // Validate waypoint
            if x == 0 and y == 0 then
                if PGS_DEBUG then
                    call BJDebugMsg("[PatrolGroup] WARNING: Waypoint [" + I2S(i) + "] not set (0,0), using default")
                endif
                set wait = this.waypointWait
            endif
            
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] Setting manual WP[" + I2S(i) + "] for GroupID " + I2S(this.currentGroupId) + ": (" + R2S(x) + ", " + R2S(y) + "), wait=" + R2S(wait))
            endif
            
            // Store waypoint directly in PatrolSystem for this group
            call PatrolSystem_GroupSetWaypoint(this.currentGroupId, i, x, y, wait)
            
            set i = i + 1
        endloop
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] === MANUAL WAYPOINTS SET COMPLETE ===")
        endif
    endmethod
    
    private method generateRandomWaypoints takes nothing returns nothing
        local integer i = 0
        local real x
        local real y
        local real minX
        local real maxX
        local real minY
        local real maxY
        local real rangeX
        local real rangeY
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] === GENERATING RANDOM WAYPOINTS ===")
            call BJDebugMsg("[PatrolGroup] GroupID: " + I2S(this.currentGroupId) + ", WaypointCount: " + I2S(this.waypointCount))
        endif
        
        // Verify patrol region is valid
        if this.patrolRegion == null then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: patrolRegion is NULL!")
            endif
            return
        endif
        
        // Get bounds from the patrol region
        set minX = GetRectMinX(this.patrolRegion)
        set maxX = GetRectMaxX(this.patrolRegion)
        set minY = GetRectMinY(this.patrolRegion)
        set maxY = GetRectMaxY(this.patrolRegion)
        set rangeX = maxX - minX
        set rangeY = maxY - minY
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Patrol region: X[" + R2S(minX) + " to " + R2S(maxX) + "], Y[" + R2S(minY) + " to " + R2S(maxY) + "]")
        endif
        
        // Verify the region has valid size
        if rangeX <= 0 or rangeY <= 0 then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: Invalid region size!")
            endif
            return
        endif
        
        // Generate waypoints and store them directly in the patrol group
        set i = 0
        loop
            exitwhen i >= this.waypointCount
            
            // Generate random coordinates within the bounds
            set x = GetRandomReal(minX, maxX)
            set y = GetRandomReal(minY, maxY)
            
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] Setting random WP[" + I2S(i) + "] for GroupID " + I2S(this.currentGroupId) + ": (" + R2S(x) + ", " + R2S(y) + "), wait=" + R2S(this.waypointWait))
            endif
            
            // Store waypoint directly in PatrolSystem for this group
            call PatrolSystem_GroupSetWaypoint(this.currentGroupId, i, x, y, this.waypointWait)
            
            set i = i + 1
        endloop
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] === RANDOM WAYPOINT GENERATION COMPLETE ===")
        endif
    endmethod
    
    private method cleanupWaypoints takes nothing returns nothing
        // No manual cleanup needed since waypoints are stored in the PatrolSystem's hashtable
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Waypoint cleanup not needed (stored in hashtable)")
        endif
    endmethod
    
    private method spawnUnits takes nothing returns nothing
        local integer i = 0
        local unit u
        local location spawnLoc = GetRectCenter(this.spawnRegion)
        local real spawnX = GetLocationX(spawnLoc)
        local real spawnY = GetLocationY(spawnLoc)
        local real offsetX
        local real offsetY
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Spawning " + I2S(this.unitCount) + " units...")
        endif
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
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Spawned " + I2S(BlzGroupGetSize(this.unitGroup)) + " units")
        endif
        call RemoveLocation(spawnLoc)
        set spawnLoc = null
    endmethod
    
    private method startPatrol takes nothing returns nothing
        local group tempGroup = CreateGroup()
        local group copyGroup = CreateGroup()
        local unit u
        local integer unitCount = 0
        local boolean hasValidUnits = false
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] === STARTING PATROL ===")
        endif
        
        if this.currentGroupId > 0 then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] Stopping previous patrol ID: " + I2S(this.currentGroupId))
            endif
            call PatrolSystem_GroupStop(this.currentGroupId)
            set this.currentGroupId = 0
        endif
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Copying units to patrol group...")
        endif
        
        // First, copy all units from this.unitGroup to copyGroup
        call BlzGroupAddGroupFast(this.unitGroup, copyGroup)
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Copied " + I2S(BlzGroupGetSize(copyGroup)) + " units")
        endif
        
        // Now enumerate copyGroup and add valid units to tempGroup
        loop
            set u = FirstOfGroup(copyGroup)
            exitwhen u == null
            call GroupRemoveUnit(copyGroup, u)
            
            if GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD) then
                call GroupAddUnit(tempGroup, u)
                set hasValidUnits = true
                set unitCount = unitCount + 1
            endif
        endloop
        
        call DestroyGroup(copyGroup)
        set copyGroup = null
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Units for patrol: " + I2S(unitCount))
        endif
        
        if not hasValidUnits then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: No valid units!")
            endif
            call DestroyGroup(tempGroup)
            set tempGroup = null
            return
        endif
        
        // Initialize patrol group (allocates groupId and stores units)
        set this.currentGroupId = PatrolSystem_GroupInit(tempGroup, this.waypointCount, this.resetTime, this.pathStyle, true, this.moveOrder, this.patrolSpeed)
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Patrol GroupID allocated: " + I2S(this.currentGroupId))
        endif
        
        if this.currentGroupId == 0 then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: PatrolSystem_GroupInit failed!")
            endif
            call DestroyGroup(tempGroup)
            set tempGroup = null
            return
        endif
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Now setting up waypoints for GroupID: " + I2S(this.currentGroupId))
        endif
        
        // Use manual or random waypoints based on configuration
        if this.useManualWaypoints then
            call this.setManualWaypoints()
        else
            call this.generateRandomWaypoints()
        endif
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Waypoints configured, now starting patrol movement for GroupID: " + I2S(this.currentGroupId))
        endif
        
        // Start the actual patrol (issues movement orders)
        call PatrolSystem_GroupStart(this.currentGroupId)
        
        call DestroyGroup(tempGroup)
        set tempGroup = null
    endmethod
    
    private static method delayedPatrolStart takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = PatrolGroup_table[GetHandleId(t)]
        local integer count
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] === DELAYED PATROL START CALLBACK ===")
        endif
        
        if this == 0 then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: this == 0 (invalid instance)")
            endif
            call DestroyTimer(t)
            set t = null
            return
        endif
        
        set count = BlzGroupGetSize(this.unitGroup)
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Instance valid, " + I2S(count) + " units in group")
        endif
        
        if not this.isActive then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: Instance not active")
            endif
            call PatrolGroup_table.remove(GetHandleId(t))
            call DestroyTimer(t)
            set t = null
            return
        endif
        
        if count <= 0 then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: No units in group!")
            endif
            call PatrolGroup_table.remove(GetHandleId(t))
            call DestroyTimer(t)
            set t = null
            return
        endif
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] All checks passed, calling startPatrol()...")
        endif
        call this.startPatrol()
        
        call PatrolGroup_table.remove(GetHandleId(t))
        call DestroyTimer(t)
        set t = null
    endmethod
    
    private method spawnAndStartPatrol takes nothing returns nothing
        local timer delayTimer
        
        if not this.isActive then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: Not active, cannot spawn")
            endif
            return
        endif
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Spawning and starting patrol...")
        endif
        
        call this.spawnUnits()
        
        // Use a delay to ensure units are fully spawned and ready
        set delayTimer = CreateTimer()
        set PatrolGroup_table[GetHandleId(delayTimer)] = this
        call TimerStart(delayTimer, 2.0, false, function thistype.delayedPatrolStart)
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Patrol will start in 2.0 seconds")
        endif
    endmethod
    
    //=======================================================================
    // RESPAWN SYSTEM
    //=======================================================================
    
    private static method respawnTimerCallback takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = PatrolGroup_table[GetHandleId(t)]
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Respawn timer expired")
        endif
        
        if this != 0 then
            call this.spawnAndStartPatrol()
        else
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: Invalid instance on respawn")
            endif
        endif
    endmethod
    
    private method checkUnitStatus takes nothing returns nothing
        if not this.isActive then
            return
        endif
        
        if this.areAllUnitsDead() then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] All units dead, respawning in " + R2S(this.respawnTime) + " seconds")
            endif
            
            if this.currentGroupId > 0 then
                call PatrolSystem_GroupStop(this.currentGroupId)
                set this.currentGroupId = 0
            endif
            
            set PatrolGroup_table[GetHandleId(this.respawnTimer)] = this
            call TimerStart(this.respawnTimer, this.respawnTime, false, function thistype.respawnTimerCallback)
        endif
    endmethod
    
    //=======================================================================
    // DEATH EVENT
    //=======================================================================
    
    private static method checkUnitStatusDelayed takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = PatrolGroup_table[GetHandleId(t)]
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Death check triggered")
        endif
        
        if this != 0 then
            call this.checkUnitStatus()
        endif
        
        call PatrolGroup_table.remove(GetHandleId(t))
        call PauseTimer(t)
        call DestroyTimer(t)
        set t = null
    endmethod
    
    private static method onUnitDeath takes nothing returns nothing
        local unit dying = GetDyingUnit()
        local player dyingOwner = GetOwningPlayer(dying)
        local integer dyingType = GetUnitTypeId(dying)
        local integer i = 0
        local thistype pg
        local timer delayTimer
        local boolean isInGroup = false
        
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] Unit death detected")
        endif
        
        // Check if this unit is in any patrol group
        loop
            exitwhen i >= PatrolGroup_instanceCount
            set pg = PatrolGroup_instances[i]
            
            if pg != 0 and pg.isActive then
                if dyingOwner == pg.owner and dyingType == pg.unitType then
                    // Verify the dying unit is actually in this patrol group
                    if IsUnitInGroup(dying, pg.unitGroup) then
                        set isInGroup = true
                        if PGS_DEBUG then
                            call BJDebugMsg("[PatrolGroup] Death confirmed in patrol group, scheduling check")
                        endif
                        // Use timer instead of TriggerSleepAction
                        set delayTimer = CreateTimer()
                        set PatrolGroup_table[GetHandleId(delayTimer)] = pg
                        call TimerStart(delayTimer, 1.0, false, function thistype.checkUnitStatusDelayed)
                        exitwhen true
                    endif
                endif
            endif
            
            set i = i + 1
        endloop
        
        if not isInGroup then
            // call BJDebugMsg("[PatrolGroup] Death was not from a patrol group unit - ignored")
        endif
    endmethod
    
    //=======================================================================
    // PUBLIC METHODS
    //=======================================================================
    
    method start takes nothing returns nothing
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroup] START called")
        endif
        
        // Validate configuration
        if not this.useManualWaypoints then
            // Only check patrol region if using random waypoints
            if this.patrolRegion == null then
                if PGS_DEBUG then
                    call BJDebugMsg("[PatrolGroup] ERROR: patrolRegion is null!")
                endif
                return
            endif
        endif
        
        if this.spawnRegion == null then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: spawnRegion is null!")
            endif
            return
        endif
        
        if this.unitCount <= 0 then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: unitCount must be > 0!")
            endif
            return
        endif
        
        if this.waypointCount <= 0 then
            if PGS_DEBUG then
                call BJDebugMsg("[PatrolGroup] ERROR: waypointCount must be > 0!")
            endif
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
    
    method restart takes nothing returns nothing
        if this.isActive and this.currentGroupId > 0 then
            call PatrolSystem_GroupStop(this.currentGroupId)
            call TriggerSleepAction(0.5)
            call this.startPatrol()
        endif
    endmethod
    
    //=======================================================================
    // INITIALIZATION
    //=======================================================================
    
    private static method onInit takes nothing returns nothing
        set PatrolGroup_table = Table.create()
        // Register with centralized death event system
        call UnitDeathEvent_Register(function thistype.onUnitDeath)
        if PGS_DEBUG then
            call BJDebugMsg("[PatrolGroupSystem] Registered with centralized death event system")
        endif
    endmethod
endstruct

endlibrary
