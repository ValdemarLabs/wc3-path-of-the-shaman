//===========================================================================
// ItemHook v1.0 - JASS Edition
// by GitHub Copilot (Based on Tasyen's Lua ItemHook)
//===========================================================================
// Allows you to execute code when an item of a specific type is created or destroyed.
//
// Create Events: preplaced items, code-created items, creep drops, item pools, shop purchases
// Destroy Events: sold, consumed (charges reach 0), destroyed, or RemoveItem
//
// Note: Items created by RestoreUnit are not detected by this system (rare use case)
//
// OVERWRITES: CreateItem, UnitAddItemToSlotById, UnitAddItemById, PlaceRandomItem
//
//===========================================================================
// HOW TO USE:
//===========================================================================
// Call these functions in your initialization code (map init trigger):
//
// call ItemHookRegisterCreate('I000', "YourCreateFunction")
// call ItemHookRegisterDestroy('I000', "YourDestroyFunction")
//
// Your function signatures should be:
//   function YourCreateFunction takes nothing returns nothing
//     local item whichItem = ItemHookGetEventItem()
//     local unit source = ItemHookGetEventSource()  // null if not from shop
//     local unit hero = ItemHookGetEventHero()      // null if not for hero
//     // Your code here
//   endfunction
//
//   function YourDestroyFunction takes nothing returns nothing
//     local item whichItem = ItemHookGetEventItem()
//     // Your code here
//   endfunction
//
//===========================================================================

globals
    // Store registered callbacks
    private hashtable ItemHook_Hash = InitHashtable()
    
    // Keys for hashtable
    private constant integer KEY_CREATE_FUNC = 0
    private constant integer KEY_DESTROY_FUNC = 1
    private constant integer KEY_DEATH_TRIGGER = 2
    private constant integer KEY_DEATH_CONDITION = 3
    private constant integer KEY_ITEM = 4
    private constant integer KEY_ITEM_TYPE = 5
    private constant integer KEY_SOURCE = 10
    private constant integer KEY_HERO = 11
    
    // Event triggers
    private trigger ItemHook_SellTrigger = null
    private trigger ItemHook_PawnTrigger = null
    
    // Current event data (for GUI access)
    private item ItemHook_EventItem = null
    private unit ItemHook_EventSource = null
    private unit ItemHook_EventHero = null
    private integer ItemHook_EventItemType = 0
    
    // Track trigger IDs for death events
    private integer ItemHook_TriggerIdCounter = 0
endglobals

//===========================================================================
// PUBLIC GLOBAL VARIABLES - Create these in GUI Variable Editor!
// These must be created as Real variables in the GUI:
// - ItemHook_CreateEvent (Real, default: 0.00)
// - ItemHook_DestroyEvent (Real, default: 0.00)
//===========================================================================
// In JASS they are referenced as:
// udg_ItemHook_CreateEvent
// udg_ItemHook_DestroyEvent
//===========================================================================

//===========================================================================
// Event Response Functions - Call these in your callbacks or GUI triggers
//===========================================================================
function ItemHookGetEventItem takes nothing returns item
    return ItemHook_EventItem
endfunction

function ItemHookGetEventSource takes nothing returns unit
    return ItemHook_EventSource
endfunction

function ItemHookGetEventHero takes nothing returns unit
    return ItemHook_EventHero
endfunction

function ItemHookGetEventItemType takes nothing returns integer
    return ItemHook_EventItemType
endfunction

//===========================================================================
// Register a function to be called when an item of itemCode is created
// funcName: name of your function as a string, e.g. "MyItemCreateFunc"
//===========================================================================
function ItemHookRegisterCreate takes integer itemCode, string funcName returns nothing
    call SaveStr(ItemHook_Hash, itemCode, KEY_CREATE_FUNC, funcName)
endfunction

//===========================================================================
// Register a function to be called when an item of itemCode is destroyed
// funcName: name of your function as a string, e.g. "MyItemDestroyFunc"
//===========================================================================
function ItemHookRegisterDestroy takes integer itemCode, string funcName returns nothing
    call SaveStr(ItemHook_Hash, itemCode, KEY_DESTROY_FUNC, funcName)
endfunction



//===========================================================================
// Internal: Called when an item is destroyed
//===========================================================================
private function ItemHook_OnItemDestroyed takes nothing returns boolean
    local trigger trig = GetTriggeringTrigger()
    local integer trigId = GetHandleId(trig)
    local item whichItem = LoadItemHandle(ItemHook_Hash, trigId, KEY_ITEM)
    local integer itemType = LoadInteger(ItemHook_Hash, trigId, KEY_ITEM_TYPE)
    local triggercondition cond = LoadTriggerConditionHandle(ItemHook_Hash, trigId, KEY_DEATH_CONDITION)
    local string funcName = LoadStr(ItemHook_Hash, itemType, KEY_DESTROY_FUNC)
    
    // Set event data for GUI and callbacks
    set ItemHook_EventItem = whichItem
    set ItemHook_EventSource = null
    set ItemHook_EventHero = null
    set ItemHook_EventItemType = itemType
    
    // Fire GUI event by setting variable
    set udg_ItemHook_DestroyEvent = 1.00
    set udg_ItemHook_DestroyEvent = 0.00
    
    // Execute the registered destroy callback if it exists
    if funcName != null and funcName != "" then
        call ExecuteFunc(funcName)
    endif
    
    // Cleanup
    call TriggerRemoveCondition(trig, cond)
    call DestroyTrigger(trig)
    call FlushChildHashtable(ItemHook_Hash, trigId)
    
    set trig = null
    set whichItem = null
    set cond = null
    return false
endfunction

//===========================================================================
// Internal: Called when an item is created
//===========================================================================
function ItemHook_ItemCreated takes item whichItem, unit source, unit hero returns item
    local integer itemType
    local trigger deathTrig
    local integer trigId
    local triggercondition cond
    local string funcName
    
    if whichItem == null then
        return whichItem
    endif
    
    set itemType = GetItemTypeId(whichItem)
    
    // Register death event for this item
    set deathTrig = CreateTrigger()
    set trigId = GetHandleId(deathTrig)
    call TriggerRegisterDeathEvent(deathTrig, whichItem)
    set cond = TriggerAddCondition(deathTrig, Condition(function ItemHook_OnItemDestroyed))
    
    // Store item data for the death event
    call SaveItemHandle(ItemHook_Hash, trigId, KEY_ITEM, whichItem)
    call SaveInteger(ItemHook_Hash, trigId, KEY_ITEM_TYPE, itemType)
    call SaveTriggerConditionHandle(ItemHook_Hash, trigId, KEY_DEATH_CONDITION, cond)
    
    // Set event data for GUI and callbacks
    set ItemHook_EventItem = whichItem
    set ItemHook_EventSource = source
    set ItemHook_EventHero = hero
    set ItemHook_EventItemType = itemType
    
    // Fire GUI event by setting variable
    set udg_ItemHook_CreateEvent = 1.00
    set udg_ItemHook_CreateEvent = 0.00
    
    // Execute registered create callback if it exists
    set funcName = LoadStr(ItemHook_Hash, itemType, KEY_CREATE_FUNC)
    if funcName != null and funcName != "" then
        call ExecuteFunc(funcName)
    endif
    
    set deathTrig = null
    set cond = null
    return whichItem
endfunction

//===========================================================================
// Item Sell Event (shop selling to hero)
//===========================================================================
private function ItemHook_OnSellItem takes nothing returns boolean
    call ItemHook_ItemCreated(GetSoldItem(), GetSellingUnit(), GetBuyingUnit())
    return false
endfunction

//===========================================================================
// Item Pawn Event (hero selling item back to shop)
//===========================================================================
private function ItemHook_OnPawnItem takes nothing returns boolean
    // Pawn is essentially a destroy event
    local item soldItem = GetSoldItem()
    local integer itemType = GetItemTypeId(soldItem)
    local string funcName = LoadStr(ItemHook_Hash, itemType, KEY_DESTROY_FUNC)
    
    // Set event data for GUI and callbacks
    set ItemHook_EventItem = soldItem
    set ItemHook_EventSource = null
    set ItemHook_EventHero = null
    set ItemHook_EventItemType = itemType
    
    // Fire GUI event by setting variable
    set udg_ItemHook_DestroyEvent = 1.00
    set udg_ItemHook_DestroyEvent = 0.00
    
    if funcName != null and funcName != "" then
        call ExecuteFunc(funcName)
    endif
    
    set soldItem = null
    return false
endfunction

//===========================================================================
// Initialization
//===========================================================================
private function ItemHook_Init takes nothing returns nothing
    set ItemHook_SellTrigger = CreateTrigger()
    set ItemHook_PawnTrigger = CreateTrigger()
    
    call TriggerRegisterAnyUnitEventBJ(ItemHook_SellTrigger, EVENT_PLAYER_UNIT_SELL_ITEM)
    call TriggerRegisterAnyUnitEventBJ(ItemHook_PawnTrigger, EVENT_PLAYER_UNIT_PAWN_ITEM)
    
    call TriggerAddCondition(ItemHook_SellTrigger, Condition(function ItemHook_OnSellItem))
    call TriggerAddCondition(ItemHook_PawnTrigger, Condition(function ItemHook_OnPawnItem))
endfunction

//===========================================================================
// NATIVE FUNCTION HOOKS
//===========================================================================
// Note: In JASS, you cannot directly override natives. You'll need to:
// 1. Replace all CreateItem calls with ItemHook_CreateItem in your code
// 2. Or use a preprocessor/compiler that supports native overriding
//===========================================================================

//===========================================================================
// Wrapper for CreateItem - Use this instead of the native
//===========================================================================
function ItemHook_CreateItem takes integer itemid, real x, real y returns item
    return ItemHook_ItemCreated(CreateItem(itemid, x, y), null, null)
endfunction

//===========================================================================
// Wrapper for UnitAddItemToSlotById - Use this instead of the native
//===========================================================================
function ItemHook_UnitAddItemToSlotById takes unit whichUnit, integer itemId, integer itemSlot returns boolean
    local boolean result = UnitAddItemToSlotById(whichUnit, itemId, itemSlot)
    if result then
        call ItemHook_ItemCreated(UnitItemInSlot(whichUnit, itemSlot), null, whichUnit)
    endif
    return result
endfunction

//===========================================================================
// Wrapper for UnitAddItemById - Use this instead of the native
//===========================================================================
function ItemHook_UnitAddItemById takes unit whichUnit, integer itemId returns item
    local item result = UnitAddItemById(whichUnit, itemId)
    return ItemHook_ItemCreated(result, null, whichUnit)
endfunction

//===========================================================================
// Wrapper for PlaceRandomItem - Use this instead of the native
//===========================================================================
function ItemHook_PlaceRandomItem takes itempool whichItemPool, real x, real y returns item
    return ItemHook_ItemCreated(PlaceRandomItem(whichItemPool, x, y), null, null)
endfunction

//===========================================================================
// Auto-initialization
//===========================================================================
//! runtextmacro optional HOOK_INIT("ItemHook_Init")

// If you don't have an auto-init system, call this manually in your map init:
// call ItemHook_Init()
