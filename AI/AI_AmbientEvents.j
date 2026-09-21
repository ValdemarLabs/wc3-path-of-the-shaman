/**
    AI_AmbientEvents

    Author: Valdemar
    Version: 1.0.0

    Description:
    Shared coarse scheduler for lightweight ambient AI events. Each controller
    registers one attempt callback and its retry/cooldown windows. The scheduler
    checks one controller per tick, caps simultaneous events, and performs no
    unit or world enumeration itself. Controllers own their small active state
    and report start/finish transitions through this library.

    Credits:
    - PotS AI JASS migration

    How to install:
    Import after the Warcraft III timer natives and before ambient event
    controllers such as `AI_AmbientWolfHunt.j`. Add future controllers by
    registering one bounded attempt callback; do not create another permanent
    high-frequency world timer.

    API:
    call AIAmbientEvents_Register(name, retryMin, retryMax, cooldownMin, cooldownMax, callback) returns integer
    call AIAmbientEvents_MarkStarted(eventId) returns boolean
    call AIAmbientEvents_Finish(eventId)
    call AIAmbientEvents_AttemptEvent(eventId) returns boolean
    call AIAmbientEvents_SetEnabled(eventId, enabled)
    call AIAmbientEvents_IsActive(eventId) returns boolean
    call AIAmbientEvents_GetCurrentEventId() returns integer

**/
library AIAmbientEvents initializer Init

globals
    private constant integer MAX_AMBIENT_EVENTS = 32
    private constant integer MAX_ACTIVE_EVENTS = 2
    private constant real SCHEDULER_INTERVAL = 15.00
    private constant real MIN_SCHEDULE_DELAY = 15.00

    private integer EventCount = 0
    private integer EventCursor = 1
    private integer ActiveEventCount = 0
    private integer CurrentEventId = 0
    private boolean CurrentAttemptStarted = false
    private boolean CurrentAttemptFinished = false
    private real SchedulerElapsed = 0.00

    private string array EventName
    private trigger array EventAttemptTrigger
    private real array EventRetryMin
    private real array EventRetryMax
    private real array EventCooldownMin
    private real array EventCooldownMax
    private real array EventNextAttempt
    private boolean array EventEnabled
    private boolean array EventActive

    private timer SchedulerTimer = null
endglobals

private function GetNow takes nothing returns real
    return SchedulerElapsed
endfunction

private function NormalizeMinDelay takes real delay returns real
    if delay < MIN_SCHEDULE_DELAY then
        return MIN_SCHEDULE_DELAY
    endif
    return delay
endfunction

private function NormalizeMaxDelay takes real minimum, real maximum returns real
    if maximum < minimum then
        return minimum
    endif
    return maximum
endfunction

private function ScheduleRetry takes integer eventId returns nothing
    set EventNextAttempt[eventId] = GetNow() + GetRandomReal(EventRetryMin[eventId], EventRetryMax[eventId])
endfunction

private function ScheduleCooldown takes integer eventId returns nothing
    set EventNextAttempt[eventId] = GetNow() + GetRandomReal(EventCooldownMin[eventId], EventCooldownMax[eventId])
endfunction

public function Register takes string name, real retryMin, real retryMax, real cooldownMin, real cooldownMax, code callback returns integer
    local integer eventId
    local trigger attemptTrigger
    if EventCount >= MAX_AMBIENT_EVENTS then
        call BJDebugMsg("[AIAmbientEvents] ERROR: Maximum ambient event count reached.")
        return 0
    endif
    set retryMin = NormalizeMinDelay(retryMin)
    set retryMax = NormalizeMaxDelay(retryMin, retryMax)
    set cooldownMin = NormalizeMinDelay(cooldownMin)
    set cooldownMax = NormalizeMaxDelay(cooldownMin, cooldownMax)
    set attemptTrigger = CreateTrigger()
    if attemptTrigger == null then
        call BJDebugMsg("[AIAmbientEvents] ERROR: Could not create attempt trigger for " + name + ".")
        return 0
    endif
    call TriggerAddAction(attemptTrigger, callback)
    set EventCount = EventCount + 1
    set eventId = EventCount
    set EventName[eventId] = name
    set EventAttemptTrigger[eventId] = attemptTrigger
    set EventRetryMin[eventId] = retryMin
    set EventRetryMax[eventId] = retryMax
    set EventCooldownMin[eventId] = cooldownMin
    set EventCooldownMax[eventId] = cooldownMax
    set EventEnabled[eventId] = true
    set EventActive[eventId] = false
    call ScheduleRetry(eventId)
    set attemptTrigger = null
    return eventId
endfunction

public function MarkStarted takes integer eventId returns boolean
    if eventId <= 0 or eventId != CurrentEventId or EventActive[eventId] or ActiveEventCount >= MAX_ACTIVE_EVENTS then
        return false
    endif
    set EventActive[eventId] = true
    set ActiveEventCount = ActiveEventCount + 1
    set CurrentAttemptStarted = true
    return true
endfunction

public function Finish takes integer eventId returns nothing
    if eventId <= 0 or eventId > EventCount or not EventActive[eventId] then
        return
    endif
    set EventActive[eventId] = false
    if ActiveEventCount > 0 then
        set ActiveEventCount = ActiveEventCount - 1
    endif
    if eventId == CurrentEventId then
        set CurrentAttemptFinished = true
    endif
    call ScheduleCooldown(eventId)
endfunction

private function RunAttempt takes integer eventId returns boolean
    local boolean started
    if CurrentEventId != 0 or eventId <= 0 or eventId > EventCount or not EventEnabled[eventId] or EventActive[eventId] or ActiveEventCount >= MAX_ACTIVE_EVENTS or EventAttemptTrigger[eventId] == null then
        return false
    endif
    set CurrentEventId = eventId
    set CurrentAttemptStarted = false
    set CurrentAttemptFinished = false
    call TriggerExecute(EventAttemptTrigger[eventId])
    set started = CurrentAttemptStarted
    set CurrentEventId = 0
    set CurrentAttemptStarted = false
    if not started and not CurrentAttemptFinished and not EventActive[eventId] then
        call ScheduleRetry(eventId)
    endif
    set CurrentAttemptFinished = false
    return started
endfunction

public function AttemptEvent takes integer eventId returns boolean
    return RunAttempt(eventId)
endfunction

public function SetEnabled takes integer eventId, boolean enabled returns nothing
    if eventId <= 0 or eventId > EventCount then
        return
    endif
    if EventEnabled[eventId] == enabled then
        return
    endif
    set EventEnabled[eventId] = enabled
    if enabled and not EventActive[eventId] then
        call ScheduleRetry(eventId)
    endif
endfunction

public function IsActive takes integer eventId returns boolean
    return eventId > 0 and eventId <= EventCount and EventActive[eventId]
endfunction

public function GetCurrentEventId takes nothing returns integer
    return CurrentEventId
endfunction

private function OnSchedulerTick takes nothing returns nothing
    local integer eventId
    set SchedulerElapsed = SchedulerElapsed + SCHEDULER_INTERVAL
    if EventCount <= 0 then
        return
    endif
    if EventCursor > EventCount then
        set EventCursor = 1
    endif
    set eventId = EventCursor
    set EventCursor = EventCursor + 1
    if EventEnabled[eventId] and not EventActive[eventId] and GetNow() >= EventNextAttempt[eventId] then
        call RunAttempt(eventId)
    endif
endfunction

private function Init takes nothing returns nothing
    set SchedulerTimer = CreateTimer()
    call TimerStart(SchedulerTimer, SCHEDULER_INTERVAL, true, function OnSchedulerTick)
endfunction

endlibrary
