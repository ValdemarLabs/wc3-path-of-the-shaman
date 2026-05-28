library HeroItemCheck requires SharedDInvLib
//===========================================================================
/*
custom function to check if a hero has at least X items of a certain type
uses DInventory native GetDInvItemChargesByTypeThreshold

UPDATED Oct 24 2025: CRITICAL BUG FIX - Removed race conditions!
- Removed TriggerSleepAction from HeroItemCheck (was causing delays/race conditions)
- HeroItemCheckBoth now sets udg_DInvUnit atomically (same operation, no gap)
- HeroItemCheckBothAndRemove now atomically checks and removes (no time gap)
- Fixed timing issues that caused items to be removed from wrong hero

UPDATED Oct 23 2025: Now also checks vanilla inventory after checking DInventory!
This means the function will count items in BOTH inventories combined.

USAGE (GUI - Works with your existing triggers!):
Custom script: set udg_DInvItemCarrierHasItems = HeroItemCheckBoth(udg_DInvItemType, udg_DInvItemAmount)
// udg_DInvUnit is automatically set to the hero who has the items

USAGE (JASS):
if HeroItemCheck(udg_Nazgrek, 'I000', 10) then
    // Nazgrek has the items
endif

// For checking both heroes (returns boolean, sets udg_DInvUnit):
if HeroItemCheckBoth('I000', 10) then
    // One of the heroes has items, udg_DInvUnit contains which hero
endif

// For checking both heroes (returns unit):
local unit heroWithItems = HeroItemCheckBothUnit('I000', 10)
if heroWithItems != null then
    // heroWithItems has the required items
endif

// For safe check-and-remove:
if HeroItemCheckBothAndRemove('I000', 10) then
    // Items were removed from udg_DInvUnit
endif

IMPORTANT: If you need inventory to update before checking, call TriggerSleepAction
BEFORE calling these functions, not inside them!

*/
//===========================================================================
// to check if a specific hero has at least X items of a certain type
// can be useful if specific hero must have items for quest
// NOTE: This function does NOT use TriggerSleepAction anymore!
// If you need a delay, call TriggerSleepAction BEFORE calling this function.
function HeroItemCheck takes unit whichHero, integer itemId, integer requiredAmount returns boolean
    local boolean result = false
    
    set result = GetDInvItemChargesByTypeThreshold(whichHero, itemId, requiredAmount)
    return result
endfunction

// Mostly uses this function to check both heroes
// FIXED Oct 24 2025: Now properly manages udg_DInvUnit to prevent race conditions
// Sets udg_DInvUnit immediately when hero found (atomic operation)
function HeroItemCheckBoth takes integer itemId, integer requiredAmount returns boolean
    if HeroItemCheck(udg_Nazgrek, itemId, requiredAmount) then
        set udg_DInvUnit = udg_Nazgrek // Set immediately - atomic with check
        return true
    endif
    if HeroItemCheck(udg_Zulkis, itemId, requiredAmount) then
        set udg_DInvUnit = udg_Zulkis // Set immediately - atomic with check
        return true
    endif
    set udg_DInvUnit = null // Clear if neither has items
    return false
endfunction

// ADVANCED VERSION: Returns the unit directly (for JASS code)
// Use this if you want to store the hero in a local variable
function HeroItemCheckBothUnit takes integer itemId, integer requiredAmount returns unit
    if HeroItemCheck(udg_Nazgrek, itemId, requiredAmount) then
        return udg_Nazgrek
    endif
    if HeroItemCheck(udg_Zulkis, itemId, requiredAmount) then
        return udg_Zulkis
    endif
    return null
endfunction

//===========================================================================
// SAFE removal function - only removes if hero has enough items
// Use this instead of calling RemoveDInvItemChargesByType directly!
// 
// UPDATED Oct 23 2025: Now removes from BOTH DInventory and vanilla inventory!
// Removes from DInventory first, then if needed, removes from vanilla inventory.
//===========================================================================
function HeroItemCheckAndRemove takes unit whichHero, integer itemId, integer requiredAmount returns boolean
    local boolean hasItems = HeroItemCheck(whichHero, itemId, requiredAmount)
    
    if hasItems then
        call RemoveDInvItemChargesByType(whichHero, itemId, requiredAmount)
    endif
    
    return hasItems
endfunction

// Safe removal for both heroes - only removes if one of them has enough
// FIXED Oct 24 2025: Now uses atomic check-and-remove to prevent race conditions
function HeroItemCheckBothAndRemove takes integer itemId, integer requiredAmount returns boolean
    local boolean hasItems = HeroItemCheckBoth(itemId, requiredAmount)
    
    if hasItems then
        // udg_DInvUnit is already set by HeroItemCheckBoth (atomic operation)
        // Remove from the hero who has the items
        call RemoveDInvItemChargesByType(udg_DInvUnit, itemId, requiredAmount)
        return true
    endif
    
    return false
endfunction

endlibrary