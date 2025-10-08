library DConfigurationArea initializer Init requires Table, GetItemCost

globals
// Systems and module enable / disable - - - - - - - - - - - - - - - - - - - - - -

boolean DInvRarityModuleUsed = TRUE
// This will be set to TRUE automatically if the DEquipment system library is copied into your map
boolean EquipmentSystemUsed = FALSE
// CONFIGURE these below if you use the Equipment system and want to use these modules
boolean DEqRarityModuleUsed = FALSE
boolean RandomEnchantModuleUsed = FALSE
boolean PlayerNamedItemsModuleUser = FALSE
boolean RandomNamedItemsModuleUsed = FALSE
// This will be set to TRUE automatically if the PersonalLootSys triggers are present and active
boolean PersonalLootSystemUsed = FALSE
// This will be set to TRUE automatically if the DStash system library is copied into your map
boolean StashSystemUsed = FALSE
boolean AlliedPlayerStashEnabled = FALSE
// This will be set to TRUE automatically if the NamedItem system library is copied into your map
boolean DEqNamedItemModuleUsed = FALSE
// This will be set to TRUE automatically if the ItemLevel system library is copied into your map
boolean DEqItemLevelModuleUsed = FALSE
boolean DEqSoulBoundModuleUsed = FALSE
// This will be set to TRUE automatically if the GrowthItem system library is copied into your map
boolean DEqGrowthItemModuleUsed = FALSE
// This will be set to TRUE automatically if the DEqSetItem system library is copied into your map
boolean SetItemModuleUsed = FALSE

//DInventory - - - - - - - - - - -
//Choose here whether each hero should have their separate inventories, or if 1 inventory should be shared by all heroes of a certain player
//string InventoryParadigm = "1PerPlayer"
string InventoryParadigm = "1PerHero"
//If you have 1PerHero paradigm, and below is set to true, any non-computer player hero will be automatically added to the system the first time they enter the map
//Otherwise you have to tell the system one by one which hero you want to have in the system with the function: InitializeDInventoryForUnit(yourunitvariable)
boolean AutomaticallyAddHeroesToTheSystem = FALSE
//Items that say "Droppable = False" in the Object Editor may be configured to be stored or not stored.
boolean MakeDInventoryAcceptUndroppableItems = FALSE
//Drop items that in the Object Editor are set to "Dropped on death = TRUE"
boolean MakeDInventoryDropDroppedOnDeathItems = TRUE
//Maximum number of slots PER PAGE may not exceed 340 in this system
// So do NOT make Rows*Colums > 340
integer InventoryPages = 1
integer InventoryColumns = 5
integer InventoryRows = 5
integer ColXRow = InventoryColumns * InventoryRows
//The actual number of items you can carry. If you want you can adjust this number mid-game.
// Or if you have 1 inventory per hero paradigm, you can use a function to adjust the number of items each individual can carry:
// By default it is assumed that you choose the number of rows, columns, pages to make up the inventory capacity
integer InventoryCapacityBase = ColXRow * InventoryPages
//If this is TRUE, then items picked up by heroes will automatically be attempted to be stored in the DInventory.
//If FALSE, you need to drag and drop every item from the vanilla inventory to the DInventory in order to store them
// currently it must be set to TRUE as the manual way is not yet implemented
boolean AutomaticDInventoryStorage = TRUE
// Press ctrl+d in the Object Editor to see an Ability's four character AbilityId. Make sure that the ability that opens / closes the inventory is given correctly here:
// Just copy paste mine, or better: export / import the abilities and the buffs as described in the documentation.
integer OpenDInventoryAbilityId = 'DInv'
// Stacking
// Note: The DInventory will only stack items that are of categories in the Object Editor: Power Up, Charged, Purchasable. If you want to change that you need to edit the code.
// Or you can just set your item to be in these categories.
boolean InfiniteStackingSystemAllowed = FALSE

// Gold value / Shop  - - - - - - - - - - -
real ShopResaleValueX = 1.0
// Multiplicative item value means that the multipliers from various subsystems multiply. These snowball pretty quickly, so you might want to use Additive Item Gold Value instead.
// Lets say you have a Legendary, named, set item, with itemlvl 21, for example. depending on your multipliers a few hundred gold value item can easily go into the tens of thousands
// Multiplicative equation: BaseItemValue * multiplier1 * multiplier2 * ... multiplierN
// Additive equation: BaseItemValue * ( multiplier1 + multiplier2 + ... multiplierN)
// Even if you disable the shop intercept code, this affects tooltips if you have automatically generated tooltips enabled
boolean MultiplicativeItemGoldCost = FALSE
boolean AdditiveItemGoldCost = TRUE

//DEquipment - - - - - - - - - - -
real EvasionMaxCap = -9999.0
real MeleeDMGTakenPctLowCap = -9999.0
real MagicDMGTakenPctLowCap = -9999.0
real PierceDMGTakenPctLowCap = -9999.0
real DefaultCritMultiplier = 1.5
real CleaveBaseArea = 150.0
// If you want the equipment related parts of tooltips to be generated by the system (at the cost of a tiny processing power) then leave this on TRUE.
// If you want the item's Extended Tooltip to be equal to the one you set up in the Object Editor, then set this to FALSE
// In case of FALSE, this is what you get: GetItemName(it)+"|n|n" + BlzGetItemExtendedTooltip(it)
boolean DEqTooltipAutoReadReq = TRUE
//If below is set to true, any non-computer player hero will be automatically added to the system the first time they enter the map
//Otherwise you have to tell the system one by one which hero you want to have in the system with the function: InitializeDEquipmentForUnit(yourunitvariable)
boolean AutomaticallyAddHeroesToTheDEqSystem = FALSE
//If you set it to TRUE then make sure you set the ability ID properly here! If TRUE then dual wield is only possible if the unit has the dual wield ability.
boolean DEqDualWieldRestrictionEnabled = TRUE
integer DEqDualWieldAbilityId = 'DEdw'

//DItemRarity - - - - - - - - - - -
// You may define which rarity is supposed to be default for nonequipment items.
integer DInvRarityDefaultRarity = -1

//DEqRarity - - - - - - - - - - - -
// You may define which rarity is supposed to be default for equipment items.
integer DEqRarityDefaultRarity = -1

//DEqItemLvl - - - - - - - - - - -
boolean MakeILvlTheMinimumRequiredLvl = TRUE

//DEqNamedItem - - - - - - - - - -

//GrowthItem - - - - - - - - - -

endglobals

// CONFIGURE THIS:
function DInvIsItemIdOnGlobalExclusionList takes integer iid returns boolean
// Returning TRUE means the system is not allowed to put these into the DInventory, and will remain in the vanilla inventory.
// Populate with the item IDs you do not want to be put into the DInventory!
// Items that say "Droppable = False" in the Object Editor may be configured to be stored or not stored. Go to the top, and adjust global variable: MakeDInventoryAcceptUndroppableItems
// You may also add items or itemTypeIds to the unit or player exclusion list with  the functions described in the documentation
if iid == 'ches' then
return TRUE
elseif iid == 'azhr' then
return TRUE
else
return FALSE
endif
endfunction

private function Init takes nothing returns nothing
endfunction

endlibrary