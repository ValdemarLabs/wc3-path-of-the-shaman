library ItemDropDestructible requires ItemDropConfig, ItemDropCore, DestructibleDeathEngine
//===========================================================================
/*
    ItemDropDestructible 1.0
    
    Author: [Valdemar]
    
    Description:
    Handles item drops from destructibles (crates, barrels, etc.).
    Uses the same drop logic as units but triggered by destructible death.
    
    Requires DestructibleDeathEngine to provide:
    - DestructibleDeathEvent (event variable)
    - DestructibleDeathTarget (destructible variable)
    
    Destructible Types by Level:
    - Crates (Level 1-5, 6-10, 11-15, 16-20, 21-25, 26-30)
    - Barrels (Level 1-5, etc.)
*/
//===========================================================================

//===========================================================================
// HELPER: Get destructible level based on type
// Uses Table lookup for O(1) performance
//===========================================================================
function ItemDropDestructible_GetLevel takes destructable d returns integer
    return DestructibleLevelTable[GetDestructableTypeId(d)]
endfunction

//===========================================================================
// HELPER: Check if destructible can drop items
//===========================================================================
function ItemDropDestructible_CanDrop takes destructable d returns boolean
    return ItemDropDestructible_GetLevel(d) > 0
endfunction

//===========================================================================
// DROP HANDLER: Process destructible drop by level
// Uses same drop rates as units of equivalent level
//===========================================================================
function ItemDropDestructible_ProcessDrop takes destructable d, location loc, integer destructibleLevel returns nothing
    local integer mainDice = GetRandomInt(1, 40)
    
    // Drop chance thresholds by level range (same as units)
    // LEVELS 1-5: 15% useless, 12.5% generic, 12.5% equipment
    if destructibleLevel <= 5 then
        call ItemDropCore_DropUseless(loc, mainDice, 6)
        call ItemDropCore_DropGeneric(loc, destructibleLevel, mainDice, 6, 11)
        call ItemDropCore_DropEquipment(loc, destructibleLevel, mainDice, 11, 16)
    
    // LEVELS 6-10: 15% useless, 12.5% generic, 12.5% equipment
    elseif destructibleLevel <= 10 then
        call ItemDropCore_DropUseless(loc, mainDice, 6)
        call ItemDropCore_DropGeneric(loc, destructibleLevel, mainDice, 6, 11)
        call ItemDropCore_DropEquipment(loc, destructibleLevel, mainDice, 11, 16)
    
    // LEVELS 11-15: 10% useless, 15% generic, 17.5% equipment
    elseif destructibleLevel <= 15 then
        call ItemDropCore_DropUseless(loc, mainDice, 4)
        call ItemDropCore_DropGeneric(loc, destructibleLevel, mainDice, 4, 10)
        call ItemDropCore_DropEquipment(loc, destructibleLevel, mainDice, 10, 17)
    
    // LEVELS 16-20: 10% useless, 15% generic, 17.5% equipment
    elseif destructibleLevel <= 20 then
        call ItemDropCore_DropUseless(loc, mainDice, 4)
        call ItemDropCore_DropGeneric(loc, destructibleLevel, mainDice, 4, 10)
        call ItemDropCore_DropEquipment(loc, destructibleLevel, mainDice, 10, 17)
    
    // LEVELS 21-25: 7.5% useless, 12.5% generic, 20% equipment
    elseif destructibleLevel <= 25 then
        call ItemDropCore_DropUseless(loc, mainDice, 3)
        call ItemDropCore_DropGeneric(loc, destructibleLevel, mainDice, 3, 8)
        call ItemDropCore_DropEquipment(loc, destructibleLevel, mainDice, 8, 16)
    
    // LEVELS 26-30+: 5% useless, 10% generic, 25% equipment
    else
        call ItemDropCore_DropUseless(loc, mainDice, 2)
        call ItemDropCore_DropGeneric(loc, destructibleLevel, mainDice, 2, 6)
        call ItemDropCore_DropEquipment(loc, destructibleLevel, mainDice, 6, 16)
    endif
endfunction

//===========================================================================
// EVENT HANDLER: Destructible death
//===========================================================================
function ItemDropDestructible_OnDeath takes nothing returns nothing
    local destructable d = DestructibleDeathTarget
    local location loc
    local integer destructibleLevel
    
    // Check if destructible can drop items
    if not ItemDropDestructible_CanDrop(d) then
        return
    endif
    
    // Get destructible location and level
    set loc = GetDestructableLoc(d)
    set destructibleLevel = ItemDropDestructible_GetLevel(d)
    
    // Process drop
    call ItemDropDestructible_ProcessDrop(d, loc, destructibleLevel)
    
    // Cleanup
    call RemoveLocation(loc)
    set loc = null
    set d = null
endfunction

//===========================================================================
// INITIALIZATION
//===========================================================================
function ItemDropDestructible_Init takes nothing returns nothing
    local trigger t = CreateTrigger()
    
    // Register to DestructibleDeathEngine event
    call TriggerRegisterVariableEvent(t, "DestructibleDeathEvent", EQUAL, 1.00)
    call TriggerAddAction(t, function ItemDropDestructible_OnDeath)
    
    set t = null
endfunction

//===========================================================================
endlibrary
//===========================================================================
