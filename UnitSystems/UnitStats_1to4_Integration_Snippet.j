// =================================================================
// UnitStats.j - Integration Snippet for 1-5% Stat Abilities
// =================================================================
// This file contains the code to add to UnitStats.j to support 1-5% 
// precision for percentage-based stats (Hit, Crit, Block, Dodge, Spell)
//
// NOTE: These abilities are for NON-HERO units using UnitStats.j
// For vanilla inventory items, abilities are applied automatically by WC3
// when heroes pick up/drop items - no JASS code needed!
// =================================================================

// =================================================================
// PART 1: Add these ability constants (After line ~123)
// =================================================================

// Hit 1-5% abilities
private constant integer ABILITY_HIT_1     = 'A649'
private constant integer ABILITY_HIT_2     = 'A64A'
private constant integer ABILITY_HIT_3     = 'A64C'
private constant integer ABILITY_HIT_4     = 'A64D'
private constant integer ABILITY_HIT_5     = 'A64B'

// Crit 1-5% abilities
private constant integer ABILITY_CRIT_1    = 'A64E'
private constant integer ABILITY_CRIT_2    = 'A64F'
private constant integer ABILITY_CRIT_3    = 'A64G'
private constant integer ABILITY_CRIT_4    = 'A64H'
private constant integer ABILITY_CRIT_5    = 'A64I'

// Block 1-5% abilities
private constant integer ABILITY_BLOCK_1   = 'A64J'
private constant integer ABILITY_BLOCK_2   = 'A64K'
private constant integer ABILITY_BLOCK_3   = 'A64L'
private constant integer ABILITY_BLOCK_4   = 'A64M'
private constant integer ABILITY_BLOCK_5   = 'A64N'

// Dodge 1-5% abilities
private constant integer ABILITY_DODGE_1   = 'A64O'
private constant integer ABILITY_DODGE_2   = 'A64P'
private constant integer ABILITY_DODGE_3   = 'A64Q'
private constant integer ABILITY_DODGE_4   = 'A64R'
private constant integer ABILITY_DODGE_5   = 'A64S'

// Spell Power 1-4% abilities (no 5% - covered by existing ABILITY_SPELL_5)
private constant integer ABILITY_SPELL_1   = 'A06M'
private constant integer ABILITY_SPELL_2   = 'A06N'
private constant integer ABILITY_SPELL_3   = 'A06O'
private constant integer ABILITY_SPELL_4   = 'A06P'

// =================================================================
// PART 2: Update CheckHitStats function
// =================================================================
// Add these checks at the BEGINNING of the function (before existing 5-100% checks)

private function CheckHitStats takes unit u returns nothing
    // 1-5% checks (NEW)
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
    
    // EXISTING 5-100% checks remain below (don't change these)
    // if GetUnitAbilityLevel(u, ABILITY_HIT_5) > 0 then ... (already added above)
    // if GetUnitAbilityLevel(u, ABILITY_HIT_10) > 0 then ...
   PART 3: Update CheckCritStats function
// =================================================================
// Add these checks at the BEGINNING of the function

private function CheckCritStats takes unit u returns nothing
    // 1-5% checks (NEW)
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
    
    // EXISTING 5-100% checks remain below
    // EXISTING 5-100% checks below (don't change these)
    if GetUnitAbilityLevel(u, ABILITY_CRIT_5) > 0 then
        call ApplyCritStat(u, ABILITY_CRIT_5, 5)
    endif
    // ... rest unchanged ...
endfunction
PART 4: Update CheckBlockStats function
// =================================================================
// Add these checks at the BEGINNING of the function

private function CheckBlockStats takes unit u returns nothing
    // 1-5% checks (NEW)
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
    
    // EXISTING 5-100% checks remain belowtUnitAbilityLevel(u, ABILITY_BLOCK_5) > 0 then
        call ApplyBlockStat(u, ABILITY_BLOCK_5, 5)
    endif
   PART 5: Update CheckDodgeStats function
// =================================================================
// Add these checks at the BEGINNING of the function

private function CheckDodgeStats takes unit u returns nothing
    // 1-5% checks (NEW)
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
    
    // EXISTING 5-100% checks remain below
    // EXISTING 5-100% checks below (don't change these)
    if GetUnitAbilityLevel(u, ABILITY_DODGE_5) > 0 then
        call ApplyDodgeStat(u, ABILITY_DODGE_5, 5)
    endif
   PART 6: Update CheckSpellStats function
// =================================================================
// Add these checks at the BEGINNING of the function

private function CheckSpellStats takes unit u returns nothing
    // 1-4% checks (NEW)
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
    
    // EXISTING 5-100% checks remain below
    // if GetUnitAbilityLevel(u, ABILITY_SPELL_5) > 0 then ...
    // ... rest unchanged ...
endfunction

// =================================================================
// SUMMARY OF CHANGES:
// =================================================================
// ✅ Added 24 new ability constants:
//    - Hit 1-5% (5 abilities)
//    - Crit 1-5% (5 abilities)
//    - Block 1-5% (5 abilities)
//    - Dodge 1-5% (5 abilities)
//    - Spell 1-4% (4 abilities)
//
// ✅ Added 24 if-checks across 5 functions:
//    - CheckHitStats: +5 checks
//    - CheckCritStats: +5 checks
//    - CheckBlockStats: +5 checks
//    - CheckDodgeStats: +5 checks
//    - CheckSpellStats: +4 checks
//
// 📝 Total lines added: ~120 lines
// ⏱️ Estimated time: ~20 minutes
//
// =================================================================
// VANILLA INVENTORY NOTE:
// =================================================================
// The 89 NEW abilities you created for Strength, Agility, Intelligence,
// Mana, HP, Damage, Armor, Attack Speed, and Movement Speed work
// AUTOMATICALLY with vanilla WC3 inventory - they don't need UnitStats.j!
//
// When a hero picks up an item with these abilities, WC3 automatically:
// ✅ Adds the abilities to the hero
// ✅ Applies stat bonuses (Str/Agi/Int, Damage, Armor, etc.)
// ✅ Removes abilities when item is dropped
//
// UnitStats.j is only needed for NON-HERO units with the Stats_Yes marker.
// Those units can use the percentage-based abilities (Hit, Crit, Block,
// Dodge, Spell) for combat mechanics like dodge chance, critical strike, etc.
//heckDodgeStats (for 1-4%)
// 6. Add 4 if-checks to CheckSpellStats (for 1-4%)
//
// Total lines added: ~100 lines
// Total time: ~20 minutes
// =================================================================
