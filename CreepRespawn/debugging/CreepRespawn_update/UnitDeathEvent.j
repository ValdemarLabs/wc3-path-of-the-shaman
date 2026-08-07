/**
    UnitDeathEvent

    Author: Valdemar
    Version: 3.0

    Description:
    Centralized unit-death dispatcher. The native death event is registered
    once for every player slot. Code subscribers are dispatched directly with
    stored callback triggers instead of TriggerRegisterVariableEvent.

    Direct dispatch is deterministic for nested deaths because the dying and
    killing unit context is saved/restored around each dispatch depth.

    A legacy UnitDeathEvent_Event real is retained only for compatibility with
    old GUI variable-event listeners. Code systems should use
    UnitDeathEvent_Register.

    API:
    call UnitDeathEvent_Register(function YourCallback)
    call UnitDeathEvent_RegisterTrigger(yourTrigger)
    call UnitDeathEvent_Fire(whichUnit, killingUnit)
    set dying = UnitDeathEvent_GetDyingUnit()
    set killer = UnitDeathEvent_GetKillingUnit()
    call UnitDeathEvent_SetDebugEnabled(true)

    Registered callbacks must use the accessors above instead of the native
    GetDyingUnit() and GetKillingUnit() event responses.
**/
library UnitDeathEvent initializer Init

globals
    private constant integer UNIT_DEATH_EVENT_MAX_CALLBACKS = 256
    private constant integer UNIT_DEATH_EVENT_MAX_PLAYER_INDEX = 27

    private trigger UnitDeathEvent_DeathTrigger = null
    private trigger array UnitDeathEvent_Callbacks
    private integer UnitDeathEvent_CallbackCount = 0
    private unit UnitDeathEvent_CurrentDyingUnit = null
    private unit UnitDeathEvent_CurrentKillingUnit = null
    private integer UnitDeathEvent_DispatchDepth = 0
    private boolean UnitDeathEvent_DebugEnabled = false

    // Legacy GUI compatibility only. Direct code subscribers do not use this.
    real UnitDeathEvent_Event = 0.00
endglobals

private function UnitDeathEvent_Debug takes string message returns nothing
    if UnitDeathEvent_DebugEnabled then
        call BJDebugMsg("[UnitDeathEvent] " + message)
    endif
endfunction

private function UnitDeathEvent_Error takes string message returns nothing
    call BJDebugMsg("[UnitDeathEvent] ERROR: " + message)
endfunction

private function UnitDeathEvent_RunCallback takes trigger callbackTrigger returns nothing
    if callbackTrigger == null then
        return
    endif
    if not IsTriggerEnabled(callbackTrigger) then
        return
    endif
    if TriggerEvaluate(callbackTrigger) then
        call TriggerExecute(callbackTrigger)
    endif
endfunction

private function UnitDeathEvent_DispatchUnits takes unit dyingUnit, unit killingUnit returns nothing
    local unit previousDyingUnit
    local unit previousKillingUnit
    local integer callbackIndex = 0
    local integer callbackCount = UnitDeathEvent_CallbackCount

    if dyingUnit == null then
        call UnitDeathEvent_Error("Dispatch attempted with a null dying unit.")
        return
    endif

    set previousDyingUnit = UnitDeathEvent_CurrentDyingUnit
    set previousKillingUnit = UnitDeathEvent_CurrentKillingUnit
    set UnitDeathEvent_CurrentDyingUnit = dyingUnit
    set UnitDeathEvent_CurrentKillingUnit = killingUnit
    set UnitDeathEvent_DispatchDepth = UnitDeathEvent_DispatchDepth + 1

    call UnitDeathEvent_Debug("Dispatching death of " + GetUnitName(dyingUnit) + " to " + I2S(callbackCount) + " callback(s).")

    // Snapshot callbackCount so callbacks registered during a dispatch begin
    // receiving events from the next death, not midway through this one.
    loop
        exitwhen callbackIndex >= callbackCount
        call UnitDeathEvent_RunCallback(UnitDeathEvent_Callbacks[callbackIndex])
        set callbackIndex = callbackIndex + 1
    endloop

    // Compatibility pulse for old GUI variable-event listeners. Nested deaths
    // are intentionally not pulsed because variable events are not safely
    // nestable. Direct UnitDeathEvent_Register subscribers receive every depth.
    if UnitDeathEvent_DispatchDepth == 1 then
        set UnitDeathEvent_Event = 0.00
        set UnitDeathEvent_Event = 1.00
        set UnitDeathEvent_Event = 0.00
    endif

    set UnitDeathEvent_DispatchDepth = UnitDeathEvent_DispatchDepth - 1
    set UnitDeathEvent_CurrentDyingUnit = previousDyingUnit
    set UnitDeathEvent_CurrentKillingUnit = previousKillingUnit
    set previousDyingUnit = null
    set previousKillingUnit = null
endfunction

private function UnitDeathEvent_Dispatch takes nothing returns nothing
    call UnitDeathEvent_DispatchUnits(GetDyingUnit(), GetKillingUnit())
endfunction

private function UnitDeathEvent_EnsureTrigger takes nothing returns nothing
    local integer playerIndex = 0

    if UnitDeathEvent_DeathTrigger != null then
        return
    endif

    set UnitDeathEvent_DeathTrigger = CreateTrigger()
    if UnitDeathEvent_DeathTrigger == null then
        call UnitDeathEvent_Error("Unable to create central death trigger.")
        return
    endif

    loop
        exitwhen playerIndex > UNIT_DEATH_EVENT_MAX_PLAYER_INDEX
        call TriggerRegisterPlayerUnitEvent(UnitDeathEvent_DeathTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_DEATH, null)
        set playerIndex = playerIndex + 1
    endloop

    call TriggerAddAction(UnitDeathEvent_DeathTrigger, function UnitDeathEvent_Dispatch)
    call UnitDeathEvent_Debug("Central native death trigger initialized.")
endfunction

function UnitDeathEvent_SetDebugEnabled takes boolean enabled returns nothing
    set UnitDeathEvent_DebugEnabled = enabled
endfunction

function UnitDeathEvent_GetDyingUnit takes nothing returns unit
    return UnitDeathEvent_CurrentDyingUnit
endfunction

function UnitDeathEvent_GetKillingUnit takes nothing returns unit
    return UnitDeathEvent_CurrentKillingUnit
endfunction

function UnitDeathEvent_Fire takes unit dyingUnit, unit killingUnit returns nothing
    if dyingUnit == null then
        return
    endif
    call UnitDeathEvent_EnsureTrigger()
    if UnitDeathEvent_DeathTrigger == null then
        call UnitDeathEvent_Error("Cannot fire because the central death trigger is unavailable.")
        return
    endif
    call UnitDeathEvent_DispatchUnits(dyingUnit, killingUnit)
endfunction

function UnitDeathEvent_RegisterTrigger takes trigger callbackTrigger returns nothing
    if callbackTrigger == null then
        call UnitDeathEvent_Error("Cannot register a null callback trigger.")
        return
    endif

    call UnitDeathEvent_EnsureTrigger()
    if UnitDeathEvent_DeathTrigger == null then
        call UnitDeathEvent_Error("Cannot register callback because the central death trigger is unavailable.")
        return
    endif

    if UnitDeathEvent_CallbackCount >= UNIT_DEATH_EVENT_MAX_CALLBACKS then
        call UnitDeathEvent_Error("Maximum callbacks reached (" + I2S(UNIT_DEATH_EVENT_MAX_CALLBACKS) + ").")
        return
    endif

    set UnitDeathEvent_Callbacks[UnitDeathEvent_CallbackCount] = callbackTrigger
    set UnitDeathEvent_CallbackCount = UnitDeathEvent_CallbackCount + 1
    call UnitDeathEvent_Debug("Registered callback #" + I2S(UnitDeathEvent_CallbackCount) + ".")
endfunction

function UnitDeathEvent_Register takes code callback returns nothing
    local trigger callbackTrigger

    call UnitDeathEvent_EnsureTrigger()
    if UnitDeathEvent_DeathTrigger == null then
        call UnitDeathEvent_Error("Cannot register code callback because the central death trigger is unavailable.")
        return
    endif
    if UnitDeathEvent_CallbackCount >= UNIT_DEATH_EVENT_MAX_CALLBACKS then
        call UnitDeathEvent_Error("Maximum callbacks reached (" + I2S(UNIT_DEATH_EVENT_MAX_CALLBACKS) + ").")
        return
    endif

    set callbackTrigger = CreateTrigger()
    if callbackTrigger == null then
        call UnitDeathEvent_Error("Unable to create callback trigger.")
        return
    endif

    call TriggerAddAction(callbackTrigger, callback)
    call UnitDeathEvent_RegisterTrigger(callbackTrigger)
    set callbackTrigger = null
endfunction

private function Init takes nothing returns nothing
    call UnitDeathEvent_EnsureTrigger()
endfunction

endlibrary
