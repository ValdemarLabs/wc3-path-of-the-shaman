library UnitStats initializer Init requires Table, TimerUtils, optional UnitIndexer

/*
    UnitStats 1.0 - Optimized Event-Driven Version
    
    Author: Valdemar

    Intended use:
    - Attach stat abilities (Hit, Dodge, Crit, Block, Spell Power) to units without items (basically all non-Hero units)
    
    Features:
    - Manages Hit, Dodge, Crit, Block, and Spell Power stats
    - Uses Bribe's Table for efficient storage
    - Event-driven processing (NO PERIODIC LAG!)
    - Only processes units with Stats_Yes ability (filtering)
    - Each unit processed once on spawn (no redundant checks)
    - Handles stat abilities from 5% to 100%
    
    Requirements:
    - Table by Bribe
    - TimerUtils by Vexorian
    - (Optional) UnitIndexer for Custom Value support
    
    How it works:
    - Pre-placed units scanned once at map start (2 second delay)
    - For spawned units, call UnitStats_ProcessUnit(unit) from your spawn trigger
    - Uses Table for O(1) lookup performance
    - One-time stat application per ability
    
    Integration:
    Add this to your "Unit Enters Playable Map Area" trigger:
        Custom script: call UnitStats_ProcessUnit(GetTriggerUnit())
    
    API Functions:
    - UnitStats_ProcessUnit(unit)     - Process a unit's stats (safe to call multiple times)
    - UnitStats_RefreshUnit(unit)     - Force reprocess if stats changed
    - UnitStats_SetDebugEnabled(bool) - Toggle debug messages
    - UnitStats_GetProcessedCount()   - Get total units processed
    - UnitStats_InitialScan()         - Manually trigger initial scan (optional)
*/

globals
    // OPTIMIZATION: Changed from periodic scanning to event-driven processing
    // No more CHECK_INTERVAL - units are processed once when they spawn/gain ability
    private constant real INITIAL_SCAN_DELAY = 2.0  // One-time scan at map start
    
    // Stat ability IDs - CONFIGURE THESE TO MATCH YOUR MAP
    private constant integer ABILITY_STATS_YES = 'A002'  // Marker ability
    
    // Dodge abilities (1-100%)
    private constant integer ABILITY_DODGE_1   = 'A64O'
    private constant integer ABILITY_DODGE_2   = 'A64P'
    private constant integer ABILITY_DODGE_3   = 'A64Q'
    private constant integer ABILITY_DODGE_4   = 'A64R'
    private constant integer ABILITY_DODGE_5   = 'A64S'
    private constant integer ABILITY_DODGE_10  = 'A6EQ'
    private constant integer ABILITY_DODGE_15  = 'A6ER'
    private constant integer ABILITY_DODGE_20  = 'A6ES'
    private constant integer ABILITY_DODGE_25  = 'A6ET'
    private constant integer ABILITY_DODGE_30  = 'A6EU'
    private constant integer ABILITY_DODGE_35  = 'A011'
    private constant integer ABILITY_DODGE_40  = 'A012'
    private constant integer ABILITY_DODGE_50  = 'A013'
    private constant integer ABILITY_DODGE_60  = 'A014'
    private constant integer ABILITY_DODGE_75  = 'A015'
    private constant integer ABILITY_DODGE_90  = 'A016'
    private constant integer ABILITY_DODGE_100 = 'A017'
    
    // Crit abilities (1-100%)
    private constant integer ABILITY_CRIT_1    = 'A64E'
    private constant integer ABILITY_CRIT_2    = 'A64F'
    private constant integer ABILITY_CRIT_3    = 'A64G'
    private constant integer ABILITY_CRIT_4    = 'A64H'
    private constant integer ABILITY_CRIT_5    = 'A64I'
    private constant integer ABILITY_CRIT_10   = 'A01F'
    private constant integer ABILITY_CRIT_15   = 'A01H'
    private constant integer ABILITY_CRIT_20   = 'A01I'
    private constant integer ABILITY_CRIT_25   = 'A01J'
    private constant integer ABILITY_CRIT_30   = 'A01K'
    private constant integer ABILITY_CRIT_35   = 'A01L'
    private constant integer ABILITY_CRIT_40   = 'A01M'
    private constant integer ABILITY_CRIT_50   = 'A01N'
    private constant integer ABILITY_CRIT_60   = 'A01O'
    private constant integer ABILITY_CRIT_75   = 'A01P'
    private constant integer ABILITY_CRIT_90  = 'A01Q'
    private constant integer ABILITY_CRIT_100  = 'A01R'
    
    // Block abilities (1-100%)
    private constant integer ABILITY_BLOCK_1   = 'A64J'
    private constant integer ABILITY_BLOCK_2   = 'A64K'
    private constant integer ABILITY_BLOCK_3   = 'A64L'
    private constant integer ABILITY_BLOCK_4   = 'A64M'
    private constant integer ABILITY_BLOCK_5   = 'A64N'
    private constant integer ABILITY_BLOCK_10  = 'A6EW'
    private constant integer ABILITY_BLOCK_15  = 'A6EX'
    private constant integer ABILITY_BLOCK_20  = 'A6EY'
    private constant integer ABILITY_BLOCK_25  = 'A6EZ'
    private constant integer ABILITY_BLOCK_30  = 'A6F0'
    private constant integer ABILITY_BLOCK_35  = 'A6F7'
    private constant integer ABILITY_BLOCK_40  = 'A00V'
    private constant integer ABILITY_BLOCK_50  = 'A00W'
    private constant integer ABILITY_BLOCK_60  = 'A00X'
    private constant integer ABILITY_BLOCK_75  = 'A00Y'
    private constant integer ABILITY_BLOCK_90  = 'A00Z'
    private constant integer ABILITY_BLOCK_100 = 'A64T'
    
    // Spell Power abilities (1-100%)
    private constant integer ABILITY_SPELL_1   = 'A06M'
    private constant integer ABILITY_SPELL_2   = 'A06N'
    private constant integer ABILITY_SPELL_3   = 'A06O'
    private constant integer ABILITY_SPELL_4   = 'A06P'
    private constant integer ABILITY_SPELL_5   = 'A6F1'
    private constant integer ABILITY_SPELL_10  = 'A6F2'
    private constant integer ABILITY_SPELL_15  = 'A6F3'
    private constant integer ABILITY_SPELL_20  = 'A6F4'
    private constant integer ABILITY_SPELL_25  = 'A6F5'
    private constant integer ABILITY_SPELL_30  = 'A6F6'
    private constant integer ABILITY_SPELL_35  = 'A018'
    private constant integer ABILITY_SPELL_40  = 'A019'
    private constant integer ABILITY_SPELL_50  = 'A01A'
    private constant integer ABILITY_SPELL_60  = 'A01B'
    private constant integer ABILITY_SPELL_75  = 'A01C'
    private constant integer ABILITY_SPELL_90  = 'A01D'
    private constant integer ABILITY_SPELL_100 = 'A01E'
    
    // Spell Power Flat abilities (1-300)
    private constant integer ABILITY_SPELLFLAT_1   = 'A090'
    private constant integer ABILITY_SPELLFLAT_5   = 'A08Z'
    private constant integer ABILITY_SPELLFLAT_10  = 'A08Y'
    private constant integer ABILITY_SPELLFLAT_25  = 'A08X'
    private constant integer ABILITY_SPELLFLAT_50  = 'A08W'
    private constant integer ABILITY_SPELLFLAT_100 = 'A08V'
    private constant integer ABILITY_SPELLFLAT_300 = 'A091'
    
    // Hit abilities
    private constant integer ABILITY_HIT_1     = 'A649'
    private constant integer ABILITY_HIT_2     = 'A64A'
    private constant integer ABILITY_HIT_3     = 'A64C'
    private constant integer ABILITY_HIT_4     = 'A64D'
    private constant integer ABILITY_HIT_5     = 'A64B'
    private constant integer ABILITY_HIT_10    = 'A04I'
    private constant integer ABILITY_HIT_15    = 'A04J'
    private constant integer ABILITY_HIT_20    = 'A04K'
    private constant integer ABILITY_HIT_25    = 'A04L'
    private constant integer ABILITY_HIT_30    = 'A04M'
    private constant integer ABILITY_HIT_35    = 'A04N'
    private constant integer ABILITY_HIT_40    = 'A04O'
    private constant integer ABILITY_HIT_50    = 'A04P'
    private constant integer ABILITY_HIT_60    = 'A04Q'
    private constant integer ABILITY_HIT_75    = 'A04R'
    private constant integer ABILITY_HIT_90    = 'A04S'
    private constant integer ABILITY_HIT_100   = 'A04T'
    
    // Tables for stat tracking (flags to prevent duplicate application)
    private Table dodgeApplied
    private Table critApplied
    private Table blockApplied
    private Table spellApplied
    private Table spellFlatApplied
    private Table hitApplied
    
    // OPTIMIZATION: Track which units have been processed to avoid reprocessing
    private Table processedUnits  // [unitId] = 1 if already processed
    
    // Timer data storage for hero recalculation
    private Table timerHeroData  // [unitId] = unit handle for delayed recalculation
    
    // Reusable group
    private group tempGroup = CreateGroup()
    
    // Debug settings
    private boolean debugEnabled = false
    private integer statsProcessed = 0  // Track total units processed
endglobals

//===================== UTILITY FUNCTIONS =====================

/**
 * Gets unit custom value using UnitIndexer
 */
private function GetUnitId takes unit u returns integer
    return GetUnitUserData(u)
endfunction

/**
 * Enables or disables debug messages
 */
function UnitStats_SetDebugEnabled takes boolean enable returns nothing
    set debugEnabled = enable
endfunction

/**
 * OPTIMIZED: Get total number of units processed by the system
 */
function UnitStats_GetProcessedCount takes nothing returns integer
    return statsProcessed
endfunction

//===================== STAT APPLICATION =====================

/**
 * Applies dodge stat to a unit (one-time per ability)
 */
private function ApplyDodgeStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId  // Unique key per unit per ability
    
    if dodgeApplied[key] == 0 then
        set udg_Stats_Dodge[id] = udg_Stats_Dodge[id] + value
        set dodgeApplied[key] = 1
        
        if debugEnabled then
            //call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " gained +" + I2S(value) + " Dodge")
        endif
    endif
endfunction

/**
 * Applies crit stat to a unit (one-time per ability)
 */
private function ApplyCritStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId
    
    if critApplied[key] == 0 then
        set udg_Stats_Crit[id] = udg_Stats_Crit[id] + value
        set critApplied[key] = 1
        
        if debugEnabled then
            //call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " gained +" + I2S(value) + " Crit")
        endif
    endif
endfunction

/**
 * Applies block stat to a unit (one-time per ability)
 */
private function ApplyBlockStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId
    
    if blockApplied[key] == 0 then
        set udg_Stats_Block[id] = udg_Stats_Block[id] + value
        set blockApplied[key] = 1
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " gained +" + I2S(value) + " Block")
        endif
    endif
endfunction

/**
 * Applies spell power stat to a unit (one-time per ability)
 */
private function ApplySpellStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId
    
    if spellApplied[key] == 0 then
        set udg_Stats_SpellPowerPct[id] = udg_Stats_SpellPowerPct[id] + value
        set spellApplied[key] = 1
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " gained +" + I2S(value) + " Spell Power%")
        endif
    endif
endfunction

/**
 * Applies spell power flat stat to a unit (one-time per ability)
 */
private function ApplySpellFlatStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId
    
    if spellFlatApplied[key] == 0 then
        set udg_Stats_SpellPowerFlat[id] = udg_Stats_SpellPowerFlat[id] + value
        set spellFlatApplied[key] = 1
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " gained +" + I2S(value) + " Spell Power Flat")
        endif
    endif
endfunction

/**
 * Applies hit stat to a unit (one-time per ability)
 */
private function ApplyHitStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId
    
    if hitApplied[key] == 0 then
        set udg_Stats_Hit[id] = udg_Stats_Hit[id] + value
        set hitApplied[key] = 1
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " gained +" + I2S(value) + " Hit")
        endif
    endif
endfunction

//===================== STAT REMOVAL (FOR ITEM DROPS) =====================

/**
 * Removes dodge stat from a unit (for item drops)
 */
private function RemoveDodgeStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId
    
    if dodgeApplied[key] == 1 then
        set udg_Stats_Dodge[id] = udg_Stats_Dodge[id] - value
        set dodgeApplied[key] = 0
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " lost -" + I2S(value) + " Dodge")
        endif
    endif
endfunction

/**
 * Removes crit stat from a unit (for item drops)
 */
private function RemoveCritStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId
    
    if critApplied[key] == 1 then
        set udg_Stats_Crit[id] = udg_Stats_Crit[id] - value
        set critApplied[key] = 0
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " lost -" + I2S(value) + " Crit")
        endif
    endif
endfunction

/**
 * Removes block stat from a unit (for item drops)
 */
private function RemoveBlockStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId
    
    if blockApplied[key] == 1 then
        set udg_Stats_Block[id] = udg_Stats_Block[id] - value
        set blockApplied[key] = 0
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " lost -" + I2S(value) + " Block")
        endif
    endif
endfunction

/**
 * Removes spell power stat from a unit (for item drops)
 */
private function RemoveSpellStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId
    
    if spellApplied[key] == 1 then
        set udg_Stats_SpellPowerPct[id] = udg_Stats_SpellPowerPct[id] - value
        set spellApplied[key] = 0
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " lost -" + I2S(value) + " Spell Power%")
        endif
    endif
endfunction

/**
 * Removes spell power flat stat from a unit (for item drops)
 */
private function RemoveSpellFlatStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId
    
    if spellFlatApplied[key] == 1 then
        set udg_Stats_SpellPowerFlat[id] = udg_Stats_SpellPowerFlat[id] - value
        set spellFlatApplied[key] = 0
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " lost -" + I2S(value) + " Spell Power Flat")
        endif
    endif
endfunction

/**
 * Removes hit stat from a unit (for item drops)
 */
private function RemoveHitStat takes unit u, integer abilId, integer value returns nothing
    local integer id = GetUnitId(u)
    local integer key = id * 100 + abilId
    
    if hitApplied[key] == 1 then
        set udg_Stats_Hit[id] = udg_Stats_Hit[id] - value
        set hitApplied[key] = 0
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] " + GetUnitName(u) + " lost -" + I2S(value) + " Hit")
        endif
    endif
endfunction

//===================== STAT CHECKING =====================

/**
 * Checks and applies all dodge stats for a unit
 */
private function CheckDodgeStats takes unit u returns nothing
    // 1-5% checks
    if GetUnitAbilityLevel(u, ABILITY_DODGE_1) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_1, 1)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_2) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_2, 2)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_3) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_3, 3)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_4) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_4, 4)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_5) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_5, 5)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_10) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_10, 10)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_15) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_15, 15)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_20) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_20, 20)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_25) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_25, 25)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_30) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_30, 30)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_35) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_35, 35)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_40) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_40, 40)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_50) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_50, 50)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_60) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_60, 60)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_75) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_75, 75)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_90) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_90, 90)
    endif
    if GetUnitAbilityLevel(u, ABILITY_DODGE_100) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_100, 100)
    endif
endfunction

/**
 * Checks and applies all crit stats for a unit
 */
private function CheckCritStats takes unit u returns nothing
    // 1-5% checks
    if GetUnitAbilityLevel(u, ABILITY_CRIT_1) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_1, 1)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_2) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_2, 2)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_3) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_3, 3)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_4) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_4, 4)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_5) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_5, 5)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_10) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_10, 10)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_15) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_15, 15)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_20) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_20, 20)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_25) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_25, 25)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_30) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_30, 30)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_35) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_35, 35)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_40) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_40, 40)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_50) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_50, 50)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_60) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_60, 60)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_75) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_75, 75)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_90) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_90, 90)
    endif
    if GetUnitAbilityLevel(u, ABILITY_CRIT_100) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_100, 100)
    endif
endfunction

/**
 * Checks and applies all block stats for a unit
 */
private function CheckBlockStats takes unit u returns nothing
    // 1-5% checks
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_1) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_1, 1)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_2) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_2, 2)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_3) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_3, 3)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_4) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_4, 4)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_5) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_5, 5)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_10) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_10, 10)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_15) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_15, 15)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_20) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_20, 20)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_25) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_25, 25)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_30) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_30, 30)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_35) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_35, 35)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_40) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_40, 40)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_50) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_50, 50)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_60) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_60, 60)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_75) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_75, 75)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_90) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_90, 90)
    endif
    if GetUnitAbilityLevel(u, ABILITY_BLOCK_100) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_100, 100)
    endif
endfunction

/**
 * Checks and applies all spell power stats for a unit
 */
private function CheckSpellStats takes unit u returns nothing
    // 1-4% checks
    if GetUnitAbilityLevel(u, ABILITY_SPELL_1) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_1, 1)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_2) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_2, 2)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_3) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_3, 3)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_4) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_4, 4)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_5) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_5, 5)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_10) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_10, 10)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_15) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_15, 15)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_20) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_20, 20)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_25) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_25, 25)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_30) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_30, 30)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_35) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_35, 35)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_40) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_40, 40)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_50) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_50, 50)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_60) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_60, 60)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_75) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_75, 75)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_90) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_90, 90)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELL_100) > 0 then
        call ApplySpellStat(u, ABILITY_SPELL_100, 100)
    endif
endfunction

/**
 * Checks and applies all spell power flat stats for a unit
 */
private function CheckSpellFlatStats takes unit u returns nothing
    if GetUnitAbilityLevel(u, ABILITY_SPELLFLAT_1) > 0 then
        call ApplySpellFlatStat(u, ABILITY_SPELLFLAT_1, 1)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELLFLAT_5) > 0 then
        call ApplySpellFlatStat(u, ABILITY_SPELLFLAT_5, 5)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELLFLAT_10) > 0 then
        call ApplySpellFlatStat(u, ABILITY_SPELLFLAT_10, 10)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELLFLAT_25) > 0 then
        call ApplySpellFlatStat(u, ABILITY_SPELLFLAT_25, 25)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELLFLAT_50) > 0 then
        call ApplySpellFlatStat(u, ABILITY_SPELLFLAT_50, 50)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELLFLAT_100) > 0 then
        call ApplySpellFlatStat(u, ABILITY_SPELLFLAT_100, 100)
    endif
    if GetUnitAbilityLevel(u, ABILITY_SPELLFLAT_300) > 0 then
        call ApplySpellFlatStat(u, ABILITY_SPELLFLAT_300, 300)
    endif
endfunction

/**
 * Checks and applies all hit stats for a unit
 */
private function CheckHitStats takes unit u returns nothing
    // 1-5% checks
    if GetUnitAbilityLevel(u, ABILITY_HIT_1) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_1, 1)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_2) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_2, 2)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_3) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_3, 3)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_4) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_4, 4)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_5) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_5, 5)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_10) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_10, 10)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_15) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_15, 15)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_20) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_20, 20)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_25) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_25, 25)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_30) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_30, 30)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_35) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_35, 35)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_40) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_40, 40)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_50) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_50, 50)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_60) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_60, 60)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_75) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_75, 75)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_90) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_90, 90)
    endif
    if GetUnitAbilityLevel(u, ABILITY_HIT_100) > 0 then
        call ApplyHitStat(u, ABILITY_HIT_100, 100)
    endif
endfunction

/**
 * Processes a single unit's stats
 */
private function ProcessUnitStats takes unit u returns nothing
    call CheckDodgeStats(u)
    call CheckCritStats(u)
    call CheckBlockStats(u)
    call CheckSpellStats(u)
    call CheckSpellFlatStats(u)
    call CheckHitStats(u)
endfunction

/**
 * OPTIMIZED: Process a unit's stats once (checks if already processed)
 */
private function ProcessUnitStatsOnce takes unit u returns nothing
    local integer id = GetUnitId(u)
    
    // Skip if already processed
    if processedUnits[id] != 0 then
        return
    endif
    
    // Skip if unit doesn't have Stats_Yes ability
    if GetUnitAbilityLevel(u, ABILITY_STATS_YES) <= 0 then
        return
    endif
    
    // Skip dead units
    if GetUnitState(u, UNIT_STATE_LIFE) <= 0 then
        return
    endif
    
    // Process stats and mark as processed
    call ProcessUnitStats(u)
    set processedUnits[id] = 1
    set statsProcessed = statsProcessed + 1
    
    if debugEnabled then
        call BJDebugMsg("[UnitStats] Processed: " + GetUnitName(u) + " (Total: " + I2S(statsProcessed) + ")")
    endif
endfunction

/**
 * OPTIMIZED: Manually process a specific unit's stats
 * Useful if you add Stats_Yes ability via trigger and want immediate processing
 */
function UnitStats_ProcessUnit takes unit u returns nothing
    call ProcessUnitStatsOnce(u)
endfunction

//===================== HERO ITEM STAT PROCESSING =====================

/**
 * Process hero's item stats when picking up an item
 * Checks all percentage-based stat abilities and applies them
 */
private function ProcessHeroItemStats takes unit hero returns nothing
    if not IsUnitType(hero, UNIT_TYPE_HERO) then
        return
    endif
    
    call CheckDodgeStats(hero)
    call CheckCritStats(hero)
    call CheckBlockStats(hero)
    call CheckSpellStats(hero)
    call CheckSpellFlatStats(hero)
    call CheckHitStats(hero)
endfunction

/**
 * Helper function to clear all stat tracking flags for a specific ability type
 */
private function ClearAbilityTracking takes integer unitId, integer abilId returns nothing
    local integer key = unitId * 100 + abilId
    set dodgeApplied[key] = 0
    set critApplied[key] = 0
    set blockApplied[key] = 0
    set spellApplied[key] = 0
    set spellFlatApplied[key] = 0
    set hitApplied[key] = 0
endfunction

/**
 * Clears all percentage stat tracking for a hero and resets stat values
 * Used when recalculating stats after item drop
 */
private function ClearHeroStatTracking takes unit hero returns nothing
    local integer id = GetUnitId(hero)
    
    // Reset all percentage stat values to 0
    set udg_Stats_Dodge[id] = 0
    set udg_Stats_Crit[id] = 0
    set udg_Stats_Block[id] = 0
    set udg_Stats_SpellPowerPct[id] = 0
    set udg_Stats_SpellPowerFlat[id] = 0
    set udg_Stats_Hit[id] = 0
    
    // Clear all tracking flags for all percentage abilities
    // Dodge 1-5%
    call ClearAbilityTracking(id, ABILITY_DODGE_1)
    call ClearAbilityTracking(id, ABILITY_DODGE_2)
    call ClearAbilityTracking(id, ABILITY_DODGE_3)
    call ClearAbilityTracking(id, ABILITY_DODGE_4)
    call ClearAbilityTracking(id, ABILITY_DODGE_5)
    // Dodge 10-100%
    call ClearAbilityTracking(id, ABILITY_DODGE_10)
    call ClearAbilityTracking(id, ABILITY_DODGE_15)
    call ClearAbilityTracking(id, ABILITY_DODGE_20)
    call ClearAbilityTracking(id, ABILITY_DODGE_25)
    call ClearAbilityTracking(id, ABILITY_DODGE_30)
    call ClearAbilityTracking(id, ABILITY_DODGE_35)
    call ClearAbilityTracking(id, ABILITY_DODGE_40)
    call ClearAbilityTracking(id, ABILITY_DODGE_50)
    call ClearAbilityTracking(id, ABILITY_DODGE_60)
    call ClearAbilityTracking(id, ABILITY_DODGE_75)
    call ClearAbilityTracking(id, ABILITY_DODGE_90)
    call ClearAbilityTracking(id, ABILITY_DODGE_100)
    
    // Crit 1-5%
    call ClearAbilityTracking(id, ABILITY_CRIT_1)
    call ClearAbilityTracking(id, ABILITY_CRIT_2)
    call ClearAbilityTracking(id, ABILITY_CRIT_3)
    call ClearAbilityTracking(id, ABILITY_CRIT_4)
    call ClearAbilityTracking(id, ABILITY_CRIT_5)
    // Crit 10-100%
    call ClearAbilityTracking(id, ABILITY_CRIT_10)
    call ClearAbilityTracking(id, ABILITY_CRIT_15)
    call ClearAbilityTracking(id, ABILITY_CRIT_20)
    call ClearAbilityTracking(id, ABILITY_CRIT_25)
    call ClearAbilityTracking(id, ABILITY_CRIT_30)
    call ClearAbilityTracking(id, ABILITY_CRIT_35)
    call ClearAbilityTracking(id, ABILITY_CRIT_40)
    call ClearAbilityTracking(id, ABILITY_CRIT_50)
    call ClearAbilityTracking(id, ABILITY_CRIT_60)
    call ClearAbilityTracking(id, ABILITY_CRIT_75)
    call ClearAbilityTracking(id, ABILITY_CRIT_90)
    call ClearAbilityTracking(id, ABILITY_CRIT_100)
    
    // Block 1-5%
    call ClearAbilityTracking(id, ABILITY_BLOCK_1)
    call ClearAbilityTracking(id, ABILITY_BLOCK_2)
    call ClearAbilityTracking(id, ABILITY_BLOCK_3)
    call ClearAbilityTracking(id, ABILITY_BLOCK_4)
    call ClearAbilityTracking(id, ABILITY_BLOCK_5)
    // Block 10-100%
    call ClearAbilityTracking(id, ABILITY_BLOCK_10)
    call ClearAbilityTracking(id, ABILITY_BLOCK_15)
    call ClearAbilityTracking(id, ABILITY_BLOCK_20)
    call ClearAbilityTracking(id, ABILITY_BLOCK_25)
    call ClearAbilityTracking(id, ABILITY_BLOCK_30)
    call ClearAbilityTracking(id, ABILITY_BLOCK_35)
    call ClearAbilityTracking(id, ABILITY_BLOCK_40)
    call ClearAbilityTracking(id, ABILITY_BLOCK_50)
    call ClearAbilityTracking(id, ABILITY_BLOCK_60)
    call ClearAbilityTracking(id, ABILITY_BLOCK_75)
    call ClearAbilityTracking(id, ABILITY_BLOCK_90)
    call ClearAbilityTracking(id, ABILITY_BLOCK_100)
    
    // Spell 1-4%
    call ClearAbilityTracking(id, ABILITY_SPELL_1)
    call ClearAbilityTracking(id, ABILITY_SPELL_2)
    call ClearAbilityTracking(id, ABILITY_SPELL_3)
    call ClearAbilityTracking(id, ABILITY_SPELL_4)
    // Spell 5-100%
    call ClearAbilityTracking(id, ABILITY_SPELL_5)
    call ClearAbilityTracking(id, ABILITY_SPELL_10)
    call ClearAbilityTracking(id, ABILITY_SPELL_15)
    call ClearAbilityTracking(id, ABILITY_SPELL_20)
    call ClearAbilityTracking(id, ABILITY_SPELL_25)
    call ClearAbilityTracking(id, ABILITY_SPELL_30)
    call ClearAbilityTracking(id, ABILITY_SPELL_35)
    call ClearAbilityTracking(id, ABILITY_SPELL_40)
    call ClearAbilityTracking(id, ABILITY_SPELL_50)
    call ClearAbilityTracking(id, ABILITY_SPELL_60)
    call ClearAbilityTracking(id, ABILITY_SPELL_75)
    call ClearAbilityTracking(id, ABILITY_SPELL_90)
    call ClearAbilityTracking(id, ABILITY_SPELL_100)
    
    // Spell Flat 1-300
    call ClearAbilityTracking(id, ABILITY_SPELLFLAT_1)
    call ClearAbilityTracking(id, ABILITY_SPELLFLAT_5)
    call ClearAbilityTracking(id, ABILITY_SPELLFLAT_10)
    call ClearAbilityTracking(id, ABILITY_SPELLFLAT_25)
    call ClearAbilityTracking(id, ABILITY_SPELLFLAT_50)
    call ClearAbilityTracking(id, ABILITY_SPELLFLAT_100)
    call ClearAbilityTracking(id, ABILITY_SPELLFLAT_300)
    
    // Hit 1-5%
    call ClearAbilityTracking(id, ABILITY_HIT_1)
    call ClearAbilityTracking(id, ABILITY_HIT_2)
    call ClearAbilityTracking(id, ABILITY_HIT_3)
    call ClearAbilityTracking(id, ABILITY_HIT_4)
    call ClearAbilityTracking(id, ABILITY_HIT_5)
    // Hit 10-100%
    call ClearAbilityTracking(id, ABILITY_HIT_10)
    call ClearAbilityTracking(id, ABILITY_HIT_15)
    call ClearAbilityTracking(id, ABILITY_HIT_20)
    call ClearAbilityTracking(id, ABILITY_HIT_25)
    call ClearAbilityTracking(id, ABILITY_HIT_30)
    call ClearAbilityTracking(id, ABILITY_HIT_35)
    call ClearAbilityTracking(id, ABILITY_HIT_40)
    call ClearAbilityTracking(id, ABILITY_HIT_50)
    call ClearAbilityTracking(id, ABILITY_HIT_60)
    call ClearAbilityTracking(id, ABILITY_HIT_75)
    call ClearAbilityTracking(id, ABILITY_HIT_90)
    call ClearAbilityTracking(id, ABILITY_HIT_100)
endfunction

/**
 * Recalculates hero's percentage stats from all remaining items
 * Called when hero drops an item (WC3 has no native function to check item abilities)
 * Solution: Clear all stats and recalculate from hero's current abilities
 */
private function RecalculateHeroItemStats takes unit hero returns nothing
    if not IsUnitType(hero, UNIT_TYPE_HERO) then
        return
    endif
    
    // Clear all percentage stats and tracking flags
    call ClearHeroStatTracking(hero)
    
    // Recalculate stats from hero's current abilities (from remaining items)
    call CheckDodgeStats(hero)
    call CheckCritStats(hero)
    call CheckBlockStats(hero)
    call CheckSpellStats(hero)
    call CheckSpellFlatStats(hero)
    call CheckHitStats(hero)
endfunction

/**
 * PUBLIC API: Recalculate hero's item-based stats
 * Call this after programmatically removing items from hero (e.g., DInventory transfer)
 * This clears all tracking and recalculates stats from hero's current abilities
 */
function UnitStats_RecalculateHero takes unit hero returns nothing
    if not IsUnitType(hero, UNIT_TYPE_HERO) then
        return
    endif
    
    call RecalculateHeroItemStats(hero)
    
    if debugEnabled then
        call BJDebugMsg("[UnitStats] Recalculated stats for " + GetUnitName(hero))
    endif
endfunction

//===================== HERO ITEM EVENTS =====================

/**
 * Event handler for hero picking up an item
 */
private function OnHeroPickupItem takes nothing returns nothing
    local unit hero = GetTriggerUnit()
    
    // Only process heroes
    if IsUnitType(hero, UNIT_TYPE_HERO) then
        call ProcessHeroItemStats(hero)
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] Hero " + GetUnitName(hero) + " picked up item - updating stats")
        endif
    endif
    
    set hero = null
endfunction

/**
 * Delayed recalculation callback for hero item drops
 * Called after a short delay to ensure WC3 has removed the item's abilities
 */
private function DelayedRecalculate takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer id = GetTimerData(t)
    local unit hero = timerHeroData.unit[id]
    
    call RecalculateHeroItemStats(hero)
    
    if debugEnabled then
        call BJDebugMsg("[UnitStats] Hero " + GetUnitName(hero) + " dropped item - stats recalculated")
    endif
    
    // Clean up table entry
    call timerHeroData.remove(id)
    
    call ReleaseTimer(t)
    set t = null
    set hero = null
endfunction

/**
 * Event handler for hero dropping an item
 * Recalculates all stats from remaining items (no GetItemAbilityLevel in JASS)
 * IMPORTANT: Uses 0.01s delay because WC3 removes abilities AFTER the drop event fires
 */
private function OnHeroDropItem takes nothing returns nothing
    local unit hero = GetTriggerUnit()
    local integer id
    local timer t
    
    // Only process heroes
    if IsUnitType(hero, UNIT_TYPE_HERO) then
        // Store unit reference in table
        set id = GetUnitId(hero)
        set timerHeroData.unit[id] = hero
        
        // Delay recalculation to ensure WC3 has removed the item's abilities
        set t = NewTimer()
        call SetTimerData(t, id)
        call TimerStart(t, 0.01, false, function DelayedRecalculate)
        
        if debugEnabled then
            call BJDebugMsg("[UnitStats] Hero " + GetUnitName(hero) + " dropped item - recalculating in 0.01s...")
        endif
    endif
    
    set t = null
    set hero = null
endfunction

/**
 * OPTIMIZED: Force reprocess a unit (clears processed flag first)
 * Use this if you dynamically change a unit's stat abilities
 */
function UnitStats_RefreshUnit takes unit u returns nothing
    local integer id = GetUnitId(u)
    set processedUnits[id] = 0  // Clear processed flag
    call ProcessUnitStatsOnce(u)
endfunction

//===================== MAIN LOOP =====================

/**
 * Filter function - only processes units with Stats_Yes ability
 */
private function FilterStatsUnits takes nothing returns boolean
    local unit u = GetFilterUnit()
    
    // Only process units with the marker ability
    if GetUnitAbilityLevel(u, ABILITY_STATS_YES) <= 0 then
        return false
    endif
    
    // Skip dead units
    if GetUnitState(u, UNIT_STATE_LIFE) <= 0 then
        return false
    endif
    
    return true
endfunction

/**
 * OPTIMIZED: One-time initial scan at map start (for pre-placed units only)
 * Call this from your map initialization to process all existing units
 * For units created during gameplay, call UnitStats_ProcessUnit from your spawn trigger
 */
function UnitStats_InitialScan takes nothing returns nothing
    local unit u
    local boolexpr filter
    local integer count = 0
    
    if debugEnabled then
        call BJDebugMsg("[UnitStats] ===== PERFORMING INITIAL SCAN =====")
        call BJDebugMsg("[UnitStats] Performing initial one-time scan for pre-placed units...")
    endif
    
    // Enumerate all units with Stats_Yes ability
    call GroupClear(tempGroup)
    set filter = Filter(function FilterStatsUnits)
    call GroupEnumUnitsInRect(tempGroup, GetWorldBounds(), filter)
    call DestroyBoolExpr(filter)
    
    // Process each unit once
    loop
        set u = FirstOfGroup(tempGroup)
        exitwhen u == null
        
        call ProcessUnitStatsOnce(u)
        call GroupRemoveUnit(tempGroup, u)
        set count = count + 1
    endloop
    
    if debugEnabled then
        call BJDebugMsg("[UnitStats] Initial scan processed " + I2S(count) + " units.")
        call BJDebugMsg("[UnitStats] Initial scan complete - processed " + I2S(count) + " pre-placed units")
        call BJDebugMsg("[UnitStats] For spawned units, call UnitStats_ProcessUnit from your trigger")
    endif
endfunction

//===================== INITIALIZATION =====================

/**
 * OPTIMIZED: Initializes the system (NO PERIODIC LAG!)
 * To process units, call UnitStats_ProcessUnit from your spawn trigger
 */
private function Init takes nothing returns nothing
    local trigger pickupTrig
    local trigger dropTrig
    
    // Create tables
    set dodgeApplied = Table.create()
    set critApplied  = Table.create()
    set blockApplied = Table.create()
    set spellApplied = Table.create()
    set spellFlatApplied = Table.create()
    set hitApplied   = Table.create()
    set processedUnits = Table.create()
    set timerHeroData = Table.create()
    
    // Register hero item pickup/drop events
    set pickupTrig = CreateTrigger()
    set dropTrig = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(pickupTrig, EVENT_PLAYER_UNIT_PICKUP_ITEM)
    call TriggerRegisterAnyUnitEventBJ(dropTrig, EVENT_PLAYER_UNIT_DROP_ITEM)
    call TriggerAddAction(pickupTrig, function OnHeroPickupItem)
    call TriggerAddAction(dropTrig, function OnHeroDropItem)
    
    // Perform ONE-TIME initial scan for pre-placed units after short delay
    call TimerStart(CreateTimer(), INITIAL_SCAN_DELAY, false, function UnitStats_InitialScan)
    
    if debugEnabled then
        call BJDebugMsg("[UnitStats] Debug messages enabled")
        call BJDebugMsg("[UnitStats] ===== OPTIMIZED SYSTEM INITIALIZED =====")
        call BJDebugMsg("[UnitStats] Event-driven processing (NO periodic lag!)")
        call BJDebugMsg("[UnitStats] Hero item pickup/drop events registered")
        call BJDebugMsg("[UnitStats] Call UnitStats_ProcessUnit(unit) from your spawn trigger")
        call BJDebugMsg("[UnitStats] Initial scan for pre-placed units in " + R2S(INITIAL_SCAN_DELAY) + " seconds")
    endif   
endfunction

endlibrary