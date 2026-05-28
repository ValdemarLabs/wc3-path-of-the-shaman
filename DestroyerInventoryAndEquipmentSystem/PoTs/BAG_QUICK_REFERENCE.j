/*
==============================================================================
QUICK REFERENCE: DInventory Bag System
==============================================================================
Copy these code snippets directly into your triggers for quick implementation.
==============================================================================
*/

// ============================================================================
// VENDOR FUNCTION - Copy this entire block into your shop/vendor trigger
// ============================================================================

function BuyInventoryBag takes unit buyer, integer bagTier returns nothing
    // bagTier: 1=Small(6), 2=Medium(12), 3=Large(20), 4=Massive(30)
    local player p = GetOwningPlayer(buyer)
    local integer pid = GetPlayerId(p)
    local integer slots = 0
    local integer cost = 0
    
    // Determine bag stats
    if bagTier == 1 then
        set slots = 6
        set cost = 100
    elseif bagTier == 2 then
        set slots = 12
        set cost = 300
    elseif bagTier == 3 then
        set slots = 20
        set cost = 750
    elseif bagTier == 4 then
        set slots = 30
        set cost = 1500
    else
        return  // Invalid tier
    endif
    
    // Check gold
    if GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) >= cost then
        // Deduct gold
        call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, 
            GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) - cost)
        
        // Add inventory slots
        call DInvAddSlotsForHeroVendor(buyer, slots)
        
        // Success message (already shown by DInvAddSlotsForHeroVendor)
        // Optional: Add sound effect here
    else
        // Not enough gold
        if GetLocalPlayer() == p then
            call DisplayTimedTextToPlayer(p, 0, 0, 5, 
                "|cffff0000Not enough gold! Need " + I2S(cost) + " gold.|r")
        endif
    endif
    
    set p = null
    set buyer = null
endfunction

// Usage in your trigger:
// call BuyInventoryBag(GetTriggerUnit(), 2)  // Buys Medium Bag


// ============================================================================
// CONSUMABLE BAG ITEM - Use this for bag items that are consumed on use
// ============================================================================

function UseBagItem takes nothing returns nothing
    local item it = GetManipulatedItem()
    local integer iid = GetItemTypeId(it)
    local unit u = GetTriggerUnit()
    local integer slots = 0
    
    // Check which bag was used (replace 'bag1' etc with your item IDs)
    if iid == 'bag1' then       // Small Bag
        set slots = 6
    elseif iid == 'bag2' then   // Medium Bag
        set slots = 12
    elseif iid == 'bag3' then   // Large Bag
        set slots = 20
    elseif iid == 'bag4' then   // Massive Bag
        set slots = 30
    endif
    
    if slots > 0 then
        call RemoveItem(it)
        call DInvAddSlotsForHeroVendor(u, slots)
    endif
    
    set it = null
    set u = null
endfunction

// Register this trigger:
// call TriggerRegisterAnyUnitEventBJ(yourTrigger, EVENT_PLAYER_UNIT_USE_ITEM)
// call TriggerAddAction(yourTrigger, function UseBagItem)


// ============================================================================
// TESTING COMMAND - Type "-bag #" in game to test bag purchases
// ============================================================================

function TestBagCommand takes nothing returns nothing
    local string s = GetEventPlayerChatString()
    local player p = GetTriggerPlayer()
    local unit hero = GetTriggerPlayerHero()
    local integer tier = 0
    
    // Extract tier from command (e.g., "-bag 2" -> tier = 2)
    if SubString(s, 0, 5) == "-bag " then
        set tier = S2I(SubString(s, 5, StringLength(s)))
        
        if tier > 0 and tier <= 4 then
            call BuyInventoryBag(hero, tier)
        endif
    endif
    
    set p = null
    set hero = null
endfunction

// Register this trigger:
// call TriggerRegisterPlayerChatEvent(yourTrigger, Player(0), "-bag", false)
// call TriggerAddAction(yourTrigger, function TestBagCommand)


// ============================================================================
// DIALOG SHOP EXAMPLE - Show a dialog menu for bag purchases
// ============================================================================

globals
    dialog array BagShopDialog[12]  // One per player
    button array BagButton[48]      // 12 players * 4 bag types
endglobals

function BagShopButtonClicked takes nothing returns nothing
    local button b = GetClickedButton()
    local integer pid = 0
    local integer tier = 0
    local unit hero = null
    local integer i = 0
    
    // Find which button was clicked
    loop
        exitwhen i >= 48
        if b == BagButton[i] then
            set pid = i / 4
            set tier = ModuloInteger(i, 4) + 1
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    // Get player's hero
    set hero = GetTriggerPlayerHero()
    
    if hero != null then
        call BuyInventoryBag(hero, tier)
    endif
    
    set b = null
    set hero = null
endfunction

function CreateBagShopDialog takes integer pid returns nothing
    local dialog d = DialogCreate()
    local button b
    
    set BagShopDialog[pid] = d
    
    call DialogSetMessage(d, "Bag Shop - Expand Your Inventory")
    
    // Add buttons
    set BagButton[pid*4 + 0] = DialogAddButton(d, "Small Bag (+6 slots) - 100 gold", 0)
    set BagButton[pid*4 + 1] = DialogAddButton(d, "Medium Bag (+12 slots) - 300 gold", 0)
    set BagButton[pid*4 + 2] = DialogAddButton(d, "Large Bag (+20 slots) - 750 gold", 0)
    set BagButton[pid*4 + 3] = DialogAddButton(d, "Massive Bag (+30 slots) - 1500 gold", 0)
    
    set d = null
    set b = null
endfunction

function ShowBagShop takes player p returns nothing
    call DialogDisplay(p, BagShopDialog[GetPlayerId(p)], true)
endfunction

// Initialize dialogs for all players:
// loop from i=0 to 11
//     call CreateBagShopDialog(i)
// endloop
// Set up trigger for button clicks:
//     call TriggerAddAction(yourTrigger, function BagShopButtonClicked)


// ============================================================================
// DIRECT API CALLS - For advanced users who want manual control
// ============================================================================

// For "1PerPlayer" paradigm (all heroes share inventory):
// call DInvDeltaAdditionalSlotsForPlayer(playerId, numberOfSlots)

// For "1PerHero" paradigm (each hero has separate inventory):
// call DInvDeltaAdditionalSlotsForUnit(heroUnit, numberOfSlots)

// For specific Bag ID:
// call DInvDeltaAdditionalSlotsForBID(bagId, numberOfSlots)

// Wrapper function (auto-detects paradigm):
// call DInvAddSlotsForHeroVendor(heroUnit, numberOfSlots)
// call DInvAddSlotsForPlayerVendor(playerId, numberOfSlots)


// ============================================================================
// SHOP UNIT INTERACTION - Trigger when unit comes near vendor
// ============================================================================

function VendorNearby takes nothing returns nothing
    local unit vendor = GetTriggerUnit()
    local unit customer = GetEnteringUnit()
    local player p = GetOwningPlayer(customer)
    
    if IsUnitType(customer, UNIT_TYPE_HERO) then
        // Show shop dialog
        call ShowBagShop(p)
    endif
    
    set vendor = null
    set customer = null
    set p = null
endfunction

// Register this for your vendor unit:
// local region vendorRegion = CreateRegion()
// call RegionAddRect(vendorRegion, Rect(x-256, y-256, x+256, y+256))
// call TriggerRegisterEnterRegion(yourTrigger, vendorRegion, null)
// call TriggerAddAction(yourTrigger, function VendorNearby)
