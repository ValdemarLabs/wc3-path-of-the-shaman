/**
    CreepRespawn

    Author: Valdemar
    Version: 2.3

    Description:
    Tracks configured-owner units and recreates them from immutable spawn
    records after a random delay. Recreated quest NPCs are passed to
    CreepUnitAssignmentSystem to refresh their map references. Summoned,
    timed-life, BloodSplat, and explicitly discarded units are not tracked.

    Credits:
    - Original PotS GUI creep respawn triggers

    How to install:
    Import after Table, Events, UnitDeathEvent, and
    CreepUnitAssignmentSystem. Disable the migrated GUI respawn triggers.

    API:
    call CreepRespawn_OnUnitEnter(whichUnit)
    call CreepRespawn_DiscardUnit(whichUnit)
    call CreepRespawn_SetDebugEnabled(true)

    Supported Players (JASS / Visual):
    - Player(2) = Player 3 (Teal)
    - Player(3) = Player 4 (Purple)
    - Player(5) = Player 6 (Orange)
    - Player(9) = Player 10 (Light Blue)
    - Player(10) = Player 11 (Dark Green)
    - Player(12) = Player 13 (Maroon) - Satyr Faction
    - Player(14) = Player 15 (Turquoise)
    - Player(15) = Player 16 (Violet)
    - Player(20) = Player 21 (Coal)
    - Player(22) = Player 23 (Emerald) -> Neutral Passive
    - Player(PLAYER_NEUTRAL_AGGRESSIVE) = Neutral Hostile
    - Player(PLAYER_NEUTRAL_PASSIVE) = Neutral Passive
**/
library CreepRespawn initializer Init requires Table, Events, UnitDeathEvent, CreepUnitAssignmentSystem

globals
    private Table rhash
    private Table respawnData
    private Table ignoredUnits
    private Table summonedUnits
    private group RespawnGroup
    private boolean initialPositionsSaved = false
    private boolean tableStateReady = false
    private integer tableInitStage = 0
    
    // Debug mode - set to true to enable debug messages
    private boolean DEBUG_MODE = false
    
    // Respawn min/max times
    private constant real MIN_RESPAWN_TIME = 120.0
    private constant real MAX_RESPAWN_TIME = 320.0
    private constant integer SPAWN_DATA_STRIDE = 5
    
    //===========================================================================
    // EXCLUSION LIST - Unit-types that will NOT respawn
    //===========================================================================
    private constant integer EXCLUDED_COUNT = 13
endglobals

//===========================================================================
// EXCLUSION LIST
//===========================================================================
// Keep this as pure constant logic. Do not initialize static configuration from
// the early Table struct initializer; that initializer is reserved solely for
// Table.create(), matching the working Reputation.j pattern.
//===========================================================================

//===========================================================================
// UTILITY FUNCTIONS
//===========================================================================

// Table v6 state is initialized exactly like Reputation.j: the struct onInit
// performs Table.create() directly and does no unrelated configuration work.
// This keeps the early initializer minimal and makes the stage marker identify
// the exact Table.create() call if Warcraft III terminates the initializer thread.
private struct CreepRespawnTableState extends array
    static method onInit takes nothing returns nothing
        set tableInitStage = 20
        set rhash = Table.create()
        set tableInitStage = 21

        set tableInitStage = 30
        set respawnData = Table.create()
        set tableInitStage = 31

        set tableInitStage = 40
        set ignoredUnits = Table.create()
        set tableInitStage = 41

        set tableInitStage = 50
        set summonedUnits = Table.create()
        set tableInitStage = 51

        set tableStateReady = rhash != 0 and respawnData != 0 and ignoredUnits != 0 and summonedUnits != 0
        if tableStateReady then
            set tableInitStage = 100
        endif
    endmethod
endstruct

// Runtime repair path used only after game time has started. This is deliberately
// separate from the struct initializer so we never manually invoke onInit or
// recreate Tables that were already allocated successfully.
private function EnsureTableStateRuntime takes nothing returns boolean
    if tableStateReady and rhash != 0 and respawnData != 0 and ignoredUnits != 0 and summonedUnits != 0 then
        return true
    endif

    if rhash == 0 then
        set tableInitStage = 20
        set rhash = Table.create()
        set tableInitStage = 21
    endif

    if respawnData == 0 then
        set tableInitStage = 30
        set respawnData = Table.create()
        set tableInitStage = 31
    endif

    if ignoredUnits == 0 then
        set tableInitStage = 40
        set ignoredUnits = Table.create()
        set tableInitStage = 41
    endif

    if summonedUnits == 0 then
        set tableInitStage = 50
        set summonedUnits = Table.create()
        set tableInitStage = 51
    endif

    set tableStateReady = rhash != 0 and respawnData != 0 and ignoredUnits != 0 and summonedUnits != 0
    if tableStateReady then
        set tableInitStage = 100
    endif

    return tableStateReady
endfunction

private function EnsureRespawnGroup takes nothing returns nothing
    if RespawnGroup == null then
        set RespawnGroup = CreateGroup()
    endif
endfunction

private function IsTableStateReady takes nothing returns boolean
    return tableStateReady and rhash != 0 and respawnData != 0 and ignoredUnits != 0 and summonedUnits != 0
endfunction

private function IsExcludedUnitType takes integer unitTypeId returns boolean
    // AI HEROES / COMPANIONS
    if unitTypeId == 'H60Y' then
        return true
    elseif unitTypeId == '061H' then
        return true
    elseif unitTypeId == '0631' then
        return true
    elseif unitTypeId == '0629' then
        return true
    elseif unitTypeId == 'H60X' then
        return true
    elseif unitTypeId == 'N64O' then
        return true
    elseif unitTypeId == 'N661' then
        return true
    // GUI-created BloodSplat timed-life units.
    elseif unitTypeId == 'n00W' then
        return true
    elseif unitTypeId == 'n00X' then
        return true
    elseif unitTypeId == 'n00Y' then
        return true
    elseif unitTypeId == 'n00Z' then
        return true
    elseif unitTypeId == 'n010' then
        return true
    elseif unitTypeId == 'n011' then
        return true
    endif

    return false
endfunction

private function NormalizeRespawnOwner takes player owner returns player
    if owner == Player(22) then
        return Player(PLAYER_NEUTRAL_PASSIVE)
    endif
    return owner
endfunction

private function IsRespawnableOwner takes player p returns boolean
    return p == Player(2) or /*
        */ p == Player(3) or /*
        */ p == Player(5) or /*
        */ p == Player(9) or /*
        */ p == Player(10) or /*
        */ p == Player(12) or /*
        */ p == Player(14) or /*
        */ p == Player(15) or /*
        */ p == Player(20) or /*
        */ p == Player(PLAYER_NEUTRAL_AGGRESSIVE) or /*
        */ p == Player(PLAYER_NEUTRAL_PASSIVE)
endfunction

private function IsRespawnableUnit takes unit u returns boolean
    return u != null and IsRespawnableOwner(NormalizeRespawnOwner(GetOwningPlayer(u)))
endfunction

private function IsIgnoredUnit takes unit u returns boolean
    if u == null or ignoredUnits == 0 then
        return false
    endif
    return ignoredUnits[GetHandleId(u)] == GetUnitTypeId(u)
endfunction

private function IsTransientUnit takes unit u returns boolean
    if u == null then
        return true
    endif
    return IsExcludedUnitType(GetUnitTypeId(u)) or GetUnitAbilityLevel(u, 'BTLF') > 0
endfunction

private function SaveUnitSpawnData takes unit u, integer unitTypeId, player owner, real x, real y, real facing returns nothing
    local integer base

    if u == null then
        return
    endif

    set base = GetHandleId(u) * SPAWN_DATA_STRIDE
    set rhash.real[base + 0] = x
    set rhash.real[base + 1] = y
    set rhash.real[base + 2] = facing
    set rhash[base + 3] = GetPlayerId(owner)
    set rhash[base + 4] = unitTypeId
endfunction

private function SaveUnitPosition takes unit u returns nothing
    local integer id
    if u == null then
        return
    endif
    if IsIgnoredUnit(u) then
        return
    endif
    if IsTransientUnit(u) then
        return
    endif
    set id = GetHandleId(u)
    call SaveUnitSpawnData(u, GetUnitTypeId(u), NormalizeRespawnOwner(GetOwningPlayer(u)), GetUnitX(u), GetUnitY(u), GetUnitFacing(u))
    
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Saved position for " + GetUnitName(u) + " (ID: " + I2S(id) + ") at (" + R2S(GetUnitX(u)) + ", " + R2S(GetUnitY(u)) + ")")
    endif
endfunction

private function HasSavedUnitPosition takes unit u returns boolean
    local integer id

    if u == null or rhash == 0 then
        return false
    endif

    set id = GetHandleId(u)
    set id = id * SPAWN_DATA_STRIDE
    return rhash.real.has(id + 0) and rhash.real.has(id + 1) and rhash.real.has(id + 2) and rhash.has(id + 3) and rhash.has(id + 4)
endfunction

private function ClearSavedUnitPosition takes unit u returns nothing
    local integer id

    if u == null or rhash == 0 then
        return
    endif

    set id = GetHandleId(u) * SPAWN_DATA_STRIDE
    call rhash.real.remove(id + 0)
    call rhash.real.remove(id + 1)
    call rhash.real.remove(id + 2)
    call rhash.remove(id + 3)
    call rhash.remove(id + 4)
endfunction


//===========================================================================
// PUBLIC API
//===========================================================================

function CreepRespawn_SetDebugEnabled takes boolean enabled returns nothing
    set DEBUG_MODE = enabled
endfunction

// Call this function when a unit enters the map to track it for respawning.
// The normal map-wide enter hook is registered through Events in Init.
function CreepRespawn_OnUnitEnter takes unit u returns nothing
    if u == null then
        return
    endif
    if not IsTableStateReady() then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] OnUnitEnter skipped: Table state is not ready (stage " + I2S(tableInitStage) + ").")
        endif
        set u = null
        return
    endif
    if IsIgnoredUnit(u) then
        set u = null
        return
    endif
    if summonedUnits[GetHandleId(u)] == GetUnitTypeId(u) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] OnUnitEnter: Summoned instance ignored: " + GetUnitName(u))
        endif
        set u = null
        return
    endif
    if IsRespawnableUnit(u) and not IsTransientUnit(u) then
        call SaveUnitPosition(u)
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] OnUnitEnter: Tracking unit " + GetUnitName(u) + " for respawn")
        endif
    endif
    set u = null
endfunction

private function OnUnitEnterEvent takes nothing returns nothing
    call CreepRespawn_OnUnitEnter(GetTriggerUnit())
endfunction

// Track actual summoned instances instead of relying on UNIT_TYPE_SUMMONED.
// A preplaced unit may use a summoned-classified unit type and must still be
// allowed to respawn; only instances that actually fired the summon event are
// excluded.
private function OnUnitSummonEvent takes nothing returns nothing
    local unit summoned = Events_GetSummonedUnit()
    local integer id

    if summoned == null then
        return
    endif

    if not IsTableStateReady() then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Summon tracking skipped: Table state is not ready (stage " + I2S(tableInitStage) + ").")
        endif
        set summoned = null
        return
    endif

    set id = GetHandleId(summoned)
    set summonedUnits[id] = GetUnitTypeId(summoned)

    // The world-enter event can run before the summon event. Remove any spawn
    // position that may already have been captured for this summoned instance.
    call ClearSavedUnitPosition(summoned)

    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Summoned instance marked non-respawnable: " + GetUnitName(summoned) + " (ID: " + I2S(id) + ")")
    endif

    set summoned = null
endfunction

// Mark quest-managed units that must never be saved or scheduled for respawn.
function CreepRespawn_DiscardUnit takes unit u returns nothing
    local integer id
    if u == null then
        return
    endif
    if not IsTableStateReady() then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] DiscardUnit skipped: Table state is not ready (stage " + I2S(tableInitStage) + ").")
        endif
        set u = null
        return
    endif
    set id = GetHandleId(u)
    set ignoredUnits[id] = GetUnitTypeId(u)
    if RespawnGroup != null then
        call GroupRemoveUnit(RespawnGroup, u)
    endif
    call ClearSavedUnitPosition(u)
    set u = null
endfunction

//===========================================================================
// INITIALIZATION
//===========================================================================

private function InitializeRespawnGroup takes nothing returns nothing
    local group tempGroup

    
    // Player(2) = Player 3 (Teal)
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(2), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)
    
    // Player(3) = Player 4 (Purple)
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(3), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)
    
    // Player(5) = Player 6 (Orange)
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(5), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)
    
    // Player(9) = Player 10 (Light Blue)
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(9), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)
    
    // Player(10) = Player 11 (Dark Green)
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(10), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)
    
    // Player(12) = Player 13 (Maroon) - Satyr Faction
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(12), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)
    
    // Player(14) = Player 15 (Turquoise)
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(14), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)
    
    // Player(15) = Player 16 (Violet)
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(15), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)
    
    // Player(20) = Player 21 (Coal)
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(20), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)

    // Player(22) = Player 23 (Emerald) -> Neutral Passive
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(22), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)
    
    // Neutral Hostile
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(PLAYER_NEUTRAL_AGGRESSIVE), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)
    
    // Neutral Passive
    set tempGroup = CreateGroup()
    call GroupEnumUnitsOfPlayer(tempGroup, Player(PLAYER_NEUTRAL_PASSIVE), null)
    call BlzGroupAddGroupFast(tempGroup, RespawnGroup)
    call DestroyGroup(tempGroup)
    
    set tempGroup = null
endfunction

private function SaveAllUnitPositions takes nothing returns nothing
    local unit u

    
    loop
        set u = FirstOfGroup(RespawnGroup)
        exitwhen u == null
        call GroupRemoveUnit(RespawnGroup, u)
        call SaveUnitPosition(u)
    endloop
endfunction

//===========================================================================
// RESPAWN SYSTEM
//===========================================================================

private function ClearRespawnData takes integer timerId returns nothing
    local integer base = timerId * 5
    call respawnData.remove(base + 0)
    call respawnData.remove(base + 1)
    call respawnData.real.remove(base + 2)
    call respawnData.real.remove(base + 3)
    call respawnData.real.remove(base + 4)
endfunction

private function OnRespawnTimerExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer timerId
    local integer base
    local integer utype
    local player p
    local real x
    local real y
    local real facing
    local unit newUnit

    set timerId = GetHandleId(t)
    set base = timerId * 5
    set utype = respawnData[base + 0]
    set p = Player(respawnData[base + 1])
    set x = respawnData.real[base + 2]
    set y = respawnData.real[base + 3]
    set facing = respawnData.real[base + 4]

    if utype == 0 then
        call BJDebugMsg("[CreepRespawn] ERROR: Respawn timer has no saved unit type.")
        call ClearRespawnData(timerId)
        call DestroyTimer(t)
        set t = null
        set p = null
        return
    endif
    
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Timer expired for unit type " + I2S(utype) + " at (" + R2S(x) + ", " + R2S(y) + ")")
    endif
    
    // Create new unit
    set newUnit = CreateUnit(p, utype, x, y, facing)

    if newUnit == null then
        call BJDebugMsg("[CreepRespawn] ERROR: CreateUnit failed for unit type " + I2S(utype) + ".")
        call ClearRespawnData(timerId)
        call DestroyTimer(t)
        set t = null
        set p = null
        return
    endif
    
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Spawned new unit: " + GetUnitName(newUnit) + " (New ID: " + I2S(GetHandleId(newUnit)) + ")")
    endif
    
    // Restore the exact immutable record copied from the previous instance.
    // The world-enter event fires during CreateUnit and may have saved current
    // values already, so overwrite them explicitly with the timer payload.
    call SaveUnitSpawnData(newUnit, utype, p, x, y, facing)
    
    // Assign the unit to Unit variable (quest givers, etc. important units)
    set bj_lastCreatedUnit = newUnit
    call CreepUnitAssignment(utype)
    call ClearRespawnData(timerId)
    call DestroyTimer(t)
    
    set t = null
    set p = null
    set newUnit = null
endfunction

private function ScheduleRespawn takes unit dying returns nothing
    local integer handleId
    local integer timerId
    local integer base
    local integer utype
    local player p
    local real x
    local real y
    local real facing
    local real delay
    local timer t

    if dying == null then
        return
    endif
    set handleId = GetHandleId(dying) * SPAWN_DATA_STRIDE
    set utype = rhash[handleId + 4]
    set p = Player(rhash[handleId + 3])
    set x = rhash.real[handleId + 0]
    set y = rhash.real[handleId + 1]
    set facing = rhash.real[handleId + 2]
    set delay = GetRandomReal(MIN_RESPAWN_TIME, MAX_RESPAWN_TIME)
    set t = CreateTimer()
    if t == null then
        call BJDebugMsg("[CreepRespawn] ERROR: Unable to create a respawn timer for " + GetUnitName(dying) + ".")
        call ClearSavedUnitPosition(dying)
        set p = null
        return
    endif
    set timerId = GetHandleId(t)
    set base = timerId * 5

    set respawnData[base + 0] = utype
    set respawnData[base + 1] = GetPlayerId(p)
    set respawnData.real[base + 2] = x
    set respawnData.real[base + 3] = y
    set respawnData.real[base + 4] = facing

    // The timer owns a complete copy now. Remove the dead-unit record before
    // Warcraft can recycle its handle ID for a temporary unit.
    call ClearSavedUnitPosition(dying)
    
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Scheduling respawn: " + GetUnitName(dying) + " Type: " + I2S(utype) + " at (" + R2S(x) + ", " + R2S(y) + ") in " + R2S(delay) + " seconds")
    endif
    
    call TimerStart(t, delay, false, function OnRespawnTimerExpire)
    
    set p = null
    set t = null
endfunction

private function OnUnitDeath takes nothing returns nothing
    local unit dying
    local integer unitType
    local player owner
    local integer playerId
    local integer handleId
    local integer spawnBase
    local real savedX
    local real savedY

    set dying = UnitDeathEvent_GetDyingUnit()
    if dying == null then
        call BJDebugMsg("[CreepRespawn] ERROR: UnitDeathEvent returned a null dying unit.")
        return
    endif

    if not IsTableStateReady() then
        call BJDebugMsg("[CreepRespawn] ERROR: Death callback reached but Table v6 state is not ready (stage " + I2S(tableInitStage) + ").")
        set dying = null
        return
    endif

    set handleId = GetHandleId(dying)

    // Skip only real summoned instances. Do not use UNIT_TYPE_SUMMONED here;
    // that classification can also be present on preplaced custom units.
    if summonedUnits[handleId] == GetUnitTypeId(dying) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Actual summoned instance died - SKIPPED: " + GetUnitName(dying))
        endif
        call summonedUnits.remove(handleId)
        call ClearSavedUnitPosition(dying)
        set dying = null
        return
    endif

    if IsIgnoredUnit(dying) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Unit was explicitly discarded - SKIPPED")
        endif
        call ignoredUnits.remove(handleId)
        call ClearSavedUnitPosition(dying)
        set dying = null
        return
    endif

    // Only explicitly registered instances may respawn. In particular, never
    // manufacture a spawn record from the unit's death location.
    if not HasSavedUnitPosition(dying) then
        set dying = null
        return
    endif

    set spawnBase = handleId * SPAWN_DATA_STRIDE
    set unitType = GetUnitTypeId(dying)
    if rhash[spawnBase + 4] != unitType then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Recycled handle record rejected for " + GetUnitName(dying) + " (ID: " + I2S(handleId) + ")")
        endif
        call ClearSavedUnitPosition(dying)
        set dying = null
        return
    endif

    if IsTransientUnit(dying) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Transient or excluded unit died - SKIPPED: " + GetUnitName(dying))
        endif
        call ClearSavedUnitPosition(dying)
        set dying = null
        return
    endif

    set owner = Player(rhash[spawnBase + 3])
    if not IsRespawnableOwner(owner) then
        call ClearSavedUnitPosition(dying)
        set dying = null
        set owner = null
        return
    endif

    set playerId = GetPlayerId(owner)
    set savedX = rhash.real[spawnBase + 0]
    set savedY = rhash.real[spawnBase + 1]

    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Tracked unit died: " + GetUnitName(dying) + " | Type: " + I2S(unitType) + " | Respawn owner: Player " + I2S(playerId) + " | HandleID: " + I2S(handleId))
        call BJDebugMsg("[CreepRespawn] Original spawn position: (" + R2S(savedX) + ", " + R2S(savedY) + ")")
    endif

    call ScheduleRespawn(dying)

    set dying = null
    set owner = null
endfunction

//===========================================================================
// INITIALIZATION EVENT
//===========================================================================

private function InitActions takes nothing returns nothing
    local timer t = GetExpiredTimer()

    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] InitActions ENTER | Table stage=" + I2S(tableInitStage))
    endif

    // Repair any missing Table state at game time 0 if the earlier struct
    // initializer did not complete. Already-created Tables are preserved.
    if not IsTableStateReady() then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Retrying Table v6 state initialization at game time 0 (previous stage " + I2S(tableInitStage) + ").")
        endif
        call EnsureTableStateRuntime()
        if not IsTableStateReady() then
            call BJDebugMsg("[CreepRespawn] ERROR: Table v6 state initialization incomplete (stage " + I2S(tableInitStage) + ").")
            if t != null then
                call DestroyTimer(t)
            endif
            set t = null
            return
        endif
    endif

    call EnsureRespawnGroup()
    if RespawnGroup == null then
        call BJDebugMsg("[CreepRespawn] ERROR: Unable to create respawn enumeration group.")
        if t != null then
            call DestroyTimer(t)
        endif
        set t = null
        return
    endif

    if initialPositionsSaved then
        if t != null then
            call DestroyTimer(t)
        endif
        set t = null
        return
    endif

    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Initializing CreepRespawn system...")
        call BJDebugMsg("[CreepRespawn] Excluded " + I2S(EXCLUDED_COUNT) + " unit types from respawning")
    endif

    // Initialize respawn group
    call InitializeRespawnGroup()

    // Save all unit positions
    call SaveAllUnitPositions()
    set initialPositionsSaved = true

    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Initialization complete!")
    endif

    if t != null then
        call DestroyTimer(t)
    endif
    set t = null
endfunction

//===========================================================================
// MODULE INITIALIZATION
//===========================================================================

private function Init takes nothing returns nothing
    local timer initTimer = null

    // CRITICAL: register every event callback before doing any CreepRespawn
    // runtime-state work. Table allocation is handled by a struct initializer
    // and, if needed, retried later by InitActions.
    call UnitDeathEvent_Register(function OnUnitDeath)
    call Events_RegisterUnitEnter(function OnUnitEnterEvent)
    call Events_RegisterUnitSummon(function OnUnitSummonEvent)

    // Defer preplaced-unit enumeration and any Table-state retry until game
    // time 0. This initializer itself intentionally does not call Table.create().
    set initTimer = CreateTimer()
    if initTimer == null then
        call BJDebugMsg("[CreepRespawn] ERROR: Unable to create initialization timer.")
        return
    endif

    call TimerStart(initTimer, 0.00, false, function InitActions)
    set initTimer = null
endfunction

endlibrary
