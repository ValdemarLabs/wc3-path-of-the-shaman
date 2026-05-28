library UnitDeathEvent initializer Init

/*
    Unit Death Event System
    Author: [Valdemar]
    Version: 1.0
    
    Description:
    Centralized unit death event system that prevents event limit issues.
    Instead of having multiple systems register EVENT_PLAYER_UNIT_DEATH,
    this library registers it once and dispatches to all registered callbacks.
    
    Usage:
    1. Register your callback function:
       call UnitDeathEvent.register(function YourCallback)
       
    2. Your callback should have this signature:
       function YourCallback takes nothing returns nothing
           local unit killer = GetKillingUnit()
           local unit victim = GetDyingUnit()
           // Your death handling code here
       endfunction
       
    Benefits:
    - Only ONE death event registration for all 24 players
    - Prevents hitting Warcraft 3's event registration limits
    - Ensures all death events are captured reliably
    - Easy to add/remove death callbacks
    - Better performance with many death listeners
    
    Note:
    This should be one of the first libraries to initialize (minimal dependencies).
*/

globals
    private trigger deathTrigger = null
    private trigger array callbacks
    private integer callbackCount = 0
    private constant integer MAX_CALLBACKS = 50
    private constant integer UNIT_DEATH_EVENT_MAX_PLAYER_INDEX = 27
endglobals

// Register a callback function to be called on unit death
// The callback should use GetKillingUnit() and GetDyingUnit()
function UnitDeathEvent_Register takes code callback returns nothing
    if callbackCount >= MAX_CALLBACKS then
        call BJDebugMsg("[UnitDeathEvent] ERROR: Maximum callbacks reached (" + I2S(MAX_CALLBACKS) + ")")
        return
    endif
    
    set callbacks[callbackCount] = CreateTrigger()
    call TriggerAddAction(callbacks[callbackCount], callback)
    set callbackCount = callbackCount + 1
    
    call BJDebugMsg("[UnitDeathEvent] Registered callback #" + I2S(callbackCount) + " for unit death events")
endfunction

// Internal dispatcher that calls all registered callbacks
private function DispatchDeathEvent takes nothing returns nothing
    local integer i = 0
    local unit victim = GetDyingUnit()
    local unit killer = GetKillingUnit()
    
    // Debug output (can be commented out for production)
    // call BJDebugMsg("[UnitDeathEvent] Death detected: " + GetUnitName(victim) + " killed by " + GetUnitName(killer))
    
    // Call all registered callbacks
    loop
        exitwhen i >= callbackCount
        call TriggerExecute(callbacks[i])
        set i = i + 1
    endloop
endfunction

// Initialize the death event system
private function Init takes nothing returns nothing
    local integer playerIndex = 0

    set deathTrigger = CreateTrigger()
    loop
        call TriggerRegisterPlayerUnitEvent(deathTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_DEATH, null)
        set playerIndex = playerIndex + 1
        exitwhen playerIndex > UNIT_DEATH_EVENT_MAX_PLAYER_INDEX
    endloop
    call TriggerAddAction(deathTrigger, function DispatchDeathEvent)
    call BJDebugMsg("[UnitDeathEvent] Centralized death event system initialized")
endfunction

endlibrary
