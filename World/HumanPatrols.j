/**
    HumanPatrols

    Author: Valdemar
    Version: 1.0.0

    Description:
    Runs a recurring Alliance patrol through Twilight Grove, Sereneglade,
    and Havenwoods. The patrol alternates between travel and camps, removes
    its tent before moving, and may include a unique scouting captain.

    Credits:
    - World/_oldGUI/Human Patrols

    How to install:
    Import this library, keep PatrolSpawnPoint and the three zone rects, then
    disable the four legacy Human Patrol GUI triggers. The system starts after
    the configured initial delay.

    API:
    - HumanPatrols_Start()
    - HumanPatrols_Stop(removeUnits)
    - HumanPatrols_Respawn()
    - HumanPatrols_ForceMove()
    - HumanPatrols_ForceCamp()
    - HumanPatrols_GetGroup()
    - HumanPatrols_GetTent()
    - HumanPatrols_GetLeader()
    - HumanPatrols_IsActive()
    - HumanPatrols_IsCamped()
    - HumanPatrols_GetDestinationZoneId()
    - HumanPatrols_GetTentsBuilt()

**/
library HumanPatrols initializer Init
    globals
        // Configuration
        private constant integer PATROL_OWNER_ID = 7
        private constant integer UNIT_PATROL_LEADER = 'h602'
        private constant integer UNIT_FOOTMAN = 'hfoo'
        private constant integer UNIT_TENT = 'n643'
        private constant integer ABILITY_WANDER = 'Awan'
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
        private constant real SCOUT_ORDER_PERIOD = 8.00
        private constant real SCOUT_RADIUS = 900.00
        private constant boolean AUTO_RESPAWN = true

        private constant integer PHASE_INACTIVE = 0
        private constant integer PHASE_MOVING = 1
        private constant integer PHASE_CAMPED = 2
        private constant integer PHASE_WAITING_RESPAWN = 3

        private group PatrolUnits = null
        private group WorkGroup = null
        private timer InitialTimer = null
        private timer LifecycleTimer = null
        private unit PatrolTent = null
        private unit PatrolLeader = null
        private integer PatrolPhase = PHASE_INACTIVE
        private integer DestinationZoneId = 0
        private integer LastDestinationChoice = 0
        private integer TentsBuilt = 0
        private real PhaseRemaining = 0.00
        private real ScoutElapsed = 0.00
        private real CampX = 0.00
        private real CampY = 0.00
        private boolean Enabled = true
        private boolean Active = false
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
    endfunction

    private function RemoveTent takes nothing returns nothing
        if PatrolTent != null and GetUnitTypeId(PatrolTent) != 0 then
            call RemoveUnit(PatrolTent)
        endif
        set PatrolTent = null
        set udg_PatrolGroup1Tent = null
    endfunction

    private function ClearDeadUnits takes nothing returns integer
        local unit picked = null
        local integer count = 0

        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(PatrolUnits, WorkGroup)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if IsAlive(picked) then
                set count = count + 1
            else
                call GroupRemoveUnit(PatrolUnits, picked)
                if picked == PatrolLeader then
                    set PatrolLeader = null
                endif
            endif
        endloop
        set picked = null
        return count
    endfunction

    private function ClearPatrolUnits takes boolean removeUnits returns nothing
        local unit picked = null

        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(PatrolUnits, WorkGroup)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            call GroupRemoveUnit(PatrolUnits, picked)
            if GetUnitTypeId(picked) != 0 then
                call UnitRemoveAbility(picked, ABILITY_WANDER)
                call SetUnitMoveSpeed(picked, GetUnitDefaultMoveSpeed(picked))
                if removeUnits then
                    call RemoveUnit(picked)
                endif
            endif
        endloop
        set PatrolLeader = null
        set picked = null
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

    private function ChooseDestination takes nothing returns integer
        local integer choice = GetRandomInt(1, 3)

        if choice == LastDestinationChoice then
            set choice = choice + GetRandomInt(1, 2)
            if choice > 3 then
                set choice = choice - 3
            endif
        endif
        set LastDestinationChoice = choice
        return choice
    endfunction

    private function StartMoving takes nothing returns nothing
        local rect destination = null
        local unit picked = null
        local integer choice
        local real targetX
        local real targetY

        if ClearDeadUnits() == 0 then
            set PatrolPhase = PHASE_WAITING_RESPAWN
            set PhaseRemaining = GetRandomReal(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)
            set Active = false
            call RemoveTent()
            return
        endif
        call RemoveTent()
        set choice = ChooseDestination()
        set destination = GetDestinationRect(choice)
        set DestinationZoneId = GetDestinationZoneIdForChoice(choice)
        set targetX = GetRandomReal(GetRectMinX(destination), GetRectMaxX(destination))
        set targetY = GetRandomReal(GetRectMinY(destination), GetRectMaxY(destination))
        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(PatrolUnits, WorkGroup)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if IsAlive(picked) then
                call UnitRemoveAbility(picked, ABILITY_WANDER)
                call SetUnitMoveSpeed(picked, PATROL_MOVE_SPEED)
                call IssuePointOrder(picked, "patrol", targetX, targetY)
            endif
        endloop
        set PatrolPhase = PHASE_MOVING
        set PhaseRemaining = GetRandomReal(MOVE_DURATION_MIN, MOVE_DURATION_MAX)
        set ScoutElapsed = 0.00
        set picked = null
        set destination = null
    endfunction

    private function StartCamping takes nothing returns nothing
        local player owner = Player(PATROL_OWNER_ID)
        local unit picked = null
        local unit anchor = null

        if ClearDeadUnits() == 0 then
            set PatrolPhase = PHASE_WAITING_RESPAWN
            set PhaseRemaining = GetRandomReal(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)
            set Active = false
            set owner = null
            return
        endif
        set anchor = FirstOfGroup(PatrolUnits)
        set CampX = GetUnitX(anchor)
        set CampY = GetUnitY(anchor)
        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(PatrolUnits, WorkGroup)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if IsAlive(picked) then
                call IssueImmediateOrder(picked, "stop")
                if picked != PatrolLeader then
                    call UnitAddAbility(picked, ABILITY_WANDER)
                endif
            endif
        endloop
        call RemoveTent()
        set PatrolTent = CreateUnit(owner, UNIT_TENT, CampX + 100.00, CampY + 100.00, bj_UNIT_FACING)
        set udg_PatrolGroup1Tent = PatrolTent
        if PatrolTent != null then
            set TentsBuilt = TentsBuilt + 1
        endif
        set PatrolPhase = PHASE_CAMPED
        set PhaseRemaining = GetRandomReal(CAMP_DURATION_MIN, CAMP_DURATION_MAX)
        set ScoutElapsed = 0.00
        set anchor = null
        set picked = null
        set owner = null
    endfunction

    private function SpawnPatrolInternal takes nothing returns boolean
        local player owner = Player(PATROL_OWNER_ID)
        local unit spawned = null
        local integer footmanCount = GetRandomInt(FOOTMAN_COUNT_MIN, FOOTMAN_COUNT_MAX)
        local integer index = 0
        local real spawnX
        local real spawnY

        if Active or not Enabled then
            set owner = null
            return false
        endif
        call RemoveTent()
        call ClearPatrolUnits(true)
        set spawnX = GetRandomReal(GetRectMinX(gg_rct_PatrolSpawnPoint), GetRectMaxX(gg_rct_PatrolSpawnPoint))
        set spawnY = GetRandomReal(GetRectMinY(gg_rct_PatrolSpawnPoint), GetRectMaxY(gg_rct_PatrolSpawnPoint))
        if GetRandomInt(1, 100) <= LEADER_CHANCE_PERCENT then
            set PatrolLeader = CreateUnit(owner, UNIT_PATROL_LEADER, spawnX, spawnY, bj_UNIT_FACING)
            if PatrolLeader != null then
                call GroupAddUnit(PatrolUnits, PatrolLeader)
            endif
        endif
        loop
            exitwhen index >= footmanCount
            set spawned = CreateUnit(owner, UNIT_FOOTMAN, spawnX + GetRandomReal(-120.00, 120.00), spawnY + GetRandomReal(-120.00, 120.00), bj_UNIT_FACING)
            if spawned != null then
                call GroupAddUnit(PatrolUnits, spawned)
            endif
            set index = index + 1
        endloop
        set Active = FirstOfGroup(PatrolUnits) != null
        if Active then
            call StartMoving()
        else
            set PatrolPhase = PHASE_WAITING_RESPAWN
            set PhaseRemaining = GetRandomReal(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)
        endif
        set spawned = null
        set owner = null
        return Active
    endfunction

    private function ScoutLeader takes nothing returns nothing
        local real angle
        local real distance

        if IsAlive(PatrolLeader) then
            set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
            set distance = GetRandomReal(200.00, SCOUT_RADIUS)
            call IssuePointOrder(PatrolLeader, "move", CampX + distance * Cos(angle), CampY + distance * Sin(angle))
        endif
    endfunction

    private function LifecycleTick takes nothing returns nothing
        local integer livingCount

        if not Enabled then
            return
        endif
        if PatrolTent != null and not IsAlive(PatrolTent) then
            set PatrolTent = null
            set udg_PatrolGroup1Tent = null
        endif
        if Active then
            set livingCount = ClearDeadUnits()
            if livingCount == 0 then
                set Active = false
                call RemoveTent()
                if AUTO_RESPAWN then
                    set PatrolPhase = PHASE_WAITING_RESPAWN
                    set PhaseRemaining = GetRandomReal(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)
                else
                    set PatrolPhase = PHASE_INACTIVE
                    call PauseTimer(LifecycleTimer)
                endif
                return
            endif
        endif
        set PhaseRemaining = PhaseRemaining - LIFECYCLE_PERIOD
        if PatrolPhase == PHASE_CAMPED then
            set ScoutElapsed = ScoutElapsed + LIFECYCLE_PERIOD
            if ScoutElapsed >= SCOUT_ORDER_PERIOD then
                set ScoutElapsed = 0.00
                call ScoutLeader()
            endif
        endif
        if PhaseRemaining <= 0.00 then
            if PatrolPhase == PHASE_MOVING then
                call StartCamping()
            elseif PatrolPhase == PHASE_CAMPED then
                call StartMoving()
            elseif PatrolPhase == PHASE_WAITING_RESPAWN and AUTO_RESPAWN then
                call SpawnPatrolInternal()
            endif
        endif
    endfunction

    private function OnInitialDelay takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()

        call PauseTimer(expiredTimer)
        if Enabled then
            call SpawnPatrolInternal()
            call TimerStart(LifecycleTimer, LIFECYCLE_PERIOD, true, function LifecycleTick)
        endif
        set expiredTimer = null
    endfunction

    public function Start takes nothing returns nothing
        set Enabled = true
        call PauseTimer(InitialTimer)
        if not Active then
            call SpawnPatrolInternal()
        endif
        call TimerStart(LifecycleTimer, LIFECYCLE_PERIOD, true, function LifecycleTick)
    endfunction

    public function Stop takes boolean removeUnits returns nothing
        set Enabled = false
        set Active = false
        set PatrolPhase = PHASE_INACTIVE
        set PhaseRemaining = 0.00
        call PauseTimer(InitialTimer)
        call PauseTimer(LifecycleTimer)
        call RemoveTent()
        call ClearPatrolUnits(removeUnits)
    endfunction

    public function Respawn takes nothing returns boolean
        if not Enabled then
            return false
        endif
        if Active then
            call RemoveTent()
            call ClearPatrolUnits(true)
            set Active = false
        endif
        if SpawnPatrolInternal() then
            call TimerStart(LifecycleTimer, LIFECYCLE_PERIOD, true, function LifecycleTick)
            return true
        endif
        return false
    endfunction

    public function ForceMove takes nothing returns boolean
        if not Enabled or not Active then
            return false
        endif
        call StartMoving()
        return true
    endfunction

    public function ForceCamp takes nothing returns boolean
        if not Enabled or not Active then
            return false
        endif
        call StartCamping()
        return true
    endfunction

    public function GetGroup takes nothing returns group
        return PatrolUnits
    endfunction

    public function GetTent takes nothing returns unit
        return PatrolTent
    endfunction

    public function GetLeader takes nothing returns unit
        return PatrolLeader
    endfunction

    public function IsActive takes nothing returns boolean
        return Active
    endfunction

    public function IsCamped takes nothing returns boolean
        return Active and PatrolPhase == PHASE_CAMPED
    endfunction

    public function GetDestinationZoneId takes nothing returns integer
        return DestinationZoneId
    endfunction

    public function GetTentsBuilt takes nothing returns integer
        return TentsBuilt
    endfunction

    private function Init takes nothing returns nothing
        if udg_PatrolGroup1 == null then
            set udg_PatrolGroup1 = CreateGroup()
        endif
        set PatrolUnits = udg_PatrolGroup1
        set WorkGroup = CreateGroup()
        set InitialTimer = CreateTimer()
        set LifecycleTimer = CreateTimer()
        call TimerStart(InitialTimer, INITIAL_DELAY, false, function OnInitialDelay)
    endfunction
endlibrary
