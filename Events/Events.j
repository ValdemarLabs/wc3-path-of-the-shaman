/**
    Events

    Author: Valdemar
    Version:

    Description:
    Centralized non-death event dispatcher for common map-wide unit events.
    Registers each shared event once. Code callbacks are attached directly to
    the central event trigger so normal event responses remain valid, while
    trigger callbacks are dispatched through the trigger-callback API.

    Credits:
    - UnitDeathEvent central dispatcher pattern

    How to install:
    Import this library before systems that call the Events API. Unit death is
    intentionally handled by `UnitDeathEvent` and must not be registered here.

    API:
    call Events_RegisterUnitEnter(function YourCallback)
    call Events_RegisterUnitEnterTrigger(yourTrigger)
    call Events_RegisterPlayerUnitEvent(function YourCallback, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call Events_RegisterPlayerUnitTrigger(yourTrigger, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call Events_SetDebugEnabled(true)
    call Events_GetTriggerUnit()
    call Events_GetCurrentEventId()
    call Events_GetCurrentPlayerUnitEvent()

    Prefer code callbacks for event-response-heavy logic. Code callbacks run
    directly on the central event trigger and should use normal native event
    responses like GetTriggerUnit(), GetSpellAbilityId(), and GetManipulatedItem().
    Trigger callbacks are compatibility helpers; use Events_GetTriggerUnit()
    instead of native event responses inside those callback triggers.

**/
library Events initializer Init

globals
    private constant integer EVENTS_MAX_PLAYER_INDEX = 27
    private constant integer EVENTS_MAX_UNIT_ENTER_CALLBACKS = 100
    private constant integer EVENTS_MAX_PLAYER_UNIT_EVENT_TYPES = 50
    private constant integer EVENTS_MAX_CALLBACKS_PER_PLAYER_UNIT_EVENT = 100

    private trigger Events_UnitEnterTrigger = null
    private trigger array Events_UnitEnterCallbacks
    private integer Events_UnitEnterCallbackCount = 0

    private trigger array Events_PlayerUnitEventTriggers
    private trigger array Events_PlayerUnitEventCallbacks
    private playerunitevent array Events_PlayerUnitEventTypes
    private integer array Events_PlayerUnitEventCallbackCounts
    private integer Events_PlayerUnitEventTypeCount = 0

    private boolean Events_DebugEnabled = false
    private unit Events_CurrentTriggerUnit = null
    private eventid Events_CurrentEventId = null
    private playerunitevent Events_CurrentPlayerUnitEvent = null
endglobals

private function Events_DebugMsg takes string message returns nothing
    if Events_DebugEnabled then
        call BJDebugMsg("[Events] " + message)
    endif
endfunction

private function Events_Error takes string message returns nothing
    call BJDebugMsg("[Events] ERROR: " + message)
endfunction

private function Events_RunCallback takes trigger callbackTrigger returns nothing
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

private function Events_RegisterPlayerUnitEventAllPlayers takes trigger whichTrigger, playerunitevent whichEvent returns nothing
    local integer playerIndex = 0

    loop
        call TriggerRegisterPlayerUnitEvent(whichTrigger, Player(playerIndex), whichEvent, null)
        set playerIndex = playerIndex + 1
        exitwhen playerIndex > EVENTS_MAX_PLAYER_INDEX
    endloop
endfunction

private function Events_GetPlayerUnitEventSlot takes playerunitevent whichEvent returns integer
    local integer eventSlot = 0

    loop
        exitwhen eventSlot >= Events_PlayerUnitEventTypeCount
        if Events_PlayerUnitEventTypes[eventSlot] == whichEvent then
            return eventSlot
        endif
        set eventSlot = eventSlot + 1
    endloop

    return -1
endfunction

private function Events_GetPlayerUnitEventSlotByTrigger takes trigger sourceTrigger returns integer
    local integer eventSlot = 0

    loop
        exitwhen eventSlot >= Events_PlayerUnitEventTypeCount
        if Events_PlayerUnitEventTriggers[eventSlot] == sourceTrigger then
            return eventSlot
        endif
        set eventSlot = eventSlot + 1
    endloop

    return -1
endfunction

private function Events_DispatchUnitEnter takes nothing returns nothing
    local integer callbackIndex = 0
    local integer callbackCount = Events_UnitEnterCallbackCount
    local unit previousTriggerUnit = Events_CurrentTriggerUnit
    local eventid previousEventId = Events_CurrentEventId
    local playerunitevent previousPlayerUnitEvent = Events_CurrentPlayerUnitEvent

    set Events_CurrentTriggerUnit = GetTriggerUnit()
    set Events_CurrentEventId = GetTriggerEventId()
    set Events_CurrentPlayerUnitEvent = null

    loop
        exitwhen callbackIndex >= callbackCount
        call Events_RunCallback(Events_UnitEnterCallbacks[callbackIndex])
        set callbackIndex = callbackIndex + 1
    endloop

    set Events_CurrentTriggerUnit = previousTriggerUnit
    set Events_CurrentEventId = previousEventId
    set Events_CurrentPlayerUnitEvent = previousPlayerUnitEvent

    set previousTriggerUnit = null
    set previousEventId = null
    set previousPlayerUnitEvent = null
endfunction

private function Events_DispatchPlayerUnitEvent takes nothing returns nothing
    local trigger sourceTrigger = GetTriggeringTrigger()
    local integer eventSlot = Events_GetPlayerUnitEventSlotByTrigger(sourceTrigger)
    local integer callbackIndex = 0
    local integer callbackCount
    local integer baseIndex
    local unit previousTriggerUnit = Events_CurrentTriggerUnit
    local eventid previousEventId = Events_CurrentEventId
    local playerunitevent previousPlayerUnitEvent = Events_CurrentPlayerUnitEvent

    if eventSlot < 0 then
        call Events_Error("Dispatch called from an unknown player-unit event trigger.")
        set sourceTrigger = null
        set previousTriggerUnit = null
        set previousEventId = null
        set previousPlayerUnitEvent = null
        return
    endif

    set callbackCount = Events_PlayerUnitEventCallbackCounts[eventSlot]
    set baseIndex = eventSlot * EVENTS_MAX_CALLBACKS_PER_PLAYER_UNIT_EVENT
    set Events_CurrentTriggerUnit = GetTriggerUnit()
    set Events_CurrentEventId = GetTriggerEventId()
    set Events_CurrentPlayerUnitEvent = Events_PlayerUnitEventTypes[eventSlot]

    loop
        exitwhen callbackIndex >= callbackCount
        call Events_RunCallback(Events_PlayerUnitEventCallbacks[baseIndex + callbackIndex])
        set callbackIndex = callbackIndex + 1
    endloop

    set Events_CurrentTriggerUnit = previousTriggerUnit
    set Events_CurrentEventId = previousEventId
    set Events_CurrentPlayerUnitEvent = previousPlayerUnitEvent

    set sourceTrigger = null
    set previousTriggerUnit = null
    set previousEventId = null
    set previousPlayerUnitEvent = null
endfunction

private function Events_CreatePlayerUnitEventSlot takes playerunitevent whichEvent returns integer
    local integer eventSlot
    local trigger eventTrigger

    if whichEvent == null then
        call Events_Error("Cannot register a null player-unit event.")
        return -1
    endif

    if whichEvent == EVENT_PLAYER_UNIT_DEATH then
        call Events_Error("Use UnitDeathEvent_Register for EVENT_PLAYER_UNIT_DEATH.")
        return -1
    endif

    if Events_PlayerUnitEventTypeCount >= EVENTS_MAX_PLAYER_UNIT_EVENT_TYPES then
        call Events_Error("Maximum player-unit event types reached (" + I2S(EVENTS_MAX_PLAYER_UNIT_EVENT_TYPES) + ").")
        return -1
    endif

    set eventSlot = Events_PlayerUnitEventTypeCount
    set eventTrigger = CreateTrigger()
    set Events_PlayerUnitEventTriggers[eventSlot] = eventTrigger
    set Events_PlayerUnitEventTypes[eventSlot] = whichEvent
    set Events_PlayerUnitEventCallbackCounts[eventSlot] = 0
    set Events_PlayerUnitEventTypeCount = Events_PlayerUnitEventTypeCount + 1

    call Events_RegisterPlayerUnitEventAllPlayers(eventTrigger, whichEvent)
    call TriggerAddAction(eventTrigger, function Events_DispatchPlayerUnitEvent)
    call Events_DebugMsg("Registered central player-unit event slot " + I2S(eventSlot) + ".")

    set eventTrigger = null
    return eventSlot
endfunction

function Events_SetDebugEnabled takes boolean enabled returns nothing
    set Events_DebugEnabled = enabled
endfunction

function Events_GetTriggerUnit takes nothing returns unit
    return Events_CurrentTriggerUnit
endfunction

function Events_GetCurrentEventId takes nothing returns eventid
    return Events_CurrentEventId
endfunction

function Events_GetCurrentPlayerUnitEvent takes nothing returns playerunitevent
    return Events_CurrentPlayerUnitEvent
endfunction

function Events_RegisterUnitEnterTrigger takes trigger callbackTrigger returns nothing
    if callbackTrigger == null then
        call Events_Error("Cannot register a null unit-enter callback trigger.")
        return
    endif

    if Events_UnitEnterCallbackCount >= EVENTS_MAX_UNIT_ENTER_CALLBACKS then
        call Events_Error("Maximum unit-enter callbacks reached (" + I2S(EVENTS_MAX_UNIT_ENTER_CALLBACKS) + ").")
        return
    endif

    set Events_UnitEnterCallbacks[Events_UnitEnterCallbackCount] = callbackTrigger
    set Events_UnitEnterCallbackCount = Events_UnitEnterCallbackCount + 1
    call Events_DebugMsg("Registered unit-enter callback #" + I2S(Events_UnitEnterCallbackCount) + ".")
endfunction

function Events_RegisterUnitEnter takes code callback returns nothing
    if Events_UnitEnterTrigger == null then
        call Events_Error("Unit-enter event trigger is not initialized.")
        return
    endif

    call TriggerAddAction(Events_UnitEnterTrigger, callback)
    call Events_DebugMsg("Registered direct unit-enter code callback.")
endfunction

function Events_RegisterPlayerUnitTrigger takes trigger callbackTrigger, playerunitevent whichEvent returns nothing
    local integer eventSlot = Events_GetPlayerUnitEventSlot(whichEvent)
    local integer callbackCount
    local integer callbackIndex

    if callbackTrigger == null then
        call Events_Error("Cannot register a null player-unit callback trigger.")
        return
    endif

    if eventSlot < 0 then
        set eventSlot = Events_CreatePlayerUnitEventSlot(whichEvent)
        if eventSlot < 0 then
            return
        endif
    endif

    set callbackCount = Events_PlayerUnitEventCallbackCounts[eventSlot]
    if callbackCount >= EVENTS_MAX_CALLBACKS_PER_PLAYER_UNIT_EVENT then
        call Events_Error("Maximum callbacks reached for player-unit event slot " + I2S(eventSlot) + ".")
        return
    endif

    set callbackIndex = eventSlot * EVENTS_MAX_CALLBACKS_PER_PLAYER_UNIT_EVENT + callbackCount
    set Events_PlayerUnitEventCallbacks[callbackIndex] = callbackTrigger
    set Events_PlayerUnitEventCallbackCounts[eventSlot] = callbackCount + 1
    call Events_DebugMsg("Registered player-unit callback #" + I2S(callbackCount + 1) + " for event slot " + I2S(eventSlot) + ".")
endfunction

function Events_RegisterPlayerUnitEvent takes code callback, playerunitevent whichEvent returns nothing
    local integer eventSlot = Events_GetPlayerUnitEventSlot(whichEvent)

    if eventSlot < 0 then
        set eventSlot = Events_CreatePlayerUnitEventSlot(whichEvent)
        if eventSlot < 0 then
            return
        endif
    endif

    call TriggerAddAction(Events_PlayerUnitEventTriggers[eventSlot], callback)
    call Events_DebugMsg("Registered direct player-unit code callback for event slot " + I2S(eventSlot) + ".")
endfunction

private function Init takes nothing returns nothing
    set Events_UnitEnterTrigger = CreateTrigger()
    call TriggerRegisterEnterRectSimple(Events_UnitEnterTrigger, GetWorldBounds())
    call TriggerAddAction(Events_UnitEnterTrigger, function Events_DispatchUnitEnter)
    call Events_DebugMsg("Central world-enter event initialized.")
endfunction

endlibrary
