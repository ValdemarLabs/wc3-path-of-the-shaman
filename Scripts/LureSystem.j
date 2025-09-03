//===========================================================================
/*
    Simple Lure System v1.0

    Author: [Valdemar]

    Description:
    Spawns a lure unit at a point, creeps within 1000 range are attracted.  
    This system is designed to be lightweight and efficient, allowing for
    the attraction of neutral hostile creeps without causing lag, even with
    hundreds of NPCs on the map. The lure unit can be created at any point
    and will attract all neutral hostile creeps within a specified range.   

    Features:
    - Attracts neutral hostile creeps within a specified range
    - Lightweight and efficient, suitable for maps with many NPCs
    - Can be triggered periodically to maintain attraction

    Usage from GUI:
    call CreateLure(player, x, y) // Creates a lure unit at the specified coordinates
    call LureEffect(lure) // Applies the lure effect to the specified lure unit
    call LurePeriodic() // Periodically checks for lure units and applies effects
    call InitTrig_LureSystem() // Initializes the lure system trigger
    call DestroyLure(lure) // Removes the lure unit from the game

*/ 
//===========================================================================
//========================================================================

globals
    private constant real LURE_RANGE = 1000.0
    private constant integer LURE_UNIT_ID = 'h000' // <- change to your lure dummy unit rawcode
    private constant integer ATTRACT_INTERVAL = 1  // seconds between creep checks
endglobals

// Utility function: get random unit in group
function GetRandomUnitFromGroup takes group g returns unit
    local integer count = CountUnitsInGroup(g)
    local unit u = null
    if count > 0 then
        call ForGroup(g, function GroupPickRandomUnitEnum)
        set u = udg_TempUnit
    endif
    return u
endfunction

// Helper to store picked unit
globals
    unit udg_TempUnit = null
endglobals

function GroupPickRandomUnitEnum takes nothing returns nothing
    if GetRandomInt(1, CountUnitsInGroup(bj_groupLastCreated)) == 1 then
        set udg_TempUnit = GetEnumUnit()
    endif
endfunction

// Main lure effect
function LureEffect takes unit lure returns nothing
    local group g = CreateGroup()
    local unit u
    
    call GroupEnumUnitsInRange(g, GetUnitX(lure), GetUnitY(lure), LURE_RANGE, null)
    
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null
        call GroupRemoveUnit(g, u)
        
        // Only affect neutral hostile creeps
        if GetOwningPlayer(u) == Player(PLAYER_NEUTRAL_AGGRESSIVE) and IsUnitAliveBJ(u) then
            // Order unit to move towards lure
            call IssuePointOrder(u, "attack", GetUnitX(lure), GetUnitY(lure))
        endif
    endloop
    
    call DestroyGroup(g)
    set g = null
    set u = null
endfunction

// Periodic lure check
function LurePeriodic takes nothing returns nothing
    local group g = CreateGroup()
    local unit lure
    
    call GroupEnumUnitsOfPlayer(g, Player(PLAYER_NEUTRAL_PASSIVE), null)
    
    loop
        set lure = FirstOfGroup(g)
        exitwhen lure == null
        call GroupRemoveUnit(g, lure)
        
        if GetUnitTypeId(lure) == LURE_UNIT_ID then
            call LureEffect(lure)
        endif
    endloop
    
    call DestroyGroup(g)
    set g = null
    set lure = null
endfunction

// Create lure
function CreateLure takes player p, real x, real y returns unit
    local unit lure = CreateUnit(p, LURE_UNIT_ID, x, y, 0)
    return lure
endfunction

//========================================================================
function InitTrig_LureSystem takes nothing returns nothing
    local trigger t = CreateTrigger()
    call TriggerRegisterTimerEventPeriodic(t, ATTRACT_INTERVAL)
    call TriggerAddAction(t, function LurePeriodic)
endfunction
//========================================================================