
library ItemSearch initializer Init
//===========================================================================
/*
    ItemSearch

    Author: [Valdemar]

    Description: 

    Scans a unit's inventory for an item whose name contains a given keyword (case-insensitive). 
    Sets global udg_QuestItemTemp to the item type of the first match.
    If no match found, sets udg_QuestItemTemp = 0 (null)
    
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
//===========================================================================
function ItemSearch_FindItemByKeyword takes unit u, string keyword returns nothing
    local integer i = 0
    local item it
    local string itemName

    set udg_QuestItemTemp = 0  // reset before searching

    call DebugMsg("FindItemByKeyword: Searching for keyword '" + keyword + "' in " + GetUnitName(u) + "'s inventory (6 slots).")

    loop
        exitwhen i >= 6 // always check all 6 inventory slots
        set it = UnitItemInSlot(u, i)
        if it != null then

            set itemName = GetItemName(it)
            call DebugMsg("Checking slot " + I2S(i) + ": " + itemName)

            // check if item name contains keyword (case-insensitive)
            if StringContainsIgnoreCase(itemName, keyword) then
                set udg_QuestItemTemp = GetItemTypeId(it)
                call DebugMsg("Match found! Item '" + itemName + "' matches keyword '" + keyword + "'. TypeID: " + I2S(udg_QuestItemTemp))
                return
            endif
        else
            call DebugMsg("Slot " + I2S(i) + ": empty")
        endif
        set i = i + 1
    endloop

    call DebugMsg("No match found for keyword '" + keyword + "' in unit " + GetUnitName(u) + "'s inventory.")
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
