/*******************************************************************************
* Trap Activation System - GUI Trigger Implementation
* 
* This script demonstrates how to create a trap that:
* - Activates when a unit enters a region
* - Plays "Spell" animation on the trap doodad
* - Kills all units in the region
* - Returns to "Stand" animation after 1 second
*
* GUI SETUP INSTRUCTIONS:
* ========================
* 
* 1. CREATE THE REGION:
*    - In World Editor, press R or go to Layer > Regions
*    - Create a region where you want the trap (e.g., "TrapRegion_01")
*    - Place your trap doodad in this region
*
* 2. CREATE THE TRIGGER:
*    Trigger Name: "Trap Activation"
*    
*    Events:
*    - Unit - A unit enters TrapRegion_01
*    
*    Conditions:
*    - (Owner of (Triggering unit)) Not equal to Neutral Passive
*      [Optional: Add more conditions like unit type filters]
*    
*    Actions:
*    - Destructible - Play TrapDoodad <gen> animation "Spell"
*    - Unit Group - Pick every unit in TrapRegion_01 and do (Actions)
*        Loop - Actions
*            - Unit - Kill (Picked unit)
*    - Wait 1.00 seconds
*    - Destructible - Play TrapDoodad <gen> animation "Stand"
*
* 3. SETUP VARIABLES (if needed):
*    - TrapDoodad: Destructible variable pointing to your trap
*    - TrapRegion_01: Region variable (auto-created with region)
*
* 4. ADVANCED: For multiple traps, duplicate the trigger and change region
*
*******************************************************************************/

//==============================================================================
// JASS VERSION (for reference or custom implementation)
//==============================================================================

globals
    // Trap configuration
    destructable udg_TrapDoodad = null  // Set this in GUI or JASS
    rect udg_TrapRegion_01 = null       // Your trap region
    
    // For multiple traps, you can use arrays or hashtables
    trigger array TrapTriggers
endglobals

//==============================================================================
// Kill all units in region
//==============================================================================
function TrapKillUnitsInRegion takes rect r returns nothing
    local group g = CreateGroup()
    local unit u
    
    call GroupEnumUnitsInRect(g, r, null)
    
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null
        call GroupRemoveUnit(g, u)
        
        // Kill the unit
        call KillUnit(u)
        
        // Optional: Add special effects
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Crash\\CrashingWaveDamage.mdl", GetUnitX(u), GetUnitY(u)))
    endloop
    
    call DestroyGroup(g)
    set g = null
endfunction

//==============================================================================
// Reset trap animation after delay
//==============================================================================
function TrapResetAnimation takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local destructable d = LoadDestructableHandle(udg_hashtable, GetHandleId(t), 0)
    
    // Play "Stand" animation
    call SetDestructableAnimation(d, "stand")
    
    // Cleanup
    call FlushChildHashtable(udg_hashtable, GetHandleId(t))
    call DestroyTimer(t)
    
    set t = null
    set d = null
endfunction

//==============================================================================
// Main trap activation function
//==============================================================================
function TrapActivation_Actions takes nothing returns nothing
    local destructable trap = udg_TrapDoodad
    local rect region = udg_TrapRegion_01
    local timer t
    
    // Play "Spell" animation
    call SetDestructableAnimation(trap, "spell")
    
    // Kill all units in the region
    call TrapKillUnitsInRegion(region)
    
    // Optional: Add visual/sound effects
    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Doom\\DoomDeath.mdl", GetRectCenterX(region), GetRectCenterY(region)))
    call StartSound(gg_snd_TrapActivation) // Add your sound
    
    // Reset animation after 1 second
    set t = CreateTimer()
    call SaveDestructableHandle(udg_hashtable, GetHandleId(t), 0, trap)
    call TimerStart(t, 1.0, false, function TrapResetAnimation)
    
    set t = null
endfunction

//==============================================================================
// Condition - Optional filtering
//==============================================================================
function TrapActivation_Conditions takes nothing returns boolean
    local unit u = GetTriggerUnit()
    
    // Example conditions:
    // - Ignore neutral passive units
    if GetOwningPlayer(u) == Player(PLAYER_NEUTRAL_PASSIVE) then
        set u = null
        return false
    endif
    
    // - Only trigger for heroes
    // if not IsUnitType(u, UNIT_TYPE_HERO) then
    //     set u = null
    //     return false
    // endif
    
    set u = null
    return true
endfunction

//==============================================================================
// Initialize trap trigger
//==============================================================================
function InitTrap takes destructable trap, rect region returns trigger
    local trigger t = CreateTrigger()
    local region r = CreateRegion()
    
    call RegionAddRect(r, region)
    call TriggerRegisterEnterRegion(t, r, null)
    call TriggerAddCondition(t, Condition(function TrapActivation_Conditions))
    call TriggerAddAction(t, function TrapActivation_Actions)
    
    return t
endfunction

//==============================================================================
// EXAMPLE: Initialize in map initialization
//==============================================================================
function InitTraps takes nothing returns nothing
    // Example: Set up a single trap
    // set udg_TrapDoodad = gg_dest_Trap_0001
    // set udg_TrapRegion_01 = gg_rct_TrapRegion_01
    // call InitTrap(udg_TrapDoodad, udg_TrapRegion_01)
    
    // For multiple traps, repeat with different variables
endfunction


//==============================================================================
// SIMPLIFIED VERSION - Direct GUI Conversion
//==============================================================================
/*
    In GUI, create this trigger:

    Trap Activation
        Events
            Unit - A unit enters TrapRegion_01 <gen>
        Conditions
            (Owner of (Triggering unit)) Not equal to Neutral Passive
        Actions
            -------- Play trap animation --------
            Destructible - Play TrapDoodad <gen> animation "Spell"
            -------- Kill all units in region --------
            Unit Group - Pick every unit in (Units in TrapRegion_01 <gen>) and do (Actions)
                Loop - Actions
                    Unit - Kill (Picked unit)
                    Special Effect - Create a special effect at (Position of (Picked unit)) using Abilities\Spells\Other\Crash\CrashingWaveDamage.mdl
                    Special Effect - Destroy (Last created special effect)
            -------- Wait and reset animation --------
            Wait 1.00 seconds
            Destructible - Play TrapDoodad <gen> animation "Stand"

    NOTES:
    - Replace "TrapDoodad" with your actual destructible variable
    - Replace "TrapRegion_01" with your region name
    - For multiple traps, duplicate the trigger and change the region/doodad
*/
