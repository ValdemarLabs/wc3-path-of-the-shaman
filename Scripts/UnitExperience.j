
library UnitExperience initializer Init

/*
    UnitExperience  
    Version: 1.1
    Author: [Valdemar]

    Overview:
    - Units that are registered in the XP system can gain XP.
    - The unit must be near Nazgrek or Zulkis (distance check).
    - XP is granted when any nearby registered unit or Nazgrek/Zulkis kills an enemy (enemy = dying unit).
    - XP gain = level of the dying unit.
    - Units gain XP from nearby enemy deaths
    - Dummy units (Aloc > 0) are excluded
    - XP scaling like heroes (base 200, factor 150)
    - Public API to get total XP and XP to next level
    - Max level = 30

*/

globals
    private integer array xp                    // XP storage per unit
    private integer array level                 // Fake level storage per unit
    private boolean array registered            // Whether the unit is registered in the XP system
    private boolean array xpDisabled            // Whether XP gain is disabled for a unit
    private constant integer MAX_LEVEL = 30
    private constant real    RANGE    = 1200.0  // Range to register unit to gain XP

    private constant integer XP_BASE = 200      // Base XP gain for level 1 unit
    private constant integer XP_FACTOR = 150    // Additional XP per level (e.g. level 2 = 200 + 150*1 = 350)
    
    // External references for player heroes
    //unit udg_Nazgrek
    //unit udg_Zulkis

    // Group to track all registered units
    private group gRegisteredUnits = CreateGroup()

    private group gTemp = CreateGroup()         
    private real RANGE_SQ = RANGE * RANGE       

endglobals


//===== INTERNAL UTILS =====
// Returns true if unit u is within RANGE of either hero
private function IsNearbyHero takes unit u returns boolean
    local real dx
    local real dy
    local real dist2

    if GetOwningPlayer(udg_Nazgrek) == Player(0) then
        set dx = GetUnitX(u) - GetUnitX(udg_Nazgrek)
        set dy = GetUnitY(u) - GetUnitY(udg_Nazgrek)
        set dist2 = dx*dx + dy*dy
        if dist2 <= RANGE_SQ then
            return true
        endif
    endif
    if GetOwningPlayer(udg_Zulkis) == Player(0) then
        set dx = GetUnitX(u) - GetUnitX(udg_Zulkis)
        set dy = GetUnitY(u) - GetUnitY(udg_Zulkis)
        set dist2 = dx*dx + dy*dy
        if dist2 <= RANGE_SQ then
            return true
        endif
    endif
    return false
endfunction

// Returns required XP for unit u to reach next level
private function XPRequired takes integer lvl returns integer
    return XP_BASE + XP_FACTOR * (lvl - 1)
endfunction

// Adds XP to unit u, levels up if enough XP is gained
private function AddXP takes unit u, integer amount returns nothing
    local integer id = GetUnitUserData(u)

    // Skip XP gain if disabled
    if xpDisabled[id] or level[id] >= MAX_LEVEL then
        return
    endif

    if level[id] >= MAX_LEVEL then
        return
    endif

    // Add XP
    set xp[id] = xp[id] + amount

    // Show floating text for XP gain
    call ArcingTextTag.createEx("+" + I2S(amount) + " XP", u, 1.0, 0.5, GetLocalPlayer(), 0.7, 0.7, 1.0)
    call BJDebugMsg("Unit " + GetUnitName(u) + " gained " + I2S(amount) + " XP. Total XP: " + I2S(xp[id]) + ", Level: " + I2S(level[id]))

    // LEVEL UP
    loop
        exitwhen level[id] >= MAX_LEVEL or xp[id] < XPRequired(level[id])
        set xp[id] = xp[id] - XPRequired(level[id])
        set level[id] = level[id] + 1

        // Visually increase level
        call BlzSetUnitIntegerFieldBJ(u, UNIT_IF_LEVEL, GetUnitLevel(u) + 1)
        call BJDebugMsg("Unit " + GetUnitName(u) + " leveled up! New Level: " + I2S(level[id]) + ", Remaining XP: " + I2S(xp[id]))

        // Update multiboard
        call TriggerExecute(gg_trg_MultiboardUpdateLevel)

        // Trigger stats update for Shadowclaw
        if GetUnitTypeId(u) != 'n655' then
            call TriggerExecute(gg_trg_Shadowclaw_Stats)
        endif

        // Effect + Sound
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Levelup\\LevelupCaster.mdl", u, "origin"))
        call StartSound(bj_questCompletedSound)
    endloop
endfunction

//===== PUBLIC INTERFACE =====
public function RegisterUnit takes unit u returns nothing
    local integer id = GetUnitUserData(u)

    if not registered[id] then
        set xp[id] = 0
        set level[id] = 1
        set registered[id] = true
        set xpDisabled[id] = false
        call GroupAddUnit(gRegisteredUnits, u)

        call BJDebugMsg("Unit registered for UnitExperience: " + GetUnitName(u))    
    endif
endfunction

public function RemoveUnit takes unit u returns nothing
    local integer id = GetUnitUserData(u)

    set registered[id] = false
    set xpDisabled[id] = true
    call GroupRemoveUnit(gRegisteredUnits, u)

    call BJDebugMsg("Unit removed from UnitExperience: " + GetUnitName(u))
endfunction
//===========================

// Returns true if unit u is registered in the XP system
private function IsRegisteredUnit takes unit u returns boolean
    local integer id = GetUnitUserData(u)

    return registered[id]
endfunction

// Returns true if unit is a dummy (has Aloc > 0)
private function IsDummyUnit takes unit u returns boolean
    return GetUnitAbilityLevel(u, 'Aloc') > 0
endfunction

// Helper function for ForGroup
private function AddXPToNearbyUnits takes nothing returns nothing
    local unit u = GetEnumUnit()
    local unit dying = GetDyingUnit()

    if IsRegisteredUnit(u) and IsNearbyHero(u) and not IsDummyUnit(dying) then
        call AddXP(u, GetUnitLevel(dying))
    endif
endfunction

//===== EVENT HANDLER =====
private function UnitDeathHandler takes nothing returns nothing
    local unit dying = GetDyingUnit()
    local unit killer = GetKillingUnit()

    // Prevent self-kill XP gain
    if killer == dying then
        return
    endif

    // Enumerate registered units in RANGE of dying unit
    call GroupEnumUnitsInRange(gTemp, GetUnitX(dying), GetUnitY(dying), RANGE, null)
    call ForGroup(gTemp, function AddXPToNearbyUnits)
    call GroupClear(gTemp)
endfunction

// DISABLE OR ENABLE XP GAIN FOR A UNIT
public function DisableXP takes unit u, boolean flag returns nothing
    local integer id = GetUnitUserData(u)
    if registered[id] then
        set xpDisabled[id] = flag
        if flag then
            call BJDebugMsg("XP disabled for " + GetUnitName(u))
        else
            call BJDebugMsg("XP enabled for " + GetUnitName(u))
        endif
    endif
endfunction

// // Returns total XP the unit currently has
public function UnitExperience_GetUnitXP takes unit u returns integer
    local integer id = GetUnitUserData(u)
    if registered[id] then
        return xp[id]
    endif
    return 0
endfunction

// Returns XP required for a unit to reach the next level
public function UnitExperience_GetUnitXPToNextLevel takes unit u returns integer
    local integer id = GetUnitUserData(u)
    local integer lvl
    if not registered[id] then
        return 0
    endif
    set lvl = level[id]

    if lvl >= MAX_LEVEL then
        return 0  // Already max level
    endif

    return XPRequired(lvl) - xp[id]
endfunction

//===== INITIALIZER =====
private function Init takes nothing returns nothing
    local trigger t = CreateTrigger()
    // Track deaths
    call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(t, function UnitDeathHandler)
endfunction

endlibrary
