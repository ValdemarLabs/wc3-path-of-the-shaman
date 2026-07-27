library UnitDeathEvent initializer Init

/*
    Unit Death Event System
    Author: [Valdemar]
    Version: 1.0
    
    Description:
    Centralized unit death event system that prevents event limit issues.
    Instead of having multiple systems register EVENT_PLAYER_UNIT_DEATH,
    this library registers it once and attaches all code callbacks directly to
    that central trigger. This preserves native event responses.
    
    Usage:
    1. Register your callback function:
       call UnitDeathEvent_Register(function YourCallback)
       
    2. Your callback should have this signature:
       function YourCallback takes nothing returns nothing
           local unit killer = GetKillingUnit()
           local unit victim = GetDyingUnit()
           // Your death handling code here
       endfunction
       
    Benefits:
    - Only ONE death event registration for all 24 players
    - Preserves GetDyingUnit() and GetKillingUnit() in registered callbacks
    - Prevents hitting Warcraft 3's event registration limits
    - Ensures all death events are captured reliably
    - Easy to add/remove death callbacks
    - Better performance with many death listeners
    
    Note:
    This should be one of the first libraries to initialize (minimal dependencies).
    Registration also lazily creates the central trigger if an older library calls
    UnitDeathEvent_Register before declaring an explicit dependency.
*/

globals
    private trigger deathTrigger = null
    private integer callbackCount = 0
    private constant integer MAX_CALLBACKS = 50
    private constant integer UNIT_DEATH_EVENT_MAX_PLAYER_INDEX = 27
endglobals

private function UnitDeathEvent_EnsureTrigger takes nothing returns nothing
    local integer playerIndex = 0

    if deathTrigger != null then
        return
    endif

    set deathTrigger = CreateTrigger()
    loop
        call TriggerRegisterPlayerUnitEvent(deathTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_DEATH, null)
        set playerIndex = playerIndex + 1
        exitwhen playerIndex > UNIT_DEATH_EVENT_MAX_PLAYER_INDEX
    endloop
    //call BJDebugMsg("[UnitDeathEvent] Centralized death event system initialized")
endfunction

// Register a callback function to be called on unit death
// The callback should use GetKillingUnit() and GetDyingUnit()
function UnitDeathEvent_Register takes code callback returns nothing
    call UnitDeathEvent_EnsureTrigger()
    if callbackCount >= MAX_CALLBACKS then
        //call BJDebugMsg("[UnitDeathEvent] ERROR: Maximum callbacks reached (" + I2S(MAX_CALLBACKS) + ")")
        return
    endif

    call TriggerAddAction(deathTrigger, callback)
    set callbackCount = callbackCount + 1

    //call BJDebugMsg("[UnitDeathEvent] Registered callback #" + I2S(callbackCount) + " for unit death events")
endfunction

// Initialize the death event system
private function Init takes nothing returns nothing
    call UnitDeathEvent_EnsureTrigger()
endfunction

endlibrary
