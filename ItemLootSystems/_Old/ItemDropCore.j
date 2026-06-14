library ItemDropCore requires ItemDropConfig
//===========================================================================
/*
    ItemDropCore 1.0
    
    Author: [Valdemar]
    
    Description:
    Core drop logic for ItemDropSystem. Contains functions for:
    - Generic level-based drops (useless, consumables, equipment)
    - Rarity rolling system
    - Drop chance calculations
    
    This library handles the main drop algorithms used by all other systems.
*/
//===========================================================================

//===========================================================================
// HELPER: Check if unit has Locust
//===========================================================================
function ItemDropCore_HasLocust takes unit u returns boolean
    return GetUnitAbilityLevel(u, 'Aloc') > 0
endfunction

//===========================================================================
// HELPER: Check if unit can drop items
//===========================================================================
function ItemDropCore_CanDrop takes unit u returns boolean
    return IsUnitInForce(GetOwningPlayer(u), ItemDrop_Players) and not IsUnitIllusion(u) and not ItemDropCore_HasLocust(u)
endfunction

//===========================================================================
// DROP: Useless item at location
// Chance: 1-6 rolls a random useless item
//===========================================================================
function ItemDropCore_DropUseless takes location loc, integer diceRoll, integer threshold returns nothing
    local integer randomIndex
    
    if diceRoll <= threshold then
        set randomIndex = GetRandomInt(1, 6)
        call CreateItem(ItemUseless[randomIndex], GetLocationX(loc), GetLocationY(loc))
    endif
endfunction

//===========================================================================
// DROP: Generic consumable items by level range
//===========================================================================
function ItemDropCore_DropGeneric takes location loc, integer unitLevel, integer diceRoll, integer minThreshold, integer maxThreshold returns nothing
    local integer randomIndex
    local integer itemType
    
    if diceRoll > minThreshold and diceRoll <= maxThreshold then
        // Select appropriate level range
        if unitLevel <= 5 then
            set randomIndex = GetRandomInt(1, 8)
            set itemType = ItemGeneric_1_5[randomIndex]
        elseif unitLevel <= 10 then
            set randomIndex = GetRandomInt(1, 14)
            set itemType = ItemGeneric_6_10[randomIndex]
        elseif unitLevel <= 15 then
            set randomIndex = GetRandomInt(1, 16)
            set itemType = ItemGeneric_11_15[randomIndex]
        elseif unitLevel <= 20 then
            set randomIndex = GetRandomInt(1, 16)
            set itemType = ItemGeneric_16_20[randomIndex]
        elseif unitLevel <= 25 then
            set randomIndex = GetRandomInt(1, 25)
            set itemType = ItemGeneric_21_25[randomIndex]
        else
            set randomIndex = GetRandomInt(1, 17)
            set itemType = ItemGeneric_26_30[randomIndex]
        endif
        
        call CreateItem(itemType, GetLocationX(loc), GetLocationY(loc))
    endif
endfunction

//===========================================================================
// DROP: Random equipment by level and rarity
// Returns the selected item level for "Random level X.Any Class item-type"
//===========================================================================
function ItemDropCore_GetRandomItemLevel takes integer unitLevel, integer rarityRoll returns integer
    local integer rangeIndex = GetRandomInt(1, 17)
    local integer itemLevel = 0
    
    // LEVELS 1-5
    if unitLevel <= 5 then
        if rarityRoll <= 85 then
            // COMMON 85%
            return ItemLootRanges_1_5_Common[rangeIndex]
        elseif rarityRoll <= 99 then
            // UNCOMMON 14%
            return ItemLootRanges_1_5_Uncommon[rangeIndex]
        else
            // RARE 1%
            return ItemLootRanges_1_5_Rare[rangeIndex]
        endif
    
    // LEVELS 6-10
    elseif unitLevel <= 10 then
        if rarityRoll <= 60 then
            // COMMON 60%
            return ItemLootRanges_6_10_Common[rangeIndex]
        elseif rarityRoll <= 85 then
            // UNCOMMON 25%
            return ItemLootRanges_6_10_Uncommon[rangeIndex]
        elseif rarityRoll <= 99 then
            // RARE 14%
            return ItemLootRanges_6_10_Rare[rangeIndex]
        else
            // EPIC 1%
            return ItemLootRanges_6_10_Epic[rangeIndex]
        endif
    
    // LEVELS 11-15
    elseif unitLevel <= 15 then
        if rarityRoll <= 60 then
            // COMMON 60%
            return ItemLootRanges_11_15_Common[rangeIndex]
        elseif rarityRoll <= 85 then
            // UNCOMMON 25%
            return ItemLootRanges_11_15_Uncommon[rangeIndex]
        elseif rarityRoll <= 95 then
            // RARE 10%
            return ItemLootRanges_11_15_Rare[rangeIndex]
        elseif rarityRoll <= 99 then
            // EPIC 4%
            return ItemLootRanges_11_15_Epic[rangeIndex]
        else
            // LEGENDARY 1%
            return ItemLootRanges_11_15_Legendary[rangeIndex]
        endif
    
    // LEVELS 16-20
    elseif unitLevel <= 20 then
        if rarityRoll <= 60 then
            // COMMON 60%
            return ItemLootRanges_16_20_Common[rangeIndex]
        elseif rarityRoll <= 85 then
            // UNCOMMON 25%
            return ItemLootRanges_16_20_Uncommon[rangeIndex]
        elseif rarityRoll <= 95 then
            // RARE 10%
            return ItemLootRanges_16_20_Rare[rangeIndex]
        elseif rarityRoll <= 99 then
            // EPIC 4%
            return ItemLootRanges_16_20_Epic[rangeIndex]
        else
            // LEGENDARY 1%
            return ItemLootRanges_16_20_Legendary[rangeIndex]
        endif
    
    // LEVELS 21-25
    elseif unitLevel <= 25 then
        if rarityRoll <= 50 then
            // COMMON 50%
            return ItemLootRanges_21_25_Common[rangeIndex]
        elseif rarityRoll <= 80 then
            // UNCOMMON 30%
            return ItemLootRanges_21_25_Uncommon[rangeIndex]
        elseif rarityRoll <= 95 then
            // RARE 15%
            return ItemLootRanges_21_25_Rare[rangeIndex]
        elseif rarityRoll <= 99 then
            // EPIC 4%
            return ItemLootRanges_21_25_Epic[rangeIndex]
        else
            // LEGENDARY 1%
            return ItemLootRanges_21_25_Legendary[rangeIndex]
        endif
    
    // LEVELS 26-30+
    else
        if rarityRoll <= 40 then
            // COMMON 40%
            return ItemLootRanges_26_30_Common[rangeIndex]
        elseif rarityRoll <= 70 then
            // UNCOMMON 30%
            return ItemLootRanges_26_30_Uncommon[rangeIndex]
        elseif rarityRoll <= 85 then
            // RARE 15%
            return ItemLootRanges_26_30_Rare[rangeIndex]
        elseif rarityRoll <= 95 then
            // EPIC 10%
            return ItemLootRanges_26_30_Epic[rangeIndex]
        else
            // LEGENDARY 5%
            return ItemLootRanges_26_30_Legendary[rangeIndex]
        endif
    endif
    
    return 0
endfunction

//===========================================================================
// DROP: Equipment item (uses Warcraft 3 random item generation)
// Note: This creates a random item of the specified level and any class
//===========================================================================
function ItemDropCore_DropEquipment takes location loc, integer unitLevel, integer diceRoll, integer minThreshold, integer maxThreshold returns nothing
    local integer rarityRoll
    local integer itemLevel
    
    if diceRoll > minThreshold and diceRoll <= maxThreshold then
        set rarityRoll = GetRandomInt(1, 100)
        set itemLevel = ItemDropCore_GetRandomItemLevel(unitLevel, rarityRoll)
        
        if itemLevel > 0 then
            call CreateItem(ChooseRandomItemEx(ITEM_TYPE_ANY, itemLevel), GetLocationX(loc), GetLocationY(loc))
        endif
    endif
endfunction

//===========================================================================
// MAIN DROP HANDLER: Generic level-based drops
// This is the primary function called by event handlers
//===========================================================================
function ItemDropCore_ProcessGenericDrop takes unit u, location loc returns nothing
    local integer unitLevel = GetUnitLevel(u)
    local integer mainDice = GetRandomInt(1, 40)
    
    // Skip invalid units
    if not ItemDropCore_CanDrop(u) then
        return
    endif
    
    // Drop chance thresholds vary by level range
    // LEVELS 1-5: 15% useless, 12.5% generic, 12.5% equipment
    if unitLevel <= 5 then
        call ItemDropCore_DropUseless(loc, mainDice, 6)
        call ItemDropCore_DropGeneric(loc, unitLevel, mainDice, 6, 11)
        call ItemDropCore_DropEquipment(loc, unitLevel, mainDice, 11, 16)
    
    // LEVELS 6-10: 15% useless, 12.5% generic, 12.5% equipment
    elseif unitLevel <= 10 then
        call ItemDropCore_DropUseless(loc, mainDice, 6)
        call ItemDropCore_DropGeneric(loc, unitLevel, mainDice, 6, 11)
        call ItemDropCore_DropEquipment(loc, unitLevel, mainDice, 11, 16)
    
    // LEVELS 11-15: 10% useless, 15% generic, 17.5% equipment
    elseif unitLevel <= 15 then
        call ItemDropCore_DropUseless(loc, mainDice, 4)
        call ItemDropCore_DropGeneric(loc, unitLevel, mainDice, 4, 10)
        call ItemDropCore_DropEquipment(loc, unitLevel, mainDice, 10, 17)
    
    // LEVELS 16-20: 10% useless, 15% generic, 17.5% equipment
    elseif unitLevel <= 20 then
        call ItemDropCore_DropUseless(loc, mainDice, 4)
        call ItemDropCore_DropGeneric(loc, unitLevel, mainDice, 4, 10)
        call ItemDropCore_DropEquipment(loc, unitLevel, mainDice, 10, 17)
    
    // LEVELS 21-25: 7.5% useless, 12.5% generic, 20% equipment
    elseif unitLevel <= 25 then
        call ItemDropCore_DropUseless(loc, mainDice, 3)
        call ItemDropCore_DropGeneric(loc, unitLevel, mainDice, 3, 8)
        call ItemDropCore_DropEquipment(loc, unitLevel, mainDice, 8, 16)
    
    // LEVELS 26-30+: 5% useless, 10% generic, 25% equipment
    else
        call ItemDropCore_DropUseless(loc, mainDice, 2)
        call ItemDropCore_DropGeneric(loc, unitLevel, mainDice, 2, 6)
        call ItemDropCore_DropEquipment(loc, unitLevel, mainDice, 6, 16)
    endif
endfunction

//===========================================================================
endlibrary
//===========================================================================
