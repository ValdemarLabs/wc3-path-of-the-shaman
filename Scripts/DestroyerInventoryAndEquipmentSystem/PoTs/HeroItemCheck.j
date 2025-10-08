//===========================================================================
/*
custom function to check if a hero has at least X items of a certain type
uses DInventory native GetDInvItemChargesByTypeThreshold

if HeroHasItemsByType(udg_Nazgrek, 'I000', 10) then
    // do quest stuff
endif


*/
//===========================================================================
// to check if a specific hero has at least X items of a certain type
// can be useful if specific hero must have items for quest
function HeroItemCheck takes unit whichHero, integer itemId, integer requiredAmount returns boolean
    local integer cv = GetUnitUserData(whichHero) // same as udg_CV in GUI
    local boolean result = false

    set udg_DInvUnit = whichHero
    set udg_DInvItemType = itemId
    set udg_DInvItemAmount = requiredAmount
    set result = GetDInvItemChargesByTypeThreshold(whichHero, itemId, requiredAmount)
    return result
endfunction

// Mostly uses this function to check both heroes
function HeroItemCheckBoth takes integer itemId, integer requiredAmount returns boolean
    if HeroItemCheck(udg_Nazgrek, itemId, requiredAmount) then
        set udg_DInvUnit = udg_Nazgrek // Set the unit that has the items
        return true
    endif
    if HeroItemCheck(udg_Zulkis, itemId, requiredAmount) then
        set udg_DInvUnit = udg_Zulkis // Set the unit that has the items
        return true
    endif
    return false
endfunction