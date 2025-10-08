library DestructibleDeathEngine initializer Init
    //===========================================================================
/*
    DestructibleDeathEngine

    Author: [Valdemar]

    Description:
    This engine provides a way to trigger events when a destructible is destroyed.
    It uses a global variable `DestructibleDeathEvent` to signal the event and  
    `DestructibleDeathTarget` to reference the destructible that was destroyed.

    Requirements:
    - Bannar's Destrictable Revival System 

    API:
    - udg_DestructibleDeathEvent (real): Set to 1.00 when a destructible is destroyed, otherwise 0.00.
    - udg_DestructibleDeathTarget (destructable): The destructable that was destroyed.

*/ 
//===========================================================================

globals
    private trigger array eventTriggers
    private integer eventCount = 0
endglobals

// Allows GUI to register events like "DestructibleDeathEvent == 1.00"
function RegisterDestructibleDeathEvent takes trigger whichTrigger returns nothing
    set eventCount = eventCount + 1
    set eventTriggers[eventCount] = whichTrigger
endfunction

// Internal: used by systems like DestructableRevival to fire the event
function FireDestructibleDeathEvent takes destructable d returns nothing
    local integer i = 1
    set udg_DestructibleDeathTarget = d
    set udg_DestructibleDeathEvent = 1.00
    loop
        exitwhen i > eventCount
        call TriggerEvaluate(eventTriggers[i])
        set i = i + 1
    endloop
    // Reset event value to 0.00 to allow future triggers
    set udg_DestructibleDeathEvent = 0.00
    set udg_DestructibleDeathTarget = null
endfunction

private function Init takes nothing returns nothing
    
endfunction

endlibrary
