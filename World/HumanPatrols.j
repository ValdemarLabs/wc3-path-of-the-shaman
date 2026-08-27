/**
    HumanPatrols

    Author: Valdemar
    Version: 1.1.0

    Description:
    Runs one or two recurring human patrols. Each patrol is assigned either
    to the Sereneglade-Twilight Grove route or to Havenwoods and independently
    alternates between coordinated travel, tent camps, and respawn delays.

    Credits:
    - World/_oldGUI/Human Patrols

    How to install:
    Import after CreepRespawn, keep PatrolSpawnPoint and the three zone rects,
    then disable the four legacy Human Patrol GUI triggers. The system starts
    after the configured initial delay.

    API:
    - HumanPatrols_Start()
    - HumanPatrols_Stop(removeUnits)
    - HumanPatrols_Respawn()
    - HumanPatrols_ForceMove()
    - HumanPatrols_ForceCamp()
    - HumanPatrols_GetPatrolCount()
    - HumanPatrols_GetGroupByIndex(index)
    - HumanPatrols_GetTentByIndex(index)
    - HumanPatrols_GetLeaderByIndex(index)
    - HumanPatrols_IsPatrolActive(index)
    - HumanPatrols_IsPatrolCamped(index)
    - HumanPatrols_GetDestinationZoneIdByIndex(index)
    - HumanPatrols_IsHavenwoodsRoute(index)
    - Existing singular getters return the first matching patrol state.

**/
library HumanPatrols initializer Init requires CreepRespawn
    globals
        // Configuration
        private constant integer PATROL_OWNER_ID = 9
        private constant integer UNIT_PATROL_LEADER = 'h602'
        private constant integer UNIT_FOOTMAN = 'hfoo'
        private constant integer UNIT_TENT = 'n643'
        private constant integer ABILITY_WANDER = 'Awan'
        private constant integer PATROL_COUNT_MIN = 1
        private constant integer PATROL_COUNT_MAX = 2
        private constant integer FOOTMAN_COUNT_MIN = 4
        private constant integer FOOTMAN_COUNT_MAX = 6
        private constant integer LEADER_CHANCE_PERCENT = 35
        private constant real INITIAL_DELAY = 60.00
        private constant real MOVE_DURATION_MIN = 60.00
        private constant real MOVE_DURATION_MAX = 360.00
        private constant real CAMP_DURATION_MIN = 180.00
        private constant real CAMP_DURATION_MAX = 400.00
        private constant real RESPAWN_DELAY_MIN = 300.00
        private constant real RESPAWN_DELAY_MAX = 600.00
        private constant real LIFECYCLE_PERIOD = 1.00
        private constant real PATROL_MOVE_SPEED = 100.00
        private constant real MOVE_ORDER_REISSUE_PERIOD = 10.00
        private constant real SCOUT_ORDER_PERIOD = 8.00
        private constant real SCOUT_RADIUS = 900.00
        private constant boolean AUTO_RESPAWN = true

        private constant integer ROUTE_SERENE_TWILIGHT = 1
        private constant integer ROUTE_HAVENWOODS = 2
        private constant integer PHASE_INACTIVE = 0
        private constant integer PHASE_MOVING = 1
        private constant integer PHASE_CAMPED = 2
        private constant integer PHASE_WAITING_RESPAWN = 3

        private group array PatrolUnits
        private unit array PatrolTent
        private unit array PatrolLeader
        private integer array PatrolRoute
        private integer array PatrolPhase
        private integer array DestinationZoneId
        private integer array LastDestinationChoice
        private real array PhaseRemaining
        private real array ScoutElapsed
        private real array MoveOrderElapsed
        private real array MoveTargetX
        private real array MoveTargetY
        private real array CampX
        private real array CampY
        private boolean array Active

        private group WorkGroup = null
        private timer InitialTimer = null
        private timer LifecycleTimer = null
        private integer PatrolCount = 0
        private integer TentsBuilt = 0
        private boolean Enabled = true
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
    endfunction

    private function IsValidPatrolIndex takes integer patrolIndex returns boolean
        return patrolIndex >= 1 and patrolIndex <= PatrolCount
    endfunction

    private function SyncLegacyTent takes integer patrolIndex returns nothing
        if patrolIndex == 1 then
            set udg_PatrolGroup1Tent = PatrolTent[1]
        endif
    endfunction

    private function RemoveTent takes integer patrolIndex returns nothing
        if PatrolTent[patrolIndex] != null and GetUnitTypeId(PatrolTent[patrolIndex]) != 0 then
            call RemoveUnit(PatrolTent[patrolIndex])
        endif
        set PatrolTent[patrolIndex] = null
        call SyncLegacyTent(patrolIndex)
    endfunction

    private function ClearDeadUnits takes integer patrolIndex returns integer
        local unit picked = null
        local integer count = 0

        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(PatrolUnits[patrolIndex], WorkGroup)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if IsAlive(picked) then
                set count = count + 1
            else
                call GroupRemoveUnit(PatrolUnits[patrolIndex], picked)
                if picked == PatrolLeader[patrolIndex] then
                    set PatrolLeader[patrolIndex] = null
                endif
            endif
        endloop
        set picked = null
        return count
    endfunction

    private function ClearPatrolUnits takes integer patrolIndex, boolean removeUnits returns nothing
        local unit picked = null

        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(PatrolUnits[patrolIndex], WorkGroup)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            call GroupRemoveUnit(PatrolUnits[patrolIndex], picked)
            if GetUnitTypeId(picked) != 0 then
                call UnitRemoveAbility(picked, ABILITY_WANDER)
                call SetUnitMoveSpeed(picked, GetUnitDefaultMoveSpeed(picked))
                if removeUnits then
                    call RemoveUnit(picked)
                endif
            endif
        endloop
        set PatrolLeader[patrolIndex] = null
        set picked = null
    endfunction

    private function AnyLeaderAlive takes nothing returns boolean
        local integer patrolIndex = 1

        loop
            exitwhen patrolIndex > PatrolCount
            if IsAlive(PatrolLeader[patrolIndex]) then
                return true
            endif
            set patrolIndex = patrolIndex + 1
        endloop
        return false
    endfunction

    private function ChooseDestination takes integer patrolIndex returns integer
        local integer choice

        if PatrolRoute[patrolIndex] == ROUTE_HAVENWOODS then
            set choice = 3
        elseif LastDestinationChoice[patrolIndex] == 1 then
            set choice = 2
        elseif LastDestinationChoice[patrolIndex] == 2 then
            set choice = 1
        else
            set choice = GetRandomInt(1, 2)
        endif
        set LastDestinationChoice[patrolIndex] = choice
        return choice
    endfunction

    private function GetDestinationRect takes integer choice returns rect
        if choice == 1 then
            return gg_rct_001TwilightGroveFull
        elseif choice == 2 then
            return gg_rct_02SereneGlade
        endif
        return gg_rct_07Havenwoods
    endfunction

    private function GetDestinationZoneIdForChoice takes integer choice returns integer
        if choice == 1 then
            return 1
        elseif choice == 2 then
            return 2
        endif
        return 7
    endfunction

    private function GetSpawnRect takes integer patrolIndex returns rect
        if PatrolRoute[patrolIndex] == ROUTE_HAVENWOODS then
            return gg_rct_07Havenwoods
        endif
        return gg_rct_PatrolSpawnPoint
    endfunction

    private function OrderMovingFormation takes integer patrolIndex returns nothing
        call GroupPointOrder(PatrolUnits[patrolIndex], "attack", MoveTargetX[patrolIndex], MoveTargetY[patrolIndex])
    endfunction

    private function StartMoving takes integer patrolIndex returns nothing
        local rect destination = null
        local unit picked = null
        local integer choice

        if ClearDeadUnits(patrolIndex) == 0 then
            set PatrolPhase[patrolIndex] = PHASE_WAITING_RESPAWN
            set PhaseRemaining[patrolIndex] = GetRandomReal(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)
            set Active[patrolIndex] = false
            call RemoveTent(patrolIndex)
            return
        endif
        call RemoveTent(patrolIndex)
        set choice = ChooseDestination(patrolIndex)
        set destination = GetDestinationRect(choice)
        set DestinationZoneId[patrolIndex] = GetDestinationZoneIdForChoice(choice)
        set MoveTargetX[patrolIndex] = GetRandomReal(GetRectMinX(destination), GetRectMaxX(destination))
        set MoveTargetY[patrolIndex] = GetRandomReal(GetRectMinY(destination), GetRectMaxY(destination))
        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(PatrolUnits[patrolIndex], WorkGroup)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if IsAlive(picked) then
                call UnitRemoveAbility(picked, ABILITY_WANDER)
                call SetUnitMoveSpeed(picked, PATROL_MOVE_SPEED)
            endif
        endloop
        call OrderMovingFormation(patrolIndex)
        set PatrolPhase[patrolIndex] = PHASE_MOVING
        set PhaseRemaining[patrolIndex] = GetRandomReal(MOVE_DURATION_MIN, MOVE_DURATION_MAX)
        set ScoutElapsed[patrolIndex] = 0.00
        set MoveOrderElapsed[patrolIndex] = 0.00
        set picked = null
        set destination = null
    endfunction

    private function StartCamping takes integer patrolIndex returns nothing
        local player owner = Player(PATROL_OWNER_ID)
        local unit picked = null
        local unit anchor = null

        if ClearDeadUnits(patrolIndex) == 0 then
            set PatrolPhase[patrolIndex] = PHASE_WAITING_RESPAWN
            set PhaseRemaining[patrolIndex] = GetRandomReal(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)
            set Active[patrolIndex] = false
            set owner = null
            return
        endif
        set anchor = FirstOfGroup(PatrolUnits[patrolIndex])
        set CampX[patrolIndex] = GetUnitX(anchor)
        set CampY[patrolIndex] = GetUnitY(anchor)
        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(PatrolUnits[patrolIndex], WorkGroup)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if IsAlive(picked) then
                call IssueImmediateOrder(picked, "stop")
                if picked != PatrolLeader[patrolIndex] then
                    call UnitAddAbility(picked, ABILITY_WANDER)
                endif
            endif
        endloop
        call RemoveTent(patrolIndex)
        set PatrolTent[patrolIndex] = CreateUnit(owner, UNIT_TENT, CampX[patrolIndex] + 100.00, CampY[patrolIndex] + 100.00, bj_UNIT_FACING)
        if PatrolTent[patrolIndex] != null then
            call CreepRespawn_DiscardUnit(PatrolTent[patrolIndex])
            set TentsBuilt = TentsBuilt + 1
        endif
        call SyncLegacyTent(patrolIndex)
        set PatrolPhase[patrolIndex] = PHASE_CAMPED
        set PhaseRemaining[patrolIndex] = GetRandomReal(CAMP_DURATION_MIN, CAMP_DURATION_MAX)
        set ScoutElapsed[patrolIndex] = 0.00
        set MoveOrderElapsed[patrolIndex] = 0.00
        set anchor = null
        set picked = null
        set owner = null
    endfunction

    private function SpawnPatrolInternal takes integer patrolIndex returns boolean
        local player owner = Player(PATROL_OWNER_ID)
        local rect spawnRect = null
        local unit spawned = null
        local integer footmanCount = GetRandomInt(FOOTMAN_COUNT_MIN, FOOTMAN_COUNT_MAX)
        local integer index = 0
        local real spawnX
        local real spawnY

        if Active[patrolIndex] or not Enabled then
            set owner = null
            return false
        endif
        call RemoveTent(patrolIndex)
        call ClearPatrolUnits(patrolIndex, true)
        set spawnRect = GetSpawnRect(patrolIndex)
        set spawnX = GetRandomReal(GetRectMinX(spawnRect), GetRectMaxX(spawnRect))
        set spawnY = GetRandomReal(GetRectMinY(spawnRect), GetRectMaxY(spawnRect))
        if not AnyLeaderAlive() and GetRandomInt(1, 100) <= LEADER_CHANCE_PERCENT then
            set PatrolLeader[patrolIndex] = CreateUnit(owner, UNIT_PATROL_LEADER, spawnX, spawnY, bj_UNIT_FACING)
            if PatrolLeader[patrolIndex] != null then
                call CreepRespawn_DiscardUnit(PatrolLeader[patrolIndex])
                call GroupAddUnit(PatrolUnits[patrolIndex], PatrolLeader[patrolIndex])
            endif
        endif
        loop
            exitwhen index >= footmanCount
            set spawned = CreateUnit(owner, UNIT_FOOTMAN, spawnX + GetRandomReal(-120.00, 120.00), spawnY + GetRandomReal(-120.00, 120.00), bj_UNIT_FACING)
            if spawned != null then
                call CreepRespawn_DiscardUnit(spawned)
                call GroupAddUnit(PatrolUnits[patrolIndex], spawned)
            endif
            set index = index + 1
        endloop
        set Active[patrolIndex] = FirstOfGroup(PatrolUnits[patrolIndex]) != null
        if Active[patrolIndex] then
            call StartMoving(patrolIndex)
        else
            set PatrolPhase[patrolIndex] = PHASE_WAITING_RESPAWN
            set PhaseRemaining[patrolIndex] = GetRandomReal(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)
        endif
        set spawned = null
        set spawnRect = null
        set owner = null
        return Active[patrolIndex]
    endfunction

    private function ScoutLeader takes integer patrolIndex returns nothing
        local real angle
        local real distance

        if IsAlive(PatrolLeader[patrolIndex]) then
            set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
            set distance = GetRandomReal(200.00, SCOUT_RADIUS)
            call IssuePointOrder(PatrolLeader[patrolIndex], "move", CampX[patrolIndex] + distance * Cos(angle), CampY[patrolIndex] + distance * Sin(angle))
        endif
    endfunction

    private function UpdatePatrol takes integer patrolIndex returns nothing
        local integer livingCount

        if PatrolTent[patrolIndex] != null and not IsAlive(PatrolTent[patrolIndex]) then
            set PatrolTent[patrolIndex] = null
            call SyncLegacyTent(patrolIndex)
        endif
        if Active[patrolIndex] then
            set livingCount = ClearDeadUnits(patrolIndex)
            if livingCount == 0 then
                set Active[patrolIndex] = false
                call RemoveTent(patrolIndex)
                if AUTO_RESPAWN then
                    set PatrolPhase[patrolIndex] = PHASE_WAITING_RESPAWN
                    set PhaseRemaining[patrolIndex] = GetRandomReal(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)
                else
                    set PatrolPhase[patrolIndex] = PHASE_INACTIVE
                endif
                return
            endif
        endif
        set PhaseRemaining[patrolIndex] = PhaseRemaining[patrolIndex] - LIFECYCLE_PERIOD
        if PatrolPhase[patrolIndex] == PHASE_CAMPED then
            set ScoutElapsed[patrolIndex] = ScoutElapsed[patrolIndex] + LIFECYCLE_PERIOD
            if ScoutElapsed[patrolIndex] >= SCOUT_ORDER_PERIOD then
                set ScoutElapsed[patrolIndex] = 0.00
                call ScoutLeader(patrolIndex)
            endif
        elseif PatrolPhase[patrolIndex] == PHASE_MOVING then
            set MoveOrderElapsed[patrolIndex] = MoveOrderElapsed[patrolIndex] + LIFECYCLE_PERIOD
            if MoveOrderElapsed[patrolIndex] >= MOVE_ORDER_REISSUE_PERIOD then
                set MoveOrderElapsed[patrolIndex] = 0.00
                call OrderMovingFormation(patrolIndex)
            endif
        endif
        if PhaseRemaining[patrolIndex] <= 0.00 then
            if PatrolPhase[patrolIndex] == PHASE_MOVING then
                call StartCamping(patrolIndex)
            elseif PatrolPhase[patrolIndex] == PHASE_CAMPED then
                call StartMoving(patrolIndex)
            elseif PatrolPhase[patrolIndex] == PHASE_WAITING_RESPAWN and AUTO_RESPAWN then
                call SpawnPatrolInternal(patrolIndex)
            endif
        endif
    endfunction

    private function LifecycleTick takes nothing returns nothing
        local integer patrolIndex = 1

        if not Enabled then
            return
        endif
        loop
            exitwhen patrolIndex > PatrolCount
            call UpdatePatrol(patrolIndex)
            set patrolIndex = patrolIndex + 1
        endloop
    endfunction

    private function ConfigurePatrols takes nothing returns nothing
        set PatrolCount = GetRandomInt(PATROL_COUNT_MIN, PATROL_COUNT_MAX)
        if PatrolCount == 1 then
            set PatrolRoute[1] = GetRandomInt(ROUTE_SERENE_TWILIGHT, ROUTE_HAVENWOODS)
        else
            set PatrolRoute[1] = ROUTE_SERENE_TWILIGHT
            set PatrolRoute[2] = ROUTE_HAVENWOODS
        endif
    endfunction

    private function OnInitialDelay takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()
        local integer patrolIndex = 1

        call PauseTimer(expiredTimer)
        if Enabled then
            loop
                exitwhen patrolIndex > PatrolCount
                call SpawnPatrolInternal(patrolIndex)
                set patrolIndex = patrolIndex + 1
            endloop
            call TimerStart(LifecycleTimer, LIFECYCLE_PERIOD, true, function LifecycleTick)
        endif
        set expiredTimer = null
    endfunction

    public function Start takes nothing returns nothing
        local integer patrolIndex = 1

        set Enabled = true
        call PauseTimer(InitialTimer)
        loop
            exitwhen patrolIndex > PatrolCount
            if not Active[patrolIndex] then
                call SpawnPatrolInternal(patrolIndex)
            endif
            set patrolIndex = patrolIndex + 1
        endloop
        call TimerStart(LifecycleTimer, LIFECYCLE_PERIOD, true, function LifecycleTick)
    endfunction

    public function Stop takes boolean removeUnits returns nothing
        local integer patrolIndex = 1

        set Enabled = false
        call PauseTimer(InitialTimer)
        call PauseTimer(LifecycleTimer)
        loop
            exitwhen patrolIndex > PatrolCount
            set Active[patrolIndex] = false
            set PatrolPhase[patrolIndex] = PHASE_INACTIVE
            set PhaseRemaining[patrolIndex] = 0.00
            call RemoveTent(patrolIndex)
            call ClearPatrolUnits(patrolIndex, removeUnits)
            set patrolIndex = patrolIndex + 1
        endloop
    endfunction

    public function Respawn takes nothing returns boolean
        local integer patrolIndex = 1
        local boolean spawnedAny = false

        if not Enabled then
            return false
        endif
        loop
            exitwhen patrolIndex > PatrolCount
            if Active[patrolIndex] then
                call RemoveTent(patrolIndex)
                call ClearPatrolUnits(patrolIndex, true)
                set Active[patrolIndex] = false
            endif
            if SpawnPatrolInternal(patrolIndex) then
                set spawnedAny = true
            endif
            set patrolIndex = patrolIndex + 1
        endloop
        call TimerStart(LifecycleTimer, LIFECYCLE_PERIOD, true, function LifecycleTick)
        return spawnedAny
    endfunction

    public function ForceMove takes nothing returns boolean
        local integer patrolIndex = 1
        local boolean movedAny = false

        loop
            exitwhen patrolIndex > PatrolCount
            if Active[patrolIndex] then
                call StartMoving(patrolIndex)
                set movedAny = true
            endif
            set patrolIndex = patrolIndex + 1
        endloop
        return movedAny
    endfunction

    public function ForceCamp takes nothing returns boolean
        local integer patrolIndex = 1
        local boolean campedAny = false

        loop
            exitwhen patrolIndex > PatrolCount
            if Active[patrolIndex] then
                call StartCamping(patrolIndex)
                set campedAny = true
            endif
            set patrolIndex = patrolIndex + 1
        endloop
        return campedAny
    endfunction

    public function GetPatrolCount takes nothing returns integer
        return PatrolCount
    endfunction

    public function GetGroupByIndex takes integer patrolIndex returns group
        if IsValidPatrolIndex(patrolIndex) then
            return PatrolUnits[patrolIndex]
        endif
        return null
    endfunction

    public function GetTentByIndex takes integer patrolIndex returns unit
        if IsValidPatrolIndex(patrolIndex) then
            return PatrolTent[patrolIndex]
        endif
        return null
    endfunction

    public function GetLeaderByIndex takes integer patrolIndex returns unit
        if IsValidPatrolIndex(patrolIndex) then
            return PatrolLeader[patrolIndex]
        endif
        return null
    endfunction

    public function IsPatrolActive takes integer patrolIndex returns boolean
        return IsValidPatrolIndex(patrolIndex) and Active[patrolIndex]
    endfunction

    public function IsPatrolCamped takes integer patrolIndex returns boolean
        return IsValidPatrolIndex(patrolIndex) and Active[patrolIndex] and PatrolPhase[patrolIndex] == PHASE_CAMPED
    endfunction

    public function GetDestinationZoneIdByIndex takes integer patrolIndex returns integer
        if IsValidPatrolIndex(patrolIndex) then
            return DestinationZoneId[patrolIndex]
        endif
        return 0
    endfunction

    public function IsHavenwoodsRoute takes integer patrolIndex returns boolean
        return IsValidPatrolIndex(patrolIndex) and PatrolRoute[patrolIndex] == ROUTE_HAVENWOODS
    endfunction

    public function GetGroup takes nothing returns group
        return PatrolUnits[1]
    endfunction

    public function GetTent takes nothing returns unit
        local integer patrolIndex = 1

        loop
            exitwhen patrolIndex > PatrolCount
            if PatrolTent[patrolIndex] != null then
                return PatrolTent[patrolIndex]
            endif
            set patrolIndex = patrolIndex + 1
        endloop
        return null
    endfunction

    public function GetLeader takes nothing returns unit
        local integer patrolIndex = 1

        loop
            exitwhen patrolIndex > PatrolCount
            if IsAlive(PatrolLeader[patrolIndex]) then
                return PatrolLeader[patrolIndex]
            endif
            set patrolIndex = patrolIndex + 1
        endloop
        return null
    endfunction

    public function IsActive takes nothing returns boolean
        local integer patrolIndex = 1

        loop
            exitwhen patrolIndex > PatrolCount
            if Active[patrolIndex] then
                return true
            endif
            set patrolIndex = patrolIndex + 1
        endloop
        return false
    endfunction

    public function IsCamped takes nothing returns boolean
        local integer patrolIndex = 1

        loop
            exitwhen patrolIndex > PatrolCount
            if Active[patrolIndex] and PatrolPhase[patrolIndex] == PHASE_CAMPED then
                return true
            endif
            set patrolIndex = patrolIndex + 1
        endloop
        return false
    endfunction

    public function GetDestinationZoneId takes nothing returns integer
        local integer patrolIndex = 1

        loop
            exitwhen patrolIndex > PatrolCount
            if Active[patrolIndex] then
                return DestinationZoneId[patrolIndex]
            endif
            set patrolIndex = patrolIndex + 1
        endloop
        return 0
    endfunction

    public function GetTentsBuilt takes nothing returns integer
        return TentsBuilt
    endfunction

    private function Init takes nothing returns nothing
        local integer patrolIndex = 1

        if udg_PatrolGroup1 == null then
            set udg_PatrolGroup1 = CreateGroup()
        endif
        set PatrolUnits[1] = udg_PatrolGroup1
        loop
            exitwhen patrolIndex > PATROL_COUNT_MAX
            if PatrolUnits[patrolIndex] == null then
                set PatrolUnits[patrolIndex] = CreateGroup()
            endif
            set patrolIndex = patrolIndex + 1
        endloop
        set WorkGroup = CreateGroup()
        set InitialTimer = CreateTimer()
        set LifecycleTimer = CreateTimer()
        call ConfigurePatrols()
        call TimerStart(InitialTimer, INITIAL_DELAY, false, function OnInitialDelay)
    endfunction
endlibrary
