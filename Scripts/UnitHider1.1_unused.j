library UnitHider

/*
    UnitHider1.1 - Unit Hiding System Documentation

    Overview:
    This system allows you to hide or unhide units based on their proximity to reference units. 
    The system continuously checks and updates the visibility of all units on the map, hiding units that are far from reference units and unhiding those that are close.

    Features:
    1. **Unit Hiding**: Units will be hidden when they are more than 1200 distance away from any reference unit and shown when they are close to one of the reference units.
    2. **Debug Messages**: The system includes debug messages that can be enabled or disabled. These messages show information about which units are being hidden or shown, and a summary of the system's actions.
    3. **Enable/Disable System**: The system can be enabled or disabled dynamically. When disabled, all hidden units will be unhidden.

    Requirements:
    - UnitIndexr (UDex) - This system requires the UnitIndexr library to function. Make sure to include it in your map.
    ----> This system utilizes: ==== Unit Event 2.5.3.2 ====

    Usage:
    - **UnitHider_SetSystemEnabled(boolean enable)**: Enables or disables the unit hiding system. When disabled, all hidden units will be unhidden.
    - **UnitHider_SetDebugEnabled(boolean enable)**: Enables or disables the debug messages. When disabled, no debug information will be shown.
    - **UnitHider_SetHidingDistance(real newDistance)**: Sets the distance at which units will be hidden or shown. The default is 1200.0.
    - **UnitHider_StartHideUnitsSystem()**: Call this function at the start of your map to initialize the unit hiding system. It will set up the trigger that checks unit visibility periodically.
    - **UnitHider_HideDistantUnits()**: This function is called by the trigger to check all units on the map and hide those that are not near any reference unit. It can also be called manually if needed.
        
    Functions:
    - `UnitHider_IsUnitNearReferenceUnits(unit u)`: Checks if a unit is within 1200 distance of any reference unit. Returns `true` if the unit is near a reference unit.
    - `UnitHider_HideDistantUnits()`: Checks all units on the map and hides those that are not near any reference unit and shows those that are. This is called repeatedly to keep the unit visibility up to date.
    - `UnitHider_InitHideUnitsTrigger()`: Initializes the trigger that checks unit visibility periodically.
    - `UnitHider_StartHideUnitsSystem()`: Starts the system and initializes the visibility check.

    Globals:
    - `systemEnabled`: A boolean that controls whether the system is active or not. If `false`, all hidden units will be unhidden.
    - `debugEnabled`: A boolean that controls whether debug messages are displayed. If `false`, no debug messages will be shown.
    - `hiddenUnitsTable`: A hashtable to store hidden units.
    - `hiddenUnits`: A group that holds all the units that are hidden.
*/

globals
    hashtable hiddenUnitsTable = InitHashtable()
    group hiddenUnits = CreateGroup() // Stores hidden units
    boolean systemEnabled = true // Controls whether the system is enabled or not
    boolean debugEnabled = true // Controls whether debug messages are shown or not
    real HidingDistance = 5500.0 // Global variable for distance, can be changed dynamically
endglobals

function UnitHider_IsUnitNearReferenceUnits takes unit u returns boolean
    local group refGroup = CreateGroup()
    local group copyGroup = udg_UnitHider_ReferenceGroup    // Reference group containing units that should be considered for hiding logic
    local real ux = GetUnitX(u)
    local real uy = GetUnitY(u)
    local unit ref
    local real dx
    local real dy
    local real distance
    local boolean result = false

    // Copy reference group into refGroup safely
    loop
        set ref = FirstOfGroup(copyGroup)
        exitwhen ref == null
        call GroupRemoveUnit(copyGroup, ref)
        call GroupAddUnit(refGroup, ref)
        call GroupAddUnit(copyGroup, ref) // Re-add back to original
    endloop

    // Check each unit in the reference group
    set ref = FirstOfGroup(refGroup)
    loop
        set ref = FirstOfGroup(refGroup)
        exitwhen ref == null
        call GroupRemoveUnit(refGroup, ref)

        // Calculate the distance to the unit
        set dx = GetUnitX(ref) - ux
        set dy = GetUnitY(ref) - uy
        set distance = SquareRoot(dx * dx + dy * dy)

        // If the distance is less than or equal to HidingDistance, set result to true and exit
        if distance <= HidingDistance then
            set result = true
            exitwhen true // Exit the loop early once the condition is met
        endif
    endloop

    call DestroyGroup(refGroup) // Cleanup
    return result
endfunction

// Function to set the hiding distance
function UnitHider_SetHidingDistance takes real newDistance returns nothing
    set HidingDistance = newDistance
endfunction

function UnitHider_HideDistantUnits takes nothing returns nothing
    local group g = CreateGroup()
    local unit u
    local integer countUnits = 0
    local integer countHidden = 0
    local integer countShown = 0

    // Check if the system is enabled
    if not systemEnabled then
        return
    endif

    // Only show debug messages if debugEnabled is true
    if debugEnabled then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "|cffffcc00[UnitHider]|r Checking units visibility...")
    endif

    // Unhide units near reference units
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null
        call GroupRemoveUnit(hiddenUnits, u)

        if UnitHider_IsUnitNearReferenceUnits(u) then
            call ShowUnit(u, true)
            set countShown = countShown + 1
            if debugEnabled then
                call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "|cff00ff00[UnitHider]|r Unhiding: " + GetUnitName(u))
            endif
        else
            call GroupAddUnit(hiddenUnits, u) // Keep it hidden
        endif
    endloop


    // Hide distant units not already hidden or ignored
    call GroupEnumUnitsInRect(g, GetWorldBounds(), null)
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null
        call GroupRemoveUnit(g, u)
        set countUnits = countUnits + 1

        if not UnitHider_IsUnitNearReferenceUnits(u) and not IsUnitInGroup(u, udg_UnitHider_IgnoredUnits) and not IsUnitInGroup(u, hiddenUnits) then
            call ShowUnit(u, false)
            call GroupAddUnit(hiddenUnits, u)
            set countHidden = countHidden + 1
            if debugEnabled then
                call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "|cffff0000[UnitHider]|r Hiding: " + GetUnitName(u))
            endif
        endif
    endloop

    call DestroyGroup(g)

    // Debug summary
    if debugEnabled then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "|cffffcc00[UnitHider]|r Total Units: " + I2S(countUnits) + " | Hidden: " + I2S(countHidden) + " | Shown: " + I2S(countShown))
    endif
endfunction

// Function to enable or disable the system
function UnitHider_SetSystemEnabled takes boolean enable returns nothing
    local unit u   
    local group tempGroup = CreateGroup()

    set systemEnabled = enable

    // debug messages
    if debugEnabled then
        if enable then
            call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "|cffffcc00[UnitHider]|r System is now ENABLED")
        else
            call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "|cffffcc00[UnitHider]|r System is now DISABLED")
        endif
    endif

    if systemEnabled then
        // Force an immediate refresh of hidden units after enabling the system
        call UnitHider_HideDistantUnits()
    else
        // Unhide all hidden units
        // Unhide all hidden units
        loop
            set u = FirstOfGroup(hiddenUnits)
            exitwhen u == null
            call ShowUnit(u, true)
            call GroupRemoveUnit(hiddenUnits, u)
        endloop
    endif

    call DestroyGroup(tempGroup)
endfunction

// Function to enable or disable debug messages
function UnitHider_SetDebugEnabled takes boolean enable returns nothing
    set debugEnabled = enable
endfunction

// Initialize the HideUnits trigger
function UnitHider_InitHideUnitsTrigger takes nothing returns nothing
    local trigger t = CreateTrigger()
    call TriggerRegisterTimerEvent(t, 0.5, true)
    call TriggerAddAction(t, function UnitHider_HideDistantUnits)

    // Show debug message if enabled
    if debugEnabled then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "|cff00ccff[UnitHider]|r Hide Units System Initialized.")
    endif

    // Delay the first execution of calling HideDistantUnits once at init to populate hiddenUnits
    call TimerStart(CreateTimer(), 0.10, false, function UnitHider_HideDistantUnits)
endfunction

// Ensures system starts at map initialization
function UnitHider_StartHideUnitsSystem takes nothing returns nothing
    call UnitHider_SetDebugEnabled(false)
    set udg_UnitHider_debug = false // Debug messages are disabled by default
    call UnitHider_InitHideUnitsTrigger()
    call UnitHider_SetSystemEnabled(true)
    set udg_UnitHider_SetSystem = true
endfunction

endlibrary
