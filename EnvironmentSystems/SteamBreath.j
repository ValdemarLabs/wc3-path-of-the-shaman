
//===========================================================================
/*
    SteamBreath System 2.0

    Author: [Valdemar]

    Description:
    This system manages the visual effects of steam breath on units in the game.
    It attaches steam effects to units within specific weather regions, excluding mechanical, structure, 
    and summoned units. The system supports up to 1000 units per region and provides functions to attach, 
    remove, and clean up steam effects.

    API:
    -   call AttachSteamEffectsInRegion(rect, integer) - Attaches steam effects to units in a specific region.
    -   call RemoveSteamEffectsInRegion(integer) - Removes steam effects from a specific region.
    -   call AttachSteamEffects() - Legacy: Attaches steam effects globally (deprecated).
    -   call RemoveSteamEffects() - Legacy: Removes all steam effects globally (deprecated).

*/ 
//===========================================================================

library SteamBreathSystem initializer Init requires UnitDeathEvent

globals
    private constant integer MAX_UNITS_PER_REGION = 1000 // Maximum units that can have steam in one region
    private constant integer MAX_REGIONS = 100 // Must match WeatherSystem MAX_REGIONS
    private unit array RandomUnits // Store affected units [regionIndex * MAX_UNITS_PER_REGION + unitIndex]
    private effect array SteamEffects // Store attached effects [regionIndex * MAX_UNITS_PER_REGION + unitIndex]
    private integer array RegionUnitCount // Track units per region
endglobals
//===========================================================================
function Filter_IsSteamTarget takes nothing returns boolean
    local unit u = GetFilterUnit()
    local boolean result = IsUnitAliveBJ(u) and not IsUnitType(u, UNIT_TYPE_MECHANICAL) and not IsUnitType(u, UNIT_TYPE_STRUCTURE) and not IsUnitType(u, UNIT_TYPE_SUMMONED)
    set u = null
    return result
endfunction

function SteamBreathCleanup takes nothing returns nothing
    local integer i = 0
    local integer j = 0
    local integer index
    loop
        exitwhen i >= MAX_REGIONS
        set j = 0
        loop
            exitwhen j >= MAX_UNITS_PER_REGION
            set index = i * MAX_UNITS_PER_REGION + j
            if SteamEffects[index] != null then
                call DestroyEffect(SteamEffects[index])
                set SteamEffects[index] = null
            endif
            set RandomUnits[index] = null
            set j = j + 1
        endloop
        set RegionUnitCount[i] = 0
        set i = i + 1
    endloop
endfunction
//===========================================================================
// Remove steam effects from a specific region
function RemoveSteamEffectsInRegion takes integer regionIndex returns nothing
    local integer i = 0
    local integer baseIndex
    
    if regionIndex < 0 or regionIndex >= MAX_REGIONS then
        return
    endif
    
    set baseIndex = regionIndex * MAX_UNITS_PER_REGION
    
    loop
        exitwhen i >= RegionUnitCount[regionIndex]
        if SteamEffects[baseIndex + i] != null then
            call DestroyEffect(SteamEffects[baseIndex + i])
            set SteamEffects[baseIndex + i] = null
        endif
        set RandomUnits[baseIndex + i] = null
        set i = i + 1
    endloop
    
    set RegionUnitCount[regionIndex] = 0
endfunction

// Attach steam effects to units in a specific region
function AttachSteamEffectsInRegion takes rect whichRegion, integer regionIndex returns nothing
    local group g = CreateGroup()
    local unit u
    local integer i = 0
    local integer baseIndex
    
    if whichRegion == null or regionIndex < 0 or regionIndex >= MAX_REGIONS then
        call DestroyGroup(g)
        set g = null
        return
    endif
    
    // Remove existing steam effects in this region first
    call RemoveSteamEffectsInRegion(regionIndex)
    
    set baseIndex = regionIndex * MAX_UNITS_PER_REGION

    // Pick all units in the specified region
    // Pick only valid steam targets (alive, non-mechanical, non-structure, non-summoned)
    call GroupEnumUnitsInRect(g, whichRegion, Condition(function Filter_IsSteamTarget))

    // Attach effects to units (up to MAX_UNITS_PER_REGION)
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null or i >= MAX_UNITS_PER_REGION
        
        set RandomUnits[baseIndex + i] = u // Store unit reference
        set SteamEffects[baseIndex + i] = AddSpecialEffectTarget("SteamBreath_Small_Moderate.mdx", u, "head")

        call GroupRemoveUnit(g, u)
        set i = i + 1
    endloop
    
    set RegionUnitCount[regionIndex] = i

    call DestroyGroup(g)
    set u = null
    set g = null
endfunction
//===========================================================================
// Legacy function - attaches steam effects globally (deprecated)
function AttachSteamEffects takes nothing returns nothing
    local group g = CreateGroup()
    local unit u
    local integer i = 0
    
    // Clear previous RandomUnits[] data
    call SteamBreathCleanup()

    // Pick all units in the playable map area
    // Pick only valid steam targets (alive, non-mechanical, non-structure, non-summoned)
    call GroupEnumUnitsInRect(g, bj_mapInitialPlayableArea, Condition(function Filter_IsSteamTarget))

    // Attach effects to random units (up to MAX_UNITS_PER_REGION)
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null or i >= MAX_UNITS_PER_REGION
        
        set RandomUnits[i] = u // Store unit reference
        set SteamEffects[i] = AddSpecialEffectTarget("SteamBreath_Small_Moderate.mdx", u, "head")

        call GroupRemoveUnit(g, u)
        set i = i + 1
    endloop

    set RegionUnitCount[0] = i
    call DestroyGroup(g)
    set u = null
    set g = null
endfunction
//===========================================================================
// Legacy function - removes all steam effects globally (deprecated)
function RemoveSteamEffects takes nothing returns nothing
    local integer i = 0
    loop
        exitwhen i >= MAX_UNITS_PER_REGION
        if SteamEffects[i] != null then
            call DestroyEffect(SteamEffects[i])
            set SteamEffects[i] = null
        endif
        set RandomUnits[i] = null
        set i = i + 1
    endloop
    set RegionUnitCount[0] = 0
endfunction
//===========================================================================
// Checks if a unit has a steam breath effect
//===========================================================================
function HasSteamEffect takes unit u returns boolean
    local integer i = 0
    local integer j = 0
    local integer index
    if u == null then
        return false
    endif
    loop
        exitwhen i >= MAX_REGIONS
        set j = 0
        loop
            exitwhen j >= RegionUnitCount[i]
            set index = i * MAX_UNITS_PER_REGION + j
            if RandomUnits[index] == u then
                return true
            endif
            set j = j + 1
        endloop
        set i = i + 1
    endloop
    return false
endfunction
//===========================================================================
// Removes steam effect from a single unit
//===========================================================================
function RemoveSteamEffectUnit takes unit u returns nothing
    local integer i = 0
    local integer j = 0
    local integer index
    if u == null then
        return
    endif
    loop
        exitwhen i >= MAX_REGIONS
        set j = 0
        loop
            exitwhen j >= RegionUnitCount[i]
            set index = i * MAX_UNITS_PER_REGION + j
            if RandomUnits[index] == u then
                if SteamEffects[index] != null then
                    call DestroyEffect(SteamEffects[index])
                    set SteamEffects[index] = null
                endif
                set RandomUnits[index] = null
            endif
            set j = j + 1
        endloop
        set i = i + 1
    endloop
endfunction
//===========================================================================
// Trigger to detect death and remove steam breath
//===========================================================================
function SteamBreath_Death takes nothing returns nothing
    local unit u = GetDyingUnit()
    call RemoveSteamEffectUnit(u)
    set u = null
endfunction

private function Init takes nothing returns nothing
    // Register with centralized death event system
    call UnitDeathEvent_Register(function SteamBreath_Death)
endfunction

endlibrary
