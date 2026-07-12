/**
    HordeMainBasePeons

    Author: Valdemar
    Version:

    Description:
    Ambient AIRoutines setup for the Horde Main base peons. AIRoutines creates
    and manages Orc Peon units (`'opeo'`) at `gg_rct_HordeMainBasePeons`; they
    harvest lumber by day, wander and idle around `gg_rct_HordeScoutBase`,
    and move to the camp to sleep at night.

    Credits:
    - PotS AI JASS migration

    How to install:
    Import after `AIRoutines.j`. The map must provide `gg_rct_HordeMainBasePeons`
    and `gg_rct_HordeScoutBase`.

    API:
    call HordeMainBasePeons_Refresh()

**/
library HordeMainBasePeons initializer Init requires AIRoutines

globals
    // Configuration
    private constant real MP_DAWN_TIME = 6.00
    private constant real MP_DUSK_TIME = 18.00
    private constant real MP_SYNC_INTERVAL = 15.00
    private constant real MP_RESPAWN_DELAY = 60.00
    private constant real MP_RANDOM_FACING = -1.00
    private constant real MP_HARVEST_RANGE = 1024.00
    private constant real MP_HARVEST_RANGE_SQ = 1048576.00
    private constant integer MP_OWNER_PLAYER_ID = 1
    // Horde Base parent zone for the mountain camp.
    private constant integer MP_ROUTINE_ZONE_ID = 8810
    private constant integer MP_PEON_UNIT_TYPE_ID = 'opeo'
    private constant integer MP_PEON_COUNT = 5

    private integer MP_DayRoutineId = 0
    private integer MP_NightRoutineId = 0
    private integer MP_SpawnGroupId = 0
    private boolean MP_NightActive = false
    private boolean MP_HarvestIssued = false
    private rect MP_HarvestRect = null
    private unit MP_HarvestPeon = null
    private timer MP_SyncTimer = null
    private trigger MP_DawnTrigger = null
    private trigger MP_DuskTrigger = null
endglobals

private function IsNight takes nothing returns boolean
    local real timeOfDay = GetFloatGameState(GAME_STATE_TIME_OF_DAY)
    return timeOfDay < MP_DAWN_TIME or timeOfDay >= MP_DUSK_TIME
endfunction

private function GetActiveRoutineId takes nothing returns integer
    if IsNight() then
        return MP_NightRoutineId
    endif
    return MP_DayRoutineId
endfunction

private function ApplyRoutineMode takes boolean useNightRoutine returns nothing
    if MP_SpawnGroupId > 0 then
        if useNightRoutine then
            call AIRoutines_SetManagedUnitGroupRoutine(MP_SpawnGroupId, MP_NightRoutineId)
        else
            call AIRoutines_SetManagedUnitGroupRoutine(MP_SpawnGroupId, MP_DayRoutineId)
        endif
    endif
    set MP_NightActive = useNightRoutine
endfunction

public function Refresh takes nothing returns nothing
    call ApplyRoutineMode(IsNight())
    call AIRoutines_RefillManagedUnitGroup(MP_SpawnGroupId)
endfunction

private function SyncDayNightMode takes nothing returns nothing
    local boolean useNightRoutine = IsNight()
    if useNightRoutine != MP_NightActive then
        call ApplyRoutineMode(useNightRoutine)
    endif
    call AIRoutines_RefillManagedUnitGroup(MP_SpawnGroupId)
endfunction

private function CampAction takes nothing returns nothing
    local unit whichUnit = AIRoutines_EventUnit
    local integer action
    local real x
    local real y

    if whichUnit == null then
        return
    endif

    set action = GetRandomInt(1, 5)
    if action == 1 then
        call IssueImmediateOrder(whichUnit, "stop")
        call SetUnitAnimation(whichUnit, "stand")
    elseif action == 2 then
        call IssueImmediateOrder(whichUnit, "stop")
        call SetUnitAnimation(whichUnit, "stand work")
    elseif action == 3 then
        call IssueImmediateOrder(whichUnit, "stop")
        call SetUnitAnimation(whichUnit, "attack")
    elseif action == 4 then
        set x = GetRandomReal(GetRectMinX(gg_rct_HordeScoutBase), GetRectMaxX(gg_rct_HordeScoutBase))
        set y = GetRandomReal(GetRectMinY(gg_rct_HordeScoutBase), GetRectMaxY(gg_rct_HordeScoutBase))
        call IssuePointOrder(whichUnit, "move", x, y)
    else
        call IssueImmediateOrder(whichUnit, "stop")
        call SetUnitAnimation(whichUnit, "stand victory")
    endif

    set whichUnit = null
endfunction

private function TryHarvestNearbyDestructable takes nothing returns nothing
    local destructable whichDestructable = GetEnumDestructable()
    local real dx
    local real dy

    if MP_HarvestIssued or whichDestructable == null or MP_HarvestPeon == null then
        set whichDestructable = null
        return
    endif
    if GetDestructableLife(whichDestructable) <= 0.405 then
        set whichDestructable = null
        return
    endif

    set dx = GetDestructableX(whichDestructable) - GetUnitX(MP_HarvestPeon)
    set dy = GetDestructableY(whichDestructable) - GetUnitY(MP_HarvestPeon)
    if dx * dx + dy * dy <= MP_HARVEST_RANGE_SQ then
        set MP_HarvestIssued = IssueTargetOrder(MP_HarvestPeon, "harvest", whichDestructable)
    endif

    set whichDestructable = null
endfunction

private function HarvestNearbyLumber takes nothing returns nothing
    local unit whichUnit = AIRoutines_EventUnit
    local real x
    local real y

    if whichUnit == null then
        return
    endif

    set x = GetUnitX(whichUnit)
    set y = GetUnitY(whichUnit)
    set MP_HarvestPeon = whichUnit
    set MP_HarvestIssued = false
    call SetRect(MP_HarvestRect, x - MP_HARVEST_RANGE, y - MP_HARVEST_RANGE, x + MP_HARVEST_RANGE, y + MP_HARVEST_RANGE)
    call EnumDestructablesInRect(MP_HarvestRect, null, function TryHarvestNearbyDestructable)
    if not MP_HarvestIssued then
        call IssueImmediateOrder(whichUnit, "stop")
    endif

    set MP_HarvestPeon = null
    set whichUnit = null
endfunction

private function CreateDayRoutine takes nothing returns integer
    local integer routineId = AIRoutines_CreateRoutine("Horde Base Peons Day")
    if routineId <= 0 then
        return 0
    endif

    call AIRoutines_AddRectOrderStep(routineId, "move", gg_rct_MountainPeons, 6.00, 12.00)
    call AIRoutines_AddCallbackStep(routineId, 45.00, 80.00, function HarvestNearbyLumber)
    call AIRoutines_AddWanderStep(routineId, gg_rct_HordeMountainCamp, 8.00, 18.00)
    call AIRoutines_AddCallbackStep(routineId, 4.00, 10.00, function CampAction)
    call AIRoutines_AddWaitStep(routineId, 3.00, 8.00)
    call AIRoutines_AddRectOrderStep(routineId, "move", gg_rct_MountainPeons, 6.00, 12.00)
    call AIRoutines_AddCallbackStep(routineId, 35.00, 70.00, function HarvestNearbyLumber)
    return routineId
endfunction

private function CreateNightRoutine takes nothing returns integer
    local integer routineId = AIRoutines_CreateRoutine("Horde Base Peons Night")
    if routineId <= 0 then
        return 0
    endif

    call AIRoutines_AddRectOrderStep(routineId, "move", gg_rct_HordeScoutBase, 6.00, 12.00)
    call AIRoutines_AddSleepStep(routineId, 300.00, 300.00, false)
    return routineId
endfunction

private function Init takes nothing returns nothing
    set MP_HarvestRect = Rect(0.00, 0.00, 0.00, 0.00)
    set MP_DayRoutineId = CreateDayRoutine()
    set MP_NightRoutineId = CreateNightRoutine()
    set MP_SpawnGroupId = AIRoutines_CreateManagedUnitGroupInZone(Player(MP_OWNER_PLAYER_ID), MP_PEON_UNIT_TYPE_ID, gg_rct_HordeMainBasePeons, GetActiveRoutineId(), MP_PEON_COUNT, MP_RESPAWN_DELAY, MP_RANDOM_FACING, MP_ROUTINE_ZONE_ID)
    set MP_NightActive = IsNight()

    set MP_DawnTrigger = CreateTrigger()
    call TriggerRegisterGameStateEvent(MP_DawnTrigger, GAME_STATE_TIME_OF_DAY, EQUAL, MP_DAWN_TIME)
    call TriggerAddAction(MP_DawnTrigger, function SyncDayNightMode)

    set MP_DuskTrigger = CreateTrigger()
    call TriggerRegisterGameStateEvent(MP_DuskTrigger, GAME_STATE_TIME_OF_DAY, EQUAL, MP_DUSK_TIME)
    call TriggerAddAction(MP_DuskTrigger, function SyncDayNightMode)

    set MP_SyncTimer = CreateTimer()
    call TimerStart(MP_SyncTimer, MP_SYNC_INTERVAL, true, function SyncDayNightMode)
endfunction

endlibrary
