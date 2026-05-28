library DItemTransfer requires SharedDInvLib

/*  Function: TransferAllItemsAndEquipment
    Transfers all DInventory items and equipped DEquipment items from sourceUnit to targetUnit.
    Both units must have valid DInventory and DEquipment IDs.
    
    Parameters:
        sourceUnit - The unit from which items and equipment will be transferred.
        targetUnit - The unit to which items and equipment will be transferred. 
    
    Example Usage:
        call DItemTransfer_TransferAllItemsAndEquipment(udg_DInv_SourceUnit, udg_DInv_TargetUnit)

    Order in GUI trigger:
        Set udg_DInv_SourceUnit = (Triggering unit)
        Custom script: call DItemTransfer_StoreSourceUnit()
        Unit - Replace (Triggering unit) with a Paladin using The old unit's relative life and mana
        Set udg_DInv_TargetUnit = (Last replaced unit)
        Custom script: call InitializeDInventoryForUnit(udg_DInv_TargetUnit)
        Custom script: call InitializeDEquipmentForUnit(udg_DInv_TargetUnit)
        Custom script: call DItemTransfer_TransferDItemsGUI()
    
    IMPORTANT: The new unit MUST be initialized with DInventory/DEquipment before transfer!

*/

function DItemTransfer_TransferAllItemsAndEquipment takes unit sourceUnit, unit targetUnit returns nothing
local integer sourceBid = BIDOfUnit(sourceUnit)
local integer targetBid = BIDOfUnit(targetUnit)
local integer sourceEqid = EQIDOfUnit(sourceUnit)
local integer targetEqid = EQIDOfUnit(targetUnit)
local integer sourcePid = GetPlayerId(GetOwningPlayer(sourceUnit))
local integer targetPid = GetPlayerId(GetOwningPlayer(targetUnit))
local integer maxCap = MaxDInvCapacityOfUnit(sourceUnit)
local integer slotId = 0
local integer eqSlotId = 1
local item it = null

// Transfer DInventory items
if sourceBid > -1 and targetBid > -1 then
    loop
        set it = DInventoryDB[sourceBid].item[slotId]
        if it != null then
            call DeleteItemFromDInventory(it)
            call DInvUnitAddItem(targetUnit, it)
        endif
        set slotId = slotId + 1
        exitwhen slotId >= maxCap
    endloop
endif

// Transfer equipped items (12 equipment slots)
if sourceEqid > 0 and targetEqid > 0 then
    loop
        set it = EQIDDB[sourceEqid][4].item[eqSlotId]
        if it != null then
            call UnequipDEqItemToDInvSlot(sourcePid, sourceBid, sourceEqid, sourceUnit, GetHandleId(sourceUnit), it, eqSlotId, 0)
            call DInvUnitAddItem(targetUnit, it)
        endif
        set eqSlotId = eqSlotId + 1
        exitwhen eqSlotId > 12
    endloop
endif

set sourceUnit = null
set targetUnit = null
set it = null
endfunction

/*  Function: TransferDItemsGUI
    GUI-friendly wrapper for transferring items using global variables.
    Stores source unit's BID/EQID before replacement to safely access items after unit is removed.
    
    GUI Usage:
        1. Set variable (Set udg_DInv_SourceUnit = [unit being replaced])
        2. Custom script: call DItemTransfer_StoreSourceUnit()
        3. Unit - Replace (Triggering unit) with a Paladin...
        4. Set variable (Set udg_DInv_TargetUnit = [Last replaced unit])
        5. Custom script: call InitializeDInventoryForUnit(udg_DInv_TargetUnit)
        6. Custom script: call InitializeDEquipmentForUnit(udg_DInv_TargetUnit)
        7. Custom script: call DItemTransfer_TransferDItemsGUI()
*/

globals
    private integer storedSourceBid = -1
    private integer storedSourceEqid = -1
    private integer storedSourcePid = -1
endglobals

function DItemTransfer_StoreSourceUnit takes nothing returns nothing
    if udg_DInv_SourceUnit != null then
        set storedSourceBid = BIDOfUnit(udg_DInv_SourceUnit)
        set storedSourceEqid = EQIDOfUnit(udg_DInv_SourceUnit)
        set storedSourcePid = GetPlayerId(GetOwningPlayer(udg_DInv_SourceUnit))
    endif
endfunction

function DItemTransfer_TransferDItemsGUI takes nothing returns nothing
local integer targetBid = -1
local integer targetEqid = -1
local integer targetPid = -1
local integer maxCap = 0
local integer slotId = 0
local integer eqSlotId = 1
local item it = null

    if udg_DInv_TargetUnit == null or storedSourceBid == -1 then
        return
    endif
    
    set targetBid = BIDOfUnit(udg_DInv_TargetUnit)
    set targetEqid = EQIDOfUnit(udg_DInv_TargetUnit)
    set targetPid = GetPlayerId(GetOwningPlayer(udg_DInv_TargetUnit))
    
    // Transfer DInventory items using stored BID
    if storedSourceBid > -1 and targetBid > -1 then
        set maxCap = MaxBagCapacityOfBID(storedSourcePid, storedSourceBid)
        loop
            set it = DInventoryDB[storedSourceBid].item[slotId]
            if it != null then
                call DeleteItemFromDInventory(it)
                call DInvUnitAddItem(udg_DInv_TargetUnit, it)
            endif
            set slotId = slotId + 1
            exitwhen slotId >= maxCap
        endloop
    endif

    // Transfer equipped items using stored EQID
    if storedSourceEqid > 0 and targetEqid > 0 then
        loop
            set it = EQIDDB[storedSourceEqid][4].item[eqSlotId]
            if it != null then
                // Unequip from source (using stored IDs)
                call EQIDDB[storedSourceEqid][4].item.remove(eqSlotId)
                set DInvItemHandleDB[GetHandleId(it)].integer[4] = 0
                // Add to target
                call DInvUnitAddItem(udg_DInv_TargetUnit, it)
            endif
            set eqSlotId = eqSlotId + 1
            exitwhen eqSlotId > 12
        endloop
    endif
    
    // Clear stored values
    set storedSourceBid = -1
    set storedSourceEqid = -1
    set storedSourcePid = -1
    set it = null
endfunction

endlibrary