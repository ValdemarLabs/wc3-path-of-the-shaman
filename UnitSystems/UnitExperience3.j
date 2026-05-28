library UnitExperience initializer Init requires Table, UnitDeathEvent
/*
    UnitExperience
    Version: 3.0
    Author: Valdemar

    Requires:
        - Table by Briebe
        - CustomStats defined in the WC3 map
        - Global variables udg_Nazgrek and udg_Zulkis)
        - UnitIndexer

    Description:
    This script implements a custom experience and leveling system for units in Warcraft III.
    Units gain experience when nearby either hero (Nazgrek or Zulkis) upon killing an enemy unit.
    Upon leveling up, units receive stat boosts to HP, Armor, Damage, and Regen.
    The experience required to level up increases with each level.
    The system supports up to MAX_LEVEL levels and can be toggled on or off for individual units.
    It also includes custom secondary stats (Block, Crit, Dodge, Hit) that increase with each level.

    Note:
    Specially crafted for "Path of The Shaman" map

*/

globals
    private constant boolean    DEBUG_MODE              = false // Set to true to enable debug messages
    private constant integer    MAX_LEVEL               = 30
    private constant real       RANGE                   = 1200.0
    private constant real       RANGE_SQ                = RANGE * RANGE
    private constant integer    XP_BASE                 = 200
    private constant integer    XP_FACTOR               = 150

    // Unit-type constants - MODIFY AS NEEDED
    private constant integer    SHADOWCLAW              = 'n655' // Special handling for unit-type Shadowclaw
    // Turtles
    private constant integer    GIANTSEATURTLE          = 'nrtg'
    private constant integer    GIANTSEATURTLE_15       = 'n01G'
    private constant integer    GARGSEATURTLE           = 'ntrt'
    private constant integer    SEATURTLE               = 'ntrs'
    private constant integer    SEATURTLE_10            = 'n01F'
    private constant integer    SEATURTLEHATCH          = 'ntrh'

    // Tigers, panthers
    private constant integer    TIGER_2                 = 'n61P'
    private constant integer    TIGER_10                = 'n017'
    private constant integer    TIGER_15                = 'n018'


    // Wolves
    private constant integer    TIMBERWOLF              = 'nwlt'
    private constant integer    DIREWOLF                = 'nwld'
    private constant integer    GIANTWOLF               = 'nwlg'

    // Bears
    private constant integer    BEARCLUB                = 'ngz1'
    private constant integer    BEAR                    = 'ngz2'
    private constant integer    FEROBEAR                = 'ngza'

    // Add more unit-type constants as needed...
    //private constant integer    XXX                = 'xxxx'

    private Table xp
    private Table level
    private Table registered
    private Table xpDisabled
    private Table baseHP
    private Table baseArmor
    private Table baseMinDmg
    private Table baseMaxDmg
    private Table baseRegen

    private group ENUM_GROUP = CreateGroup() // Manual global group for reuse
endglobals

//===================== STAT PROFILE SYSTEM =====================

/**
 * Struct to hold stat multipliers and bonus stats per level
*/
private struct StatProfile
    real hpMult
    real armorMult
    real dmgMult
    real regenMult
    integer blockBonus
    integer critBonus
    integer dodgeBonus
    integer hitBonus
    
    /**
     * Creates a generic/default stat profile
    */
    static method createGeneric takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.hpMult      = 1.12
        set this.armorMult   = 1.05
        set this.dmgMult     = 1.09
        set this.regenMult   = 1.05
        set this.blockBonus  = 1
        set this.critBonus   = 1
        set this.dodgeBonus  = 2
        set this.hitBonus    = 1
        return this
    endmethod
    
    /**
     * Creates a tanky profile (Turtle)
     * High HP, Armor, Block, Dodge. Low damage.
    */
    static method createTank takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.hpMult      = 1.15    // +15% HP per level
        set this.armorMult   = 1.08    // +8% Armor per level
        set this.dmgMult     = 1.05    // +5% Damage per level (low)
        set this.regenMult   = 1.06
        set this.blockBonus  = 3       // +3 Block per level
        set this.critBonus   = 0       // No Crit
        set this.dodgeBonus  = 4       // +4 Dodge per level
        set this.hitBonus    = 1
        return this
    endmethod
    
    /**
     * Creates a damage profile (Tiger)
     * High Crit, Damage, Hit. Low HP/Armor.
    */
    static method createDamage takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.hpMult      = 1.08    // +8% HP per level (low)
        set this.armorMult   = 1.03    // +3% Armor per level (low)
        set this.dmgMult     = 1.14    // +14% Damage per level (high)
        set this.regenMult   = 1.04
        set this.blockBonus  = 0       // No Block
        set this.critBonus   = 4       // +4 Crit per level
        set this.dodgeBonus  = 1       // +1 Dodge per level
        set this.hitBonus    = 3       // +3 Hit per level
        return this
    endmethod
    
    /**
     * Creates a balanced profile (Wolf)
     * Balanced stats, focus on Dodge and Hit
    */
    static method createBalanced takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.hpMult      = 1.10
        set this.armorMult   = 1.05
        set this.dmgMult     = 1.10
        set this.regenMult   = 1.05
        set this.blockBonus  = 1
        set this.critBonus   = 2
        set this.dodgeBonus  = 3       // +3 Dodge per level
        set this.hitBonus    = 2       // +2 Hit per level
        return this
    endmethod
    
    /**
     * Creates a bruiser profile (Bear)
     * High HP, Damage, moderate defense
    */
    static method createBruiser takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.hpMult      = 1.13    // +13% HP per level
        set this.armorMult   = 1.04
        set this.dmgMult     = 1.11    // +11% Damage per level
        set this.regenMult   = 1.07
        set this.blockBonus  = 2
        set this.critBonus   = 2
        set this.dodgeBonus  = 1
        set this.hitBonus    = 2
        return this
    endmethod
endstruct

/**
 * Returns the appropriate stat profile for a unit type.
 * If unit type is not predefined, returns generic profile.
 * 
 * @param unitTypeId - The unit type ID to check
 * @return StatProfile for the unit type
*/
private function GetStatProfile takes integer unitTypeId returns StatProfile
    // TANK UNITS - High HP, Armor, Block, Dodge. Low Damage.
    if unitTypeId == GIANTSEATURTLE then
        return StatProfile.createTank()
    elseif unitTypeId == GIANTSEATURTLE_15 then
        return StatProfile.createTank()
    elseif unitTypeId == GARGSEATURTLE then
        return StatProfile.createTank()        
    elseif unitTypeId == SEATURTLE then
        return StatProfile.createTank()   
    elseif unitTypeId == SEATURTLE_10 then
        return StatProfile.createTank()           
    elseif unitTypeId == SEATURTLEHATCH then
        return StatProfile.createTank()  

    // Add more tank units here:
    // elseif unitTypeId == TURTLE2 then
    //     return StatProfile.createTank()
    // elseif unitTypeId == STONEGOLEM the
    //     return StatProfile.createTank()
    
    // DAMAGE UNITS - High Crit, Damage, Hit. Low HP/Armor.
    elseif unitTypeId == TIGER_2 then
        return StatProfile.createDamage()
    elseif unitTypeId == TIGER_10 then
        return StatProfile.createDamage()
    elseif unitTypeId == TIGER_15 then
        return StatProfile.createDamage()

    // Add more damage units here:
    // elseif unitTypeId == PANTHER then
    //     return StatProfile.createDamage()
    // elseif unitTypeId == PANTHER2 then 
    //     return StatProfile.createDamage()
    
    // BALANCED UNITS - Balanced stats, focus on Dodge and Hit
    elseif unitTypeId == TIMBERWOLF then
        return StatProfile.createBalanced()
    elseif unitTypeId == DIREWOLF then
        return StatProfile.createBalanced()
    elseif unitTypeId == GIANTWOLF then
        return StatProfile.createBalanced()

    // Add more balanced units here:
    // elseif unitTypeId == WOLF2 then 
    //     return StatProfile.createBalanced()
    // elseif unitTypeId == WOLF3 then 
    //     return StatProfile.createBalanced()
    
    // BRUISER UNITS - High HP, Damage, moderate defense
    elseif unitTypeId == BEAR then
        return StatProfile.createBruiser()
    elseif unitTypeId == BEARCLUB then
        return StatProfile.createBruiser()
    elseif unitTypeId == FEROBEAR then
        return StatProfile.createBruiser()

    // Add more bruiser units here:
    // elseif unitTypeId == BEAR2 then 
    //     return StatProfile.createBruiser()
    // elseif unitTypeId == BEAR3 then
    //     return StatProfile.createBruiser()

    // Create more profiles as needed...
    
    // DEFAULT - Generic balanced profile for unlisted unit types
    else
        return StatProfile.createGeneric()
    endif
endfunction

//===================== INTERNAL UTILS =====================
/* Checks if unit u is within RANGE of either hero (Nazgrek or Zulkis)
 * owned by Player(0).
 * 
 * @param u - The unit to check
 * @return true if unit is within range of either hero, false otherwise
*/
private function IsNearbyHero takes unit u returns boolean
    local real dx
    local real dy

    if GetOwningPlayer(udg_Nazgrek) == Player(0) then
        set dx = GetUnitX(u) - GetUnitX(udg_Nazgrek)
        set dy = GetUnitY(u) - GetUnitY(udg_Nazgrek)
        if dx*dx + dy*dy <= RANGE_SQ then
            return true
        endif
    endif
    if GetOwningPlayer(udg_Zulkis) == Player(0) then
        set dx = GetUnitX(u) - GetUnitX(udg_Zulkis)
        set dy = GetUnitY(u) - GetUnitY(udg_Zulkis)
        if dx*dx + dy*dy <= RANGE_SQ then
            return true
        endif
    endif
    return false
endfunction

/**
 * Calculates the XP required to advance from a given level to the next.
 * Uses formula: XP_BASE + XP_FACTOR * (lvl - 1)
 * 
 * @param lvl - The current level
 * @return The amount of XP required to reach the next level
*/
private function XPRequired takes integer lvl returns integer
    return XP_BASE + XP_FACTOR * (lvl - 1)
endfunction

//===================== STAT SCALING =====================
/**
 * Scales unit stats (HP, Armor, Damage, Regen, Block, Crit, Dodge, Hit)
 * based on the new level. Uses multiplicative scaling per level.
 * 
 * @param u - The unit to scale
 * @param newLevel - The new level the unit has reached
*/
//===================== STAT SCALING =====================
/**
 * Scales unit stats (HP, Armor, Damage, Regen, Block, Crit, Dodge, Hit)
 * based on the new level and unit type. Uses unit-specific stat profiles.
 * 
 * @param u - The unit to scale
 * @param newLevel - The new level the unit has reached
*/
private function ScaleUnitStats takes unit u, integer newLevel returns nothing
    local integer id = GetUnitUserData(u)
    local integer CV = id
    local integer unitTypeId = GetUnitTypeId(u)
    local StatProfile profile = GetStatProfile(unitTypeId)
    local real oldMaxLife
    local real newMaxLife
    local real newArmor
    local real newMinDmg
    local real newMaxDmg

    // Initialize base HP if first time
    if not baseHP.has(id) then
        set baseHP.real[id] = GetUnitState(u, UNIT_STATE_MAX_LIFE)
    endif

    // Scale HP
    set oldMaxLife = GetUnitState(u, UNIT_STATE_MAX_LIFE)
    set newMaxLife = oldMaxLife * profile.hpMult

    call BlzSetUnitMaxHP(u, R2I(newMaxLife))
    call SetUnitState(u, UNIT_STATE_LIFE, newMaxLife)
    
    set baseHP.real[id] = baseHP.real[id] * profile.hpMult
    call SetUnitState(u, UNIT_STATE_LIFE, GetUnitState(u, UNIT_STATE_LIFE) * profile.hpMult)

    // Scale Regen
    if not baseRegen.has(id) then
        set baseRegen.real[id] = 0.0
    endif
    set baseRegen.real[id] = baseRegen.real[id] * profile.regenMult
    call SetUnitState(u, UNIT_STATE_LIFE, GetUnitState(u, UNIT_STATE_LIFE) + (oldMaxLife * (profile.regenMult - 1.0)))

    // Custom secondary stats - use profile bonuses
    if CV > 0 then
        set udg_Stats_Block[CV] = udg_Stats_Block[CV] + profile.blockBonus
        set udg_Stats_Crit[CV]  = udg_Stats_Crit[CV]  + profile.critBonus
        set udg_Stats_Dodge[CV] = udg_Stats_Dodge[CV] + profile.dodgeBonus
        set udg_Stats_Hit[CV]   = udg_Stats_Hit[CV]   + profile.hitBonus
        
        if DEBUG_MODE then
            call BJDebugMsg(GetUnitName(u) + " gains +" + I2S(profile.blockBonus) + " Block, +" + I2S(profile.critBonus) + " Crit, +" + I2S(profile.dodgeBonus) + " Dodge, +" + I2S(profile.hitBonus) + " Hit from level-up.")
        endif
    endif

    // BLZ enhancements for armor/damage
    if not baseArmor.has(id) then
        set baseArmor.real[id]   = BlzGetUnitArmor(u)
        set baseMinDmg.real[id]  = BlzGetUnitBaseDamage(u, 0)
        set baseMaxDmg.real[id]  = BlzGetUnitDiceSides(u, 0) + baseMinDmg.real[id]
    endif

    // compute new armor/damage/regens using multiplicative growth
    set newArmor  = baseArmor.real[id] * profile.armorMult
    set newMinDmg = baseMinDmg.real[id] * profile.dmgMult
    set newMaxDmg = baseMaxDmg.real[id] * profile.dmgMult

    call BlzSetUnitArmor(u, newArmor)
    call BlzSetUnitBaseDamage(u, R2I(newMinDmg), 0)
    call BlzSetUnitDiceSides(u, R2I(newMaxDmg - newMinDmg), 0)
    call BlzSetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE, baseRegen.real[id] * profile.regenMult)

    // Clean up profile
    call profile.destroy()

    //if DEBUG_MODE then
    //    call BJDebugMsg("ScaleUnitStats applied to " + GetUnitName(u) + " (CV " + I2S(id) + "). Level: " + I2S(newLevel))
    //endif
endfunction

//===================== CORE LOGIC =====================
/**
 * Adds XP to a unit and handles level-up logic if enough XP is gained.
 * Scales unit stats for each level gained.
 * 
 * @param u - The unit to add XP to
 * @param amount - The amount of XP to add
*/
private function AddXP takes unit u, integer amount returns nothing
    local integer id = GetUnitUserData(u)
    local string a = null
    local string b = null
    local string c = null
    local string d = null
    local string e = null
    local string f = null

    if id == 0 or xpDisabled.boolean[id] or level.integer[id] >= MAX_LEVEL then
        return
    endif

    set xp.integer[id] = xp.integer[id] + amount

    call ArcingTextTag.createEx("+" + I2S(amount) + " XP", u, 1.0, 0.5, GetLocalPlayer(), 0.7, 0.7, 1.0)
    //if DEBUG_MODE then
    //    call BJDebugMsg("XP Added: " + I2S(amount) + " to " + GetUnitName(u) + ". Total XP: " + I2S(xp.integer[id]))
    //endif

    loop
        exitwhen level.integer[id] >= MAX_LEVEL or xp.integer[id] < XPRequired(level.integer[id])
        set xp.integer[id] = xp.integer[id] - XPRequired(level.integer[id])
        set level.integer[id] = level.integer[id] + 1

        call BlzSetUnitIntegerField(u, UNIT_IF_LEVEL, GetUnitLevel(u) + 1)
        call TriggerExecute(gg_trg_MultiboardUpdateLevelTamed)

        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Levelup\\LevelupCaster.mdl", u, "origin"))
        call StartSound(bj_questCompletedSound)

        // ShowTitle
        set a = "|cffffcc00"
        set b = GetUnitName(u)
        set c = "|r has reached Level |cffffcc00"
        set d = I2S(level.integer[id])
        set e = "|r"
        set f = a + b + c + d + e
        call ShowSingleLineText(f, 0.5, 3, 1.5, 1.5)

        if DEBUG_MODE then
            call BJDebugMsg("Pet Leveled Up: " + GetUnitName(u) + ". New Level: " + I2S(level.integer[id]))
        endif

        // Modify stats of the unit
        call ScaleUnitStats(u, level.integer[id])
    endloop
endfunction

/**
 * Removes a unit from the XP system.
 * Clears all stored data for the unit.
 * 
 * @param u - The unit to remove
*/
public function DeregisterUnit takes unit u returns nothing
    local integer id = GetUnitUserData(u)
    
    // Only deregister if unit is actually registered
    if id > 0 and registered.boolean[id] then
        call xp.remove(id)
        call level.remove(id)
        call registered.remove(id)
        call xpDisabled.remove(id)
        call baseHP.remove(id)
        call baseArmor.remove(id)
        call baseMinDmg.remove(id)
        call baseMaxDmg.remove(id)
        call baseRegen.remove(id)
        //if DEBUG_MODE then
        //    call BJDebugMsg("Unit Removed from XP System: " + GetUnitName(u))
        //endif
    endif
endfunction

/**
 * Filter function for GroupEnumUnitsInRange.
 * Only includes registered units that are alive.
 * 
 * @return true if unit should be included in enumeration, false otherwise
*/
private function FilterRegisteredUnits takes nothing returns boolean
    local unit u = GetFilterUnit()
    local integer id = GetUnitUserData(u)
    
    // Only check units that are registered and not dead
    return id > 0 and registered.boolean[id] and GetUnitState(u, UNIT_STATE_LIFE) > 0
endfunction

/**
 * Callback function used with ForGroup.
 * Adds XP to enumerated unit if it's near a hero and not the dying unit.
*/
private function AddXPToNearbyUnits takes nothing returns nothing
    local unit u = GetEnumUnit()
    local unit dying = GetDyingUnit()
    local integer id = GetUnitUserData(u)

    // Unit is already filtered as registered, now just check if near hero
    if IsNearbyHero(u) and u != dying then
        call AddXP(u, GetUnitLevel(dying))
    endif
endfunction

/**
 * Event handler for EVENT_PLAYER_UNIT_DEATH.
 * Distributes XP to nearby registered units when a non-registered unit dies.
 * Prevents XP grants if:
 * - Dying unit is registered (XP units don't give XP)
 * - Dying unit has Locust ability
 * - Killer is the dying unit itself
*/
private function UnitDeathHandler takes nothing returns nothing
    local unit dying = GetDyingUnit()
    local unit killer = GetKillingUnit()
    local integer dyingId = GetUnitUserData(dying)
    local boolexpr filter

    // Don't grant XP if dying unit is registered (XP units don't give XP when they die)
    if dyingId > 0 and registered.boolean[dyingId] then
        //if DEBUG_MODE then
        //    call BJDebugMsg("Registered XP unit died - no XP granted: " + GetUnitName(dying))
        //endif

        // Remove registered unit from system when it dies (except Shadowclaw)
        if GetUnitTypeId(dying) != SHADOWCLAW then
            call DeregisterUnit(dying)
        endif
        
        return
    endif

    // Don't grant XP if dying unit has Locust
    if GetUnitAbilityLevel(dying, 'Aloc') > 0 then
        return
    endif

    // Don't grant XP if killer is the dying unit itself
    if killer == dying then
        return
    endif

    // Use filter to only enumerate registered units
    set filter = Filter(function FilterRegisteredUnits)
    call GroupEnumUnitsInRange(ENUM_GROUP, GetUnitX(dying), GetUnitY(dying), RANGE, filter)
    call ForGroup(ENUM_GROUP, function AddXPToNearbyUnits)
    call GroupClear(ENUM_GROUP)
    call DestroyBoolExpr(filter)
endfunction

/**
 * Registers a unit to the XP system.
 * Initializes the unit's XP based on its current level.
 * 
 * @param u - The unit to register
*/
public function RegisterUnit takes unit u returns nothing
    local integer id = GetUnitUserData(u)
    local integer currentLevel
    local integer i
    local integer totalXP = 0

    if id == 0 then
        //if DEBUG_MODE then
        //    call BJDebugMsg("ERROR: Cannot register unit with Custom Value 0: " + GetUnitName(u))
        //endif
        return
    endif

    if not registered.boolean[id] then
        set currentLevel = GetUnitLevel(u)
        if currentLevel < 1 then
            set currentLevel = 1
        endif

        // Start with 0 XP at the current level (unit begins fresh at their current level)
        // This prevents immediate level-ups upon registration
        set xp.integer[id] = 0
        set level.integer[id] = currentLevel
        set registered.boolean[id] = true
        set xpDisabled.boolean[id] = false

        //if DEBUG_MODE then
        //    call BJDebugMsg("Unit Registered for XP: " + GetUnitName(u) + " (CV " + I2S(id) + ", Level " + I2S(currentLevel) + ")")
        //    call BJDebugMsg("Initialized XP to: 0 (starting fresh at current level)")
        //endif
    else
        //if DEBUG_MODE then
        //    call BJDebugMsg("Unit already registered: " + GetUnitName(u) + " (CV " + I2S(id) + ")")
        //endif
    endif
endfunction

/**
 * Enables or disables XP gain for a registered unit.
 * When disabled, unit will not receive any XP from kills.
 * 
 * @param u - The unit to modify
 * @param flag - true to disable XP, false to enable XP
*/
public function DisableXP takes unit u, boolean flag returns nothing
    local integer id = GetUnitUserData(u)
    if id > 0 and registered.boolean[id] then
        set xpDisabled.boolean[id] = flag
        //if DEBUG_MODE then
        //    if flag then
        //        call BJDebugMsg("XP Disabled for: " + GetUnitName(u))
        //    else
        //        call BJDebugMsg("XP Enabled for: " + GetUnitName(u))
        //    endif
        //endif
    endif
endfunction

/**
 * Gets the current XP of a unit.
 * 
 * @param u - The unit to query
 * @return The unit's current XP amount
*/
public function GetUnitXP takes unit u returns integer
    return xp.integer[GetUnitUserData(u)]
endfunction

/**
 * Gets the amount of XP required for a unit to reach the next level.
 * 
 * @param u - The unit to query
 * @return The XP needed to level up, or 0 if at max level
*/
public function GetUnitXPToNextLevel takes unit u returns integer
    local integer id = GetUnitUserData(u)
    local integer lvl = level.integer[id]

    if lvl >= MAX_LEVEL then
        return 0
    endif
    return XPRequired(lvl) - xp.integer[id]
endfunction

/**
 * Checks if a unit is registered in the XP system.
 * 
 * @param u - The unit to check
 * @return true if unit is registered, false otherwise
*/
public function IsUnitRegistered takes unit u returns boolean
    local integer id = GetUnitUserData(u)
    local boolean isReg = false
    local string status = "false"

    if u == null or id == 0 then
        //if DEBUG_MODE then
        //    call BJDebugMsg("IsUnitRegistered: null unit or CV=0")
        //endif
        return false
    endif

    set isReg = registered.boolean[id]

    if isReg then
        set status = "true"
    else
        set status = "false"
    endif

    //if DEBUG_MODE then
    //    call BJDebugMsg("Checking registration for: " + GetUnitName(u) + " (CV: " + I2S(id) + ") -> " + status)
    //endif

    return isReg
endfunction

/**
 * Forces a unit to level up a specified number of times, ignoring XP requirements.
 * Useful for GM commands, special events, or testing.
 * 
 * @param u - The unit to level up
 * @param levels - The number of levels to gain (default 1)
*/
public function ForceLevelUp takes unit u, integer levels returns nothing
    local integer id = GetUnitUserData(u)
    local integer i = 0
    local integer startLevel
    local integer endLevel

    // Validation checks
    if id == 0 then
        if DEBUG_MODE then
            call BJDebugMsg("ERROR: Cannot force level up - unit has Custom Value 0: " + GetUnitName(u))
        endif
        return
    endif

    if not registered.boolean[id] then
        if DEBUG_MODE then
            call BJDebugMsg("ERROR: Cannot force level up - unit not registered: " + GetUnitName(u))
        endif
        return
    endif

    if level.integer[id] >= MAX_LEVEL then
        if DEBUG_MODE then
            call BJDebugMsg("Cannot force level up - unit already at max level: " + GetUnitName(u))
        endif
        return
    endif

    if levels < 1 then
        set levels = 1
    endif

    set startLevel = level.integer[id]
    
    // Level up the specified number of times (or until MAX_LEVEL)
    loop
        exitwhen i >= levels or level.integer[id] >= MAX_LEVEL
        
        set level.integer[id] = level.integer[id] + 1
        call BlzSetUnitIntegerField(u, UNIT_IF_LEVEL, GetUnitLevel(u) + 1)
        call TriggerExecute(gg_trg_MultiboardUpdateLevelTamed)

        // Visual and audio effects
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Levelup\\LevelupCaster.mdl", u, "origin"))
        if i == 0 then
            call StartSound(bj_questCompletedSound)
        endif

        if DEBUG_MODE then
            call BJDebugMsg("Force Level Up: " + GetUnitName(u) + ". New Level: " + I2S(level.integer[id]))
        endif

        // Apply stat scaling
        call ScaleUnitStats(u, level.integer[id])
        
        set i = i + 1
    endloop

    set endLevel = level.integer[id]
    
    if endLevel > startLevel then
        call ArcingTextTag.createEx("Level Up!", u, 1.5, 0.5, GetLocalPlayer(), 1.0, 0.84, 0.0)
        if DEBUG_MODE then
            call BJDebugMsg(GetUnitName(u) + " forced to level " + I2S(endLevel) + " (gained " + I2S(endLevel - startLevel) + " levels)")
        endif
    endif
endfunction

//===================== INITIALIZER =====================
/**
 * Initializes the UnitExperience system.
 * Creates all required Tables and registers the unit death event.
*/
private function Init takes nothing returns nothing
    set xp          = Table.create()
    set level       = Table.create()
    set registered  = Table.create()
    set xpDisabled  = Table.create()
    set baseHP      = Table.create()
    set baseArmor   = Table.create()
    set baseMinDmg  = Table.create()
    set baseMaxDmg  = Table.create()
    set baseRegen   = Table.create()

    // Register with centralized death event system
    call UnitDeathEvent_Register(function UnitDeathHandler)
    if DEBUG_MODE then
        call BJDebugMsg("[UnitExperience] Registered with centralized death event system")
    endif
endfunction

endlibrary
