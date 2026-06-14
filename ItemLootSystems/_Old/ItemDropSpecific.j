library ItemDropSpecific requires ItemDropConfig, ItemDropCore
//===========================================================================
/*
    ItemDropSpecific 1.0
    
    Author: [Valdemar]
    
    Description:
    Handles unit-specific drops for special creature types:
    - Wolves (Wolf Jawbone, Raw Wolf Meat, Wolf Skin)
    - Stags (Large Hoof, Raw Stag Meat, Stag Hair)
    - Gnolls (Phat Lewt, quest items)
    - Dragons (Sharp Claw, Flame Sac, Scales)
    
    Each function checks unit type and drops appropriate items.
*/
//===========================================================================
globals
    // Quest tracking variables (these should be defined elsewhere, but included here for reference)
    // quest QuestGnollHeadcount
    // quest QuestKribugsSatchel
    // item KribugsSatchel
endglobals

//===========================================================================
// WOLF DROPS
// Drops: Wolf Jawbone, Raw Wolf Meat, Wolf Skin
// Drop chance: 1 in 6 (16.67%)
//===========================================================================
function ItemDropSpecific_Wolf takes location loc returns nothing
    local integer randomIndex
    
    // Setup loot table
    set ItemLootTable[1] = 'I100' // Wolf Jawbone
    set ItemLootTable[2] = 'I101' // Raw Wolf Meat
    set ItemLootTable[3] = 'I102' // Wolf Skin
    
    // 1 in 6 chance to drop
    if GetRandomInt(1, 6) == 1 then
        set randomIndex = GetRandomInt(1, 3)
        call CreateItem(ItemLootTable[randomIndex], GetLocationX(loc), GetLocationY(loc))
    endif
endfunction

//===========================================================================
// STAG DROPS
// Drops: Large Hoof, Raw Stag Meat, Stag Hair
// Drop chance: 1 in 6 (16.67%)
//===========================================================================
function ItemDropSpecific_Stag takes location loc returns nothing
    local integer randomIndex
    
    // Setup loot table
    set ItemLootTable[1] = 'I110' // Large Hoof
    set ItemLootTable[2] = 'I111' // Raw Stag Meat
    set ItemLootTable[3] = 'I112' // Stag Hair
    
    // 1 in 6 chance to drop
    if GetRandomInt(1, 6) == 1 then
        set randomIndex = GetRandomInt(1, 3)
        call CreateItem(ItemLootTable[randomIndex], GetLocationX(loc), GetLocationY(loc))
    endif
endfunction

//===========================================================================
// GNOLL DROPS
// Drops: Phat Lewt, quest items (Gnoll Head, Kribug's Satchel)
// Drop chance: 1 in 6 (16.67%) for regular loot
// Quest items have separate drop logic
//===========================================================================
function ItemDropSpecific_Gnoll takes location loc returns nothing
    local integer randomIndex
    local group nearbyHeroes
    
    // Setup loot table
    set ItemLootTable[1] = 'I120' // Phat Lewt
    set ItemLootTable[2] = 'I121' // Phat Lewt
    set ItemLootTable[3] = 'I122' // Phat Lewt
    set ItemLootTable[4] = 'I123' // Phat Lewt
    set ItemLootTable[5] = 'I124' // Phat Lewt
    set ItemLootTable[6] = 'I125' // Phat Lewt
    
    // Check for nearby player heroes (within 1000 range)
    set nearbyHeroes = CreateGroup()
    call GroupEnumUnitsInRangeOfLoc(nearbyHeroes, loc, 1000.0, null)
    
    // Quest item: Gnoll Head (if quest is active)
    // Note: Replace QuestGnollHeadcount with your actual quest variable
    // if IsQuestDiscovered(QuestGnollHeadcount) then
    //     if GetRandomInt(1, 3) == 1 then
    //         call CreateItem('I130', GetLocationX(loc), GetLocationY(loc)) // Gnoll Head
    //     endif
    // endif
    
    // Quest item: Kribug's Satchel (if quest is active and item not yet obtained)
    // if IsQuestDiscovered(QuestKribugsSatchel) and KribugsSatchel == null then
    //     if GetRandomInt(1, 5) == 1 then
    //         set KribugsSatchel = CreateItem('I131', GetLocationX(loc), GetLocationY(loc))
    //     endif
    // endif
    
    // Regular loot drop (1 in 6 chance)
    if GetRandomInt(1, 6) == 1 then
        set randomIndex = GetRandomInt(1, 6)
        call CreateItem(ItemLootTable[randomIndex], GetLocationX(loc), GetLocationY(loc))
    endif
    
    call DestroyGroup(nearbyHeroes)
    set nearbyHeroes = null
endfunction

//===========================================================================
// DRAGON WHELP DROPS (Level 6-10)
// Drops: Sharp Claw, Small Flame Sac, Ruined Dragonhide, Whelp Scale
// Drop chance: 1 in 6 for junk, 1 in 2 for scale
//===========================================================================
function ItemDropSpecific_DragonWhelp_6_10 takes location loc returns nothing
    local integer randomIndex
    
    // Junk drops
    set ItemLootTable[1] = 'I140' // Sharp Claw
    set ItemLootTable[2] = 'I141' // Small Flame Sac
    set ItemLootTable[3] = 'I142' // Ruined Dragonhide
    
    // 1 in 6 chance for junk
    if GetRandomInt(1, 6) == 1 then
        set randomIndex = GetRandomInt(1, 3)
        call CreateItem(ItemLootTable[randomIndex], GetLocationX(loc), GetLocationY(loc))
    endif
    
    // 1 in 2 chance for scale
    if GetRandomInt(1, 2) == 1 then
        call CreateItem('I143', GetLocationX(loc), GetLocationY(loc)) // Whelp Scale
    endif
endfunction

//===========================================================================
// DRAGON WHELP DROPS (Level 16-20)
// Drops: Sharp Claw, Small Flame Sac, Ruined Dragonhide, Whelp Scale
// Drop chance: 1 in 6 for junk, 1 in 2 for scale
//===========================================================================
function ItemDropSpecific_DragonWhelp_16_20 takes location loc returns nothing
    local integer randomIndex
    
    // Junk drops
    set ItemLootTable[1] = 'I140' // Sharp Claw
    set ItemLootTable[2] = 'I141' // Small Flame Sac
    set ItemLootTable[3] = 'I142' // Ruined Dragonhide
    
    // 1 in 6 chance for junk
    if GetRandomInt(1, 6) == 1 then
        set randomIndex = GetRandomInt(1, 3)
        call CreateItem(ItemLootTable[randomIndex], GetLocationX(loc), GetLocationY(loc))
    endif
    
    // 1 in 2 chance for scale
    if GetRandomInt(1, 2) == 1 then
        call CreateItem('I143', GetLocationX(loc), GetLocationY(loc)) // Whelp Scale
    endif
endfunction

//===========================================================================
// MAIN HANDLER: Process unit-specific drops
// Uses Table lookup to determine loot type
//===========================================================================
function ItemDropSpecific_Process takes unit u, location loc returns boolean
    local integer lootType = UnitLootTypeTable[GetUnitTypeId(u)]
    
    // Check loot type and call appropriate handler
    if lootType == LOOT_TYPE_WOLF then
        call ItemDropSpecific_Wolf(loc)
        return true
    elseif lootType == LOOT_TYPE_STAG then
        call ItemDropSpecific_Stag(loc)
        return true
    elseif lootType == LOOT_TYPE_GNOLL then
        call ItemDropSpecific_Gnoll(loc)
        return true
    elseif lootType == LOOT_TYPE_DRAGON_WHELP_6_10 then
        call ItemDropSpecific_DragonWhelp_6_10(loc)
        return true
    elseif lootType == LOOT_TYPE_DRAGON_WHELP_16_20 then
        call ItemDropSpecific_DragonWhelp_16_20(loc)
        return true
    endif
    
    return false
endfunction

//===========================================================================
endlibrary
//===========================================================================
