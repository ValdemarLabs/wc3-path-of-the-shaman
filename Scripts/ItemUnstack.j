//==================================================================================
/*
    ItemUnstack 1.0

    Author: [Valdemar]

    Description:
    This library allows unstacking of items with multiple charges by self-dropping or double right-clicking them in inventory.
    When an item with multiple charges is dropped, one charge is removed from the original item and a new item with one charge is created.
    If the unit has room in inventory, the new item is added there, otherwise it is placed on the ground in front of the unit.

*/
//==================================================================================
library ItemUnstack initializer onInit

    //==================================================
    private function UnitInventoryFull takes unit u returns boolean
        local integer size = UnitInventorySize(u)
        local integer i = 0
        loop
            exitwhen i >= size
            if UnitItemInSlot(u, i) == null then
                return false
            endif
            set i = i + 1
        endloop
        return true
    endfunction

    //==================================================
    private function UnitUnstackItem takes unit u, item whichItem returns item
        local integer charges = GetItemCharges(whichItem)
        local integer typeId = GetItemTypeId(whichItem)
        local real x
        local real y
        local real angle
        local real dropDist = 100.0    // distance in front of unit to create/drop the new item
        local item newItem = null
        local boolean added = false

        if charges > 1 then
            //call BJDebugMsg("Unstacking item typeId=" + I2S(typeId) + " with charges=" + I2S(charges))

            // reduce stack on the original
            call SetItemCharges(whichItem, charges - 1)
            //call BJDebugMsg("Original item reduced to " + I2S(GetItemCharges(whichItem)) + " charges")

            // compute a safe position in front of the unit
            set x = GetUnitX(u)
            set y = GetUnitY(u)
            set angle = GetUnitFacing(u) * bj_DEGTORAD

            // create the new 1-charge item slightly in front of the unit
            set newItem = CreateItem(typeId, x + dropDist * Cos(angle), y + dropDist * Sin(angle))
            call SetItemCharges(newItem, 1)
            //call BJDebugMsg("Created new item (id=" + I2S(GetHandleId(newItem)) + ") at (" + R2S(GetItemX(newItem)) + ", " + R2S(GetItemY(newItem)) + ")")

            // if unit has room, try to add it and check the return value
            if not UnitInventoryFull(u) then
                set added = UnitAddItem(u, newItem)    // THIS RETURNS boolean
                if added then
                    //call BJDebugMsg("Item successfully added to inventory")
                else
                    //call BJDebugMsg("Attempted to add item to inventory but failed (engine returned false)")
                endif
            else
                //call BJDebugMsg("Inventory was full, cannot add directly")
            endif

            // If add failed (inventory full or some engine quirk), explicitly leave the item on the ground
            if not added then
                call SetItemPosition(newItem, x + (dropDist + 40.0) * Cos(angle), y + (dropDist + 40.0) * Sin(angle))
                //call BJDebugMsg("Item placed on ground at (" + R2S(GetItemX(newItem)) + ", " + R2S(GetItemY(newItem)) + ")")
            endif
        else
            //call BJDebugMsg("UnitUnstackItem called but charges <= 1, no split performed")
        endif

        return newItem
    endfunction

    //==================================================
    // Trigger callback: detect self-drop or double right-click
    //==================================================
    private function OnIssuedOrder takes nothing returns boolean
        local unit u = GetTriggerUnit()
        local integer orderId = GetIssuedOrderId()
        local item itm
        local integer slot

        // orders 852002..852007 == "moveslot1".."moveslot6"
        if orderId >= 852002 and orderId <= 852007 then
            set slot = orderId - 852002
            set itm = UnitItemInSlot(u, slot)

            if itm != null and GetOrderTargetItem() == itm then
                //call BJDebugMsg("Unstack triggered by moveslot order from unit id=" + I2S(GetHandleId(u)))
                call UnitUnstackItem(u, itm)
            endif
        endif

        set u = null
        set itm = null
        return false
    endfunction

    //==================================================
    private function onInit takes nothing returns nothing
        local trigger t = CreateTrigger()
        local integer i = 0
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            call TriggerRegisterPlayerUnitEvent(t, Player(i), EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, null)
            set i = i + 1
        endloop
        call TriggerAddCondition(t, function OnIssuedOrder)
        //call BJDebugMsg("ItemUnstack initialized")
    endfunction

endlibrary
