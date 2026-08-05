/**
    UnitDeathEvent

    Author: Valdemar
    Version: 2.0

    Description:
    Centralized unit-death dispatcher. The native death event is registered
    once for every player slot, while subscribers listen to a shared variable
    event through separate callback triggers. Death-event responses are cached
    before dispatch so subscribers retain the dying and killing units.

    Credits:
    - Original PotS UnitDeathEvent implementation

    How to install:
    Import this library before systems that register death callbacks and add
    UnitDeathEvent to their library requirements.

    API:
    call UnitDeathEvent_Register(function YourCallback)
    call UnitDeathEvent_Fire(whichUnit, killingUnit)
    set dying = UnitDeathEvent_GetDyingUnit()
    set killer = UnitDeathEvent_GetKillingUnit()

    Registered callbacks must use the accessors above instead of the native
    GetDyingUnit() and GetKillingUnit() event responses.
**/
library UnitDeathEvent initializer Init

globals
    private constant integer UNIT_DEATH_EVENT_MAX_CALLBACKS = 50
    private constant integer UNIT_DEATH_EVENT_MAX_PLAYER_INDEX = 27

    private trigger UnitDeathEvent_DeathTrigger = null
    private integer UnitDeathEvent_CallbackCount = 0
    private unit UnitDeathEvent_CurrentDyingUnit = null
    private unit UnitDeathEvent_CurrentKillingUnit = null
    real UnitDeathEvent_Event = 0.00
endglobals

private function UnitDeathEvent_DispatchUnits takes unit dyingUnit, unit killingUnit returns nothing
    local unit previousDyingUnit = UnitDeathEvent_CurrentDyingUnit
    local unit previousKillingUnit = UnitDeathEvent_CurrentKillingUnit

    set UnitDeathEvent_CurrentDyingUnit = dyingUnit
    set UnitDeathEvent_CurrentKillingUnit = killingUnit

    // Reset first so nested deaths can cross the equality threshold again.
    set UnitDeathEvent_Event = 0.00
    set UnitDeathEvent_Event = 1.00
    set UnitDeathEvent_Event = 0.00

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
    loop
        call TriggerRegisterPlayerUnitEvent(UnitDeathEvent_DeathTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_DEATH, null)
        set playerIndex = playerIndex + 1
        exitwhen playerIndex > UNIT_DEATH_EVENT_MAX_PLAYER_INDEX
    endloop
    call TriggerAddAction(UnitDeathEvent_DeathTrigger, function UnitDeathEvent_Dispatch)
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
    call UnitDeathEvent_DispatchUnits(dyingUnit, killingUnit)
endfunction

function UnitDeathEvent_Register takes code callback returns nothing
    local trigger callbackTrigger

    call UnitDeathEvent_EnsureTrigger()
    if UnitDeathEvent_CallbackCount >= UNIT_DEATH_EVENT_MAX_CALLBACKS then
        call BJDebugMsg("[UnitDeathEvent] ERROR: Maximum callbacks reached (" + I2S(UNIT_DEATH_EVENT_MAX_CALLBACKS) + ").")
        return
    endif

    set callbackTrigger = CreateTrigger()
    call TriggerRegisterVariableEvent(callbackTrigger, "UnitDeathEvent_Event", EQUAL, 1.00)
    call TriggerAddAction(callbackTrigger, callback)
    set UnitDeathEvent_CallbackCount = UnitDeathEvent_CallbackCount + 1
    set callbackTrigger = null
endfunction

private function Init takes nothing returns nothing
    call UnitDeathEvent_EnsureTrigger()
endfunction

endlibrary
