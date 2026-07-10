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
    rect, or by unit type across the map.

    Credits:
    - PotS AI JASS migration

    How to install:
    Import after `AI.j` and `Table`. Optional AI profile registration is
    available per routine family; keep it disabled for pure ambient NPCs if the
    shared AI revive behavior is not wanted.

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
    call AIRoutines_RegisterUnitsInRect(whichRect, routineId)
    call AIRoutines_RegisterUnitTypeInRect(unitTypeId, whichRect, routineId)
    call AIRoutines_RegisterUnitType(unitTypeId, routineId)
    call AIRoutines_UnregisterUnit(whichUnit)
    call AIRoutines_WakeUnit(whichUnit)
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

**/
library AIRoutines initializer Init requires AI, Table

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
    private constant integer AIR_SLEEP_ABILITY_ID = 'A0F1'
    private constant integer AIR_MAX_ROUTINES = 512
    private constant integer AIR_MAX_STEPS = 4096
    private constant integer AIR_MAX_ROUTINE_STEPS = 128
    private constant integer AIR_MAX_ACTIVE_UNITS = 2048
    private constant integer AIR_MAX_PLAYER_INDEX = 27
    private constant integer AIR_ROUTINE_STEP_KEY = 1000
    private constant real AIR_TICK_INTERVAL = 0.50
    private constant real AIR_ATTACK_WAKE_DELAY = 12.00

    // Routine families and lookup.
    private integer AIR_NextRoutineId = 1
    private integer AIR_NextStepId = 1
    private integer AIR_ActiveCount = 0
    private integer AIR_AIClassId = 0
    private timer AIR_ClockTimer = null
    private timer AIR_TickTimer = null
    private trigger AIR_AttackTrigger = null
    private trigger AIR_EnterTrigger = null
    private region AIR_EnterRegion = null

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

    private Table AIR_RoutineByName = 0
    private Table AIR_RoutineStepId = 0
    private Table AIR_UnitRoutine = 0
    private Table AIR_UnitStep = 0
    private Table AIR_UnitNextTime = 0
    private Table AIR_UnitActiveSlot = 0
    private Table AIR_UnitPaused = 0
    private Table AIR_UnitSleeping = 0
    private Table AIR_UnitSleepHidden = 0
    private Table AIR_UnitWasPaused = 0
    private Table AIR_UnitWasHidden = 0
    private Table AIR_UnitHadSleepAbility = 0
    private Table AIR_UnitAIRegistered = 0
    private Table AIR_UnitTypeRoutine = 0
    private Table AIR_AIProfileByRoutineType = 0
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
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
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
    set moved = null
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
    call AIR_UnitRoutine.remove(unitKey)
    call AIR_UnitStep.remove(unitKey)
    call AIR_UnitNextTime.real.remove(unitKey)
    call AIR_UnitPaused.boolean.remove(unitKey)
    call AIR_UnitSleeping.boolean.remove(unitKey)
    call AIR_UnitSleepHidden.boolean.remove(unitKey)
    call AIR_UnitWasPaused.boolean.remove(unitKey)
    call AIR_UnitWasHidden.boolean.remove(unitKey)
    call AIR_UnitHadSleepAbility.boolean.remove(unitKey)
endfunction

private function AIR_RegisterUnitInternal takes unit whichUnit, integer routineId returns boolean
    local integer unitKey
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 or not AIR_RoutineExists(routineId) then
        return false
    endif
    set unitKey = GetHandleId(whichUnit)
    if AIR_UnitRoutine[unitKey] == routineId then
        return true
    endif
    if AIR_UnitRoutine[unitKey] > 0 then
        call AIR_ClearUnitRegistration(whichUnit, true)
    endif
    if not AIR_AddActiveUnit(whichUnit, unitKey) then
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

function AIRoutines_RegisterUnitType takes integer unitTypeId, integer routineId returns nothing
    if unitTypeId == 0 or not AIR_RoutineExists(routineId) then
        return
    endif
    set AIR_UnitTypeRoutine[unitTypeId] = routineId
    call AIRoutines_RegisterUnitTypeInRect(unitTypeId, GetWorldBounds(), routineId)
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
            set x = GetRandomReal(GetRectMinX(whichRect), GetRectMaxX(whichRect))
            set y = GetRandomReal(GetRectMinY(whichRect), GetRectMaxY(whichRect))
            call IssuePointOrder(whichUnit, order, x, y)
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

private function Init takes nothing returns nothing
    set AIR_RoutineByName = Table.create()
    set AIR_RoutineStepId = Table.create()
    set AIR_UnitRoutine = Table.create()
    set AIR_UnitStep = Table.create()
    set AIR_UnitNextTime = Table.create()
    set AIR_UnitActiveSlot = Table.create()
    set AIR_UnitPaused = Table.create()
    set AIR_UnitSleeping = Table.create()
    set AIR_UnitSleepHidden = Table.create()
    set AIR_UnitWasPaused = Table.create()
    set AIR_UnitWasHidden = Table.create()
    set AIR_UnitHadSleepAbility = Table.create()
    set AIR_UnitAIRegistered = Table.create()
    set AIR_UnitTypeRoutine = Table.create()
    set AIR_AIProfileByRoutineType = Table.create()

    set AIR_AIClassId = AI_RegisterClass("Routine")

    set AIR_ClockTimer = CreateTimer()
    call TimerStart(AIR_ClockTimer, 1000000.00, false, function AIR_NoOp)

    set AIR_TickTimer = CreateTimer()
    call TimerStart(AIR_TickTimer, AIR_TICK_INTERVAL, true, function AIR_Periodic)

    set AIR_AttackTrigger = CreateTrigger()
    call AIR_RegisterPlayerUnitEventAll(AIR_AttackTrigger, EVENT_PLAYER_UNIT_ATTACKED)
    call TriggerAddAction(AIR_AttackTrigger, function AIR_OnUnitAttacked)

    set AIR_EnterRegion = CreateRegion()
    call RegionAddRect(AIR_EnterRegion, GetWorldBounds())
    set AIR_EnterTrigger = CreateTrigger()
    call TriggerRegisterEnterRegion(AIR_EnterTrigger, AIR_EnterRegion, null)
    call TriggerAddAction(AIR_EnterTrigger, function AIR_OnEnterWorld)
endfunction

endlibrary
