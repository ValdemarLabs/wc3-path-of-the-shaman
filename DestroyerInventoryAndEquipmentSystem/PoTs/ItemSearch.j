
library ItemSearch initializer Init requires SharedDInvLib
//===========================================================================
/*
    ItemSearch

    Author: [Valdemar]

    Description: 

    Scans a unit's inventory for an item whose name contains a given keyword (case-insensitive). 
    Sets global udg_QuestItemTemp to the item type of the first match.
    If no match found, sets udg_QuestItemTemp = 0 (null)
    
    UPDATED Oct 23 2025: Now searches BOTH DInventory and vanilla inventory!
    Searches DInventory first, then vanilla inventory if no match found.
    
    Parameters:
        u      - the unit to scan
        keyword - string to search for in item names (e.g., "meat")
        sets: set udg_QuestItemTemp = GetItemTypeId(it)

    API:
        call ItemSearch_FindItemByKeyword(unit u, string keyword)
*/ 
//===========================================================================

globals
    private boolean DEBUG_MODE              = false // set false to disable debug messages

endglobals
//===========================================================================
private function DebugMsg takes string msg returns nothing
    if DEBUG_MODE then
        call BJDebugMsg(msg)
    endif

endfunction

//===========================================================================
// Helper function: Case-insensitive string comparison
private function StringContainsIgnoreCase takes string haystack, string needle returns boolean
    local string h = StringCase(haystack, false) // convert haystack to lowercase
    local string n = StringCase(needle, false)   // convert needle to lowercase
    local integer lenH = StringLength(h)
    local integer lenN = StringLength(n)
    local integer i = 0

    if lenN == 0 then
        return false
    endif

    loop
        exitwhen i + lenN > lenH
        if SubString(h, i, i + lenN) == n then
            return true
        endif
        set i = i + 1
    endloop

    return false

endfunction

//===========================================================================
// Scans a unit's inventory for an item whose name contains a given keyword
// Sets global udg_QuestItemTemp to the item type of the first match
// If no match found, sets udg_QuestItemTemp = 0
// UPDATED Oct 23 2025: Now searches both DInventory and vanilla inventory
//===========================================================================
function ItemSearch_FindItemByKeyword takes unit u, string keyword returns nothing
    local integer slotId = 0
    local integer bid = BIDOfUnit(u)
    local integer maxCapacity = 0
    local integer vanillaSlot = 0
    local item it
    local string itemName

    set udg_QuestItemTemp = 0  // reset before searching

    call DebugMsg("FindItemByKeyword: Searching for keyword '" + keyword + "' in " + GetUnitName(u) + "'s inventories.")

    // PHASE 1: Search DInventory first (if unit has one)
    if bid != -1 then
        set maxCapacity = MaxDInvCapacityOfUnit(u)
        call DebugMsg("  Phase 1: Searching DInventory (" + I2S(maxCapacity) + " slots)")
        
        loop
            exitwhen slotId >= maxCapacity
            set it = DInventoryDB[bid].item[slotId]
            
            if it != null then
                set itemName = GetItemName(it)
                call DebugMsg("  DInv Slot " + I2S(slotId) + ": " + itemName)
                
                // check if item name contains keyword (case-insensitive)
                if StringContainsIgnoreCase(itemName, keyword) then
                    set udg_QuestItemTemp = GetItemTypeId(it)
                    call DebugMsg("  Match found in DInventory! Item '" + itemName + "' matches keyword '" + keyword + "'. TypeID: " + I2S(udg_QuestItemTemp))
                    return
                endif
            else
                call DebugMsg("  DInv Slot " + I2S(slotId) + ": empty")
            endif
            set slotId = slotId + 1
        endloop
        
        call DebugMsg("  No match in DInventory, checking vanilla inventory...")
    else
        call DebugMsg("  Unit has no DInventory, checking vanilla inventory only...")
    endif

    // PHASE 2: Search vanilla inventory
    call DebugMsg("  Phase 2: Searching vanilla inventory (6 slots)")
    loop
        exitwhen vanillaSlot >= 6 // always check all 6 inventory slots
        set it = UnitItemInSlot(u, vanillaSlot)
        
        if it != null then
            set itemName = GetItemName(it)
            call DebugMsg("  Vanilla Slot " + I2S(vanillaSlot) + ": " + itemName)

            // check if item name contains keyword (case-insensitive)
            if StringContainsIgnoreCase(itemName, keyword) then
                set udg_QuestItemTemp = GetItemTypeId(it)
                call DebugMsg("  Match found in vanilla inventory! Item '" + itemName + "' matches keyword '" + keyword + "'. TypeID: " + I2S(udg_QuestItemTemp))
                return
            endif
        else
            call DebugMsg("  Vanilla Slot " + I2S(vanillaSlot) + ": empty")
        endif
        set vanillaSlot = vanillaSlot + 1
    endloop

    call DebugMsg("No match found for keyword '" + keyword + "' in unit " + GetUnitName(u) + "'s inventories.")
    set udg_QuestItemTemp = 0  // no match found

endfunction
//===========================================================================
// Initializer (optional)
//===========================================================================
private function Init takes nothing returns nothing
    // Initialization code if needed

endfunction

//===========================================================================
endlibrary
