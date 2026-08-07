/**
    CreepRespawn

    Author: Valdemar
    Version: 2.1

    Description:
    Tracks configured-owner units and recreates them at their saved spawn
    position after a random delay. Recreated quest NPCs are passed to
    CreepUnitAssignmentSystem to refresh their map references.

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
    private boolean exclusionListReady = false
    private boolean initialPositionsSaved = false
    
    // Debug mode - set to true to enable debug messages
    private boolean DEBUG_MODE = true
    
    // Respawn min/max times
    private constant real MIN_RESPAWN_TIME = 120.0
    private constant real MAX_RESPAWN_TIME = 320.0
    
    //===========================================================================
    // EXCLUSION LIST - Unit-types that will NOT respawn
    //===========================================================================
    private integer array EXCLUDED_UNIT_TYPES
    private integer EXCLUDED_COUNT = 0
endglobals

//===========================================================================
// EXCLUSION LIST SETUP
//===========================================================================
// Add unit-type IDs here to prevent them from respawning
// Use 4-character unit-type codes in 'XXXX' format
//===========================================================================
private function InitExclusionList takes nothing returns nothing
    // Add your exclusions here:
    // AI HEROES
    set EXCLUDED_UNIT_TYPES[0] = 'H60Y'  // Human Paladin (companion)
    set EXCLUDED_UNIT_TYPES[1] = '061H'  // Shaman (companion)
    set EXCLUDED_UNIT_TYPES[2] = '0631'  // Rogue (companion)
    set EXCLUDED_UNIT_TYPES[3] = '0629'  // Warrior (companion)
    set EXCLUDED_UNIT_TYPES[4] = 'H60X'  // Warlock (companion) 
    set EXCLUDED_UNIT_TYPES[5] = 'N64O'  // Engineer (companion) 
    set EXCLUDED_UNIT_TYPES[6] = 'N661'  // Engineer shredder-form (companion) 

    // Other exclusions
    // set EXCLUDED_UNIT_TYPES[7] = 'yyyy'  // Another unit
    
    // Update this count to match the number of exclusions above:
    set EXCLUDED_COUNT = 7
endfunction

//===========================================================================
// UTILITY FUNCTIONS
//===========================================================================

private function EnsureState takes nothing returns nothing
    if not exclusionListReady then
        call InitExclusionList()
        set exclusionListReady = true
    endif
    if rhash == 0 then
        set rhash = Table.create()
    endif
    if respawnData == 0 then
        set respawnData = Table.create()
    endif
    if ignoredUnits == 0 then
        set ignoredUnits = Table.create()
    endif
    if summonedUnits == 0 then
        set summonedUnits = Table.create()
    endif
    if RespawnGroup == null then
        set RespawnGroup = CreateGroup()
    endif
endfunction

private function IsExcludedUnitType takes integer unitTypeId returns boolean
    local integer i = 0
    
    // Check if unit type is in exclusion list
    loop
        exitwhen i >= EXCLUDED_COUNT
        if EXCLUDED_UNIT_TYPES[i] == unitTypeId then
            return true
        endif
        set i = i + 1
    endloop
    
    return false
endfunction

private function GetRespawnOwner takes unit u returns player
    local integer id
    local integer savedOwnerId
    local player owner = null

    if u == null then
        return null
    endif

    set owner = GetOwningPlayer(u)
    set id = GetHandleId(u)
    if rhash != 0 and rhash.has(id * 4 + 3) then
        set savedOwnerId = rhash[id * 4 + 3]
        return Player(savedOwnerId)
    endif

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
    return IsRespawnableOwner(GetRespawnOwner(u))
endfunction

private function IsIgnoredUnit takes unit u returns boolean
    if u == null or ignoredUnits == 0 then
        return false
    endif
    return ignoredUnits.has(GetHandleId(u))
endfunction

private function SaveUnitPosition takes unit u returns nothing
    local integer id
    if u == null then
        return
    endif
    if IsIgnoredUnit(u) then
        return
    endif
    set id = GetHandleId(u)
    set rhash.real[id * 4 + 0] = GetUnitX(u)
    set rhash.real[id * 4 + 1] = GetUnitY(u)
    set rhash.real[id * 4 + 2] = GetUnitFacing(u)
    set rhash[id * 4 + 3] = GetPlayerId(GetRespawnOwner(u))
    
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
    return rhash.real.has(id * 4 + 0) and rhash.real.has(id * 4 + 1) and rhash.real.has(id * 4 + 2) and rhash.has(id * 4 + 3)
endfunction

private function ClearSavedUnitPosition takes unit u returns nothing
    local integer id

    if u == null or rhash == 0 then
        return
    endif

    set id = GetHandleId(u)
    call rhash.real.remove(id * 4 + 0)
    call rhash.real.remove(id * 4 + 1)
    call rhash.real.remove(id * 4 + 2)
    call rhash.remove(id * 4 + 3)
endfunction


//===========================================================================
// PUBLIC API
//===========================================================================

function CreepRespawn_SetDebugEnabled takes boolean enabled returns nothing
    set DEBUG_MODE = enabled
    call UnitDeathEvent_SetDebugEnabled(enabled)
endfunction

// Call this function when a unit enters the map to track it for respawning.
// The normal map-wide enter hook is registered through Events in Init.
function CreepRespawn_OnUnitEnter takes unit u returns nothing
    if u == null then
        return
    endif
    call EnsureState()
    if IsIgnoredUnit(u) then
        set u = null
        return
    endif
    if summonedUnits.has(GetHandleId(u)) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] OnUnitEnter: Summoned instance ignored: " + GetUnitName(u))
        endif
        set u = null
        return
    endif
    if IsRespawnableUnit(u) then
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

    set id = GetHandleId(summoned)
    set summonedUnits[id] = 1

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
    call EnsureState()
    set id = GetHandleId(u)
    set ignoredUnits[id] = 1
    if RespawnGroup != null then
        call GroupRemoveUnit(RespawnGroup, u)
    endif
    if rhash != 0 then
        call rhash.real.remove(id * 4 + 0)
        call rhash.real.remove(id * 4 + 1)
        call rhash.real.remove(id * 4 + 2)
        call rhash.remove(id * 4 + 3)
    endif
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
    
    // Save new unit position
    call SaveUnitPosition(newUnit)
    
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
    set handleId = GetHandleId(dying)
    set utype = GetUnitTypeId(dying)
    set p = GetRespawnOwner(dying)
    set x = rhash.real[handleId * 4 + 0]
    set y = rhash.real[handleId * 4 + 1]
    set facing = rhash.real[handleId * 4 + 2]
    set delay = GetRandomReal(MIN_RESPAWN_TIME, MAX_RESPAWN_TIME)
    set t = CreateTimer()
    if t == null then
        call BJDebugMsg("[CreepRespawn] ERROR: Unable to create a respawn timer for " + GetUnitName(dying) + ".")
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
    local real savedX
    local real savedY
    local boolean hasSavedPosition

    // This is intentionally the first operation in the callback. If this is
    // not printed while DEBUG_MODE is true, UnitDeathEvent did not dispatch
    // to CreepRespawn.
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] OnUnitDeath ENTER")
    endif

    set dying = UnitDeathEvent_GetDyingUnit()
    if dying == null then
        call BJDebugMsg("[CreepRespawn] ERROR: UnitDeathEvent returned a null dying unit.")
        return
    endif

    set handleId = GetHandleId(dying)

    // Skip only real summoned instances. Do not use UNIT_TYPE_SUMMONED here;
    // that classification can also be present on preplaced custom units.
    if summonedUnits.has(handleId) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Actual summoned instance died - SKIPPED: " + GetUnitName(dying))
        endif
        call summonedUnits.remove(handleId)
        call ClearSavedUnitPosition(dying)
        set dying = null
        return
    endif

    set owner = GetRespawnOwner(dying)
    set playerId = GetPlayerId(owner)
    set savedX = rhash.real[handleId * 4 + 0]
    set savedY = rhash.real[handleId * 4 + 1]
    set hasSavedPosition = HasSavedUnitPosition(dying)

    if GetOwningPlayer(dying) == Player(22) and DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Player 23 (Emerald) unit detected - converting to Neutral Passive for respawn")
    endif

    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Unit died: " + GetUnitName(dying) + " | Type: " + I2S(GetUnitTypeId(dying)) + " | Owner: Player " + I2S(playerId) + " | HandleID: " + I2S(handleId))
        if hasSavedPosition then
            call BJDebugMsg("[CreepRespawn] Saved position: (" + R2S(savedX) + ", " + R2S(savedY) + ") | Has saved data: true")
        else
            call BJDebugMsg("[CreepRespawn] Saved position: (" + R2S(savedX) + ", " + R2S(savedY) + ") | Has saved data: false")
        endif
    endif

    if IsIgnoredUnit(dying) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Unit was explicitly discarded - SKIPPED")
        endif
        set dying = null
        set owner = null
        return
    endif

    if not IsRespawnableOwner(owner) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Unit owner not respawnable - SKIPPED")
        endif
        set dying = null
        set owner = null
        return
    endif

    set unitType = GetUnitTypeId(dying)
    if IsExcludedUnitType(unitType) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Unit type is excluded - SKIPPED")
        endif
        set dying = null
        set owner = null
        return
    endif

    if not hasSavedPosition then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] No saved spawn data found; saving current death position before scheduling respawn")
        endif
        call SaveUnitPosition(dying)
    endif

    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Unit PASSED all checks - WILL RESPAWN")
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
        call BJDebugMsg("[CreepRespawn] InitActions ENTER")
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

    // First-line diagnostic: if this does not appear with DEBUG_MODE enabled,
    // the CreepRespawn library initializer itself is not being executed.
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Init ENTER")
    endif

    // Mirror respawn debugging into the centralized dispatcher so a native
    // death can be distinguished from a missing CreepRespawn callback.
    call UnitDeathEvent_SetDebugEnabled(DEBUG_MODE)

    // Initialize all persistent state exactly once. Internal functions assume
    // this invariant after Init; public API entry points remain defensive.
    call EnsureState()
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] State initialized")
    endif

    // UnitDeathEvent v3 dispatches registered callbacks directly and does not
    // rely on TriggerRegisterVariableEvent.
    call UnitDeathEvent_Register(function OnUnitDeath)
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Registered with centralized death event system")
    endif

    call Events_RegisterUnitEnter(function OnUnitEnterEvent)
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Registered with centralized unit-enter event system")
    endif

    call Events_RegisterUnitSummon(function OnUnitSummonEvent)
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Registered summoned-instance tracking")
    endif

    // Defer the preplaced-unit scan until game-time 0 so map-placed units are
    // guaranteed to exist before enumeration.
    set initTimer = CreateTimer()
    if initTimer == null then
        call BJDebugMsg("[CreepRespawn] ERROR: Unable to create initialization timer.")
        return
    endif

    call TimerStart(initTimer, 0.00, false, function InitActions)

    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Init EXIT")
    endif

    set initTimer = null
endfunction

endlibrary
