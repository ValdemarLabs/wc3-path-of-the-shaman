/*
    FrostbiteSystem 1.0 – Cold Exposure Debuff System

    Overview:
    This system simulates cold weather debuff mechanics for units exposed to cold aura areas in your map.
    Units standing in snow-covered regions (with the "Cold" buff) for too long will receive a stacking exposure effect.
    After prolonged exposure, the unit will receive the "Frostbite" debuff which disables health and mana regeneration.
    The debuff is only removed when the unit is either no longer exposed to cold or is near a warm area (e.g., a campfire with "Warmth" aura).

    Features:
    1. **Exposure Timer**: Tracks how long each unit has been exposed to Cold without Warmth.
    2. **Debuff Application**: Applies a dummy-casted Frostbite ability when exposure time exceeds a configurable threshold.
    3. **Debuff Removal**: Automatically removes the debuff when unit escapes cold or gets Warmth.
    4. **Debug Mode**: Optional debug messages show in-game status of exposure, debuffing, and recovery.

    Usage:
    - Assign the correct rawcodes to the configuration section at the top of the script.
    - Make sure your Cold and Warmth auras are correctly applying their buffs.
    - Ensure a dummy caster unit is placed in the Object Editor and given the correct Frostbite ability.
    - Call `InitTrig_FrostbiteSystem()` in your map initialization.

    Functions:
    - `Frostbite_IsInCold(unit u)`: Returns true if the unit has the Cold aura buff.
    - `Frostbite_IsNearCampfire(unit u)`: Returns true if the unit has the Warmth aura buff.
    - `Frostbite_ApplyDebuff(unit u)`: Spawns a dummy to cast the Frostbite ability on a unit.
    - `Frostbite_RemoveDebuff(unit u)`: Removes the Frostbite ability from the unit.
    - `Frostbite_Periodic()`: Core loop that tracks and updates all affected units.
    - `Frostbite_Debug(string msg)`: Displays a debug message if debug mode is enabled.

    Globals:
    - `FROSTBITE_BUFF_COLD`: Rawcode of the "Cold" aura buff.
    - `FROSTBITE_BUFF_WARMTH`: Rawcode of the "Warmth" aura buff.
    - `FROSTBITE_ABILITY_ID`: Rawcode of the Frostbite debuff ability.
    - `FROSTBITE_DUMMY_ID`: Rawcode of the dummy caster unit.
    - `FROSTBITE_EXPOSURE_LIMIT`: Time in seconds required to trigger the Frostbite debuff.
    - `FROSTBITE_ORDER_STRING`: Order string used to cast the Frostbite ability.
    - `FROSTBITE_DEBUG_MODE`: Set to `true` to enable in-game debug messages.
    - `Frostbite_ExposureTime[8190]`: Array storing exposure time for each unit by custom value.
    - `Frostbite_HasDebuff[8190]`: Tracks which units currently have the Frostbite debuff.
    - `Frostbite_TempGroup`: Recycled group used for looping through units.
*/

//===========================================================================
// CONFIGURATION SECTION – CHANGE THESE TO MATCH YOUR MAP
//===========================================================================
globals
    constant integer FROSTBITE_BUFF_COLD      = 'B01Y'
    constant integer FROSTBITE_BUFF_WARMTH    = 'B607'
    constant integer FROSTBITE_ABILITY_ID     = 'A02V'
    constant integer FROSTBITE_DEBUFF_BUFF    = 'B01Z'
    constant integer FROSTBITE_DUMMY_ID       = 'n00R'
    constant real    FROSTBITE_EXPOSURE_LIMIT = 30.0
    constant string  FROSTBITE_ORDER_STRING   = "acidbomb"
    // Add this if you want only certain types of tents to count
    constant integer FROSTBITE_TENT_UNIT_TYPE = 'n643' // Replace with your tent's unit type ID
endglobals

//===========================================================================
// INTERNAL VARIABLES
//===========================================================================
globals
    integer array Frostbite_ExposureTime
    boolean array Frostbite_HasDebuff
    group Frostbite_TempGroup = CreateGroup()
    boolean Frostbite_SystemEnabled = true  // This flag enables or disables the entire system
    boolean Frostbite_Debug_Mode = true     // Debug mode, can be toggled on/off at runtime
endglobals

//===========================================================================
// SYSTEM CONTROL FUNCTIONS
//===========================================================================
// Function to enable or disable the system
function Frostbite_EnableSystem takes boolean enable returns nothing
    set Frostbite_SystemEnabled = enable
endfunction

// Function to enable or disable debug messages
function Frostbite_ToggleDebugMode takes boolean enable returns nothing
    set Frostbite_Debug_Mode = enable
endfunction

//===========================================================================
// DEBUG UTILITY
//===========================================================================
function Frostbite_Debug takes string msg returns nothing
    if Frostbite_Debug_Mode then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[Frostbite] " + msg)
    endif
endfunction

//===========================================================================
// UTILITY FUNCTIONS
//===========================================================================
// Check if the unit has a specific buff
function Frostbite_HasBuff takes unit u, integer buffId returns boolean
    return UnitHasBuffBJ(u, buffId)
endfunction

// Check if the unit is in a cold area (Cold buff)
function Frostbite_IsInCold takes unit u returns boolean
    return Frostbite_HasBuff(u, FROSTBITE_BUFF_COLD)
endfunction

// Check if the unit is near a campfire (Warmth buff)
function Frostbite_IsNearCampfire takes unit u returns boolean
    return Frostbite_HasBuff(u, FROSTBITE_BUFF_WARMTH)
endfunction

// Check if the unit has the Cold buff and remove it if Warmth is present
function Frostbite_RemoveColdBuffIfWarm takes unit u returns nothing
    if Frostbite_IsNearCampfire(u) and Frostbite_HasBuff(u, FROSTBITE_BUFF_COLD) then
        call UnitRemoveBuffBJ(FROSTBITE_BUFF_COLD, u)
        call Frostbite_Debug("Removed Cold buff from " + GetUnitName(u) + " due to Warmth.")
    endif
endfunction

// Check if the unit has the Frostbite debuff
function Frostbite_ApplyDebuff takes unit target returns nothing
    local unit dummy = CreateUnit(GetOwningPlayer(target), FROSTBITE_DUMMY_ID, GetUnitX(target), GetUnitY(target), 0)
    call UnitAddAbility(dummy, FROSTBITE_ABILITY_ID)
    call IssueTargetOrder(dummy, FROSTBITE_ORDER_STRING, target)
    call UnitApplyTimedLife(dummy, 'BTLF', 2.0)
endfunction

// Remove the debuff from the target unit
function Frostbite_RemoveDebuff takes unit target returns nothing
    call UnitRemoveAbility(target, FROSTBITE_ABILITY_ID)
    call UnitRemoveBuffBJ(FROSTBITE_DEBUFF_BUFF, target)
endfunction

// Check if the unit is alive and not a structure
function ConditionIsAlive takes nothing returns boolean
    return IsUnitAliveBJ(GetFilterUnit()) and not IsUnitType(GetFilterUnit(), UNIT_TYPE_STRUCTURE)
endfunction

//===========================================================================
// MAIN LOGIC LOOP
//===========================================================================
// This function is called periodically to check for cold exposure and apply/remove debuffs
function Frostbite_Periodic takes nothing returns nothing
    local unit u
    local integer id
    local player p

    if not Frostbite_SystemEnabled then
        return
    endif

    call GroupEnumUnitsInRect(Frostbite_TempGroup, bj_mapInitialPlayableArea, Condition(function ConditionIsAlive))
    loop
        set u = FirstOfGroup(Frostbite_TempGroup)
        exitwhen u == null
        call GroupRemoveUnit(Frostbite_TempGroup, u) 

        //call Frostbite_RemoveColdBuffIfWarm(u) // << Remove Cold buff if Warmth is present

        // Check if the unit is a player-controlled unit
        set p = GetOwningPlayer(u)
        if p == Player(0) or p == Player(1) or p == Player(19) then
            set id = GetUnitUserData(u)

            // Initialize exposure time and debuff status if not already done
            if Frostbite_HasDebuff[id] and not Frostbite_HasBuff(u, FROSTBITE_DEBUFF_BUFF) then
                call Frostbite_Debug("Frostbite wore off naturally from " + GetUnitName(u) + ", resuming exposure tracking.")
                set Frostbite_HasDebuff[id] = false
                set Frostbite_ExposureTime[id] = 0
            endif

            // Check if the unit is in a cold area and not near a campfire
            // If the unit is in a cold area and not near a campfire, increase exposure time
            if Frostbite_IsInCold(u) and not Frostbite_IsNearCampfire(u) then
                if not Frostbite_HasDebuff[id] then
                    // Set the GUI event trigger variables
                    set udg_Frostbite_Unit = u
                    set udg_Frostbite_ColdEvent = udg_Frostbite_ColdEvent + 1.00
                    
                    set Frostbite_ExposureTime[id] = Frostbite_ExposureTime[id] + 1
                    call Frostbite_Debug("Unit " + GetUnitName(u) + " exposed to cold for " + I2S(Frostbite_ExposureTime[id]) + "s.")
            
                    if Frostbite_ExposureTime[id] >= R2I(FROSTBITE_EXPOSURE_LIMIT) then
                        call Frostbite_Debug("Applying Frostbite to " + GetUnitName(u))
                        call Frostbite_ApplyDebuff(u)
                        set Frostbite_HasDebuff[id] = true
                        set Frostbite_ExposureTime[id] = 0 // Reset exposure count

                        // Set the GUI event trigger variables
                        set udg_Frostbite_Unit = u
                        set udg_Frostbite_FrostbiteEvent = udg_Frostbite_FrostbiteEvent + 1.00
                    endif
                endif
            else
                if Frostbite_HasDebuff[id] and (not Frostbite_IsInCold(u) or Frostbite_IsNearCampfire(u)) then
                    call Frostbite_Debug("Removing Frostbite from " + GetUnitName(u))
                    call Frostbite_RemoveDebuff(u)
                    set Frostbite_HasDebuff[id] = false

                    // Reset FrostbiteEvent when removing the debuff
                    set udg_Frostbite_FrostbiteEvent = 0  // Reset event counter
                endif
                if Frostbite_ExposureTime[id] > 0 then
                    call Frostbite_Debug("Resetting exposure time for " + GetUnitName(u))
                endif
                set udg_Frostbite_ColdEvent = 0
            endif
        endif

        set u = null
    endloop
endfunction

//===========================================================================
// Entering tent
//===========================================================================
// This function is called when a unit enters a tent (transport unit)
function Frostbite_OnUnitEntersTent takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local unit tent = GetTransportUnit()
    local integer id = GetUnitUserData(u)

    call Frostbite_Debug("Transport: " + GetUnitName(tent) + " | Unit: " + GetUnitName(u))

    // Optional: restrict to specific tent types
    if GetUnitTypeId(tent) != FROSTBITE_TENT_UNIT_TYPE then
        return
    endif

    if Frostbite_HasDebuff[id] then
        call Frostbite_Debug("Unit " + GetUnitName(u) + " entered a tent. Removing Frostbite.")
        call Frostbite_RemoveDebuff(u)
        set Frostbite_HasDebuff[id] = false
    endif

    if Frostbite_ExposureTime[id] > 0 then
        call Frostbite_Debug("Resetting exposure time for " + GetUnitName(u) + " due to tent shelter.")
        set Frostbite_ExposureTime[id] = 0
    endif
endfunction

//===========================================================================
// TRIGGER INITIALIZATION
//===========================================================================
// This function is called to start the periodic system check
function Frostbite_StartSystem takes nothing returns nothing
    local trigger t = CreateTrigger()
    call TriggerRegisterTimerEvent(t, 1.00, true)
    call TriggerAddAction(t, function Frostbite_Periodic)
endfunction

// This function initializes the system and sets up the triggers
function InitTrig_FrostbiteSystem takes nothing returns nothing
    local trigger startTrigger = CreateTrigger()
    // Tent entry detection
    local trigger tentTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(startTrigger, 1.00, false) // Delay start by 1 second
    call TriggerAddAction(startTrigger, function Frostbite_StartSystem)
    // Tent related triggers
    call TriggerRegisterAnyUnitEventBJ(tentTrigger, EVENT_PLAYER_UNIT_LOADED)
    call TriggerAddAction(tentTrigger, function Frostbite_OnUnitEntersTent)
    call Frostbite_ToggleDebugMode(false) // Disable debug mode by default
    set udg_Frostbite_Debug = false // Debug messages are disabled by default
endfunction