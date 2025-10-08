//TESH.scrollpos=0
//TESH.alwaysfold=0
//=====================================================================================
// Easy Item Stack 'n Split v2.7.4
//  by Dangerb0y
//=====================================================================================
library EasyItemStacknSplit initializer onInit
//=====================================================================================
//
// This system adds some much needed item stacking, item splitting, and full inventory
// functionality to Warcraft III.
//
// A couple of useful functions are also included...
//
// - UnitInventoryFull( unit )
//     Returns true if all of a unit's inventory slots are occupied, else false.
//
// - UnitStackItem( unit, item )
//     Works like UnitAddItem(), but will try to stack items even if inventory is full.
//     If excess items from an item stack are dropped, returns the item, else null.
//
//=====================================================================================
// SYSTEM PARAMETERS
//=====================================================================================
globals
    // Allow item splitting with double right-click?
    private boolean SPLIT = true
    
    // Amount to split from stack... (0 = half)
    private integer SPLIT_SIZE = 1
    
    // Allow consecutively split items to stack together?
    private boolean SPLIT_STACK = true
    private real SPLIT_STACK_DELAY = 2.00
    
    // Allow split items to be dropped if no inventory slots are open?
    private boolean SPLIT_DROP = true
    
    // Use item levels to determine stack limit? (false = unlimited stacks)
    private boolean USE_ITEM_LEVEL = true
    
    // Full inventory error sound filename... (null = disabled)
    private string ERROR_SOUND = "Sound\\Interface\\Error.wav"
    private string ERROR_MESSAGE = "Inventory is full."

    private integer array DUMMY_ITEM_TYPES
    private integer array REAL_ITEM_TYPES
    private integer DUMMY_ITEMS_COUNT
endglobals

    function InitDummyItemPairs takes nothing returns nothing
        // Since BlzSetItemBooleanField does not work, to allow buying items with full inventory we are forced to do this
        // For each item with charges, we created a tome-like dummy copy with "use automatically on acquired" = true.
        // Such dummy items can be clicked-bought even with full inventory, contrary to other items.
        set DUMMY_ITEM_TYPES[0] = 'I001' // 1st dummy item bought from shop
        set REAL_ITEM_TYPES[0] = 'dust' // 1st real item heroes can use
        set DUMMY_ITEM_TYPES[1] = 'I000'
        set REAL_ITEM_TYPES[1] = 'stwp'
    endfunction

//=====================================================================================
// DO NOT EDIT BELOW THIS LINE
//=====================================================================================

    globals
        private unit array goPickButFullUnits
        private unit array splitStackUnits
        private item array goPickButFullItems
        private item array splitStackItem1s
        private item array splitStackItem2s
        private real array splitStackDelays
        private integer goPickButFullCount = 0
        private integer splitStackCount = 0
        private timer t = CreateTimer()
    endglobals
    
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    // PUBLIC FUNCTION : UnitInventoryFull( unit )
    //  Checks if all the inventory slots of a unit are occupied.
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    function UnitInventoryFull takes unit u returns boolean
        local integer inventorySize = UnitInventorySize( u )
        local integer slot = 0
        loop
            exitwhen slot >= inventorySize
            if UnitItemInSlot(u, slot) == null then
                return false
            endif
            set slot = slot + 1
        endloop
        return true
    endfunction

    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    // PUBLIC FUNCTION : FireStackChangedEvent( unit, item )
    //  Fire an event to signal that the stack size on an item carriet has changed.
    //  The solution decided for the moment is to trigger a "Unit - is issued an order targeting item" to move it in-place event.
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    function FireStackChangedEvent takes unit u, item i returns nothing
        local integer inventorySize = UnitInventorySize(u)
        local integer slot = 0
        
        // Retrieve the item's slot
        loop
             if ( UnitItemInSlot(u, slot) == i ) then
                 exitwhen true // item's slot found
             endif
             set slot = slot + 1
             exitwhen slot >= inventorySize
        endloop
        
        if ( slot < inventorySize ) then
            call DisableTrigger( gg_trg_EasyItemStacknSplit )
            call UnitDropItemSlot( u, i, slot )
            call EnableTrigger( gg_trg_EasyItemStacknSplit )
        endif
    endfunction
 
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    // PUBLIC FUNCTION : UnitStackItem( unit, item )
    //  Works like UnitAddItem() with full inventory functionality.
    //  Returns true if excess items are dropped. Otherwise false.
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    function UnitStackItem takes unit u, item item1 returns boolean
        local integer item1Charges = GetItemCharges( item1 )
        local integer inventorySize
        local integer item1Level
        local integer item1TypeId
        local item item2
        local integer item2Charges
        local integer item2Level
        local integer slot
        local real posX
        local real posY
        local real unitAngle

        // Make sure the item has charges
        if item1Charges <= 0 then
            // If not we just give it to the unit
            call DisableTrigger( gg_trg_EasyItemStacknSplit )
            call UnitAddItem( u, item1 )
            call EnableTrigger( gg_trg_EasyItemStacknSplit )
        else
            // Item has charges
            set inventorySize = UnitInventorySize( u )
            set item1Level = GetItemLevel( item1 )
            set item1TypeId = GetItemTypeId( item1 )
            // We can remove the item, we have all the data we need from it
            call RemoveItem( item1 )
            // Look for items of the same type and try stack onto them
            set slot = 0
            loop
                set item2 = UnitItemInSlot( u, slot )
                set item2Charges = GetItemCharges( item2 )
                set item2Level = GetItemLevel( item2 )
                if item2 != null and (not USE_ITEM_LEVEL or item2Level == 0 or item2Charges < item2Level) and GetItemTypeId(item2) == item1TypeId then
                    // Found an item with same type and room for some charges
                    if USE_ITEM_LEVEL and item2Level > 0 and item2Charges + item1Charges > item2Level then
                        // Not all charges can be stacked onto this item, stack as many as possible and keep the rest
                        call SetItemCharges( item2, item2Level )
                        call FireStackChangedEvent(u,item2)
                        set item1Charges = item2Charges + item1Charges - item2Level
                    else
                        // All charges can be stacked onto this item
                        call SetItemCharges( item2, item2Charges + item1Charges )
                        call FireStackChangedEvent(u,item2)
                        set item1Charges = 0
                    endif
                endif
                set slot = slot + 1
                exitwhen item1Charges <= 0 or slot >= inventorySize
            endloop
            // If there are any charges left over, look for open slots
            if item1Charges > 0 then
                // There are charges left
                set posX = GetUnitX( u )
                set posY = GetUnitY( u )
                set slot = 0
                loop
                    // Create as many items as necessary and possible in the unit inventory
                    set item2 = UnitItemInSlot( u, slot )
                    if item2 == null then
                        // There is a free slot: create a new item there for the remaining charges
                        set item2 = CreateItem( item1TypeId, posX, posY )
                        if USE_ITEM_LEVEL and item1Level > 0 and item1Charges > item1Level then
                            // Not all charges can fit in a single item, just put as many as possible
                            call SetItemCharges( item2, item1Level )
                            set item1Charges = item1Charges - item1Level
                        else
                            // All charges fit in this new item
                            call SetItemCharges( item2, item1Charges )
                            set item1Charges = 0
                        endif
                        call DisableTrigger( gg_trg_EasyItemStacknSplit )
                        call UnitAddItem( u, item2 )
                        call EnableTrigger( gg_trg_EasyItemStacknSplit )
                    endif
                    set slot = slot + 1
                    exitwhen item1Charges <= 0 or slot >= inventorySize
                endloop
                // If there are still charges left over, drop them on the ground
                if item1Charges > 0 then
                    // There are some charges left that cannot be carried
                    set unitAngle = GetUnitFacing( u )
                    set posX = GetUnitX( u ) + 100 * Cos( unitAngle * bj_DEGTORAD )
                    set posY = GetUnitY( u ) + 100 * Sin( unitAngle * bj_DEGTORAD )
                    loop
                        // Create a many items as necessary on the floor
                        if item1Charges > item1Level then
                            // Not all charges can find in a single
                            set item2Charges = item1Level
                            set item1Charges = item1Charges - item1Level
                        else
                            // All charges can fit in a single item
                            set item2Charges = item1Charges
                            set item1Charges = 0
                        endif
                        set item2 = CreateItem( item1TypeId, posX, posY )
                        call SetItemCharges( item2, item2Charges )
                        exitwhen item1Charges <= 0
                    endloop
                    return true
                endif
            endif
        endif
        // Nothing dropped
        return false
    endfunction
   
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    // TEXTMACRO : EasyItemStacknSplit_PLAYITEMSOUND( soundname, unitvar )
    //  Plays item sound for player if the triggering unit is nearby.
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    //! textmacro EasyItemStacknSplit_PLAYITEMSOUND takes FILENAME
        set str = "Sound\\Interface\\$FILENAME$.wav"
        
        set snd = CreateSound( str, false, true, false, 12700, 12700, "" )
        call AttachSoundToUnit( snd, u )
        call SetSoundVolume( snd, 75 )
        call SetSoundDistances( snd, 600.0, 1024.0 )
        call SetSoundDistanceCutoff( snd, 1536.0 )
        if GetLocalPlayer() != p then
            call StartSound( snd )
        endif
        call KillSoundWhenDone( snd )
    //! endtextmacro

    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    // CONTROLLER : TimerController
    //  EVENTS : Global Timer (t) expires (periodically, 0.05)
    //  Runs through full-stack and split-stack queues, and works its magic.
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    private function TimerController takes nothing returns nothing
        local unit u
        local item item1
        local item item2
        local integer index
        local integer orderId
        local real deltax
        local real deltay
        local real delay
        local player p
        local string str
        local sound snd
        // Run through the go-pick-but-full actions stack queue
        if goPickButFullCount > 0 then
            set index = 0
            loop
                set u = goPickButFullUnits[index]
                set item1 = goPickButFullItems[index]
                if u != null and item1 != null and not IsItemOwned(item1) and GetWidgetLife(item1) > 0 and GetWidgetLife(u) > 0 then
                    // Unit and items are still untouched
                    set orderId = GetUnitCurrentOrder( u )
                    set deltax = GetItemX( item1 ) - GetUnitX( u )
                    set deltay = GetItemY( item1 ) - GetUnitY( u )
                    if deltax * deltax + deltay * deltay <= 22500 or orderId != 851986 then
                        // Unit has reached the item, or unit is not currently moving
                        if orderId == 851986 then
                            // Unit is moving - get the item and try to stack it
                            set p = GetOwningPlayer( u )
                            // Play the "Item Get" sound
                            //! runtextmacro EasyItemStacknSplit_PLAYITEMSOUND( "PickUpItem" )
                            call IssueImmediateOrder( u, "stop" )
                            call SetUnitFacing( u, bj_RADTODEG * Atan2(GetItemY(item1) - GetUnitY(u), GetItemX(item1) - GetUnitX(u)) )
                            if UnitStackItem(u, item1) then
                                // Couldn't stack all the charges, somes have been left on the floor, play the "Item Drop" sound
                                //! runtextmacro EasyItemStacknSplit_PLAYITEMSOUND( "HeroDropItem1" )
                            endif
                        endif
                        set goPickButFullCount = goPickButFullCount - 1
                        if goPickButFullCount > 0 then
                            // To fill the hole in the queue, move-in the last action
                            set goPickButFullUnits[index] = goPickButFullUnits[goPickButFullCount]
                            set goPickButFullItems[index] = goPickButFullItems[goPickButFullCount]
                            set index = index - 1
                        endif
                    endif
                elseif u != null or item1 != null then
                    // The item has been destroyed or picked by someone else
                    call IssueImmediateOrder( u, "stop" )
                    set goPickButFullCount = goPickButFullCount - 1
                    if goPickButFullCount > 0 then
                        // To fill the hole in the queue, move-in the last action
                        set goPickButFullUnits[index] = goPickButFullUnits[goPickButFullCount]
                        set goPickButFullItems[index] = goPickButFullItems[goPickButFullCount]
                        set index = index - 1
                    endif
                endif
                set index = index + 1
                exitwhen index >= goPickButFullCount
            endloop
        endif
        // Run through split-stack actions queue
        if SPLIT_STACK and splitStackCount > 0 then
            set index = 0
            loop
                set u = splitStackUnits[index]
                set item1 = splitStackItem1s[index]
                set item2 = splitStackItem2s[index]
                set delay = splitStackDelays[index]
                if u != null and item1 != null and item2 != null and delay > 0 and UnitHasItem(u, item1) and UnitHasItem(u, item2) then
                    // Unit still carries both items - split&stack may have not been resolved yet
                    set splitStackDelays[index] = delay - 0.05
                else
                    // Split-stack has been finished somehow
                    set splitStackCount = splitStackCount - 1
                    if splitStackCount > 0 then
                        // To fill the hole in the queue, move-in the last action
                        set splitStackUnits[index] = splitStackUnits[splitStackCount]
                        set splitStackItem1s[index] = splitStackItem1s[splitStackCount]
                        set splitStackItem2s[index] = splitStackItem2s[splitStackCount]
                        set splitStackDelays[index] = splitStackDelays[splitStackCount]
                        set index = index - 1
                    endif
                endif
                set index = index + 1
                exitwhen index >= splitStackCount
            endloop
        endif
        // Pause timer if not needed
        if goPickButFullCount <= 0 and (not SPLIT_STACK or splitStackCount <= 0) then
            // If all timed events have been resolved, pause the timer
            call PauseTimer( t )
        endif
        set u = null
        set item1 = null
        set p = null
        set snd = null
    endfunction

    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    // CONTROLLER : CancelController
    //  EVENTS : Unit Targets Point
    //  Flushes trigger-unit and target-item from timer queue.
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    private function CancelController takes nothing returns boolean
        local integer index = 0
        if goPickButFullCount > 0 then
            loop
                if goPickButFullUnits[index] == GetTriggerUnit() and (GetOrderPointX() != GetItemX(goPickButFullItems[index]) or GetOrderPointY() != GetItemY(goPickButFullItems[index])) then
                    set goPickButFullCount = goPickButFullCount - 1
                    if goPickButFullCount > 0 then
                        set goPickButFullUnits[index] = goPickButFullUnits[goPickButFullCount]
                        set goPickButFullItems[index] = goPickButFullItems[goPickButFullCount]
                        set index = index - 1
                    elseif not SPLIT_STACK or splitStackCount <= 0 then
                        call PauseTimer( t )
                    endif
                endif
                set index = index + 1
                exitwhen index >= goPickButFullCount
            endloop
        endif
        return false
    endfunction

    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    // CONTROLLER : ActionController
    //  EVENTS : Unit Acquires Item, Unit Targets Object
    //  Main system controller. Determines unit order and runs actions accordingly.
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    private function ActionController takes nothing returns boolean
        local eventid eventId = GetTriggerEventId()
        local unit u = GetTriggerUnit()
        local integer inventorySize = UnitInventorySize(u)
        local player p
        local integer orderId
        local item item1 // Item being manipulated
        local integer item1TypeId
        local integer item1Charges
        local integer item1Level
        local item item2 // Either target or newly created item
        local integer item2Charges
        local integer item2Level
        local integer item2Slot
        local integer index
        local integer splitChargeCount
        local location pos
        local boolean full
        local real unitAngle
        local string str
        local sound snd

        // Only units with not-null inventory are relevant
        if (inventorySize == 0) then
            return false
        endif

        // Detect if triggering event is "unit acquires an item" or "unit is issued an order targeting item"
        if (eventId == EVENT_PLAYER_UNIT_PICKUP_ITEM) then
            // Unit acquired an item
            set item1 = GetManipulatedItem()
            if (item1 != null) then
                // Could it be a dummy item (allow buying items with full inventory)
                if ( BlzGetItemBooleanField(item1, ITEM_BF_USE_AUTOMATICALLY_WHEN_ACQUIRED) == true ) then
                    // Compare to the dummy item list
                    set index = 0
                    loop
                        exitwhen (DUMMY_ITEM_TYPES[index] == null or REAL_ITEM_TYPES[index] == null)
                        if (GetItemTypeId(item1) == DUMMY_ITEM_TYPES[index] ) then
                            // Dummy item found > replace with the real one
                            call RemoveItem(item1)
                            call DisplayTextToForce( GetPlayersAll(), "Removing dummy item" )
                            set pos = GetUnitLoc(u)
                            set item1 = CreateItemLoc( REAL_ITEM_TYPES[index], pos )
                            call DisplayTextToForce( GetPlayersAll(), "Creating real item" )
                            call RemoveLocation(pos)
                            exitwhen true
                        endif
                        set index = index + 1
                    endloop
                endif
                if ( BlzGetItemBooleanField(item1, ITEM_BF_USE_AUTOMATICALLY_WHEN_ACQUIRED) == true and GetItemCharges(item1) == 1 ) then
                    // Nothing to add in inventory, all charges will be used on acquisition
                else
                    // The item is being acquired so we stack it
                    if UnitStackItem(u, item1) then
                        // Couldnot stack all charges in inventory, some remain on the floor. Play the "Item Drop" sound
                        set p = GetOwningPlayer( u )
                        //! runtextmacro EasyItemStacknSplit_PLAYITEMSOUND( "HeroDropItem1.wav" )
                    endif
                endif
            endif
        elseif (eventId == EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER) then
            // Unit is issued an order targeting an object: attack, attack once, move to, right click, moveslot<1-6>
            set item1 = GetOrderTargetItem()
            if (item1 != null) then
                if ( BlzGetItemBooleanField(item1, ITEM_BF_USE_AUTOMATICALLY_WHEN_ACQUIRED) == true and GetItemCharges(item1) == 1 ) then
                    // Nothing to add in inventory, all charges will be used on acquisition
                else
                    set orderId = GetIssuedOrderId()
                    if (orderId == 851971) then
                        // The item is on the floor and left clicked (going to pick it)
                        if UnitInventoryFull(u) then
                            // The item is being targeted with a full inventory so we add it to the timer queue
                            set item1Charges = GetItemCharges( item1 )
                            set index = 0
                            if ( item1Charges > 0 ) then
                                // Item with charges, look up if there is an item available to receive those charges in unit inventory
                                set item1Level = GetItemLevel( item1 )
                                set item1TypeId = GetItemTypeId( item1 )
                                set index = 0
                                loop
                                    set item2 = UnitItemInSlot( u, index )
                                    set item2Level = GetItemLevel( item2 )
                                    if item2 != item1 and GetItemTypeId(item2) == item1TypeId and (not USE_ITEM_LEVEL or item2Level == 0 or GetItemCharges(item2) < item2Level) then
                                        // Found item with same type 
                                        set index = inventorySize + 1
                                    else
                                        set index = index + 1
                                    endif
                                    exitwhen index >= inventorySize
                                endloop
                            endif
                            // Is it possible to pick some charges or not ?
                            if index > inventorySize then
                                // Inventory has room to receive the charges
                                set index = 0
                                if goPickButFullCount > 0 then
                                    // Check if unit is already moving to pick other charges
                                    loop
                                        if goPickButFullUnits[index] == u then
                                            set goPickButFullItems[index] = item1 // Update the parameters
                                            set index = -1
                                        else
                                            set index = index + 1
                                        endif
                                        exitwhen index >= goPickButFullCount or index == -1
                                    endloop
                                endif
                                if index >= 0 then
                                    // No previous go-pick-but-full action, just check if the timer should be started and append this action
                                    if goPickButFullCount == 0 then
                                        call TimerStart( t, 0.05, true, function TimerController )
                                    endif
                                    set goPickButFullUnits[goPickButFullCount] = u
                                    set goPickButFullItems[goPickButFullCount] = item1
                                    set goPickButFullCount = goPickButFullCount + 1
                                endif
                                // Order the unit to move to the item position
                                call IssuePointOrder( u, "move", GetItemX(item1), GetItemY(item1) )
                            else
                                // Full inventory error
                                call IssueImmediateOrder( u, "stop" )
                                set p = GetOwningPlayer( u )
                                // Play error sound
                                if ERROR_SOUND != null and ERROR_SOUND != "" then
                                    set str = ERROR_SOUND
                                    set snd = CreateSound( str, false, false, false, 12700, 12700, "" )
                                    call SetSoundVolume( snd, 127 )
                                    if GetLocalPlayer() != p then
                                        call StartSound( snd )
                                    endif
                                    call KillSoundWhenDone( snd )
                                    call ClearTextMessages()
                                    call DisplayTimedTextToPlayer(GetOwningPlayer(udg_EasyItem_unit),0.50,-1.00,2.00,"|cffffcc00"+ERROR_MESSAGE+"|r")
                                endif
                            endif
                        else
                            // The item will be picked normally when the unit reaches it (a unit acquire item event will be fired by W3)
                        endif
                    elseif (orderId > 852001 and orderId < 852008) then
                        // The unit is issued a moveslot<1-6> order: an item is being moved to another inventory slot
                        if UnitHasItem(u, item1) then
                            // Safety check: item comes from the unit inventory
                            set item1Charges = GetItemCharges( item1 )
                            if (item1Charges > 0) then
                                // The moved item has charges
                                set item2Slot = orderId - 852002 // target slot index (0 to 5)
                                set item2 = UnitItemInSlot( u, item2Slot )
                                if GetItemTypeId(item2) == GetItemTypeId(item1) then
                                    // The moved item and target item have the same type or are identical
                                    if item2 == item1 then
                                        // The item is moved on itself - split charges
                                        if SPLIT then
                                            // Split by double right-click is enabled in settings
                                            set full = UnitInventoryFull( u )
                                            if item1Charges > 1 and (SPLIT_DROP or not full) then
                                                // Split is possible (there is room in inventory or drop is enabled in settings)
                                                if SPLIT_SIZE > 0 then
                                                    // Split is set to a fixed size in settings
                                                    if SPLIT_SIZE >= item1Charges then
                                                        // Not enough charges: splitting total quantity minus 1
                                                        set splitChargeCount = item1Charges - 1
                                                    else
                                                        // Enough charges for full-split
                                                        set splitChargeCount = SPLIT_SIZE
                                                    endif
                                                else
                                                    // Splits in half (bottom-rounded)
                                                    set splitChargeCount = item1Charges / 2
                                                endif
                                                call SetItemCharges( item1, item1Charges - splitChargeCount )
                                                call FireStackChangedEvent(u, item1)
                                                if SPLIT_STACK then
                                                    // Splitted charged stacked on other items is enabled in settings
                                                    set item2 = null
                                                    if splitStackCount > 0 then
                                                        // Cancel timer is on
                                                        set index = 0
                                                        loop
                                                            if u == splitStackUnits[index] then
                                                                // This unit already is in the splitstack/cancel timer input
                                                                set item2 = splitStackItem2s[index]
                                                                set item2Charges = GetItemCharges( item2 )
                                                                set item1Charges = GetItemLevel( item2 )
                                                                exitwhen true
                                                            endif
                                                            set index = index + 1
                                                            exitwhen index >= splitStackCount
                                                        endloop
                                                    endif
                                                endif
                                                if SPLIT_STACK and item2 != null and item2 != item1 and splitStackItem1s[index] == item1 and (not USE_ITEM_LEVEL or item1Charges == 0 or item2Charges < item1Charges) and UnitHasItem(u, item2) and GetItemTypeId(item2) == GetItemTypeId(item1) then
                                                    // Merge this split-stack with the other entry in the splitstack/cancel timer input
                                                    call SetItemCharges( item2, item2Charges + splitChargeCount )
                                                    call FireStackChangedEvent(u, item2)
                                                    set splitStackDelays[index] = SPLIT_STACK_DELAY
                                                else
                                                    // Create a new item with the splitted charges
                                                    set unitAngle = GetUnitFacing( u )
                                                    set item2 = CreateItem( GetItemTypeId(item1), GetUnitX(u) + 100 * Cos(unitAngle * bj_DEGTORAD), GetUnitY(u) + 100 * Sin(unitAngle * bj_DEGTORAD) )
                                                    call SetItemCharges( item2, splitChargeCount )
                                                    if not full then
                                                        // There is room, give the new item to the unit
                                                        call DisableTrigger( gg_trg_EasyItemStacknSplit )
                                                        call UnitAddItem( u, item2 )
                                                        call EnableTrigger( gg_trg_EasyItemStacknSplit )
                                                        if SPLIT_STACK then
                                                            // Splitted charged stacked on other items is enabled in settings
                                                            set index = 0
                                                            if splitStackCount > 0 then
                                                                // Cancel timer is on
                                                                loop
                                                                    if splitStackUnits[index] == u then
                                                                        // This unit already is in the splitstack/cancel timer input - update the previous parameters
                                                                        set splitStackItem1s[index] = item1
                                                                        set splitStackItem2s[index] = item2
                                                                        set splitStackDelays[index] = SPLIT_STACK_DELAY
                                                                        set index = -1
                                                                    else
                                                                        set index = index + 1
                                                                    endif
                                                                    exitwhen index >= splitStackCount or index == -1
                                                                endloop
                                                            endif
                                                            if index >= 0 then
                                                                // This unit is not already in the cancel timer input
                                                                if splitStackCount == 0 then
                                                                    // If not started, start the timer
                                                                    call TimerStart( t, 0.05, true, function TimerController )
                                                                endif
                                                                // Push back this unit to the splitstack/cancel timer input
                                                                set splitStackUnits[splitStackCount] = u
                                                                set splitStackItem1s[splitStackCount] = item1
                                                                set splitStackItem2s[splitStackCount] = item2
                                                                set splitStackDelays[splitStackCount] = SPLIT_STACK_DELAY
                                                                set splitStackCount = splitStackCount + 1
                                                            endif
                                                        endif
                                                    else
                                                        // There is no room for the new item, leave it on the floor and play the "Item Drop" sound
                                                        set p = GetOwningPlayer( u )
                                                        //! runtextmacro EasyItemStacknSplit_PLAYITEMSOUND( "HeroDropItem1" )                                          
                                                    endif
                                                endif
                                            endif
                                        endif
                                    else
                                        // The item is moved on another item of same type - stack them
                                        set item1Level = GetItemLevel( item1 )
                                        set item2Charges = GetItemCharges( item2 )
                                        if USE_ITEM_LEVEL and item1Level > 0 and item2Charges + item1Charges > item1Level then
                                            // Total charges of destination item is limited and that limit is exceeded
                                            if item1Charges < GetItemLevel(item2) and item2Charges < GetItemLevel(item2) then
                                                // Safety check: both items had less than max charge. Stack a max of charges in the destination item, leave the rest in the source item
                                                call SetItemCharges( item2, item2Charges + item1Charges - item1Level )
                                                call FireStackChangedEvent(u, item2)
                                                call SetItemCharges( item1, item1Level )
                                                call FireStackChangedEvent(u, item1)
                                            endif
                                        else
                                            // All the charges can be stacked, source item disapears
                                            call SetItemCharges( item2, item2Charges + item1Charges )
                                            call FireStackChangedEvent(u, item2)
                                            call RemoveItem( item1 )
                                        endif
                                    endif
                                endif
                            endif
                        endif
                    else
                        // Other irrelevant orders targeting an item (attack, ...)
                    endif
                endif
            endif
        else
            // OTHER TYPE OF TRIGGERING EVENT - SHOULD NEVER HAPPEN
        endif
        set u = null
        set p = null
        set item1 = null
        set item2 = null
        set snd = null
        return false
    endfunction

    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    // CONTROLLER : PreloadController
    //  EVENTS : Game Time Elapsed = 0.00
    //  Preloads sound files so that they play the first time around.
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    private function PreloadController takes nothing returns boolean
        local string array str
        local sound snd
        local integer x = 0
        set str[0] = "Sound\\Interface\\PickUpItem.wav"
        set str[1] = "Sound\\Interface\\HeroDropItem1.wav"
        if ERROR_SOUND != null and ERROR_SOUND != "" then
            set str[2] = ERROR_SOUND
        endif
        loop
            exitwhen str[x] == null
            set snd = CreateSound( str[x], false, false, false, 12700, 12700, "" )
            call SetSoundVolume( snd, 0 )
            call StartSound( snd )
            call KillSoundWhenDone( snd )
            set x = x + 1
        endloop
        set snd = null
        call DestroyTrigger( GetTriggeringTrigger() )
        return false
    endfunction

    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    // TRIGGER INITIALIZER
    //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    private function onInit takes nothing returns nothing
        local trigger CancelTrigger = CreateTrigger()
        local trigger PreloadTrigger = CreateTrigger()
        local integer index = 0
        call InitDummyItemPairs()
        set gg_trg_EasyItemStacknSplit = CreateTrigger()
        loop
            call TriggerRegisterPlayerUnitEvent( gg_trg_EasyItemStacknSplit, Player(index), EVENT_PLAYER_UNIT_PICKUP_ITEM, null )
            call TriggerRegisterPlayerUnitEvent( gg_trg_EasyItemStacknSplit, Player(index), EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, null )
            call TriggerRegisterPlayerUnitEvent( CancelTrigger, Player(index), EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, null )
            set index = index + 1
            exitwhen index >= bj_MAX_PLAYER_SLOTS
        endloop
        call TriggerRegisterTimerEvent( PreloadTrigger, 0.00, false )
        call TriggerAddCondition( gg_trg_EasyItemStacknSplit, function ActionController )
        call TriggerAddCondition( CancelTrigger, function CancelController )
        call TriggerAddCondition( PreloadTrigger, function PreloadController )
    endfunction

endlibrary