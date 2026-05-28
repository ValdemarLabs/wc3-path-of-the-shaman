library ItemDropBoss requires ItemDropConfig
//===========================================================================
/*
    ItemDropBoss 1.0
    
    Author: [Valdemar]
    
    Description:
    Handles special drops from boss units. Each boss has unique loot tables
    and often drops quest items or guaranteed legendary items.
    
    Boss Units:
    - Deathlord Fel'Dok
    - Margul
    - Mur'gal
    - Sargoth
    - Unknown Entity
    - Rol'jin
    - Velaria (Succubus)
    - Colossus
    - Gollum
    - Mordrax
    - And more...
*/
//===========================================================================
globals
    // Quest item tracking variables (should be defined in quest system)
    // item ItemMagicalEye
    // item ItemTrollHead
    // item QuestDesolatorItem
endglobals

//===========================================================================
// BOSS: Deathlord Fel'Dok
// Drops: Helm of Fel'Dok, Weapon of Fel'Dok (guaranteed)
//===========================================================================
function ItemDropBoss_FelDok takes location loc returns nothing
    local integer randomIndex
    
    set ItemLootTable[1] = 'I200' // Helm of Fel'Dok
    set ItemLootTable[2] = 'I201' // Weapon of Fel'Dok
    
    set randomIndex = GetRandomInt(1, 2)
    call CreateItem(ItemLootTable[randomIndex], GetLocationX(loc), GetLocationY(loc))
endfunction

//===========================================================================
// BOSS: Margul
// Drops: Margul's Claw (guaranteed)
//===========================================================================
function ItemDropBoss_Margul takes location loc returns nothing
    call CreateItem('I210', GetLocationX(loc), GetLocationY(loc)) // Margul's Claw
endfunction

//===========================================================================
// BOSS: Mur'gal
// Drops: Eye of Mur'gal (quest item, invulnerable)
//===========================================================================
function ItemDropBoss_Murgal takes unit u, location loc returns nothing
    local item questItem
    
    call UnitAddItem(u, CreateItem('I220', GetLocationX(loc), GetLocationY(loc))) // Eye of Mur'gal
    set questItem = GetItemOfTypeFromUnitBJ(u, 'I220')
    call SetItemInvulnerable(questItem, true)
    // set ItemMagicalEye = questItem
    
    set questItem = null
endfunction

//===========================================================================
// BOSS: Sargoth
// Drops: Sargoth's Ichor (quest item, invulnerable)
//===========================================================================
function ItemDropBoss_Sargoth takes unit u, location loc returns nothing
    local item questItem
    
    call UnitAddItem(u, CreateItem('I230', GetLocationX(loc), GetLocationY(loc))) // Sargoth's Ichor
    set questItem = UnitItemInSlot(u, 0)
    call SetItemInvulnerable(questItem, true)
    
    set questItem = null
endfunction

//===========================================================================
// BOSS: Unknown Entity
// Drops: Orb of Darkness, Disgusting Slime (quest item)
//===========================================================================
function ItemDropBoss_UnknownEntity takes unit u, location loc returns nothing
    local item questItem
    
    // Regular drop
    call CreateItem('I240', GetLocationX(loc), GetLocationY(loc)) // Orb of Darkness
    
    // Quest item
    call UnitAddItem(u, CreateItem('I241', GetLocationX(loc), GetLocationY(loc))) // Disgusting Slime
    set questItem = UnitItemInSlot(u, 0)
    call SetItemInvulnerable(questItem, true)
    
    set questItem = null
endfunction

//===========================================================================
// BOSS: Rol'jin
// Drops: Rol'jin's Head (quest item, invulnerable)
//===========================================================================
function ItemDropBoss_Roljin takes unit u, location loc returns nothing
    local item questItem
    
    call UnitAddItem(u, CreateItem('I250', GetLocationX(loc), GetLocationY(loc))) // Rol'jin's Head
    set questItem = GetItemOfTypeFromUnitBJ(u, 'I250')
    call SetItemInvulnerable(questItem, true)
    // set ItemTrollHead = questItem
    
    set questItem = null
endfunction

//===========================================================================
// BOSS: Velaria (Succubus)
// Drops: Orb of Lifesteal (guaranteed)
//===========================================================================
function ItemDropBoss_Succubus takes location loc returns nothing
    call CreateItem('I260', GetLocationX(loc), GetLocationY(loc)) // Orb of Lifesteal
endfunction

//===========================================================================
// BOSS: Colossus (Level 15)
// Drops: 2 random epic/legendary items from loot table
//===========================================================================
function ItemDropBoss_Colossus takes location loc returns nothing
    local integer randomIndex
    
    // Setup loot table with epic/legendary items
    set ItemLootTable[1] = 'I270' // Blazing Obsidian Sharpblade
    set ItemLootTable[2] = 'I271' // Crown of the Molten Golem King
    set ItemLootTable[3] = 'I272' // Dragonforged Warboots
    set ItemLootTable[4] = 'I273' // Cloak of Dragonbound Mountain
    set ItemLootTable[5] = 'I274' // Infernal Sigil of Colossus
    
    // Drop first item
    set randomIndex = GetRandomInt(1, 5)
    call CreateItem(ItemLootTable[randomIndex], GetLocationX(loc), GetLocationY(loc))
    
    // Drop second item
    set randomIndex = GetRandomInt(1, 5)
    call CreateItem(ItemLootTable[randomIndex], GetLocationX(loc), GetLocationY(loc))
endfunction

//===========================================================================
// BOSS: Gollum (Level 13)
// Drops: The One Ring (guaranteed)
//===========================================================================
function ItemDropBoss_Gollum takes location loc returns nothing
    call CreateItem('I280', GetLocationX(loc), GetLocationY(loc)) // The One Ring
endfunction

//===========================================================================
// BOSS: Mordrax
// Drops: 2 random epic/legendary items + Scale of Mordrax (quest item)
//===========================================================================
function ItemDropBoss_Mordrax takes unit u, location loc returns nothing
    local integer randomIndex
    local item questItem
    
    // Display WIP message
    call DisplayTextToForce(GetPlayersAll(), "WIP: Create Mordrax...")
    
    // Setup loot table
    set ItemLootTable[1] = 'I270' // Blazing Obsidian Sharpblade
    set ItemLootTable[2] = 'I271' // Crown of the Molten Golem King
    set ItemLootTable[3] = 'I272' // Dragonforged Warboots
    set ItemLootTable[4] = 'I273' // Cloak of Dragonbound Mountain
    set ItemLootTable[5] = 'I274' // Infernal Sigil of Colossus
    
    // Drop first item
    set randomIndex = GetRandomInt(1, 5)
    call CreateItem(ItemLootTable[randomIndex], GetLocationX(loc), GetLocationY(loc))
    
    // Drop second item
    set randomIndex = GetRandomInt(1, 5)
    call CreateItem(ItemLootTable[randomIndex], GetLocationX(loc), GetLocationY(loc))
    
    // Quest item
    call UnitAddItem(u, CreateItem('I290', GetLocationX(loc), GetLocationY(loc))) // Scale of Mordrax
    set questItem = GetItemOfTypeFromUnitBJ(u, 'I290')
    call SetItemInvulnerable(questItem, true)
    // set QuestDesolatorItem = questItem
    
    set questItem = null
endfunction

//===========================================================================
// MAIN HANDLER: Process boss drops
// Uses Table lookup to determine boss type
//===========================================================================
function ItemDropBoss_Process takes unit u, location loc returns boolean
    local integer bossType = UnitLootTypeTable[GetUnitTypeId(u)]
    
    // Check if it's a boss and call appropriate handler
    if bossType == BOSS_FELDOK then
        call ItemDropBoss_FelDok(loc)
        return true
    elseif bossType == BOSS_MARGUL then
        call ItemDropBoss_Margul(loc)
        return true
    elseif bossType == BOSS_MURGAL then
        call ItemDropBoss_Murgal(u, loc)
        return true
    elseif bossType == BOSS_SARGOTH then
        call ItemDropBoss_Sargoth(u, loc)
        return true
    elseif bossType == BOSS_UNKNOWN_ENTITY then
        call ItemDropBoss_UnknownEntity(u, loc)
        return true
    elseif bossType == BOSS_ROLJIN then
        call ItemDropBoss_Roljin(u, loc)
        return true
    elseif bossType == BOSS_SUCCUBUS then
        call ItemDropBoss_Succubus(loc)
        return true
    elseif bossType == BOSS_COLOSSUS then
        call ItemDropBoss_Colossus(loc)
        return true
    elseif bossType == BOSS_GOLLUM then
        call ItemDropBoss_Gollum(loc)
        return true
    elseif bossType == BOSS_MORDRAX then
        call ItemDropBoss_Mordrax(u, loc)
        return true
    endif
    
    return false
endfunction

//===========================================================================
endlibrary
//===========================================================================
