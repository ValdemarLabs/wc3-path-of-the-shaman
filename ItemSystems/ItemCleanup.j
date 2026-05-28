// ============================================================
// ItemCleanup
// ============================================================
// Consolidates old GUI item cleanup logic into one runtime library.
//
// Credits:
// - Bribe (GUI Conversion)
// - Tirlititi (vJass version)
// - Vexorian
//
// Main purposes:
// 1. Periodically remove leftover world items that have been lying on the map
//    for too long and are not inside inventories / protected systems.
// 2. Periodically clean up used tome leftovers and other dead/zero-life items
//    that would otherwise remain as tiny icons on the ground.
//
// Behavior:
// - Periodically ages visible world items and removes stale clutter.
// - Periodically finds dead/zero-life items, including consumed tome remnants,
//   and removes them after a short delay.
// - Exempts protected items such as:
//   * Gather node items
//   * Campaign / quest items
//   * DInventory-managed items
//   * Manually protected item instances / item types
//
// Public API:
// - IC_RegisterProtectedItem(item it)
// - IC_UnregisterProtectedItem(item it)
// - IC_RegisterProtectedItemType(integer itemTypeId)
// - IC_UnregisterProtectedItemType(integer itemTypeId)
// - IC_ResetItemAge(item it)
// - IC_IsProtectedItem(item it)
//
// ============================================================

library ItemCleanup initializer Init requires Table, optional GatherNodes, optional SharedDInvLib

globals
    // ============ CONFIGURATION
    // How often world items are aged for long-term clutter cleanup.
    // Default 120.00 = every 2 minutes.
    private constant real IC_ITEM_AGE_INTERVAL = 180.00

    // How many age ticks an unprotected ground item may survive before removal.
    // With the default values above, 4 ticks means roughly 8 minutes on the map.
    private constant integer IC_ITEM_AGE_REMOVE_AFTER = 4

    // How often the system scans the map for dead / zero-life item remnants,
    // such as used tome leftovers.
    // Default 15.00 = every 15 seconds.
    private constant real IC_DEAD_SCAN_INTERVAL = 15.00

    // Delay before removing dead item remnants after they are found.
    // This gives a short window for any visuals or side effects to finish.
    // Default 1.50 = 1.5 seconds.
    private constant real IC_DEAD_REMOVE_DELAY = 1.50

    // Safety cap for the number of dead items queued for one delayed cleanup pass.
    // Default 8192 is intentionally generous for full-map scans.
    private constant integer IC_MAX_DEAD_ITEMS = 8192

    // ==================================================================

    private Table IC_ItemAge             // item handle -> age ticks
    private Table IC_ProtectedItems      // item handle -> protected flag
    private Table IC_ProtectedItemTypes  // item type id -> protected flag

    private item array IC_DeadItems
    private integer IC_DeadItemCount = 0
    private boolean IC_DeadRemovePending = false

    private trigger IC_AgeTrigger = null
    private trigger IC_PickupTrigger = null
    private trigger IC_DeadScanTrigger = null
    private timer IC_DeadRemoveTimer = null
endglobals

function IC_ResetItemAge takes item it returns nothing
    local integer handleId

    if it == null then
        return
    endif

    set handleId = GetHandleId(it)
    set IC_ItemAge.integer[handleId] = 0
endfunction

function IC_RegisterProtectedItem takes item it returns nothing
    if it == null then
        return
    endif

    set IC_ProtectedItems.integer[GetHandleId(it)] = 1
endfunction

function IC_UnregisterProtectedItem takes item it returns nothing
    local integer handleId

    if it == null then
        return
    endif

    set handleId = GetHandleId(it)
    if IC_ProtectedItems.has(handleId) then
        call IC_ProtectedItems.remove(handleId)
    endif
endfunction

function IC_RegisterProtectedItemType takes integer itemTypeId returns nothing
    if itemTypeId != 0 then
        set IC_ProtectedItemTypes.integer[itemTypeId] = 1
    endif
endfunction

function IC_UnregisterProtectedItemType takes integer itemTypeId returns nothing
    if itemTypeId != 0 and IC_ProtectedItemTypes.has(itemTypeId) then
        call IC_ProtectedItemTypes.remove(itemTypeId)
    endif
endfunction

private function IC_IsDInventoryManagedItem takes item it returns boolean
    static if LIBRARY_SharedDInvLib then
        if it != null and GetPIDOfItem(it) >= 0 then
            return true
        endif
    endif
    return false
endfunction

function IC_IsProtectedItem takes item it returns boolean
    local integer handleId
    local integer itemTypeId

    if it == null then
        return true
    endif

    if not IsItemVisible(it) then
        return true
    endif

    set itemTypeId = GetItemTypeId(it)
    if itemTypeId == 0 then
        return true
    endif

    if GetItemType(it) == ITEM_TYPE_CAMPAIGN then
        return true
    endif

    if IC_IsDInventoryManagedItem(it) then
        return true
    endif

    static if LIBRARY_GatherNodes then
        if GN_IsGatherItem(it) then
            return true
        endif
    endif

    set handleId = GetHandleId(it)
    if IC_ProtectedItems.has(handleId) then
        return true
    endif

    if IC_ProtectedItemTypes.has(itemTypeId) then
        return true
    endif

    return false
endfunction

private function IC_ShouldAgeItem takes item it returns boolean
    if it == null then
        return false
    endif
    if not IsItemVisible(it) then
        return false
    endif
    if GetWidgetLife(it) <= 0.405 then
        return false
    endif
    if IC_IsProtectedItem(it) then
        return false
    endif
    return true
endfunction

private function IC_AgeEnum takes nothing returns nothing
    local item it = GetEnumItem()
    local integer handleId
    local integer age

    if IC_ShouldAgeItem(it) then
        set handleId = GetHandleId(it)
        if IC_ItemAge.has(handleId) then
            set age = IC_ItemAge.integer[handleId] + 1
        else
            set age = 1
        endif

        if age >= IC_ITEM_AGE_REMOVE_AFTER then
            if IC_ItemAge.has(handleId) then
                call IC_ItemAge.remove(handleId)
            endif
            call RemoveItem(it)
        else
            set IC_ItemAge.integer[handleId] = age
        endif
    endif

    set it = null
endfunction

private function IC_AgeTick takes nothing returns nothing
    call EnumItemsInRect(GetPlayableMapRect(), null, function IC_AgeEnum)
endfunction

private function IC_QueueDeadItem takes item it returns nothing
    if it == null or IC_DeadItemCount >= IC_MAX_DEAD_ITEMS then
        return
    endif

    set IC_DeadItems[IC_DeadItemCount] = it
    set IC_DeadItemCount = IC_DeadItemCount + 1
endfunction

private function IC_DeadScanEnum takes nothing returns nothing
    local item it = GetEnumItem()

    // Used tomes and similar consumed items can remain on the map as dead
    // zero-life item remnants. Queue them for delayed cleanup here.
    if it != null and IsItemVisible(it) and GetWidgetLife(it) <= 0.405 and not IC_IsProtectedItem(it) then
        call IC_QueueDeadItem(it)
    endif

    set it = null
endfunction

private function IC_DeadRemoveCallback takes nothing returns nothing
    local integer i = 0
    local item it
    local integer handleId

    loop
        exitwhen i >= IC_DeadItemCount
        set it = IC_DeadItems[i]
        if it != null and GetItemTypeId(it) != 0 and not IC_IsProtectedItem(it) then
            set handleId = GetHandleId(it)
            if IC_ItemAge.has(handleId) then
                call IC_ItemAge.remove(handleId)
            endif
            call SetWidgetLife(it, 1.00)
            call RemoveItem(it)
        endif
        set IC_DeadItems[i] = null
        set i = i + 1
    endloop

    set IC_DeadItemCount = 0
    set IC_DeadRemovePending = false
    set it = null
endfunction

private function IC_DeadScanTick takes nothing returns nothing
    if IC_DeadRemovePending then
        return
    endif

    set IC_DeadItemCount = 0
    call EnumItemsInRect(GetPlayableMapRect(), null, function IC_DeadScanEnum)

    if IC_DeadItemCount > 0 then
        set IC_DeadRemovePending = true
        call TimerStart(IC_DeadRemoveTimer, IC_DEAD_REMOVE_DELAY, false, function IC_DeadRemoveCallback)
    endif
endfunction

private function IC_OnPickup takes nothing returns boolean
    call IC_ResetItemAge(GetManipulatedItem())
    return false
endfunction

private function Init takes nothing returns nothing
    local integer playerIndex = 0

    set IC_ItemAge = Table.create()
    set IC_ProtectedItems = Table.create()
    set IC_ProtectedItemTypes = Table.create()

    set IC_AgeTrigger = CreateTrigger()
    call TriggerRegisterTimerEventPeriodic(IC_AgeTrigger, IC_ITEM_AGE_INTERVAL)
    call TriggerAddAction(IC_AgeTrigger, function IC_AgeTick)

    set IC_DeadScanTrigger = CreateTrigger()
    call TriggerRegisterTimerEventPeriodic(IC_DeadScanTrigger, IC_DEAD_SCAN_INTERVAL)
    call TriggerAddAction(IC_DeadScanTrigger, function IC_DeadScanTick)

    set IC_DeadRemoveTimer = CreateTimer()

    set IC_PickupTrigger = CreateTrigger()
    loop
        exitwhen playerIndex >= 24
        call TriggerRegisterPlayerUnitEvent(IC_PickupTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_PICKUP_ITEM, null)
        set playerIndex = playerIndex + 1
    endloop
    call TriggerAddCondition(IC_PickupTrigger, Condition(function IC_OnPickup))
endfunction

endlibrary
