/**
    AIRoutines

    Author: Valdemar
    Version:

    Description:
    Flexible routine scheduler for ambient RPG NPC behavior. A routine family
    is a reusable ordered list of steps that can move, wander, work, animate,
    sleep, interact with targets, or run a custom callback. The system is not
    tied to any one profession; blacksmiths, fishers, guards, villagers,
    shopkeepers, workers, tavern patrons, and quest NPCs should all be built by
    combining the same small step types. Units can be assigned individually, by
    rect, by unit type across the map, or created and respawned by managed
    unit groups owned by AIRoutines.

    Credits:
    - PotS AI JASS migration

    How to install:
    Import after `AI.j`, `Table`, and `ZoneEvent`. Optional AI profile
    registration is available per routine family; keep it disabled for pure
    ambient NPCs if the shared AI revive behavior is not wanted.

    API:
    call AIRoutines_CreateRoutine(familyName)
    call AIRoutines_SetRoutineLoop(routineId, enabled)
    call AIRoutines_SetRoutineAIRegistration(routineId, enabled)
    call AIRoutines_AddWaitStep(routineId, minDuration, maxDuration)
    call AIRoutines_AddWorkStep(routineId, animationName, effectPath, attachPoint, minDuration, maxDuration)
    call AIRoutines_AddPointOrderStep(routineId, order, x, y, minDuration, maxDuration)
    call AIRoutines_AddRectOrderStep(routineId, order, whichRect, minDuration, maxDuration)
    call AIRoutines_AddTargetUnitOrderStep(routineId, order, target, minDuration, maxDuration)
    call AIRoutines_AddTargetDestructableOrderStep(routineId, order, target, minDuration, maxDuration)
    call AIRoutines_AddImmediateOrderStep(routineId, order, minDuration, maxDuration)
    call AIRoutines_AddSleepStep(routineId, minDuration, maxDuration, hideDuringSleep)
    call AIRoutines_AddCallbackStep(routineId, minDuration, maxDuration, callback)
    call AIRoutines_SetStepAnimation(stepId, animationName)
    call AIRoutines_SetStepEffect(stepId, effectPath, attachPoint)
    call AIRoutines_AddWanderStep(routineId, wanderRect, minDuration, maxDuration)
    call AIRoutines_AddStandStep(routineId, animationName, minDuration, maxDuration)
    call AIRoutines_AddEffectWorkStep(routineId, animationName, effectPath, attachPoint, minDuration, maxDuration)
    call AIRoutines_RegisterUnit(whichUnit, routineId)
    call AIRoutines_RegisterUnitInZone(whichUnit, routineId, zoneId)
    call AIRoutines_RegisterUnitsInRect(whichRect, routineId)
    call AIRoutines_RegisterUnitsInRectInZone(whichRect, routineId, zoneId)
    call AIRoutines_RegisterUnitTypeInRect(unitTypeId, whichRect, routineId)
    call AIRoutines_RegisterUnitTypeInRectInZone(unitTypeId, whichRect, routineId, zoneId)
    call AIRoutines_RegisterUnitType(unitTypeId, routineId)
    call AIRoutines_UnregisterUnit(whichUnit)
    call AIRoutines_WakeUnit(whichUnit)
    call AIRoutines_SetZoneActive(zoneId, active)
    set isActive = AIRoutines_IsZoneActive(zoneId)
    call AIRoutines_CreateManagedUnitGroup(owner, unitTypeId, spawnRect, routineId, count, respawnDelay, facing)
    call AIRoutines_CreateManagedUnitGroupInZone(owner, unitTypeId, spawnRect, routineId, count, respawnDelay, facing, zoneId)
    call AIRoutines_CreateManagedRandomUnitGroup(owner, spawnRect, routineId, count, respawnDelay, facing)
    call AIRoutines_CreateManagedRandomUnitGroupInZone(owner, spawnRect, routineId, count, respawnDelay, facing, zoneId)
    call AIRoutines_AddManagedUnitGroupType(spawnGroupId, unitTypeId, weight)
    call AIRoutines_SetManagedUnitGroupTurnover(spawnGroupId, minInterval, maxInterval, exitRect, removeDelay)
    call AIRoutines_SetManagedUnitGroupRemovalPlayerGuardRange(spawnGroupId, range)
    call AIRoutines_SetManagedUnitGroupRoutine(spawnGroupId, routineId)
    call AIRoutines_SetManagedUnitGroupEnabled(spawnGroupId, enabled)
    call AIRoutines_RefillManagedUnitGroup(spawnGroupId)
    call AIRoutines_CreateVillageWanderRoutine(familyName, villageRect, moveMin, moveMax, idleMin, idleMax)
    call AIRoutines_CreateFishingRoutine(familyName, fishingRect, fishMin, fishMax, idleMin, idleMax)
    call AIRoutines_CreateBlacksmithRoutine(familyName, workRect)
    call AIRoutines_CreatePeonLumberSleepRoutine(familyName, lumberRect, sleepRect, harvestDuration, sleepDuration, hideDuringSleep)

    Callback globals:
    AIRoutines_EventUnit
    AIRoutines_EventRoutineId
    AIRoutines_EventStepId
    AIRoutines_EventStepType

    Guide:
    - Think in routine families, not individual NPCs. Create one family such as
      "Village Fishers", add its ordered steps, then register many units to it.
    - Durations use min/max ranges. Equal values make fixed timing; different
      values desync NPCs so a village does not move in lockstep.
    - Rect steps choose a random point inside the rect each time, which makes
      wandering, fishing spots, market browsing, field work, and guard pacing
      reusable without creating many fixed points.
    - Work/stand steps are animation steps. Use model animation names like
      "stand", "stand work", "attack", "spell", "walk", or a model-specific
      sequence. Missing animations safely fall back to normal model behavior.
    - Callback steps are the escape hatch for anything custom: quest flags,
      dialog barks, spawning props, changing facing, buying/selling, or calling
      another local system. Read AIRoutines_EventUnit and AIRoutines_EventStepId
      inside the callback.
    - Target steps are for props and actors: face/use a forge, anvil, fishing
      node, bed, chair, shop counter, door, training dummy, or another NPC.
    - Other routine ideas use the same blocks: tavern patrons sit/wander/talk,
      priests walk altar aisles and cast, dockworkers carry crates, stablehands
      tend animals, children run between play spots, miners work veins, farmers
      work fields, bards perform, vendors stand at counters, and quest NPCs run
      callback-driven ambient barks between idle poses.

    Common patterns:
    Village walker:
      set r = AIRoutines_CreateRoutine("Village Walkers")
      call AIRoutines_AddWanderStep(r, gg_rct_VillageStreets, 8.00, 16.00)
      call AIRoutines_AddWaitStep(r, 3.00, 8.00)
      call AIRoutines_RegisterUnitsInRect(gg_rct_Villagers, r)

    Fisher:
      set r = AIRoutines_CreateRoutine("Fishers")
      call AIRoutines_AddWanderStep(r, gg_rct_Dock, 4.00, 8.00)
      call AIRoutines_AddStandStep(r, "stand work", 20.00, 45.00)
      call AIRoutines_AddWaitStep(r, 4.00, 10.00)
      call AIRoutines_RegisterUnitsInRect(gg_rct_FisherNPCs, r)

    Guard patrol:
      set r = AIRoutines_CreateRoutine("Village Guards")
      call AIRoutines_AddRectOrderStep(r, "move", gg_rct_GuardPostA, 8.00, 12.00)
      call AIRoutines_AddStandStep(r, "stand", 5.00, 12.00)
      call AIRoutines_AddRectOrderStep(r, "move", gg_rct_GuardPostB, 8.00, 12.00)
      call AIRoutines_AddStandStep(r, "stand", 5.00, 12.00)

    Day worker, then sleep:
      set r = AIRoutines_CreateRoutine("Field Workers")
      call AIRoutines_AddRectOrderStep(r, "move", gg_rct_Field, 8.00, 12.00)
      call AIRoutines_AddStandStep(r, "stand work", 45.00, 90.00)
      call AIRoutines_AddRectOrderStep(r, "move", gg_rct_WorkerHuts, 8.00, 12.00)
      call AIRoutines_AddSleepStep(r, 60.00, 160.00, true)

    Shopkeeper or quest NPC with custom logic:
      set r = AIRoutines_CreateRoutine("Shopkeepers")
      call AIRoutines_AddStandStep(r, "stand", 10.00, 20.00)
      call AIRoutines_AddCallbackStep(r, 2.00, 4.00, function MyNpcRoutineCallback)

    Managed unit group:
      set r = AIRoutines_CreateVillageWanderRoutine("Created Villagers", gg_rct_Village, 8.00, 16.00, 3.00, 8.00)
      call AIRoutines_CreateManagedUnitGroup(Player(PLAYER_NEUTRAL_PASSIVE), 'nvlk', gg_rct_VillageSpawn, r, 6, 60.00, -1.00)

    Managed random village group:
      set g = AIRoutines_CreateManagedRandomUnitGroup(Player(PLAYER_NEUTRAL_PASSIVE), gg_rct_VillageSpawn, r, 8, 45.00, -1.00)
      call AIRoutines_AddManagedUnitGroupType(g, 'nvlk', 6)
      call AIRoutines_AddManagedUnitGroupType(g, 'nvil', 3)
      call AIRoutines_AddManagedUnitGroupType(g, 'nwgs', 1)
      call AIRoutines_SetManagedUnitGroupTurnover(g, 180.00, 420.00, gg_rct_VillageExits, 10.00)
      call AIRoutines_RefillManagedUnitGroup(g)

    Zone-gated NPCs:
      set r = AIRoutines_CreateVillageWanderRoutine("Sereneglade Villagers", gg_rct_02SereneGlade, 8.00, 16.00, 3.00, 8.00)
      call AIRoutines_RegisterUnitsInRectInZone(gg_rct_Villagers, r, 2)
      // The units above are only in AIRoutines' active loop while ZoneEvent
      // reports at least one player hero in zone 2.

**/
library AIRoutines initializer Init requires AI, Table, ZoneEvent, FallenHeroState

globals
    constant integer AIR_STEP_WAIT = 1
    constant integer AIR_STEP_POINT_ORDER = 2
    constant integer AIR_STEP_RECT_ORDER = 3
    constant integer AIR_STEP_TARGET_UNIT_ORDER = 4
    constant integer AIR_STEP_TARGET_DESTRUCTABLE_ORDER = 5
    constant integer AIR_STEP_IMMEDIATE_ORDER = 6
    constant integer AIR_STEP_WORK = 7
    constant integer AIR_STEP_SLEEP = 8
    constant integer AIR_STEP_CALLBACK = 9

    unit AIRoutines_EventUnit = null
    integer AIRoutines_EventRoutineId = 0
    integer AIRoutines_EventStepId = 0
    integer AIRoutines_EventStepType = 0

    // Configuration
    private constant boolean AIR_DEBUG = false
    private constant boolean AIR_DEFAULT_LOOP = true
    private constant boolean AIR_DEFAULT_USE_AI_REGISTRY = false
    private constant integer AIR_SLEEP_ABILITY_ID = 'Asla'
    private constant integer AIR_MAX_ROUTINES = 512
    private constant integer AIR_MAX_STEPS = 4096
    private constant integer AIR_MAX_ROUTINE_STEPS = 128
    private constant integer AIR_MAX_ACTIVE_UNITS = 2048
    private constant integer AIR_MAX_ZONE_UNITS = 999
    private constant integer AIR_MAX_SPAWN_GROUPS = 512
    private constant integer AIR_MAX_SPAWN_GROUP_UNIT_TYPES = 32
    private constant integer AIR_MAX_PLAYER_INDEX = 27
    private constant integer AIR_ROUTINE_STEP_KEY = 1000
    private constant integer AIR_ZONE_UNIT_KEY = 1000
    private constant integer AIR_SPAWN_GROUP_TYPE_KEY = 100
    private constant real AIR_TICK_INTERVAL = 0.50
    private constant real AIR_ATTACK_WAKE_DELAY = 12.00
    private constant real AIR_DEFAULT_TURNOVER_REMOVE_DELAY = 8.00

    // Routine families and lookup.
    private integer AIR_NextRoutineId = 1
    private integer AIR_NextStepId = 1
    private integer AIR_NextSpawnGroupId = 1
    private integer AIR_ActiveCount = 0
    private integer AIR_AIClassId = 0
    private boolean AIR_TickRunning = false
    private timer AIR_ClockTimer = null
    private timer AIR_TickTimer = null
    private trigger AIR_TickTrigger = null
    private trigger AIR_AttackTrigger = null
    private trigger AIR_DeathTrigger = null
    private trigger AIR_EnterTrigger = null
    private region AIR_EnterRegion = null
    private group AIR_RemovalGuardEnumGroup = null
    private destructable AIR_EnumDestructablePick = null
    private integer AIR_EnumDestructableCount = 0

    private string array AIR_RoutineName
    private integer array AIR_RoutineStepCount
    private boolean array AIR_RoutineLoop
    private boolean array AIR_RoutineAIEnabled
    private unit array AIR_ActiveUnit

    private integer array AIR_StepType
    private string array AIR_StepOrder
    private string array AIR_StepAnimation
    private string array AIR_StepEffect
    private string array AIR_StepAttach
    private real array AIR_StepMinDuration
    private real array AIR_StepMaxDuration
    private real array AIR_StepX
    private real array AIR_StepY
    private rect array AIR_StepRect
    private unit array AIR_StepTargetUnit
    private destructable array AIR_StepTargetDestructable
    private trigger array AIR_StepCallback
    private boolean array AIR_StepSleepHide

    private integer array AIR_SpawnGroupUnitType
    private integer array AIR_SpawnGroupTypeCount
    private integer array AIR_SpawnGroupTypeWeightTotal
    private integer array AIR_SpawnGroupRoutine
    private integer array AIR_SpawnGroupZone
    private integer array AIR_SpawnGroupTargetCount
    private integer array AIR_SpawnGroupAliveCount
    private real array AIR_SpawnGroupRespawnDelay
    private real array AIR_SpawnGroupFacing
    private real array AIR_SpawnGroupTurnoverMin
    private real array AIR_SpawnGroupTurnoverMax
    private real array AIR_SpawnGroupTurnoverRemoveDelay
    private real array AIR_SpawnGroupRemovalPlayerGuardRange
    private boolean array AIR_SpawnGroupEnabled
    private boolean array AIR_SpawnGroupRandomTypes
    private boolean array AIR_SpawnGroupTurnoverEnabled
    private player array AIR_SpawnGroupOwner
    private rect array AIR_SpawnGroupRect
    private rect array AIR_SpawnGroupExitRect

    private Table AIR_RoutineByName = 0
    private Table AIR_RoutineStepId = 0
    private Table AIR_UnitRoutine = 0
    private Table AIR_UnitStep = 0
    private Table AIR_UnitNextTime = 0
    private Table AIR_UnitActiveSlot = 0
    private Table AIR_UnitZone = 0
    private Table AIR_UnitZoneSlot = 0
    private Table AIR_UnitPaused = 0
    private Table AIR_UnitSleeping = 0
    private Table AIR_UnitSleepHidden = 0
    private Table AIR_UnitWasPaused = 0
    private Table AIR_UnitWasHidden = 0
    private Table AIR_UnitHadSleepAbility = 0
    private Table AIR_UnitAIRegistered = 0
    private Table AIR_UnitTypeRoutine = 0
    private Table AIR_UnitSpawnGroup = 0
    private Table AIR_UnitTurnoverTime = 0
    private Table AIR_UnitLeaving = 0
    private Table AIR_SpawnGroupUnitTypeChoice = 0
    private Table AIR_SpawnGroupUnitTypeWeight = 0
    private Table AIR_RespawnTimerGroup = 0
    private Table AIR_TurnoverTimerUnit = 0
    private Table AIR_AIProfileByRoutineType = 0
    private Table AIR_ZoneActive = 0
    private Table AIR_ZoneHeroCount = 0
    private Table AIR_ZoneUnit = 0
    private Table AIR_ZoneUnitCount = 0
endglobals

private function AIR_DebugMsg takes string msg returns nothing
    if AIR_DEBUG then
        call BJDebugMsg("[AIRoutines] " + msg)
    endif
endfunction

private function AIR_NoOp takes nothing returns nothing
endfunction

private function AIR_GetNow takes nothing returns real
    if AIR_ClockTimer == null then
        set AIR_ClockTimer = CreateTimer()
        call TimerStart(AIR_ClockTimer, 1000000.00, false, function AIR_NoOp)
    endif
    return TimerGetElapsed(AIR_ClockTimer)
endfunction

private function AIR_IsAliveUnit takes unit whichUnit returns boolean
    return FallenHeroState_IsAlive(whichUnit)
endfunction

private function AIR_IsPlayerUnitNear takes unit whichUnit, real range returns boolean
    local unit enumUnit
    local boolean found = false
    if whichUnit == null or range <= 0.00 or AIR_RemovalGuardEnumGroup == null then
        return false
    endif

    call GroupEnumUnitsInRange(AIR_RemovalGuardEnumGroup, GetUnitX(whichUnit), GetUnitY(whichUnit), range, null)
    loop
        set enumUnit = FirstOfGroup(AIR_RemovalGuardEnumGroup)
        exitwhen enumUnit == null or found
        call GroupRemoveUnit(AIR_RemovalGuardEnumGroup, enumUnit)
        if GetOwningPlayer(enumUnit) == Player(0) and AIR_IsAliveUnit(enumUnit) and not IsUnitHidden(enumUnit) then
            set found = true
        endif
    endloop
    call GroupClear(AIR_RemovalGuardEnumGroup)

    set enumUnit = null
    return found
endfunction

private function AIR_RoutineExists takes integer routineId returns boolean
    return routineId > 0 and routineId < AIR_NextRoutineId
endfunction

private function AIR_GetRoutineStepKey takes integer routineId, integer stepIndex returns integer
    return routineId * AIR_ROUTINE_STEP_KEY + stepIndex
endfunction

private function AIR_GetAIProfileKey takes integer routineId, integer unitTypeId returns integer
    return StringHash("AIR|" + I2S(routineId) + "|" + I2S(unitTypeId))
endfunction

private function AIR_GetStepDuration takes integer stepId returns real
    local real minDuration = AIR_StepMinDuration[stepId]
    local real maxDuration = AIR_StepMaxDuration[stepId]
    if minDuration < 0.00 then
        set minDuration = 0.00
    endif
    if maxDuration < minDuration then
        set maxDuration = minDuration
    endif
    if maxDuration > minDuration then
        return GetRandomReal(minDuration, maxDuration)
    endif
    return minDuration
endfunction

private function AIR_RunTickTrigger takes nothing returns nothing
    if AIR_TickTrigger != null then
        call TriggerExecute(AIR_TickTrigger)
    endif
endfunction

private function AIR_StartTickTimer takes nothing returns nothing
    if AIR_TickTimer != null and not AIR_TickRunning then
        set AIR_TickRunning = true
        call TimerStart(AIR_TickTimer, AIR_TICK_INTERVAL, true, function AIR_RunTickTrigger)
    endif
endfunction

private function AIR_StopTickTimer takes nothing returns nothing
    if AIR_TickTimer != null and AIR_TickRunning and AIR_ActiveCount <= 0 then
        set AIR_TickRunning = false
        call PauseTimer(AIR_TickTimer)
    endif
endfunction

private function AIR_SetEventContext takes unit whichUnit, integer routineId, integer stepId returns nothing
    set AIRoutines_EventUnit = whichUnit
    set AIRoutines_EventRoutineId = routineId
    set AIRoutines_EventStepId = stepId
    set AIRoutines_EventStepType = AIR_StepType[stepId]
endfunction

private function AIR_ClearEventContext takes nothing returns nothing
    set AIRoutines_EventUnit = null
    set AIRoutines_EventRoutineId = 0
    set AIRoutines_EventStepId = 0
    set AIRoutines_EventStepType = 0
endfunction

private function AIR_AddActiveUnit takes unit whichUnit, integer unitKey returns boolean
    if AIR_UnitActiveSlot[unitKey] > 0 then
        return true
    endif
    if AIR_ActiveCount >= AIR_MAX_ACTIVE_UNITS then
        call BJDebugMsg("[AIRoutines] ERROR: AIR_MAX_ACTIVE_UNITS reached.")
        return false
    endif
    set AIR_ActiveCount = AIR_ActiveCount + 1
    set AIR_ActiveUnit[AIR_ActiveCount] = whichUnit
    set AIR_UnitActiveSlot[unitKey] = AIR_ActiveCount
    call AIR_StartTickTimer()
    return true
endfunction

private function AIR_RemoveActiveUnit takes integer unitKey returns nothing
    local integer slot = AIR_UnitActiveSlot[unitKey]
    local unit moved
    local integer movedKey
    if slot <= 0 or slot > AIR_ActiveCount then
        return
    endif
    if slot < AIR_ActiveCount then
        set moved = AIR_ActiveUnit[AIR_ActiveCount]
        set movedKey = GetHandleId(moved)
        set AIR_ActiveUnit[slot] = moved
        set AIR_UnitActiveSlot[movedKey] = slot
    endif
    set AIR_ActiveUnit[AIR_ActiveCount] = null
    set AIR_ActiveCount = AIR_ActiveCount - 1
    call AIR_UnitActiveSlot.remove(unitKey)
    call AIR_StopTickTimer()
    set moved = null
endfunction

private function AIR_GetZoneUnitKey takes integer zoneId, integer slot returns integer
    return zoneId * AIR_ZONE_UNIT_KEY + slot
endfunction

private function AIR_RemoveZoneUnit takes integer unitKey returns nothing
    local integer zoneId = AIR_UnitZone[unitKey]
    local integer slot = AIR_UnitZoneSlot[unitKey]
    local integer count
    local integer storeKey
    local unit moved
    local integer movedKey

    if zoneId <= 0 or slot <= 0 then
        return
    endif

    set count = AIR_ZoneUnitCount[zoneId]
    if slot > count then
        call AIR_UnitZone.remove(unitKey)
        call AIR_UnitZoneSlot.remove(unitKey)
        return
    endif

    if slot < count then
        set moved = AIR_ZoneUnit.unit[AIR_GetZoneUnitKey(zoneId, count)]
        set storeKey = AIR_GetZoneUnitKey(zoneId, slot)
        if moved != null then
            set AIR_ZoneUnit.unit[storeKey] = moved
            set movedKey = GetHandleId(moved)
            set AIR_UnitZoneSlot[movedKey] = slot
        else
            call AIR_ZoneUnit.unit.remove(storeKey)
        endif
    endif

    call AIR_ZoneUnit.unit.remove(AIR_GetZoneUnitKey(zoneId, count))
    if count <= 1 then
        call AIR_ZoneUnitCount.remove(zoneId)
    else
        set AIR_ZoneUnitCount[zoneId] = count - 1
    endif
    call AIR_UnitZone.remove(unitKey)
    call AIR_UnitZoneSlot.remove(unitKey)
    set moved = null
endfunction

private function AIR_AddZoneUnit takes unit whichUnit, integer unitKey, integer zoneId returns boolean
    local integer count
    local integer slot
    if whichUnit == null or zoneId <= 0 then
        return false
    endif
    if AIR_UnitZone[unitKey] == zoneId then
        return true
    endif
    if AIR_UnitZone[unitKey] > 0 then
        call AIR_RemoveZoneUnit(unitKey)
    endif

    set count = AIR_ZoneUnitCount[zoneId]
    if count >= AIR_MAX_ZONE_UNITS then
        call BJDebugMsg("[AIRoutines] ERROR: AIR_MAX_ZONE_UNITS reached for zone " + I2S(zoneId) + ".")
        return false
    endif

    set slot = count + 1
    set AIR_ZoneUnitCount[zoneId] = slot
    set AIR_ZoneUnit.unit[AIR_GetZoneUnitKey(zoneId, slot)] = whichUnit
    set AIR_UnitZone[unitKey] = zoneId
    set AIR_UnitZoneSlot[unitKey] = slot
    return true
endfunction

private function AIR_SetUnitZoneAssignment takes unit whichUnit, integer unitKey, integer zoneId returns boolean
    call AIR_RemoveActiveUnit(unitKey)
    if AIR_UnitZone[unitKey] > 0 then
        call AIR_RemoveZoneUnit(unitKey)
    endif

    if zoneId > 0 then
        if not AIR_AddZoneUnit(whichUnit, unitKey, zoneId) then
            return false
        endif
        if AIR_ZoneActive.boolean[zoneId] then
            return AIR_AddActiveUnit(whichUnit, unitKey)
        endif
        return true
    endif

    return AIR_AddActiveUnit(whichUnit, unitKey)
endfunction

private function AIR_SetZoneActiveInternal takes integer zoneId, boolean active returns nothing
    local integer index = 1
    local integer count
    local integer unitKey
    local real now
    local unit whichUnit

    if zoneId <= 0 then
        return
    endif
    if AIR_ZoneActive.boolean[zoneId] == active then
        return
    endif

    set AIR_ZoneActive.boolean[zoneId] = active
    if not active then
        call AIR_ZoneActive.boolean.remove(zoneId)
    endif

    set count = AIR_ZoneUnitCount[zoneId]
    set now = AIR_GetNow()
    loop
        exitwhen index > count
        set whichUnit = AIR_ZoneUnit.unit[AIR_GetZoneUnitKey(zoneId, index)]
        if whichUnit != null then
            set unitKey = GetHandleId(whichUnit)
            if active then
                if AIR_UnitRoutine[unitKey] > 0 and AIR_IsAliveUnit(whichUnit) then
                    if AIR_AddActiveUnit(whichUnit, unitKey) and not AIR_UnitSleeping.boolean[unitKey] then
                        set AIR_UnitNextTime.real[unitKey] = now
                    endif
                endif
            else
                call AIR_RemoveActiveUnit(unitKey)
                if AIR_UnitRoutine[unitKey] > 0 and not AIR_UnitSleeping.boolean[unitKey] then
                    call IssueImmediateOrder(whichUnit, "stop")
                    call SetUnitAnimation(whichUnit, "stand")
                endif
            endif
        endif
        set index = index + 1
    endloop
    set whichUnit = null
endfunction

private function AIR_PlayStepEffect takes unit whichUnit, integer stepId returns nothing
    local string effectPath = AIR_StepEffect[stepId]
    local string attachPoint = AIR_StepAttach[stepId]
    if effectPath != null and effectPath != "" then
        if attachPoint != null and attachPoint != "" then
            call DestroyEffect(AddSpecialEffectTarget(effectPath, whichUnit, attachPoint))
        else
            call DestroyEffect(AddSpecialEffect(effectPath, GetUnitX(whichUnit), GetUnitY(whichUnit)))
        endif
    endif
endfunction

private function AIR_ApplyStepAnimation takes unit whichUnit, integer stepId returns nothing
    local string animationName = AIR_StepAnimation[stepId]
    if animationName != null and animationName != "" then
        call SetUnitAnimation(whichUnit, animationName)
    endif
endfunction

private function AIR_WakeUnitByKey takes unit whichUnit, integer unitKey returns nothing
    if whichUnit == null or not AIR_UnitSleeping.boolean[unitKey] then
        return
    endif
    if AIR_UnitSleepHidden.boolean[unitKey] and not AIR_UnitWasHidden.boolean[unitKey] then
        call ShowUnit(whichUnit, true)
    endif
    if not AIR_UnitHadSleepAbility.boolean[unitKey] then
        call UnitRemoveAbility(whichUnit, AIR_SLEEP_ABILITY_ID)
    endif
    if not AIR_UnitWasPaused.boolean[unitKey] then
        call PauseUnit(whichUnit, false)
    endif
    call SetUnitAnimation(whichUnit, "stand")
    call AIR_UnitSleeping.boolean.remove(unitKey)
    call AIR_UnitSleepHidden.boolean.remove(unitKey)
    call AIR_UnitWasPaused.boolean.remove(unitKey)
    call AIR_UnitWasHidden.boolean.remove(unitKey)
    call AIR_UnitHadSleepAbility.boolean.remove(unitKey)
endfunction

private function AIR_BeginSleep takes unit whichUnit, integer unitKey, boolean hideDuringSleep returns nothing
    if whichUnit == null then
        return
    endif
    set AIR_UnitHadSleepAbility.boolean[unitKey] = GetUnitAbilityLevel(whichUnit, AIR_SLEEP_ABILITY_ID) > 0
    set AIR_UnitWasPaused.boolean[unitKey] = IsUnitPaused(whichUnit)
    set AIR_UnitWasHidden.boolean[unitKey] = IsUnitHidden(whichUnit)
    set AIR_UnitSleeping.boolean[unitKey] = true
    set AIR_UnitSleepHidden.boolean[unitKey] = hideDuringSleep
    call IssueImmediateOrder(whichUnit, "stop")
    if not AIR_UnitHadSleepAbility.boolean[unitKey] then
        call UnitAddAbility(whichUnit, AIR_SLEEP_ABILITY_ID)
    endif
    call SetUnitAnimation(whichUnit, "sleep")
    call PauseUnit(whichUnit, true)
    if hideDuringSleep then
        call ShowUnit(whichUnit, false)
    endif
endfunction

private function AIR_GetOrCreateAIProfile takes integer routineId, integer unitTypeId returns integer
    local integer key
    local integer profileId
    if not AIR_RoutineExists(routineId) or unitTypeId == 0 or AIR_AIClassId <= 0 then
        return 0
    endif
    set key = AIR_GetAIProfileKey(routineId, unitTypeId)
    set profileId = AIR_AIProfileByRoutineType[key]
    if profileId > 0 then
        return profileId
    endif
    set profileId = AI_RegisterProfile(AIR_AIClassId, unitTypeId, "Routine:" + AIR_RoutineName[routineId] + ":" + I2S(unitTypeId))
    if profileId > 0 then
        call AI_SetProfileAutonomous(profileId, false)
        set AIR_AIProfileByRoutineType[key] = profileId
    endif
    return profileId
endfunction

private function AIR_TryRegisterAI takes unit whichUnit, integer routineId, integer unitKey returns nothing
    local integer profileId
    if whichUnit == null or not AIR_RoutineAIEnabled[routineId] then
        return
    endif
    if AI_GetInstance(whichUnit) > 0 then
        return
    endif
    set profileId = AIR_GetOrCreateAIProfile(routineId, GetUnitTypeId(whichUnit))
    if profileId > 0 and AI_RegisterUnit(whichUnit, profileId, 0) > 0 then
        set AIR_UnitAIRegistered.boolean[unitKey] = true
    endif
endfunction

private function AIR_TryUnregisterAI takes unit whichUnit, integer unitKey returns nothing
    if whichUnit != null and AIR_UnitAIRegistered.boolean[unitKey] then
        call AI_UnregisterUnit(whichUnit)
    endif
    call AIR_UnitAIRegistered.boolean.remove(unitKey)
endfunction

private function AIR_AddStep takes integer routineId, integer stepType, real minDuration, real maxDuration returns integer
    local integer stepId
    local integer stepIndex
    if not AIR_RoutineExists(routineId) then
        return 0
    endif
    if AIR_RoutineStepCount[routineId] >= AIR_MAX_ROUTINE_STEPS then
        call BJDebugMsg("[AIRoutines] ERROR: AIR_MAX_ROUTINE_STEPS reached for " + AIR_RoutineName[routineId] + ".")
        return 0
    endif
    if AIR_NextStepId > AIR_MAX_STEPS then
        call BJDebugMsg("[AIRoutines] ERROR: AIR_MAX_STEPS reached.")
        return 0
    endif
    if minDuration < 0.00 then
        set minDuration = 0.00
    endif
    if maxDuration < minDuration then
        set maxDuration = minDuration
    endif
    set stepId = AIR_NextStepId
    set AIR_NextStepId = AIR_NextStepId + 1
    set AIR_StepType[stepId] = stepType
    set AIR_StepMinDuration[stepId] = minDuration
    set AIR_StepMaxDuration[stepId] = maxDuration
    set stepIndex = AIR_RoutineStepCount[routineId] + 1
    set AIR_RoutineStepCount[routineId] = stepIndex
    set AIR_RoutineStepId[AIR_GetRoutineStepKey(routineId, stepIndex)] = stepId
    return stepId
endfunction

private function AIR_ClearUnitRegistration takes unit whichUnit, boolean wakeFirst returns nothing
    local integer unitKey
    if whichUnit == null then
        return
    endif
    set unitKey = GetHandleId(whichUnit)
    if AIR_UnitRoutine[unitKey] <= 0 then
        return
    endif
    if wakeFirst then
        call AIR_WakeUnitByKey(whichUnit, unitKey)
    endif
    call AIR_TryUnregisterAI(whichUnit, unitKey)
    call AIR_RemoveActiveUnit(unitKey)
    call AIR_RemoveZoneUnit(unitKey)
    call AIR_UnitRoutine.remove(unitKey)
    call AIR_UnitStep.remove(unitKey)
    call AIR_UnitNextTime.real.remove(unitKey)
    call AIR_UnitPaused.boolean.remove(unitKey)
    call AIR_UnitSleeping.boolean.remove(unitKey)
    call AIR_UnitSleepHidden.boolean.remove(unitKey)
    call AIR_UnitWasPaused.boolean.remove(unitKey)
    call AIR_UnitWasHidden.boolean.remove(unitKey)
    call AIR_UnitHadSleepAbility.boolean.remove(unitKey)
    call AIR_UnitTurnoverTime.real.remove(unitKey)
    call AIR_UnitLeaving.boolean.remove(unitKey)
endfunction

private function AIR_RegisterUnitInternalEx takes unit whichUnit, integer routineId, integer zoneId returns boolean
    local integer unitKey
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 or not AIR_RoutineExists(routineId) then
        return false
    endif
    set unitKey = GetHandleId(whichUnit)
    if AIR_UnitRoutine[unitKey] == routineId then
        return AIR_SetUnitZoneAssignment(whichUnit, unitKey, zoneId)
    endif
    if AIR_UnitRoutine[unitKey] > 0 then
        call AIR_ClearUnitRegistration(whichUnit, true)
    endif
    if not AIR_SetUnitZoneAssignment(whichUnit, unitKey, zoneId) then
        return false
    endif
    set AIR_UnitRoutine[unitKey] = routineId
    set AIR_UnitStep[unitKey] = 0
    set AIR_UnitNextTime.real[unitKey] = 0.00
    call AIR_UnitPaused.boolean.remove(unitKey)
    call AIR_TryRegisterAI(whichUnit, routineId, unitKey)
    call AIR_DebugMsg("Registered " + GetUnitName(whichUnit) + " to " + AIR_RoutineName[routineId] + ".")
    return true
endfunction

private function AIR_RegisterUnitInternal takes unit whichUnit, integer routineId returns boolean
    return AIR_RegisterUnitInternalEx(whichUnit, routineId, 0)
endfunction

private function AIR_SpawnGroupExists takes integer spawnGroupId returns boolean
    return spawnGroupId > 0 and spawnGroupId < AIR_NextSpawnGroupId
endfunction

private function AIR_GetRectRandomX takes rect whichRect returns real
    return GetRandomReal(GetRectMinX(whichRect), GetRectMaxX(whichRect))
endfunction

private function AIR_GetRectRandomY takes rect whichRect returns real
    return GetRandomReal(GetRectMinY(whichRect), GetRectMaxY(whichRect))
endfunction

private function AIR_GetSpawnFacing takes integer spawnGroupId returns real
    if AIR_SpawnGroupFacing[spawnGroupId] < 0.00 then
        return GetRandomReal(0.00, 360.00)
    endif
    return AIR_SpawnGroupFacing[spawnGroupId]
endfunction

private function AIR_GetSpawnGroupTypeKey takes integer spawnGroupId, integer index returns integer
    return spawnGroupId * AIR_SPAWN_GROUP_TYPE_KEY + index
endfunction

private function AIR_GetRandomSpawnGroupUnitType takes integer spawnGroupId returns integer
    local integer typeCount = AIR_SpawnGroupTypeCount[spawnGroupId]
    local integer totalWeight = AIR_SpawnGroupTypeWeightTotal[spawnGroupId]
    local integer index = 1
    local integer key
    local integer weight
    local integer roll
    if typeCount <= 0 then
        return 0
    endif
    if totalWeight <= 0 then
        return AIR_SpawnGroupUnitTypeChoice[AIR_GetSpawnGroupTypeKey(spawnGroupId, GetRandomInt(1, typeCount))]
    endif

    set roll = GetRandomInt(1, totalWeight)
    loop
        exitwhen index > typeCount
        set key = AIR_GetSpawnGroupTypeKey(spawnGroupId, index)
        set weight = AIR_SpawnGroupUnitTypeWeight[key]
        if roll <= weight then
            return AIR_SpawnGroupUnitTypeChoice[key]
        endif
        set roll = roll - weight
        set index = index + 1
    endloop
    return AIR_SpawnGroupUnitTypeChoice[AIR_GetSpawnGroupTypeKey(spawnGroupId, typeCount)]
endfunction

private function AIR_GetSpawnGroupUnitType takes integer spawnGroupId returns integer
    if AIR_SpawnGroupRandomTypes[spawnGroupId] or AIR_SpawnGroupTypeCount[spawnGroupId] > 0 then
        return AIR_GetRandomSpawnGroupUnitType(spawnGroupId)
    endif
    return AIR_SpawnGroupUnitType[spawnGroupId]
endfunction

private function AIR_GetTurnoverDelay takes integer spawnGroupId returns real
    local real minDelay = AIR_SpawnGroupTurnoverMin[spawnGroupId]
    local real maxDelay = AIR_SpawnGroupTurnoverMax[spawnGroupId]
    if minDelay < 0.00 then
        set minDelay = 0.00
    endif
    if maxDelay < minDelay then
        set maxDelay = minDelay
    endif
    if maxDelay > minDelay then
        return GetRandomReal(minDelay, maxDelay)
    endif
    return minDelay
endfunction

private function AIR_GetTurnoverRemoveDelay takes integer spawnGroupId returns real
    local real removeDelay = AIR_SpawnGroupTurnoverRemoveDelay[spawnGroupId]
    if removeDelay <= 0.00 then
        return AIR_DEFAULT_TURNOVER_REMOVE_DELAY
    endif
    return removeDelay
endfunction

private function AIR_ResetUnitTurnover takes unit whichUnit, integer spawnGroupId returns nothing
    local integer unitKey
    local real delay
    if whichUnit == null then
        return
    endif
    set unitKey = GetHandleId(whichUnit)
    set delay = AIR_GetTurnoverDelay(spawnGroupId)
    if AIR_SpawnGroupTurnoverEnabled[spawnGroupId] and delay > 0.00 then
        set AIR_UnitTurnoverTime.real[unitKey] = AIR_GetNow() + delay
    else
        call AIR_UnitTurnoverTime.real.remove(unitKey)
    endif
endfunction

private function AIR_SpawnManagedUnit takes integer spawnGroupId returns unit
    local rect spawnRect
    local player owner
    local unit created
    local integer unitTypeId
    if not AIR_SpawnGroupExists(spawnGroupId) or not AIR_SpawnGroupEnabled[spawnGroupId] then
        return null
    endif
    if not AIR_RoutineExists(AIR_SpawnGroupRoutine[spawnGroupId]) then
        return null
    endif
    set unitTypeId = AIR_GetSpawnGroupUnitType(spawnGroupId)
    if unitTypeId == 0 then
        return null
    endif

    set spawnRect = AIR_SpawnGroupRect[spawnGroupId]
    set owner = AIR_SpawnGroupOwner[spawnGroupId]
    if spawnRect == null or owner == null then
        set spawnRect = null
        set owner = null
        return null
    endif

    set created = CreateUnit(owner, unitTypeId, AIR_GetRectRandomX(spawnRect), AIR_GetRectRandomY(spawnRect), AIR_GetSpawnFacing(spawnGroupId))
    if created != null then
        if AIR_RegisterUnitInternalEx(created, AIR_SpawnGroupRoutine[spawnGroupId], AIR_SpawnGroupZone[spawnGroupId]) then
            set AIR_SpawnGroupAliveCount[spawnGroupId] = AIR_SpawnGroupAliveCount[spawnGroupId] + 1
            set AIR_UnitSpawnGroup[GetHandleId(created)] = spawnGroupId
            call AIR_ResetUnitTurnover(created, spawnGroupId)
        else
            call RemoveUnit(created)
            set created = null
        endif
    endif

    set spawnRect = null
    set owner = null
    return created
endfunction

private function AIR_SwitchRegisteredUnitRoutine takes unit whichUnit, integer routineId returns nothing
    local integer unitKey
    if whichUnit == null or not AIR_RoutineExists(routineId) then
        return
    endif
    set unitKey = GetHandleId(whichUnit)
    if AIR_UnitLeaving.boolean[unitKey] then
        return
    endif
    if AIR_UnitRoutine[unitKey] <= 0 then
        call AIR_RegisterUnitInternal(whichUnit, routineId)
        return
    endif
    if AIR_UnitRoutine[unitKey] == routineId then
        return
    endif

    call AIR_WakeUnitByKey(whichUnit, unitKey)
    call AIR_TryUnregisterAI(whichUnit, unitKey)
    set AIR_UnitRoutine[unitKey] = routineId
    set AIR_UnitStep[unitKey] = 0
    set AIR_UnitNextTime.real[unitKey] = AIR_GetNow()
    call AIR_UnitPaused.boolean.remove(unitKey)
    call AIR_TryRegisterAI(whichUnit, routineId, unitKey)
endfunction

private function AIR_RefillSpawnGroup takes integer spawnGroupId returns nothing
    local integer guard = 0
    local unit created
    if not AIR_SpawnGroupExists(spawnGroupId) or not AIR_SpawnGroupEnabled[spawnGroupId] then
        return
    endif
    loop
        exitwhen AIR_SpawnGroupAliveCount[spawnGroupId] >= AIR_SpawnGroupTargetCount[spawnGroupId]
        exitwhen guard >= AIR_SpawnGroupTargetCount[spawnGroupId]
        set created = AIR_SpawnManagedUnit(spawnGroupId)
        exitwhen created == null
        set guard = guard + 1
    endloop
    set created = null
endfunction

private function AIR_ReassignSpawnGroupUnits takes integer spawnGroupId, integer routineId returns nothing
    local integer index = 1
    local integer zoneId
    local integer count
    local unit whichUnit
    if not AIR_SpawnGroupExists(spawnGroupId) or not AIR_RoutineExists(routineId) then
        return
    endif

    set zoneId = AIR_SpawnGroupZone[spawnGroupId]
    if zoneId > 0 then
        set count = AIR_ZoneUnitCount[zoneId]
        loop
            exitwhen index > count
            set whichUnit = AIR_ZoneUnit.unit[AIR_GetZoneUnitKey(zoneId, index)]
            if whichUnit != null and AIR_UnitSpawnGroup[GetHandleId(whichUnit)] == spawnGroupId then
                call AIR_SwitchRegisteredUnitRoutine(whichUnit, routineId)
            endif
            set index = index + 1
        endloop
    else
        loop
            exitwhen index > AIR_ActiveCount
            set whichUnit = AIR_ActiveUnit[index]
            if whichUnit != null and AIR_UnitSpawnGroup[GetHandleId(whichUnit)] == spawnGroupId then
                call AIR_SwitchRegisteredUnitRoutine(whichUnit, routineId)
            endif
            set index = index + 1
        endloop
    endif
    set whichUnit = null
endfunction

private function AIR_ResetSpawnGroupTurnoverUnits takes integer spawnGroupId returns nothing
    local integer index = 1
    local integer zoneId
    local integer count
    local unit whichUnit
    if not AIR_SpawnGroupExists(spawnGroupId) then
        return
    endif

    set zoneId = AIR_SpawnGroupZone[spawnGroupId]
    if zoneId > 0 then
        set count = AIR_ZoneUnitCount[zoneId]
        loop
            exitwhen index > count
            set whichUnit = AIR_ZoneUnit.unit[AIR_GetZoneUnitKey(zoneId, index)]
            if whichUnit != null and AIR_UnitSpawnGroup[GetHandleId(whichUnit)] == spawnGroupId then
                call AIR_ResetUnitTurnover(whichUnit, spawnGroupId)
            endif
            set index = index + 1
        endloop
    else
        loop
            exitwhen index > AIR_ActiveCount
            set whichUnit = AIR_ActiveUnit[index]
            if whichUnit != null and AIR_UnitSpawnGroup[GetHandleId(whichUnit)] == spawnGroupId then
                call AIR_ResetUnitTurnover(whichUnit, spawnGroupId)
            endif
            set index = index + 1
        endloop
    endif
    set whichUnit = null
endfunction

private function AIR_OnManagedRespawnTimer takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer timerKey = GetHandleId(expiredTimer)
    local integer spawnGroupId = AIR_RespawnTimerGroup[timerKey]
    call AIR_RespawnTimerGroup.remove(timerKey)
    call DestroyTimer(expiredTimer)
    if AIR_SpawnGroupExists(spawnGroupId) and AIR_SpawnGroupEnabled[spawnGroupId] and AIR_SpawnGroupAliveCount[spawnGroupId] < AIR_SpawnGroupTargetCount[spawnGroupId] then
        call AIR_SpawnManagedUnit(spawnGroupId)
    endif
    set expiredTimer = null
endfunction

private function AIR_ScheduleManagedRespawn takes integer spawnGroupId returns nothing
    local timer respawnTimer
    if not AIR_SpawnGroupExists(spawnGroupId) or not AIR_SpawnGroupEnabled[spawnGroupId] then
        return
    endif
    if AIR_SpawnGroupRespawnDelay[spawnGroupId] <= 0.00 then
        call AIR_SpawnManagedUnit(spawnGroupId)
        return
    endif
    set respawnTimer = CreateTimer()
    set AIR_RespawnTimerGroup[GetHandleId(respawnTimer)] = spawnGroupId
    call TimerStart(respawnTimer, AIR_SpawnGroupRespawnDelay[spawnGroupId], false, function AIR_OnManagedRespawnTimer)
    set respawnTimer = null
endfunction

private function AIR_HandleManagedUnitGone takes unit whichUnit returns nothing
    local integer unitKey
    local integer spawnGroupId
    if whichUnit == null then
        return
    endif
    set unitKey = GetHandleId(whichUnit)
    set spawnGroupId = AIR_UnitSpawnGroup[unitKey]
    if spawnGroupId <= 0 then
        return
    endif

    call AIR_UnitSpawnGroup.remove(unitKey)
    if AIR_SpawnGroupAliveCount[spawnGroupId] > 0 then
        set AIR_SpawnGroupAliveCount[spawnGroupId] = AIR_SpawnGroupAliveCount[spawnGroupId] - 1
    endif
    call AIR_ClearUnitRegistration(whichUnit, false)

    if AIR_SpawnGroupEnabled[spawnGroupId] and AIR_SpawnGroupAliveCount[spawnGroupId] < AIR_SpawnGroupTargetCount[spawnGroupId] then
        call AIR_ScheduleManagedRespawn(spawnGroupId)
    endif
endfunction

private function AIR_OnManagedTurnoverTimer takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer timerKey = GetHandleId(expiredTimer)
    local unit leaving = AIR_TurnoverTimerUnit.unit[timerKey]
    local integer unitKey
    local integer spawnGroupId
    local real removeDelay
    call AIR_TurnoverTimerUnit.unit.remove(timerKey)
    call DestroyTimer(expiredTimer)

    if leaving != null then
        set unitKey = GetHandleId(leaving)
        set spawnGroupId = AIR_UnitSpawnGroup[unitKey]
        if AIR_UnitLeaving.boolean[unitKey] and spawnGroupId > 0 then
            if AIR_IsPlayerUnitNear(leaving, AIR_SpawnGroupRemovalPlayerGuardRange[spawnGroupId]) then
                set removeDelay = AIR_GetTurnoverRemoveDelay(spawnGroupId)
                set expiredTimer = CreateTimer()
                set AIR_TurnoverTimerUnit.unit[GetHandleId(expiredTimer)] = leaving
                call TimerStart(expiredTimer, removeDelay, false, function AIR_OnManagedTurnoverTimer)
            else
                call AIR_HandleManagedUnitGone(leaving)
                call RemoveUnit(leaving)
            endif
        endif
    endif

    set leaving = null
    set expiredTimer = null
endfunction

private function AIR_StartManagedUnitTurnover takes unit whichUnit, integer unitKey, real now returns nothing
    local integer spawnGroupId = AIR_UnitSpawnGroup[unitKey]
    local rect exitRect
    local timer removeTimer
    local real removeDelay
    local real x
    local real y
    if spawnGroupId <= 0 or not AIR_SpawnGroupTurnoverEnabled[spawnGroupId] then
        call AIR_UnitTurnoverTime.real.remove(unitKey)
        return
    endif
    if whichUnit == null or AIR_UnitLeaving.boolean[unitKey] or not AIR_IsAliveUnit(whichUnit) then
        return
    endif

    set removeDelay = AIR_GetTurnoverRemoveDelay(spawnGroupId)

    set AIR_UnitLeaving.boolean[unitKey] = true
    call AIR_UnitTurnoverTime.real.remove(unitKey)
    call AIR_WakeUnitByKey(whichUnit, unitKey)
    set AIR_UnitPaused.boolean[unitKey] = true
    set AIR_UnitNextTime.real[unitKey] = now + removeDelay

    set exitRect = AIR_SpawnGroupExitRect[spawnGroupId]
    if exitRect != null then
        set x = AIR_GetRectRandomX(exitRect)
        set y = AIR_GetRectRandomY(exitRect)
        call IssuePointOrder(whichUnit, "move", x, y)
    else
        call IssueImmediateOrder(whichUnit, "stop")
    endif

    set removeTimer = CreateTimer()
    set AIR_TurnoverTimerUnit.unit[GetHandleId(removeTimer)] = whichUnit
    call TimerStart(removeTimer, removeDelay, false, function AIR_OnManagedTurnoverTimer)

    set exitRect = null
    set removeTimer = null
endfunction

function AIRoutines_CreateRoutine takes string familyName returns integer
    local integer key
    local integer routineId
    if familyName == null or familyName == "" then
        return 0
    endif
    set key = StringHash(familyName)
    set routineId = AIR_RoutineByName[key]
    if routineId > 0 then
        return routineId
    endif
    if AIR_NextRoutineId > AIR_MAX_ROUTINES then
        call BJDebugMsg("[AIRoutines] ERROR: AIR_MAX_ROUTINES reached.")
        return 0
    endif
    set routineId = AIR_NextRoutineId
    set AIR_NextRoutineId = AIR_NextRoutineId + 1
    set AIR_RoutineByName[key] = routineId
    set AIR_RoutineName[routineId] = familyName
    set AIR_RoutineLoop[routineId] = AIR_DEFAULT_LOOP
    set AIR_RoutineAIEnabled[routineId] = AIR_DEFAULT_USE_AI_REGISTRY
    return routineId
endfunction

function AIRoutines_GetRoutineByName takes string familyName returns integer
    if familyName == null or familyName == "" then
        return 0
    endif
    return AIR_RoutineByName[StringHash(familyName)]
endfunction

function AIRoutines_SetRoutineLoop takes integer routineId, boolean enabled returns nothing
    if AIR_RoutineExists(routineId) then
        set AIR_RoutineLoop[routineId] = enabled
    endif
endfunction

function AIRoutines_SetRoutineAIRegistration takes integer routineId, boolean enabled returns nothing
    if AIR_RoutineExists(routineId) then
        set AIR_RoutineAIEnabled[routineId] = enabled
    endif
endfunction

function AIRoutines_AddWaitStep takes integer routineId, real minDuration, real maxDuration returns integer
    return AIR_AddStep(routineId, AIR_STEP_WAIT, minDuration, maxDuration)
endfunction

function AIRoutines_AddWorkStep takes integer routineId, string animationName, string effectPath, string attachPoint, real minDuration, real maxDuration returns integer
    local integer stepId = AIR_AddStep(routineId, AIR_STEP_WORK, minDuration, maxDuration)
    if stepId > 0 then
        set AIR_StepAnimation[stepId] = animationName
        set AIR_StepEffect[stepId] = effectPath
        set AIR_StepAttach[stepId] = attachPoint
    endif
    return stepId
endfunction

function AIRoutines_AddPointOrderStep takes integer routineId, string order, real x, real y, real minDuration, real maxDuration returns integer
    local integer stepId = AIR_AddStep(routineId, AIR_STEP_POINT_ORDER, minDuration, maxDuration)
    if stepId > 0 then
        set AIR_StepOrder[stepId] = order
        set AIR_StepX[stepId] = x
        set AIR_StepY[stepId] = y
    endif
    return stepId
endfunction

function AIRoutines_AddRectOrderStep takes integer routineId, string order, rect whichRect, real minDuration, real maxDuration returns integer
    local integer stepId = AIR_AddStep(routineId, AIR_STEP_RECT_ORDER, minDuration, maxDuration)
    if stepId > 0 then
        set AIR_StepOrder[stepId] = order
        set AIR_StepRect[stepId] = whichRect
    endif
    return stepId
endfunction

function AIRoutines_AddTargetUnitOrderStep takes integer routineId, string order, unit target, real minDuration, real maxDuration returns integer
    local integer stepId = AIR_AddStep(routineId, AIR_STEP_TARGET_UNIT_ORDER, minDuration, maxDuration)
    if stepId > 0 then
        set AIR_StepOrder[stepId] = order
        set AIR_StepTargetUnit[stepId] = target
    endif
    return stepId
endfunction

function AIRoutines_AddTargetDestructableOrderStep takes integer routineId, string order, destructable target, real minDuration, real maxDuration returns integer
    local integer stepId = AIR_AddStep(routineId, AIR_STEP_TARGET_DESTRUCTABLE_ORDER, minDuration, maxDuration)
    if stepId > 0 then
        set AIR_StepOrder[stepId] = order
        set AIR_StepTargetDestructable[stepId] = target
    endif
    return stepId
endfunction

function AIRoutines_AddImmediateOrderStep takes integer routineId, string order, real minDuration, real maxDuration returns integer
    local integer stepId = AIR_AddStep(routineId, AIR_STEP_IMMEDIATE_ORDER, minDuration, maxDuration)
    if stepId > 0 then
        set AIR_StepOrder[stepId] = order
    endif
    return stepId
endfunction

function AIRoutines_AddSleepStep takes integer routineId, real minDuration, real maxDuration, boolean hideDuringSleep returns integer
    local integer stepId = AIR_AddStep(routineId, AIR_STEP_SLEEP, minDuration, maxDuration)
    if stepId > 0 then
        set AIR_StepSleepHide[stepId] = hideDuringSleep
    endif
    return stepId
endfunction

function AIRoutines_AddCallbackStep takes integer routineId, real minDuration, real maxDuration, code callback returns integer
    local integer stepId = AIR_AddStep(routineId, AIR_STEP_CALLBACK, minDuration, maxDuration)
    local trigger callbackTrigger
    if stepId <= 0 then
        return 0
    endif
    set callbackTrigger = CreateTrigger()
    call TriggerAddAction(callbackTrigger, callback)
    set AIR_StepCallback[stepId] = callbackTrigger
    set callbackTrigger = null
    return stepId
endfunction

function AIRoutines_SetStepAnimation takes integer stepId, string animationName returns nothing
    if stepId > 0 and stepId < AIR_NextStepId then
        set AIR_StepAnimation[stepId] = animationName
    endif
endfunction

function AIRoutines_SetStepEffect takes integer stepId, string effectPath, string attachPoint returns nothing
    if stepId > 0 and stepId < AIR_NextStepId then
        set AIR_StepEffect[stepId] = effectPath
        set AIR_StepAttach[stepId] = attachPoint
    endif
endfunction

function AIRoutines_AddWanderStep takes integer routineId, rect wanderRect, real minDuration, real maxDuration returns integer
    return AIRoutines_AddRectOrderStep(routineId, "move", wanderRect, minDuration, maxDuration)
endfunction

function AIRoutines_AddStandStep takes integer routineId, string animationName, real minDuration, real maxDuration returns integer
    return AIRoutines_AddWorkStep(routineId, animationName, "", "", minDuration, maxDuration)
endfunction

function AIRoutines_AddEffectWorkStep takes integer routineId, string animationName, string effectPath, string attachPoint, real minDuration, real maxDuration returns integer
    return AIRoutines_AddWorkStep(routineId, animationName, effectPath, attachPoint, minDuration, maxDuration)
endfunction

function AIRoutines_RegisterUnit takes unit whichUnit, integer routineId returns boolean
    return AIR_RegisterUnitInternal(whichUnit, routineId)
endfunction

function AIRoutines_RegisterUnitInZone takes unit whichUnit, integer routineId, integer zoneId returns boolean
    return AIR_RegisterUnitInternalEx(whichUnit, routineId, zoneId)
endfunction

function AIRoutines_UnregisterUnit takes unit whichUnit returns nothing
    call AIR_ClearUnitRegistration(whichUnit, true)
endfunction

function AIRoutines_PauseUnitRoutine takes unit whichUnit, boolean pause returns nothing
    local integer unitKey
    if whichUnit == null then
        return
    endif
    set unitKey = GetHandleId(whichUnit)
    if AIR_UnitRoutine[unitKey] <= 0 then
        return
    endif
    set AIR_UnitPaused.boolean[unitKey] = pause
    if not pause then
        set AIR_UnitNextTime.real[unitKey] = AIR_GetNow()
    endif
endfunction

function AIRoutines_WakeUnit takes unit whichUnit returns nothing
    local integer unitKey
    if whichUnit == null then
        return
    endif
    set unitKey = GetHandleId(whichUnit)
    call AIR_WakeUnitByKey(whichUnit, unitKey)
    if AIR_UnitRoutine[unitKey] > 0 then
        set AIR_UnitNextTime.real[unitKey] = AIR_GetNow()
    endif
endfunction

function AIRoutines_IsUnitSleeping takes unit whichUnit returns boolean
    if whichUnit == null then
        return false
    endif
    return AIR_UnitSleeping.boolean[GetHandleId(whichUnit)]
endfunction

function AIRoutines_GetUnitRoutine takes unit whichUnit returns integer
    if whichUnit == null then
        return 0
    endif
    return AIR_UnitRoutine[GetHandleId(whichUnit)]
endfunction

function AIRoutines_GetUnitZone takes unit whichUnit returns integer
    if whichUnit == null then
        return 0
    endif
    return AIR_UnitZone[GetHandleId(whichUnit)]
endfunction

function AIRoutines_SetZoneActive takes integer zoneId, boolean active returns nothing
    call AIR_SetZoneActiveInternal(zoneId, active)
endfunction

function AIRoutines_IsZoneActive takes integer zoneId returns boolean
    return zoneId > 0 and AIR_ZoneActive.boolean[zoneId]
endfunction

function AIRoutines_RegisterUnitsInRect takes rect whichRect, integer routineId returns nothing
    local group enumGroup
    local unit enumUnit
    if whichRect == null or not AIR_RoutineExists(routineId) then
        return
    endif
    set enumGroup = CreateGroup()
    call GroupEnumUnitsInRect(enumGroup, whichRect, null)
    loop
        set enumUnit = FirstOfGroup(enumGroup)
        exitwhen enumUnit == null
        call GroupRemoveUnit(enumGroup, enumUnit)
        call AIR_RegisterUnitInternal(enumUnit, routineId)
    endloop
    call DestroyGroup(enumGroup)
    set enumUnit = null
    set enumGroup = null
endfunction

function AIRoutines_RegisterUnitsInRectInZone takes rect whichRect, integer routineId, integer zoneId returns nothing
    local group enumGroup
    local unit enumUnit
    if whichRect == null or not AIR_RoutineExists(routineId) or zoneId <= 0 then
        return
    endif
    set enumGroup = CreateGroup()
    call GroupEnumUnitsInRect(enumGroup, whichRect, null)
    loop
        set enumUnit = FirstOfGroup(enumGroup)
        exitwhen enumUnit == null
        call GroupRemoveUnit(enumGroup, enumUnit)
        call AIR_RegisterUnitInternalEx(enumUnit, routineId, zoneId)
    endloop
    call DestroyGroup(enumGroup)
    set enumUnit = null
    set enumGroup = null
endfunction

function AIRoutines_RegisterUnitTypeInRect takes integer unitTypeId, rect whichRect, integer routineId returns nothing
    local group enumGroup
    local unit enumUnit
    if unitTypeId == 0 or whichRect == null or not AIR_RoutineExists(routineId) then
        return
    endif
    set enumGroup = CreateGroup()
    call GroupEnumUnitsInRect(enumGroup, whichRect, null)
    loop
        set enumUnit = FirstOfGroup(enumGroup)
        exitwhen enumUnit == null
        call GroupRemoveUnit(enumGroup, enumUnit)
        if GetUnitTypeId(enumUnit) == unitTypeId then
            call AIR_RegisterUnitInternal(enumUnit, routineId)
        endif
    endloop
    call DestroyGroup(enumGroup)
    set enumUnit = null
    set enumGroup = null
endfunction

function AIRoutines_RegisterUnitTypeInRectInZone takes integer unitTypeId, rect whichRect, integer routineId, integer zoneId returns nothing
    local group enumGroup
    local unit enumUnit
    if unitTypeId == 0 or whichRect == null or not AIR_RoutineExists(routineId) or zoneId <= 0 then
        return
    endif
    set enumGroup = CreateGroup()
    call GroupEnumUnitsInRect(enumGroup, whichRect, null)
    loop
        set enumUnit = FirstOfGroup(enumGroup)
        exitwhen enumUnit == null
        call GroupRemoveUnit(enumGroup, enumUnit)
        if GetUnitTypeId(enumUnit) == unitTypeId then
            call AIR_RegisterUnitInternalEx(enumUnit, routineId, zoneId)
        endif
    endloop
    call DestroyGroup(enumGroup)
    set enumUnit = null
    set enumGroup = null
endfunction

function AIRoutines_RegisterUnitType takes integer unitTypeId, integer routineId returns nothing
    if unitTypeId == 0 or not AIR_RoutineExists(routineId) then
        return
    endif
    set AIR_UnitTypeRoutine[unitTypeId] = routineId
    call AIRoutines_RegisterUnitTypeInRect(unitTypeId, GetWorldBounds(), routineId)
endfunction

private function AIR_CreateManagedUnitGroupInternal takes player owner, integer unitTypeId, rect spawnRect, integer routineId, integer count, real respawnDelay, real facing, integer zoneId, boolean randomTypes returns integer
    local integer spawnGroupId
    if owner == null or spawnRect == null or not AIR_RoutineExists(routineId) or count <= 0 then
        return 0
    endif
    if unitTypeId == 0 and not randomTypes then
        return 0
    endif
    if AIR_NextSpawnGroupId > AIR_MAX_SPAWN_GROUPS then
        call BJDebugMsg("[AIRoutines] ERROR: AIR_MAX_SPAWN_GROUPS reached.")
        return 0
    endif

    set spawnGroupId = AIR_NextSpawnGroupId
    set AIR_NextSpawnGroupId = AIR_NextSpawnGroupId + 1
    set AIR_SpawnGroupOwner[spawnGroupId] = owner
    set AIR_SpawnGroupUnitType[spawnGroupId] = unitTypeId
    set AIR_SpawnGroupRect[spawnGroupId] = spawnRect
    set AIR_SpawnGroupRoutine[spawnGroupId] = routineId
    set AIR_SpawnGroupZone[spawnGroupId] = zoneId
    set AIR_SpawnGroupTargetCount[spawnGroupId] = count
    set AIR_SpawnGroupAliveCount[spawnGroupId] = 0
    set AIR_SpawnGroupRespawnDelay[spawnGroupId] = respawnDelay
    set AIR_SpawnGroupFacing[spawnGroupId] = facing
    set AIR_SpawnGroupEnabled[spawnGroupId] = true
    set AIR_SpawnGroupRandomTypes[spawnGroupId] = randomTypes
    set AIR_SpawnGroupTurnoverRemoveDelay[spawnGroupId] = AIR_DEFAULT_TURNOVER_REMOVE_DELAY
    call AIR_RefillSpawnGroup(spawnGroupId)
    return spawnGroupId
endfunction

function AIRoutines_CreateManagedUnitGroup takes player owner, integer unitTypeId, rect spawnRect, integer routineId, integer count, real respawnDelay, real facing returns integer
    return AIR_CreateManagedUnitGroupInternal(owner, unitTypeId, spawnRect, routineId, count, respawnDelay, facing, 0, false)
endfunction

function AIRoutines_CreateManagedUnitGroupInZone takes player owner, integer unitTypeId, rect spawnRect, integer routineId, integer count, real respawnDelay, real facing, integer zoneId returns integer
    return AIR_CreateManagedUnitGroupInternal(owner, unitTypeId, spawnRect, routineId, count, respawnDelay, facing, zoneId, false)
endfunction

function AIRoutines_CreateManagedRandomUnitGroup takes player owner, rect spawnRect, integer routineId, integer count, real respawnDelay, real facing returns integer
    return AIR_CreateManagedUnitGroupInternal(owner, 0, spawnRect, routineId, count, respawnDelay, facing, 0, true)
endfunction

function AIRoutines_CreateManagedRandomUnitGroupInZone takes player owner, rect spawnRect, integer routineId, integer count, real respawnDelay, real facing, integer zoneId returns integer
    return AIR_CreateManagedUnitGroupInternal(owner, 0, spawnRect, routineId, count, respawnDelay, facing, zoneId, true)
endfunction

function AIRoutines_AddManagedUnitGroupType takes integer spawnGroupId, integer unitTypeId, integer weight returns boolean
    local integer typeCount
    local integer key
    if not AIR_SpawnGroupExists(spawnGroupId) or unitTypeId == 0 then
        return false
    endif
    if AIR_SpawnGroupTypeCount[spawnGroupId] >= AIR_MAX_SPAWN_GROUP_UNIT_TYPES then
        call BJDebugMsg("[AIRoutines] ERROR: AIR_MAX_SPAWN_GROUP_UNIT_TYPES reached.")
        return false
    endif
    if weight <= 0 then
        set weight = 1
    endif

    set typeCount = AIR_SpawnGroupTypeCount[spawnGroupId] + 1
    set AIR_SpawnGroupTypeCount[spawnGroupId] = typeCount
    set AIR_SpawnGroupTypeWeightTotal[spawnGroupId] = AIR_SpawnGroupTypeWeightTotal[spawnGroupId] + weight
    set AIR_SpawnGroupRandomTypes[spawnGroupId] = true
    set key = AIR_GetSpawnGroupTypeKey(spawnGroupId, typeCount)
    set AIR_SpawnGroupUnitTypeChoice[key] = unitTypeId
    set AIR_SpawnGroupUnitTypeWeight[key] = weight
    return true
endfunction

function AIRoutines_SetManagedUnitGroupTurnover takes integer spawnGroupId, real minInterval, real maxInterval, rect exitRect, real removeDelay returns nothing
    if not AIR_SpawnGroupExists(spawnGroupId) then
        return
    endif
    if minInterval <= 0.00 and maxInterval <= 0.00 then
        set AIR_SpawnGroupTurnoverEnabled[spawnGroupId] = false
        set AIR_SpawnGroupTurnoverMin[spawnGroupId] = 0.00
        set AIR_SpawnGroupTurnoverMax[spawnGroupId] = 0.00
        set AIR_SpawnGroupExitRect[spawnGroupId] = null
        call AIR_ResetSpawnGroupTurnoverUnits(spawnGroupId)
        return
    endif
    if minInterval <= 0.00 then
        set minInterval = maxInterval
    endif
    if maxInterval < minInterval then
        set maxInterval = minInterval
    endif
    if removeDelay <= 0.00 then
        set removeDelay = AIR_DEFAULT_TURNOVER_REMOVE_DELAY
    endif

    set AIR_SpawnGroupTurnoverEnabled[spawnGroupId] = true
    set AIR_SpawnGroupTurnoverMin[spawnGroupId] = minInterval
    set AIR_SpawnGroupTurnoverMax[spawnGroupId] = maxInterval
    set AIR_SpawnGroupTurnoverRemoveDelay[spawnGroupId] = removeDelay
    set AIR_SpawnGroupExitRect[spawnGroupId] = exitRect
    call AIR_ResetSpawnGroupTurnoverUnits(spawnGroupId)
endfunction

function AIRoutines_SetManagedUnitGroupRemovalPlayerGuardRange takes integer spawnGroupId, real range returns nothing
    if not AIR_SpawnGroupExists(spawnGroupId) then
        return
    endif
    if range < 0.00 then
        set range = 0.00
    endif
    set AIR_SpawnGroupRemovalPlayerGuardRange[spawnGroupId] = range
endfunction

function AIRoutines_SetManagedUnitGroupRoutine takes integer spawnGroupId, integer routineId returns nothing
    if not AIR_SpawnGroupExists(spawnGroupId) or not AIR_RoutineExists(routineId) then
        return
    endif
    set AIR_SpawnGroupRoutine[spawnGroupId] = routineId
    call AIR_ReassignSpawnGroupUnits(spawnGroupId, routineId)
endfunction

function AIRoutines_SetManagedUnitGroupEnabled takes integer spawnGroupId, boolean enabled returns nothing
    if not AIR_SpawnGroupExists(spawnGroupId) then
        return
    endif
    set AIR_SpawnGroupEnabled[spawnGroupId] = enabled
    if enabled then
        call AIR_RefillSpawnGroup(spawnGroupId)
    endif
endfunction

function AIRoutines_RefillManagedUnitGroup takes integer spawnGroupId returns nothing
    call AIR_RefillSpawnGroup(spawnGroupId)
endfunction

function AIRoutines_CreateVillageWanderRoutine takes string familyName, rect villageRect, real moveMin, real moveMax, real idleMin, real idleMax returns integer
    local integer routineId = AIRoutines_CreateRoutine(familyName)
    if routineId <= 0 then
        return 0
    endif
    if moveMin <= 0.00 then
        set moveMin = 8.00
    endif
    if moveMax < moveMin then
        set moveMax = moveMin + 8.00
    endif
    if idleMin <= 0.00 then
        set idleMin = 3.00
    endif
    if idleMax < idleMin then
        set idleMax = idleMin + 5.00
    endif
    call AIRoutines_AddWanderStep(routineId, villageRect, moveMin, moveMax)
    call AIRoutines_AddStandStep(routineId, "stand", idleMin, idleMax)
    return routineId
endfunction

function AIRoutines_CreateFishingRoutine takes string familyName, rect fishingRect, real fishMin, real fishMax, real idleMin, real idleMax returns integer
    local integer routineId = AIRoutines_CreateRoutine(familyName)
    if routineId <= 0 then
        return 0
    endif
    if fishMin <= 0.00 then
        set fishMin = 20.00
    endif
    if fishMax < fishMin then
        set fishMax = fishMin + 25.00
    endif
    if idleMin <= 0.00 then
        set idleMin = 4.00
    endif
    if idleMax < idleMin then
        set idleMax = idleMin + 6.00
    endif
    call AIRoutines_AddWanderStep(routineId, fishingRect, 4.00, 8.00)
    call AIRoutines_AddStandStep(routineId, "stand work", fishMin, fishMax)
    call AIRoutines_AddWaitStep(routineId, idleMin, idleMax)
    return routineId
endfunction

function AIRoutines_CreateBlacksmithRoutine takes string familyName, rect workRect returns integer
    local integer routineId = AIRoutines_CreateRoutine(familyName)
    if routineId <= 0 then
        return 0
    endif
    call AIRoutines_AddRectOrderStep(routineId, "move", workRect, 2.00, 4.00)
    call AIRoutines_AddWorkStep(routineId, "attack", "", "", 1.10, 1.70)
    call AIRoutines_AddWorkStep(routineId, "attack", "", "", 1.10, 1.70)
    call AIRoutines_AddWaitStep(routineId, 2.00, 5.00)
    return routineId
endfunction

function AIRoutines_CreatePeonLumberSleepRoutine takes string familyName, rect lumberRect, rect sleepRect, real harvestDuration, real sleepDuration, boolean hideDuringSleep returns integer
    local integer routineId = AIRoutines_CreateRoutine(familyName)
    if routineId <= 0 then
        return 0
    endif
    if harvestDuration <= 0.00 then
        set harvestDuration = 45.00
    endif
    if sleepDuration <= 0.00 then
        set sleepDuration = 60.00
    endif
    call AIRoutines_AddRectOrderStep(routineId, "harvest", lumberRect, harvestDuration, harvestDuration)
    call AIRoutines_AddRectOrderStep(routineId, "move", sleepRect, 6.00, 12.00)
    call AIRoutines_AddSleepStep(routineId, sleepDuration, sleepDuration, hideDuringSleep)
    return routineId
endfunction

private function AIR_PickRandomDestructableEnum takes nothing returns nothing
    local destructable enumDest = GetEnumDestructable()
    if enumDest != null and GetDestructableLife(enumDest) > 0.405 then
        set AIR_EnumDestructableCount = AIR_EnumDestructableCount + 1
        if GetRandomInt(1, AIR_EnumDestructableCount) == 1 then
            set AIR_EnumDestructablePick = enumDest
        endif
    endif
    set enumDest = null
endfunction

private function AIR_GetRandomDestructableInRect takes rect whichRect returns destructable
    if whichRect == null then
        return null
    endif
    set AIR_EnumDestructablePick = null
    set AIR_EnumDestructableCount = 0
    call EnumDestructablesInRect(whichRect, null, function AIR_PickRandomDestructableEnum)
    return AIR_EnumDestructablePick
endfunction

private function AIR_StartStep takes unit whichUnit, integer unitKey, integer routineId, integer stepIndex, integer stepId, real now returns nothing
    local string order = AIR_StepOrder[stepId]
    local rect whichRect = AIR_StepRect[stepId]
    local unit targetUnit = AIR_StepTargetUnit[stepId]
    local destructable targetDest = AIR_StepTargetDestructable[stepId]
    local trigger callbackTrigger = AIR_StepCallback[stepId]
    local real duration = AIR_GetStepDuration(stepId)
    local real x
    local real y

    if order == null or order == "" then
        set order = "move"
    endif

    call AIR_SetEventContext(whichUnit, routineId, stepId)

    if AIR_StepType[stepId] == AIR_STEP_POINT_ORDER then
        call IssuePointOrder(whichUnit, order, AIR_StepX[stepId], AIR_StepY[stepId])
    elseif AIR_StepType[stepId] == AIR_STEP_RECT_ORDER then
        if whichRect != null then
            if order == "harvest" then
                set targetDest = AIR_GetRandomDestructableInRect(whichRect)
                if targetDest != null then
                    call IssueTargetOrder(whichUnit, order, targetDest)
                else
                    set x = GetRandomReal(GetRectMinX(whichRect), GetRectMaxX(whichRect))
                    set y = GetRandomReal(GetRectMinY(whichRect), GetRectMaxY(whichRect))
                    call IssuePointOrder(whichUnit, order, x, y)
                endif
            else
                set x = GetRandomReal(GetRectMinX(whichRect), GetRectMaxX(whichRect))
                set y = GetRandomReal(GetRectMinY(whichRect), GetRectMaxY(whichRect))
                call IssuePointOrder(whichUnit, order, x, y)
            endif
        endif
    elseif AIR_StepType[stepId] == AIR_STEP_TARGET_UNIT_ORDER then
        if targetUnit != null then
            call IssueTargetOrder(whichUnit, order, targetUnit)
        endif
    elseif AIR_StepType[stepId] == AIR_STEP_TARGET_DESTRUCTABLE_ORDER then
        if targetDest != null then
            call IssueTargetOrder(whichUnit, order, targetDest)
        endif
    elseif AIR_StepType[stepId] == AIR_STEP_IMMEDIATE_ORDER then
        call IssueImmediateOrder(whichUnit, order)
    elseif AIR_StepType[stepId] == AIR_STEP_WORK then
        call IssueImmediateOrder(whichUnit, "stop")
        call AIR_ApplyStepAnimation(whichUnit, stepId)
        call AIR_PlayStepEffect(whichUnit, stepId)
    elseif AIR_StepType[stepId] == AIR_STEP_SLEEP then
        call AIR_BeginSleep(whichUnit, unitKey, AIR_StepSleepHide[stepId])
    elseif AIR_StepType[stepId] == AIR_STEP_CALLBACK then
        if callbackTrigger != null then
            call TriggerExecute(callbackTrigger)
        endif
    endif

    if AIR_StepType[stepId] != AIR_STEP_WORK then
        call AIR_ApplyStepAnimation(whichUnit, stepId)
        call AIR_PlayStepEffect(whichUnit, stepId)
    endif

    set AIR_UnitNextTime.real[unitKey] = now + duration
    call AIR_ClearEventContext()

    set whichRect = null
    set targetUnit = null
    set targetDest = null
    set callbackTrigger = null
endfunction

private function AIR_StartNextStep takes unit whichUnit, integer unitKey, real now returns nothing
    local integer routineId = AIR_UnitRoutine[unitKey]
    local integer stepCount
    local integer stepIndex
    local integer stepId
    if not AIR_RoutineExists(routineId) or whichUnit == null then
        return
    endif
    set stepCount = AIR_RoutineStepCount[routineId]
    if stepCount <= 0 then
        set AIR_UnitNextTime.real[unitKey] = now + 1.00
        return
    endif
    set stepIndex = AIR_UnitStep[unitKey] + 1
    if stepIndex > stepCount then
        if not AIR_RoutineLoop[routineId] then
            set AIR_UnitPaused.boolean[unitKey] = true
            return
        endif
        set stepIndex = 1
    endif
    set stepId = AIR_RoutineStepId[AIR_GetRoutineStepKey(routineId, stepIndex)]
    if stepId <= 0 then
        set AIR_UnitNextTime.real[unitKey] = now + 1.00
        return
    endif
    set AIR_UnitStep[unitKey] = stepIndex
    call AIR_StartStep(whichUnit, unitKey, routineId, stepIndex, stepId, now)
endfunction

private function AIR_ProcessUnit takes unit whichUnit, real now returns nothing
    local integer unitKey
    if whichUnit == null then
        return
    endif
    set unitKey = GetHandleId(whichUnit)
    if GetUnitTypeId(whichUnit) == 0 then
        call AIR_HandleManagedUnitGone(whichUnit)
        call AIR_ClearUnitRegistration(whichUnit, false)
        return
    endif
    if AIR_UnitRoutine[unitKey] <= 0 then
        return
    endif
    if not AIR_IsAliveUnit(whichUnit) then
        if AIR_UnitSleeping.boolean[unitKey] then
            call AIR_WakeUnitByKey(whichUnit, unitKey)
        endif
        return
    endif
    if AIR_UnitLeaving.boolean[unitKey] then
        return
    endif
    if AIR_UnitTurnoverTime.real[unitKey] > 0.00 and now >= AIR_UnitTurnoverTime.real[unitKey] then
        call AIR_StartManagedUnitTurnover(whichUnit, unitKey, now)
        return
    endif
    if AIR_UnitPaused.boolean[unitKey] then
        return
    endif
    if AIR_UnitSleeping.boolean[unitKey] then
        if now >= AIR_UnitNextTime.real[unitKey] then
            call AIR_WakeUnitByKey(whichUnit, unitKey)
            call AIR_StartNextStep(whichUnit, unitKey, now)
        endif
        return
    endif
    if now >= AIR_UnitNextTime.real[unitKey] then
        call AIR_StartNextStep(whichUnit, unitKey, now)
    endif
endfunction

private function AIR_Periodic takes nothing returns nothing
    local integer index = 1
    local real now = AIR_GetNow()
    local unit whichUnit
    loop
        exitwhen index > AIR_ActiveCount
        set whichUnit = AIR_ActiveUnit[index]
        call AIR_ProcessUnit(whichUnit, now)
        set index = index + 1
    endloop
    set whichUnit = null
endfunction

private function AIR_OnUnitAttacked takes nothing returns nothing
    local unit attacked = GetTriggerUnit()
    local integer unitKey
    if attacked == null then
        return
    endif
    set unitKey = GetHandleId(attacked)
    if AIR_UnitSleeping.boolean[unitKey] then
        call AIR_WakeUnitByKey(attacked, unitKey)
        set AIR_UnitNextTime.real[unitKey] = AIR_GetNow() + AIR_ATTACK_WAKE_DELAY
    endif
    set attacked = null
endfunction

private function AIR_OnUnitDeath takes nothing returns nothing
    local unit dying = GetDyingUnit()
    call AIR_HandleManagedUnitGone(dying)
    set dying = null
endfunction

private function AIR_OnEnterWorld takes nothing returns nothing
    local unit entering = GetEnteringUnit()
    local integer routineId
    if entering == null then
        return
    endif
    set routineId = AIR_UnitTypeRoutine[GetUnitTypeId(entering)]
    if routineId > 0 then
        call AIR_RegisterUnitInternal(entering, routineId)
    endif
    set entering = null
endfunction

private function AIR_RegisterPlayerUnitEventAll takes trigger whichTrigger, playerunitevent whichEvent returns nothing
    local integer playerIndex = 0
    loop
        exitwhen playerIndex > AIR_MAX_PLAYER_INDEX
        call TriggerRegisterPlayerUnitEvent(whichTrigger, Player(playerIndex), whichEvent, null)
        set playerIndex = playerIndex + 1
    endloop
endfunction

private function AIR_OnZoneHeroEnter takes nothing returns nothing
    local integer zoneId = ZoneEvent_EventZoneId
    local integer heroCount
    if zoneId <= 0 then
        return
    endif

    set heroCount = AIR_ZoneHeroCount[zoneId] + 1
    set AIR_ZoneHeroCount[zoneId] = heroCount
    if heroCount == 1 then
        call AIR_SetZoneActiveInternal(zoneId, true)
    endif
endfunction

private function AIR_OnZoneHeroLeave takes nothing returns nothing
    local integer zoneId = ZoneEvent_EventZoneId
    local integer heroCount
    if zoneId <= 0 then
        return
    endif

    set heroCount = AIR_ZoneHeroCount[zoneId]
    if heroCount <= 1 then
        call AIR_ZoneHeroCount.remove(zoneId)
        call AIR_SetZoneActiveInternal(zoneId, false)
    else
        set AIR_ZoneHeroCount[zoneId] = heroCount - 1
    endif
endfunction

private function Init takes nothing returns nothing
    set AIR_RoutineByName = Table.create()
    set AIR_RoutineStepId = Table.create()
    set AIR_UnitRoutine = Table.create()
    set AIR_UnitStep = Table.create()
    set AIR_UnitNextTime = Table.create()
    set AIR_UnitActiveSlot = Table.create()
    set AIR_UnitZone = Table.create()
    set AIR_UnitZoneSlot = Table.create()
    set AIR_UnitPaused = Table.create()
    set AIR_UnitSleeping = Table.create()
    set AIR_UnitSleepHidden = Table.create()
    set AIR_UnitWasPaused = Table.create()
    set AIR_UnitWasHidden = Table.create()
    set AIR_UnitHadSleepAbility = Table.create()
    set AIR_UnitAIRegistered = Table.create()
    set AIR_UnitTypeRoutine = Table.create()
    set AIR_UnitSpawnGroup = Table.create()
    set AIR_UnitTurnoverTime = Table.create()
    set AIR_UnitLeaving = Table.create()
    set AIR_SpawnGroupUnitTypeChoice = Table.create()
    set AIR_SpawnGroupUnitTypeWeight = Table.create()
    set AIR_RespawnTimerGroup = Table.create()
    set AIR_TurnoverTimerUnit = Table.create()
    set AIR_AIProfileByRoutineType = Table.create()
    set AIR_ZoneActive = Table.create()
    set AIR_ZoneHeroCount = Table.create()
    set AIR_ZoneUnit = Table.create()
    set AIR_ZoneUnitCount = Table.create()
    set AIR_RemovalGuardEnumGroup = CreateGroup()

    set AIR_AIClassId = AI_RegisterClass("Routine")

    set AIR_ClockTimer = CreateTimer()
    call TimerStart(AIR_ClockTimer, 1000000.00, false, function AIR_NoOp)

    set AIR_TickTrigger = CreateTrigger()
    call TriggerAddAction(AIR_TickTrigger, function AIR_Periodic)
    set AIR_TickTimer = CreateTimer()
    call ZoneEvent_RegisterEnterAction(function AIR_OnZoneHeroEnter)
    call ZoneEvent_RegisterLeaveAction(function AIR_OnZoneHeroLeave)

    set AIR_AttackTrigger = CreateTrigger()
    call AIR_RegisterPlayerUnitEventAll(AIR_AttackTrigger, EVENT_PLAYER_UNIT_ATTACKED)
    call TriggerAddAction(AIR_AttackTrigger, function AIR_OnUnitAttacked)

    set AIR_DeathTrigger = CreateTrigger()
    call AIR_RegisterPlayerUnitEventAll(AIR_DeathTrigger, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(AIR_DeathTrigger, function AIR_OnUnitDeath)

    set AIR_EnterRegion = CreateRegion()
    call RegionAddRect(AIR_EnterRegion, GetWorldBounds())
    set AIR_EnterTrigger = CreateTrigger()
    call TriggerRegisterEnterRegion(AIR_EnterTrigger, AIR_EnterRegion, null)
    call TriggerAddAction(AIR_EnterTrigger, function AIR_OnEnterWorld)
endfunction

endlibrary
