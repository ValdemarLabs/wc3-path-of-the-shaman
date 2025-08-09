
//===========================================================================
/*
    SteamBreath System 1.0

    Author: [Queel]

    Description:
    This system manages the visual effects of steam breath on units in the game.
    It attaches steam effects to random units in the playable map area, excluding mechanical, structure, 
    and summoned units. The system supports up to 1000 units and provides functions to attach, remove,
    and clean up steam effects.

    API:
    -   call AttachSteamEffects() - Attaches steam effects to random units in the playable map area.
    -   call RemoveSteamEffects() - Removes all attached steam effects.     
    -   call SteamBreathCleanup() - Cleans up the RandomUnits and SteamEffects arrays.          

*/ 
//===========================================================================
//////////////////////////////////////////////////
globals
    integer MAX_UNITS = 1000
    unit array RandomUnits // Store affected units
    effect array SteamEffects // Store attached effects
endglobals
//////////////////////////////////////////////////
//===========================================================================
function Filter_IsSteamTarget takes nothing returns boolean
    local unit u = GetFilterUnit()
    return IsUnitAliveBJ(u) and not IsUnitType(u, UNIT_TYPE_MECHANICAL) and not IsUnitType(u, UNIT_TYPE_STRUCTURE) and not IsUnitType(u, UNIT_TYPE_SUMMONED)
endfunction

function SteamBreathCleanup takes nothing returns nothing
    local integer i = 0
    loop
        exitwhen i >= MAX_UNITS
        set RandomUnits[i] = null
        set i = i + 1
    endloop
endfunction
//===========================================================================
function AttachSteamEffects takes nothing returns nothing
    local group g = CreateGroup()
    local unit u
    local integer i = 0
    
    // Clear previous RandomUnits[] data
    call SteamBreathCleanup()

    // Pick all units in the playable map area
    // Pick only valid steam targets (alive, non-mechanical, non-structure, non-summoned)
    call GroupEnumUnitsInRect(g, bj_mapInitialPlayableArea, Condition(function Filter_IsSteamTarget))

    // Attach effects to random units (up to 1000)
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null or i >= MAX_UNITS
        
        set RandomUnits[i] = u // Store unit reference
        set SteamEffects[i] = AddSpecialEffectTarget("SteamBreath_Small_Moderate.mdx", u, "head")

        call GroupRemoveUnit(g, u)
        set i = i + 1
    endloop

    call DestroyGroup(g)
endfunction
//===========================================================================
function RemoveSteamEffects takes nothing returns nothing
    local integer i = 0
    loop
        exitwhen i >= MAX_UNITS
        if SteamEffects[i] != null then
            call DestroyEffect(SteamEffects[i])
            set SteamEffects[i] = null
        endif
        set i = i + 1
    endloop
endfunction