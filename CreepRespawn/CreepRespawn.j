
library CreepRespawn initializer Init requires Table, TimerUtils, UnitDeathEvent, CreepUnitAssignmentSystem

/*
    Creep Respawn System
    Converted from GUI triggers to vJASS
    
    Automatically respawns creeps at their original spawn location after a random delay.
    Stores original position and facing for each unit in a Table.
    
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
    - Player(PLAYER_NEUTRAL_AGGRESSIVE) = Neutral Hostile
    - Player(PLAYER_NEUTRAL_PASSIVE) = Neutral Passive
*/

globals
    private Table rhash
    private Table respawnData
    private group RespawnGroup
    private integer nextRespawnId = 0
    
    // Debug mode - set to true to enable debug messages
    private constant boolean DEBUG_MODE = false
    
    // Event ID constant for map initialization
    private constant integer EVENT_GAME_INIT = 4
    
    // String hash constants for Table keys
    private constant integer HASH_X = StringHash("x")
    private constant integer HASH_Y = StringHash("y")
    private constant integer HASH_FACING = StringHash("facing")
    private constant real MIN_RESPAWN_TIME = 80.0
    private constant real MAX_RESPAWN_TIME = 240.0
    
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
    local player owner = GetOwningPlayer(u)

    if u == null then
        return null
    endif

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

private function SaveUnitPosition takes unit u returns nothing
    local integer id = GetHandleId(u)
    set rhash.real[id * 4 + 0] = GetUnitX(u)
    set rhash.real[id * 4 + 1] = GetUnitY(u)
    set rhash.real[id * 4 + 2] = GetUnitFacing(u)
    set rhash[id * 4 + 3] = GetPlayerId(GetRespawnOwner(u))
    
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Saved position for " + GetUnitName(u) + " (ID: " + I2S(id) + ") at (" + R2S(GetUnitX(u)) + ", " + R2S(GetUnitY(u)) + ")")
    endif
endfunction


//===========================================================================
// PUBLIC API
//===========================================================================

// Call this function when a unit enters the map to track it for respawning
// Usage from GUI: Custom script:   call CreepRespawn_OnUnitEnter(GetTriggerUnit())
function CreepRespawn_OnUnitEnter takes unit u returns nothing
    if IsRespawnableUnit(u) then
        call SaveUnitPosition(u)
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] OnUnitEnter: Tracking unit " + GetUnitName(u) + " for respawn")
        endif
    endif
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

private function ClearRespawnData takes integer respawnId returns nothing
    local integer base = respawnId * 5
    call respawnData.remove(base + 0)
    call respawnData.remove(base + 1)
    call respawnData.remove(base + 2)
    call respawnData.remove(base + 3)
    call respawnData.remove(base + 4)
endfunction

private function OnRespawnTimerExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer respawnId = GetTimerData(t)
    local integer base = respawnId * 5
    local integer utype = respawnData[base + 0]
    local player p = Player(respawnData[base + 1])
    local real x = respawnData.real[base + 2]
    local real y = respawnData.real[base + 3]
    local real facing = respawnData.real[base + 4]
    local unit newUnit
    
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Timer expired for unit type " + I2S(utype) + " at (" + R2S(x) + ", " + R2S(y) + ")")
    endif
    
    // Create new unit
    set newUnit = CreateUnit(p, utype, x, y, facing)
    
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Spawned new unit: " + GetUnitName(newUnit) + " (New ID: " + I2S(GetHandleId(newUnit)) + ")")
    endif
    
    // Save new unit position
    call SaveUnitPosition(newUnit)
    
    // Assign the unit to Unit variable (quest givers, etc. important units)
    set bj_lastCreatedUnit = newUnit
    call CreepUnitAssignment(utype)
    call ClearRespawnData(respawnId)
    call ReleaseTimer(t)
    
    set t = null
    set p = null
    set newUnit = null
endfunction

private function ScheduleRespawn takes unit dying returns nothing
    local integer handleId = GetHandleId(dying)
    local integer respawnId = nextRespawnId + 1
    local integer base = respawnId * 5
    local integer utype = GetUnitTypeId(dying)
    local player p = GetRespawnOwner(dying)
    local real x = rhash.real[handleId * 4 + 0]
    local real y = rhash.real[handleId * 4 + 1]
    local real facing = rhash.real[handleId * 4 + 2]
    local real delay = GetRandomReal(MIN_RESPAWN_TIME, MAX_RESPAWN_TIME)
    local timer t = NewTimer()
    
    set nextRespawnId = respawnId
    set respawnData[base + 0] = utype
    set respawnData[base + 1] = GetPlayerId(p)
    set respawnData.real[base + 2] = x
    set respawnData.real[base + 3] = y
    set respawnData.real[base + 4] = facing
    call SetTimerData(t, respawnId)
    
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Scheduling respawn: " + GetUnitName(dying) + " Type: " + I2S(utype) + " at (" + R2S(x) + ", " + R2S(y) + ") in " + R2S(delay) + " seconds")
    endif
    
    call TimerStart(t, delay, false, function OnRespawnTimerExpire)
    
    set p = null
    set t = null
endfunction

private function OnUnitDeath takes nothing returns nothing
    local unit dying = GetDyingUnit()
    local integer unitType
    local player owner = GetRespawnOwner(dying)
    local integer playerId = GetPlayerId(owner)
    local integer handleId = GetHandleId(dying)
    local real savedX = rhash.real[handleId * 4 + 0]
    local real savedY = rhash.real[handleId * 4 + 1]
    
    if GetOwningPlayer(dying) == Player(22) and DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Player 23 (Emerald) unit detected - converting to Neutral Passive for respawn")
    endif
    
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Unit died: " + GetUnitName(dying) + " | Type: " + I2S(GetUnitTypeId(dying)) + " | Owner: Player " + I2S(playerId) + " | HandleID: " + I2S(handleId))
        if savedX != 0.0 or savedY != 0.0 then
            call BJDebugMsg("[CreepRespawn] Saved position: (" + R2S(savedX) + ", " + R2S(savedY) + ") | Has saved data: true")
        else
            call BJDebugMsg("[CreepRespawn] Saved position: (" + R2S(savedX) + ", " + R2S(savedY) + ") | Has saved data: false")
        endif
    endif
    
    // Check if unit is not summoned
    if IsUnitType(dying, UNIT_TYPE_SUMMONED) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Unit is summoned - SKIPPED")
        endif
        set dying = null
        set owner = null
        return
    endif
    
    // Check if unit is respawnable owner
    if not IsRespawnableUnit(dying) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Unit owner not respawnable - SKIPPED")
        endif
        set dying = null
        set owner = null
        return
    endif
    
    // Check if unit type is excluded from respawning
    set unitType = GetUnitTypeId(dying)
    if IsExcludedUnitType(unitType) then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Unit type is excluded - SKIPPED")
        endif
        set dying = null
        set owner = null
        return
    endif
    
    // Unit passed all checks, proceed with respawn logic
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
    local integer eventId = GetHandleId(GetTriggerEventId())
    
    if eventId == EVENT_GAME_INIT then
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Initializing CreepRespawn system...")
        endif
        
        // Initialize exclusion list
        call InitExclusionList()
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Excluded " + I2S(EXCLUDED_COUNT) + " unit types from respawning")
        endif
        
        // Initialize tables
        set rhash = Table.create()
        set respawnData = Table.create()
        
        // Initialize respawn group
        call InitializeRespawnGroup()
        
        // Save all unit positions
        call SaveAllUnitPositions()
        
        if DEBUG_MODE then
            call BJDebugMsg("[CreepRespawn] Initialization complete!")
        endif
    endif
endfunction

//===========================================================================
// MODULE INITIALIZATION
//===========================================================================

private function Init takes nothing returns nothing
    local trigger initTrigger = CreateTrigger()
    
    // Initialize respawn group
    set RespawnGroup = CreateGroup()
    
    // Respawn System Init (runs at map start)
    call TriggerRegisterTimerEvent(initTrigger, 0.00, false)
    call TriggerAddAction(initTrigger, function InitActions)
    
    // Register with centralized death event system
    call UnitDeathEvent_Register(function OnUnitDeath)
    if DEBUG_MODE then
        call BJDebugMsg("[CreepRespawn] Registered with centralized death event system")
    endif
    
    set initTrigger = null
endfunction

endlibrary
