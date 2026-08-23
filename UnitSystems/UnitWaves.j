/**
    UnitWaves

    Author: Valdemar
    Version:

    Description:
    Runs reusable, staged unit-wave events. Each stage may contain any number
    of unit-type spawn entries, waits for its living units to be cleared, and
    then advances after a configurable delay.

    Credits:
    Built on the PotS UnitSpawn Wave tracker.

    How to install:
    Import after UnitSpawn and Table. Configure an UnitWaveEvent, add stages
    and spawn entries, set callbacks as needed, then call start().

    API:
    - UnitWaveEvent.create(owner, targetX, targetY)
    - event.addStage(minDelay, maxDelay)
    - stage.addSpawnRect(unitTypeId, count, spawnRect)
    - stage.addSpawnPoint(unitTypeId, count, x, y, radius)
    - event.setCallbacks(onStart, onCleared, onComplete, onCancel)
    - event.setTiming(pollPeriod, orderPeriod)
    - event.start(), event.cancel(removeUnits), event.reset(removeUnits)
    - UnitWaves_GetTriggeringEvent/Stage/WaveIndex()

**/
library UnitWaves initializer Init requires UnitSpawn, Table

globals
    private Table UnitWavesTimerData = 0
    private integer UnitWavesTriggeringEvent = 0
    private integer UnitWavesTriggeringStage = 0
endglobals

private function CreateCallbackTrigger takes code callback returns trigger
    local trigger t = null
    if callback != null then
        set t = CreateTrigger()
        call TriggerAddAction(t, callback)
    endif
    return t
endfunction

struct UnitWaveSpawn
    integer unitTypeId
    integer count
    rect spawnRect
    real x
    real y
    real radius
    boolean useRect
    UnitWaveSpawn next

    static method createRect takes integer unitTypeId, integer count, rect spawnRect returns UnitWaveSpawn
        local thistype this = thistype.allocate()
        set this.unitTypeId = unitTypeId
        set this.count = count
        set this.spawnRect = spawnRect
        set this.x = 0.00
        set this.y = 0.00
        set this.radius = 0.00
        set this.useRect = true
        set this.next = 0
        return this
    endmethod

    static method createPoint takes integer unitTypeId, integer count, real x, real y, real radius returns UnitWaveSpawn
        local thistype this = thistype.allocate()
        set this.unitTypeId = unitTypeId
        set this.count = count
        set this.spawnRect = null
        set this.x = x
        set this.y = y
        set this.radius = radius
        set this.useRect = false
        set this.next = 0
        return this
    endmethod

    method spawn takes Wave wave, player owner returns nothing
        local integer i = 0
        local real angle
        local real distance
        local real spawnX
        local real spawnY
        local unit spawned

        if wave == 0 or owner == null or this.unitTypeId == 0 or this.count <= 0 then
            return
        endif

        loop
            exitwhen i >= this.count
            if this.useRect and this.spawnRect != null then
                set spawnX = GetRandomReal(GetRectMinX(this.spawnRect), GetRectMaxX(this.spawnRect))
                set spawnY = GetRandomReal(GetRectMinY(this.spawnRect), GetRectMaxY(this.spawnRect))
            else
                set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
                set distance = GetRandomReal(0.00, this.radius)
                set spawnX = this.x + distance * Cos(angle)
                set spawnY = this.y + distance * Sin(angle)
            endif
            set spawned = CreateUnit(owner, this.unitTypeId, spawnX, spawnY, GetRandomReal(0.00, 360.00))
            if spawned != null then
                call wave.addUnit(spawned)
            endif
            set i = i + 1
        endloop

        set spawned = null
    endmethod

    method onDestroy takes nothing returns nothing
        set this.spawnRect = null
        set this.next = 0
    endmethod
endstruct

struct UnitWaveStage
    integer index
    real minDelay
    real maxDelay
    UnitWaveSpawn firstSpawn
    UnitWaveSpawn lastSpawn
    UnitWaveStage next

    static method create takes integer index, real minDelay, real maxDelay returns UnitWaveStage
        local thistype this = thistype.allocate()
        set this.index = index
        set this.minDelay = minDelay
        set this.maxDelay = maxDelay
        set this.firstSpawn = 0
        set this.lastSpawn = 0
        set this.next = 0
        return this
    endmethod

    method addSpawnRect takes integer unitTypeId, integer count, rect spawnRect returns UnitWaveSpawn
        local UnitWaveSpawn spawn = UnitWaveSpawn.createRect(unitTypeId, count, spawnRect)
        if this.firstSpawn == 0 then
            set this.firstSpawn = spawn
        else
            set this.lastSpawn.next = spawn
        endif
        set this.lastSpawn = spawn
        return spawn
    endmethod

    method addSpawnPoint takes integer unitTypeId, integer count, real x, real y, real radius returns UnitWaveSpawn
        local UnitWaveSpawn spawn = UnitWaveSpawn.createPoint(unitTypeId, count, x, y, radius)
        if this.firstSpawn == 0 then
            set this.firstSpawn = spawn
        else
            set this.lastSpawn.next = spawn
        endif
        set this.lastSpawn = spawn
        return spawn
    endmethod

    method spawn takes Wave wave, player owner returns nothing
        local UnitWaveSpawn spawn = this.firstSpawn
        loop
            exitwhen spawn == 0
            call spawn.spawn(wave, owner)
            set spawn = spawn.next
        endloop
    endmethod

    method onDestroy takes nothing returns nothing
        local UnitWaveSpawn spawn = this.firstSpawn
        local UnitWaveSpawn nextSpawn
        loop
            exitwhen spawn == 0
            set nextSpawn = spawn.next
            call spawn.destroy()
            set spawn = nextSpawn
        endloop
        set this.firstSpawn = 0
        set this.lastSpawn = 0
        set this.next = 0
    endmethod
endstruct

private function RunCallback takes integer waveEvent, UnitWaveStage stage, trigger callbackTrigger returns nothing
    if callbackTrigger == null then
        return
    endif
    set UnitWavesTriggeringEvent = waveEvent
    set UnitWavesTriggeringStage = stage
    call TriggerExecute(callbackTrigger)
    set UnitWavesTriggeringStage = 0
    set UnitWavesTriggeringEvent = 0
endfunction

struct UnitWaveEvent
    player owner
    real targetX
    real targetY
    real pollPeriod
    real orderPeriod
    real orderElapsed
    UnitWaveStage firstStage
    UnitWaveStage lastStage
    UnitWaveStage currentStage
    Wave currentWave
    integer stageCount
    timer stageTimer
    timer pollTimer
    trigger onWaveStart
    trigger onWaveCleared
    trigger onComplete
    trigger onCancel
    boolean running
    boolean completed

    static method create takes player owner, real targetX, real targetY returns UnitWaveEvent
        local thistype this = thistype.allocate()
        set this.owner = owner
        set this.targetX = targetX
        set this.targetY = targetY
        set this.pollPeriod = 1.00
        set this.orderPeriod = 10.00
        set this.orderElapsed = 0.00
        set this.firstStage = 0
        set this.lastStage = 0
        set this.currentStage = 0
        set this.currentWave = 0
        set this.stageCount = 0
        set this.stageTimer = CreateTimer()
        set this.pollTimer = CreateTimer()
        set UnitWavesTimerData[GetHandleId(this.stageTimer)] = this
        set UnitWavesTimerData[GetHandleId(this.pollTimer)] = this
        set this.onWaveStart = null
        set this.onWaveCleared = null
        set this.onComplete = null
        set this.onCancel = null
        set this.running = false
        set this.completed = false
        return this
    endmethod

    method addStage takes real minDelay, real maxDelay returns UnitWaveStage
        local UnitWaveStage stage
        if minDelay < 0.00 then
            set minDelay = 0.00
        endif
        if maxDelay < minDelay then
            set maxDelay = minDelay
        endif
        set this.stageCount = this.stageCount + 1
        set stage = UnitWaveStage.create(this.stageCount, minDelay, maxDelay)
        if this.firstStage == 0 then
            set this.firstStage = stage
        else
            set this.lastStage.next = stage
        endif
        set this.lastStage = stage
        return stage
    endmethod

    method setTarget takes real x, real y returns nothing
        set this.targetX = x
        set this.targetY = y
        if this.currentWave != 0 then
            call this.currentWave.attackMove(x, y)
        endif
    endmethod

    method setTiming takes real pollPeriod, real orderPeriod returns nothing
        if pollPeriod > 0.00 then
            set this.pollPeriod = pollPeriod
        endif
        if orderPeriod >= 0.00 then
            set this.orderPeriod = orderPeriod
        endif
    endmethod

    method setCallbacks takes code waveStart, code waveCleared, code eventComplete, code eventCancel returns nothing
        if this.onWaveStart != null then
            call DestroyTrigger(this.onWaveStart)
        endif
        if this.onWaveCleared != null then
            call DestroyTrigger(this.onWaveCleared)
        endif
        if this.onComplete != null then
            call DestroyTrigger(this.onComplete)
        endif
        if this.onCancel != null then
            call DestroyTrigger(this.onCancel)
        endif
        set this.onWaveStart = CreateCallbackTrigger(waveStart)
        set this.onWaveCleared = CreateCallbackTrigger(waveCleared)
        set this.onComplete = CreateCallbackTrigger(eventComplete)
        set this.onCancel = CreateCallbackTrigger(eventCancel)
    endmethod

    private method scheduleCurrentStage takes nothing returns nothing
        local real delay
        if not this.running or this.currentStage == 0 then
            return
        endif
        set delay = GetRandomReal(this.currentStage.minDelay, this.currentStage.maxDelay)
        call TimerStart(this.stageTimer, delay, false, function thistype.runStage)
    endmethod

    static method runStage takes nothing returns nothing
        local timer expired = GetExpiredTimer()
        local thistype this = UnitWavesTimerData[GetHandleId(expired)]
        if this == 0 or not this.running or this.currentStage == 0 then
            set expired = null
            return
        endif
        if this.currentWave != 0 then
            call this.currentWave.destroy()
        endif
        set this.currentWave = Wave.create()
        call this.currentStage.spawn(this.currentWave, this.owner)
        call this.currentWave.attackMove(this.targetX, this.targetY)
        set this.orderElapsed = 0.00
        call RunCallback(this, this.currentStage, this.onWaveStart)
        if this.running and this.currentWave != 0 then
            call TimerStart(this.pollTimer, this.pollPeriod, true, function thistype.poll)
        endif
        set expired = null
    endmethod

    static method poll takes nothing returns nothing
        local timer expired = GetExpiredTimer()
        local thistype this = UnitWavesTimerData[GetHandleId(expired)]
        local UnitWaveStage clearedStage
        if this == 0 or not this.running or this.currentWave == 0 then
            set expired = null
            return
        endif

        if this.currentWave.getRemainingCount() <= 0 then
            call PauseTimer(this.pollTimer)
            set clearedStage = this.currentStage
            call this.currentWave.destroy()
            set this.currentWave = 0
            call RunCallback(this, clearedStage, this.onWaveCleared)
            if this.running then
                set this.currentStage = clearedStage.next
                if this.currentStage == 0 then
                    set this.running = false
                    set this.completed = true
                    call RunCallback(this, clearedStage, this.onComplete)
                else
                    call this.scheduleCurrentStage()
                endif
            endif
        elseif this.orderPeriod > 0.00 then
            set this.orderElapsed = this.orderElapsed + this.pollPeriod
            if this.orderElapsed >= this.orderPeriod then
                set this.orderElapsed = 0.00
                call this.currentWave.attackMove(this.targetX, this.targetY)
            endif
        endif
        set expired = null
    endmethod

    method start takes nothing returns boolean
        if this.running or this.firstStage == 0 or this.owner == null then
            return false
        endif
        set this.completed = false
        set this.running = true
        set this.currentStage = this.firstStage
        call this.scheduleCurrentStage()
        return true
    endmethod

    method cancel takes boolean removeUnits returns nothing
        local unit detachedUnit
        local UnitWaveStage cancelledStage
        if not this.running and this.currentWave == 0 then
            return
        endif
        set cancelledStage = this.currentStage
        call PauseTimer(this.stageTimer)
        call PauseTimer(this.pollTimer)
        if this.currentWave != 0 then
            if removeUnits then
                call this.currentWave.removeAllUnits()
            else
                loop
                    set detachedUnit = FirstOfGroup(this.currentWave.units)
                    exitwhen detachedUnit == null
                    call GroupRemoveUnit(this.currentWave.units, detachedUnit)
                endloop
                set this.currentWave.unitCount = 0
            endif
            call this.currentWave.destroy()
            set this.currentWave = 0
        endif
        set this.running = false
        set this.completed = false
        set this.currentStage = 0
        call RunCallback(this, cancelledStage, this.onCancel)
        set detachedUnit = null
        set cancelledStage = 0
    endmethod

    method reset takes boolean removeUnits returns nothing
        if this.running or this.currentWave != 0 then
            call this.cancel(removeUnits)
        endif
        set this.currentStage = 0
        set this.completed = false
        set this.orderElapsed = 0.00
    endmethod

    method onDestroy takes nothing returns nothing
        local UnitWaveStage stage = this.firstStage
        local UnitWaveStage nextStage
        call this.reset(true)
        call UnitWavesTimerData.remove(GetHandleId(this.stageTimer))
        call UnitWavesTimerData.remove(GetHandleId(this.pollTimer))
        call DestroyTimer(this.stageTimer)
        call DestroyTimer(this.pollTimer)
        if this.onWaveStart != null then
            call DestroyTrigger(this.onWaveStart)
        endif
        if this.onWaveCleared != null then
            call DestroyTrigger(this.onWaveCleared)
        endif
        if this.onComplete != null then
            call DestroyTrigger(this.onComplete)
        endif
        if this.onCancel != null then
            call DestroyTrigger(this.onCancel)
        endif
        loop
            exitwhen stage == 0
            set nextStage = stage.next
            call stage.destroy()
            set stage = nextStage
        endloop
        set this.owner = null
        set this.stageTimer = null
        set this.pollTimer = null
        set this.onWaveStart = null
        set this.onWaveCleared = null
        set this.onComplete = null
        set this.onCancel = null
        set this.firstStage = 0
        set this.lastStage = 0
        set this.currentStage = 0
    endmethod
endstruct

function UnitWaves_GetTriggeringEvent takes nothing returns UnitWaveEvent
    return UnitWavesTriggeringEvent
endfunction

function UnitWaves_GetTriggeringStage takes nothing returns UnitWaveStage
    return UnitWavesTriggeringStage
endfunction

function UnitWaves_GetTriggeringWaveIndex takes nothing returns integer
    local UnitWaveStage stage = UnitWavesTriggeringStage
    if stage == 0 then
        return 0
    endif
    return stage.index
endfunction

private function Init takes nothing returns nothing
    set UnitWavesTimerData = Table.create()
endfunction

endlibrary
