/**
    VillageTownRoutineTemplate

    Author: Valdemar
    Version:

    Description:
    Helper/template for ambient AIRoutines village, city, and town sublibraries.
    It creates a standard walk-and-idle routine, a managed random unit group,
    and optional turnover so citizens can walk toward an exit and later be
    replaced by another random unit type from the same weighted pool.

    Credits:
    - PotS AI JASS migration

    How to install:
    Import after `AIRoutines.j`. Concrete village libraries can either call
    these helpers or copy the short setup pattern from the API notes below.

    API:
    set g = VillageTownRoutineTemplate_CreateRandomGroup(familyName, owner, spawnRect, walkRect, exitRect, zoneId, count, respawnDelay, turnoverMin, turnoverMax)
    call VillageTownRoutineTemplate_AddType(g, unitTypeId, weight)
    call VillageTownRoutineTemplate_Start(g)

    Typical sublibrary setup:
      set SpawnGroupId = VillageTownRoutineTemplate_CreateRandomGroup("Sereneglade Citizens", Player(PLAYER_NEUTRAL_PASSIVE), gg_rct_SerenegladeCitizenSpawn, gg_rct_SerenegladeStreets, gg_rct_SerenegladeExits, 2, 10, 45.00, 180.00, 420.00)
      call VillageTownRoutineTemplate_AddType(SpawnGroupId, 'nvlk', 6)
      call VillageTownRoutineTemplate_AddType(SpawnGroupId, 'nvil', 3)
      call VillageTownRoutineTemplate_AddType(SpawnGroupId, 'nwgs', 1)
      call VillageTownRoutineTemplate_Start(SpawnGroupId)

**/
library VillageTownRoutineTemplate requires AIRoutines

globals
    // Default village/city walking style.
    private constant real VTT_MOVE_MIN = 8.00
    private constant real VTT_MOVE_MAX = 16.00
    private constant real VTT_IDLE_MIN = 3.00
    private constant real VTT_IDLE_MAX = 8.00
    private constant real VTT_RANDOM_FACING = -1.00
    private constant real VTT_REMOVE_AFTER_EXIT = 10.00
endglobals

public function CreateRandomGroup takes string familyName, player owner, rect spawnRect, rect walkRect, rect exitRect, integer zoneId, integer count, real respawnDelay, real turnoverMin, real turnoverMax returns integer
    local integer routineId = AIRoutines_CreateVillageWanderRoutine(familyName, walkRect, VTT_MOVE_MIN, VTT_MOVE_MAX, VTT_IDLE_MIN, VTT_IDLE_MAX)
    local integer spawnGroupId
    if routineId <= 0 then
        return 0
    endif

    if zoneId > 0 then
        set spawnGroupId = AIRoutines_CreateManagedRandomUnitGroupInZone(owner, spawnRect, routineId, count, respawnDelay, VTT_RANDOM_FACING, zoneId)
    else
        set spawnGroupId = AIRoutines_CreateManagedRandomUnitGroup(owner, spawnRect, routineId, count, respawnDelay, VTT_RANDOM_FACING)
    endif

    if spawnGroupId > 0 and (turnoverMin > 0.00 or turnoverMax > 0.00) then
        call AIRoutines_SetManagedUnitGroupTurnover(spawnGroupId, turnoverMin, turnoverMax, exitRect, VTT_REMOVE_AFTER_EXIT)
    endif
    return spawnGroupId
endfunction

public function AddType takes integer spawnGroupId, integer unitTypeId, integer weight returns boolean
    return AIRoutines_AddManagedUnitGroupType(spawnGroupId, unitTypeId, weight)
endfunction

public function Start takes integer spawnGroupId returns nothing
    call AIRoutines_RefillManagedUnitGroup(spawnGroupId)
endfunction

endlibrary
