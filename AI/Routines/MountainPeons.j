/**
    MountainPeons

    Author: Valdemar
    Version:

    Description:
    Ambient AIRoutines setup for the mountain camp peons. AIRoutines creates
    and manages Orc Peon units (`'opeo'`) at `gg_rct_MountainPeons`; they
    harvest lumber by day, wander and idle around `gg_rct_HordeMountainCamp`,
    and move to the camp to sleep at night.

    Credits:
    - PotS AI JASS migration

    How to install:
    Import after `AIRoutines.j`. The map must provide `gg_rct_MountainPeons`
    and `gg_rct_HordeMountainCamp`.

    API:
    call MountainPeons_Refresh()

**/
library MountainPeons initializer Init requires AIRoutines

globals
    // Configuration
    private constant real MP_DAWN_TIME = 6.00
    private constant real MP_DUSK_TIME = 18.00
    private constant real MP_SYNC_INTERVAL = 15.00
    private constant real MP_RESPAWN_DELAY = 60.00
    private constant real MP_RANDOM_FACING = -1.00
    private constant integer MP_OWNER_PLAYER_ID = PLAYER_NEUTRAL_PASSIVE
    private constant integer MP_PEON_UNIT_TYPE_ID = 'opeo'
    private constant integer MP_PEON_COUNT = 5

    private integer MP_DayRoutineId = 0
    private integer MP_NightRoutineId = 0
    private integer MP_SpawnGroupId = 0
    private boolean MP_NightActive = false
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
        set x = GetRandomReal(GetRectMinX(gg_rct_HordeMountainCamp), GetRectMaxX(gg_rct_HordeMountainCamp))
        set y = GetRandomReal(GetRectMinY(gg_rct_HordeMountainCamp), GetRectMaxY(gg_rct_HordeMountainCamp))
        call IssuePointOrder(whichUnit, "move", x, y)
    else
        call IssueImmediateOrder(whichUnit, "stop")
        call SetUnitAnimation(whichUnit, "stand victory")
    endif

    set whichUnit = null
endfunction

private function CreateDayRoutine takes nothing returns integer
    local integer routineId = AIRoutines_CreateRoutine("Mountain Peons Day")
    if routineId <= 0 then
        return 0
    endif

    call AIRoutines_AddRectOrderStep(routineId, "harvest", gg_rct_MountainPeons, 45.00, 80.00)
    call AIRoutines_AddWanderStep(routineId, gg_rct_HordeMountainCamp, 8.00, 18.00)
    call AIRoutines_AddCallbackStep(routineId, 4.00, 10.00, function CampAction)
    call AIRoutines_AddWaitStep(routineId, 3.00, 8.00)
    call AIRoutines_AddRectOrderStep(routineId, "harvest", gg_rct_MountainPeons, 35.00, 70.00)
    return routineId
endfunction

private function CreateNightRoutine takes nothing returns integer
    local integer routineId = AIRoutines_CreateRoutine("Mountain Peons Night")
    if routineId <= 0 then
        return 0
    endif

    call AIRoutines_AddRectOrderStep(routineId, "move", gg_rct_HordeMountainCamp, 6.00, 12.00)
    call AIRoutines_AddSleepStep(routineId, 300.00, 300.00, false)
    return routineId
endfunction

private function Init takes nothing returns nothing
    set MP_DayRoutineId = CreateDayRoutine()
    set MP_NightRoutineId = CreateNightRoutine()
    set MP_SpawnGroupId = AIRoutines_CreateManagedUnitGroup(Player(MP_OWNER_PLAYER_ID), MP_PEON_UNIT_TYPE_ID, gg_rct_MountainPeons, GetActiveRoutineId(), MP_PEON_COUNT, MP_RESPAWN_DELAY, MP_RANDOM_FACING)
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
