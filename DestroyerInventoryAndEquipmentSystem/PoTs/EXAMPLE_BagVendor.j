/*
==============================================================================
EXAMPLE: Bag Vendor System for DInventory
==============================================================================
This example shows how to create vendors that sell inventory expansion bags.
You can integrate this with your shop system or item usage triggers.

Current Configuration:
- Initial inventory: 12 slots (3 rows x 4 columns)
- Expandable dynamically by purchasing bags

Suggested Bag Sizes:
- Small Bag:  +6 slots  (costs 100 gold)
- Medium Bag: +12 slots (costs 300 gold)
- Large Bag:  +20 slots (costs 750 gold)
- Massive Bag: +30 slots (costs 1500 gold)
==============================================================================
*/

library BagVendorExample initializer Init requires SharedDInvLib

globals
    // Bag item type IDs - replace these with your actual item IDs from Object Editor
    constant integer ITEM_SMALL_BAG = 'bag1'    // Small Bag - adds 6 slots
    constant integer ITEM_MEDIUM_BAG = 'bag2'   // Medium Bag - adds 12 slots
    constant integer ITEM_LARGE_BAG = 'bag3'    // Large Bag - adds 20 slots
    constant integer ITEM_MASSIVE_BAG = 'bag4'  // Massive Bag - adds 30 slots
    
    // Bag slot amounts
    constant integer SMALL_BAG_SLOTS = 6
    constant integer MEDIUM_BAG_SLOTS = 12
    constant integer LARGE_BAG_SLOTS = 20
    constant integer MASSIVE_BAG_SLOTS = 30
endglobals



// ============================================================================
// METHOD 1: Using item pickup/usage trigger
// ============================================================================
function BagItemUsed takes nothing returns nothing
    local item usedItem = GetManipulatedItem()
    local integer itemTypeId = GetItemTypeId(usedItem)
    local unit hero = GetTriggerUnit()
    local integer pid = GetPlayerId(GetOwningPlayer(hero))
    local integer slotsToAdd = 0
    
    // Determine which bag was used
    if itemTypeId == ITEM_SMALL_BAG then
        set slotsToAdd = SMALL_BAG_SLOTS
    elseif itemTypeId == ITEM_MEDIUM_BAG then
        set slotsToAdd = MEDIUM_BAG_SLOTS
    elseif itemTypeId == ITEM_LARGE_BAG then
        set slotsToAdd = LARGE_BAG_SLOTS
    elseif itemTypeId == ITEM_MASSIVE_BAG then
        set slotsToAdd = MASSIVE_BAG_SLOTS
    endif
    
    // If a valid bag item was identified
    if slotsToAdd > 0 then
        // Add slots using the vendor function (returns true if successful)
        if DInvAddSlotsForHeroVendor(hero, slotsToAdd) then
            // Successfully added slots - now remove the bag item
            call RemoveItem(usedItem)
            
            // Optional: Play a sound effect
            // call PlaySoundOnUnitBJ(gg_snd_ReceiveGold, 100, hero)
        else
            // Failed to add slots (probably hit the 340 slot limit)
            // Don't remove the bag item so player can sell it back or use it later
        endif
    endif
    
    set usedItem = null
    set hero = null
endfunction



// ============================================================================
// METHOD 2: Direct purchase from vendor unit (shop dialog based)
// ============================================================================
function VendorSellsBag takes unit buyer, integer bagSize, integer goldCost returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(buyer))
    local player p = Player(pid)
    
    // Check if player has enough gold
    if GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) >= goldCost then
        // Try to add inventory slots first
        if DInvAddSlotsForHeroVendor(buyer, bagSize) then
            // Success! Deduct gold
            call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) - goldCost)
            
            // Display purchase message
            if GetLocalPlayer() == p then
                call DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00Purchased bag expansion for " + I2S(goldCost) + " gold!|r")
            endif
            
            // Optional: Play purchase sound
            // call PlaySoundOnUnitBJ(gg_snd_ReceiveGold, 100, buyer)
        else
            // Failed - inventory already at maximum capacity
            // Error message already shown by DInvAddSlotsForHeroVendor
        endif
    else
        // Not enough gold
        if GetLocalPlayer() == p then
            call DisplayTimedTextToPlayer(p, 0, 0, 5, "|cffff0000Not enough gold! Need " + I2S(goldCost) + " gold.|r")
        endif
    endif
    
    set buyer = null
    set p = null
endfunction



// ============================================================================
// METHOD 3: Shop unit sells bags when unit comes in range (dialog menu)
// ============================================================================
function OpenBagShopDialog takes unit buyer, unit vendor returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(buyer))
    // This is a simplified example - you would typically use a more sophisticated dialog system
    
    if GetLocalPlayer() == Player(pid) then
        call DisplayTimedTextToPlayer(Player(pid), 0, 0, 15, "|cff00ffffBag Shop:|r")
        call DisplayTimedTextToPlayer(Player(pid), 0, 0, 15, "1. Small Bag (+6 slots) - 100 gold")
        call DisplayTimedTextToPlayer(Player(pid), 0, 0, 15, "2. Medium Bag (+12 slots) - 300 gold")
        call DisplayTimedTextToPlayer(Player(pid), 0, 0, 15, "3. Large Bag (+20 slots) - 750 gold")
        call DisplayTimedTextToPlayer(Player(pid), 0, 0, 15, "4. Massive Bag (+30 slots) - 1500 gold")
    endif
    
    // In a real implementation, you would:
    // 1. Create a dialog menu
    // 2. Add buttons for each bag type
    // 3. Register button click callbacks that call VendorSellsBag()
    
    set buyer = null
    set vendor = null
endfunction



// ============================================================================
// METHOD 4: Simple command-based purchase (for testing)
// ============================================================================
function BagPurchaseCommand takes nothing returns nothing
    local string command = GetEventPlayerChatString()
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local unit hero = null
    local group g = CreateGroup()
    
    // Get player's hero
    call GroupEnumUnitsOfPlayer(g, p, null)
    loop
        set hero = FirstOfGroup(g)
        exitwhen hero == null
        call GroupRemoveUnit(g, hero)
        if IsUnitType(hero, UNIT_TYPE_HERO) then
            exitwhen true
        endif
        set hero = null
    endloop
    call DestroyGroup(g)
    
    if hero != null then
        if command == "-bag small" or command == "-bag 1" then
            call VendorSellsBag(hero, SMALL_BAG_SLOTS, 100)
        elseif command == "-bag medium" or command == "-bag 2" then
            call VendorSellsBag(hero, MEDIUM_BAG_SLOTS, 300)
        elseif command == "-bag large" or command == "-bag 3" then
            call VendorSellsBag(hero, LARGE_BAG_SLOTS, 750)
        elseif command == "-bag massive" or command == "-bag 4" then
            call VendorSellsBag(hero, MASSIVE_BAG_SLOTS, 1500)
        endif
    endif
    
    set p = null
    set hero = null
    set g = null
endfunction



// ============================================================================
// Initialization
// ============================================================================
private function Init takes nothing returns nothing
    local trigger t = CreateTrigger()
    local trigger t2 = CreateTrigger()
    local integer i = 0
    
    // Register item usage trigger for all players
    loop
        exitwhen i > 11
        call TriggerRegisterPlayerUnitEvent(t, Player(i), EVENT_PLAYER_UNIT_USE_ITEM, null)
        call TriggerRegisterPlayerChatEvent(t2, Player(i), "-bag", false)
        set i = i + 1
    endloop
    
    call TriggerAddAction(t, function BagItemUsed)
    call TriggerAddAction(t2, function BagPurchaseCommand)
    
    set t = null
    set t2 = null
    
    // Debug message
    call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 15, "|cff00ff00Bag Vendor System loaded!|r Type -bag 1/2/3/4 to test purchasing bags.")
endfunction

endlibrary
