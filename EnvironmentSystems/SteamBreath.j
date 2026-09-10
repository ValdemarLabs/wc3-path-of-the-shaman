
//===========================================================================
/*
    SteamBreath System 2.0

    Author: [Valdemar]

    Description:
    This system manages the visual effects of steam breath on units in the game.
    It attaches steam effects to units within specific weather regions, excluding mechanical, structure, 
    and summoned units. The system supports up to 1000 units per region and provides functions to attach, 
    remove, and clean up steam effects.

    Credits:
    -   PotS weather and centralized unit-death systems.

    How to install:
    Import after UnitDeathEvent and FallenHeroState. Weather systems may then
    attach and remove steam effects by registered region index.

    API:
    -   call AttachSteamEffectsInRegion(rect, integer) - Attaches steam effects to units in a specific region.
    -   call RemoveSteamEffectsInRegion(integer) - Removes steam effects from a specific region.
    -   call AttachSteamEffects() - Legacy: Attaches steam effects globally (deprecated).
    -   call RemoveSteamEffects() - Legacy: Removes all steam effects globally (deprecated).
    -   call HasSteamEffect(unit) - Returns whether a unit has a tracked steam effect.
    -   call RemoveSteamEffectUnit(unit) - Removes every tracked steam effect from a unit.

*/ 
//===========================================================================

library SteamBreathSystem initializer Init requires UnitDeathEvent, FallenHeroState, optional GatherNodes

globals
    private constant integer MAX_UNITS_PER_REGION = 1000 // Maximum units that can have steam in one region
    private constant integer MAX_REGIONS = 100 // Must match WeatherSystem MAX_REGIONS
    private constant integer UNIT_KEY_OFFSET = 0
    private constant integer EFFECT_KEY_OFFSET = MAX_UNITS_PER_REGION
    private hashtable SteamBreathData = InitHashtable() // Region index -> unit/effect slots
    private integer array RegionUnitCount // Track units per region
endglobals
//===========================================================================
private function IsGatherNodeSteamTarget takes unit u returns boolean
    static if LIBRARY_GatherNodes then
        return GN_IsGatherUnit(u)
    endif

    return false
endfunction

function Filter_IsSteamTarget takes nothing returns boolean
    local unit u = GetFilterUnit()
    local boolean result = FallenHeroState_IsAlive(u) and not IsUnitType(u, UNIT_TYPE_MECHANICAL) and not IsUnitType(u, UNIT_TYPE_STRUCTURE) and not IsUnitType(u, UNIT_TYPE_SUMMONED) and not IsGatherNodeSteamTarget(u)
    set u = null
    return result
endfunction

function SteamBreathCleanup takes nothing returns nothing
    local integer i = 0
    local integer j = 0
    local effect steamEffect
    loop
        exitwhen i >= MAX_REGIONS
        set j = 0
        loop
            exitwhen j >= RegionUnitCount[i]
            set steamEffect = LoadEffectHandle(SteamBreathData, i, EFFECT_KEY_OFFSET + j)
            if steamEffect != null then
                call DestroyEffect(steamEffect)
            endif
            set j = j + 1
        endloop
        call FlushChildHashtable(SteamBreathData, i)
        set RegionUnitCount[i] = 0
        set i = i + 1
    endloop
    set steamEffect = null
endfunction
//===========================================================================
// Remove steam effects from a specific region
function RemoveSteamEffectsInRegion takes integer regionIndex returns nothing
    local integer i = 0
    local effect steamEffect
    
    if regionIndex < 0 or regionIndex >= MAX_REGIONS then
        return
    endif
    
    loop
        exitwhen i >= RegionUnitCount[regionIndex]
        set steamEffect = LoadEffectHandle(SteamBreathData, regionIndex, EFFECT_KEY_OFFSET + i)
        if steamEffect != null then
            call DestroyEffect(steamEffect)
        endif
        set i = i + 1
    endloop

    call FlushChildHashtable(SteamBreathData, regionIndex)
    set RegionUnitCount[regionIndex] = 0
    set steamEffect = null
endfunction

// Attach steam effects to units in a specific region
function AttachSteamEffectsInRegion takes rect whichRegion, integer regionIndex returns nothing
    local group g = CreateGroup()
    local unit u
    local integer i = 0
    local effect steamEffect
    
    if whichRegion == null or regionIndex < 0 or regionIndex >= MAX_REGIONS then
        call DestroyGroup(g)
        set g = null
        return
    endif
    
    // Remove existing steam effects in this region first
    call RemoveSteamEffectsInRegion(regionIndex)
    
    // Pick all units in the specified region
    // Pick only valid steam targets (alive, non-mechanical, non-structure, non-summoned)
    call GroupEnumUnitsInRect(g, whichRegion, Condition(function Filter_IsSteamTarget))

    // Attach effects to units (up to MAX_UNITS_PER_REGION)
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null or i >= MAX_UNITS_PER_REGION
        
        set steamEffect = AddSpecialEffectTarget("SteamBreath_Small_Moderate.mdx", u, "head")
        call SaveUnitHandle(SteamBreathData, regionIndex, UNIT_KEY_OFFSET + i, u)
        call SaveEffectHandle(SteamBreathData, regionIndex, EFFECT_KEY_OFFSET + i, steamEffect)

        call GroupRemoveUnit(g, u)
        set i = i + 1
    endloop
    
    set RegionUnitCount[regionIndex] = i

    call DestroyGroup(g)
    set steamEffect = null
    set u = null
    set g = null
endfunction
//===========================================================================
// Legacy function - attaches steam effects globally (deprecated)
function AttachSteamEffects takes nothing returns nothing
    local group g = CreateGroup()
    local unit u
    local integer i = 0
    local effect steamEffect
    
    // Clear previously tracked steam effects
    call SteamBreathCleanup()

    // Pick all units in the playable map area
    // Pick only valid steam targets (alive, non-mechanical, non-structure, non-summoned)
    call GroupEnumUnitsInRect(g, bj_mapInitialPlayableArea, Condition(function Filter_IsSteamTarget))

    // Attach effects to random units (up to MAX_UNITS_PER_REGION)
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null or i >= MAX_UNITS_PER_REGION
        
        set steamEffect = AddSpecialEffectTarget("SteamBreath_Small_Moderate.mdx", u, "head")
        call SaveUnitHandle(SteamBreathData, 0, UNIT_KEY_OFFSET + i, u)
        call SaveEffectHandle(SteamBreathData, 0, EFFECT_KEY_OFFSET + i, steamEffect)

        call GroupRemoveUnit(g, u)
        set i = i + 1
    endloop

    set RegionUnitCount[0] = i
    call DestroyGroup(g)
    set steamEffect = null
    set u = null
    set g = null
endfunction
//===========================================================================
// Legacy function - removes all steam effects globally (deprecated)
function RemoveSteamEffects takes nothing returns nothing
    call RemoveSteamEffectsInRegion(0)
endfunction
//===========================================================================
// Checks if a unit has a steam breath effect
//===========================================================================
function HasSteamEffect takes unit u returns boolean
    local integer i = 0
    local integer j = 0
    local unit trackedUnit
    if u == null then
        return false
    endif
    loop
        exitwhen i >= MAX_REGIONS
        set j = 0
        loop
            exitwhen j >= RegionUnitCount[i]
            set trackedUnit = LoadUnitHandle(SteamBreathData, i, UNIT_KEY_OFFSET + j)
            if trackedUnit == u then
                set trackedUnit = null
                return true
            endif
            set j = j + 1
        endloop
        set i = i + 1
    endloop
    set trackedUnit = null
    return false
endfunction
//===========================================================================
// Removes steam effect from a single unit
//===========================================================================
function RemoveSteamEffectUnit takes unit u returns nothing
    local integer i = 0
    local integer j = 0
    local unit trackedUnit
    local effect steamEffect
    if u == null then
        return
    endif
    loop
        exitwhen i >= MAX_REGIONS
        set j = 0
        loop
            exitwhen j >= RegionUnitCount[i]
            set trackedUnit = LoadUnitHandle(SteamBreathData, i, UNIT_KEY_OFFSET + j)
            if trackedUnit == u then
                set steamEffect = LoadEffectHandle(SteamBreathData, i, EFFECT_KEY_OFFSET + j)
                if steamEffect != null then
                    call DestroyEffect(steamEffect)
                endif
                call RemoveSavedHandle(SteamBreathData, i, UNIT_KEY_OFFSET + j)
                call RemoveSavedHandle(SteamBreathData, i, EFFECT_KEY_OFFSET + j)
            endif
            set j = j + 1
        endloop
        set i = i + 1
    endloop
    set trackedUnit = null
    set steamEffect = null
endfunction
//===========================================================================
// Trigger to detect death and remove steam breath
//===========================================================================
function SteamBreath_Death takes nothing returns nothing
    local unit u = UnitDeathEvent_GetDyingUnit()
    call RemoveSteamEffectUnit(u)
    set u = null
endfunction

private function Init takes nothing returns nothing
    // Register with centralized death event system
    call UnitDeathEvent_Register(function SteamBreath_Death)
endfunction

endlibrary
