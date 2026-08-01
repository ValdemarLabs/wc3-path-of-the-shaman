/**
    DInventory

    Author: Valdemar
    Version: 1.0.0

    Description:
    Frame-based per-player or per-hero inventory with stacking, paging,
    capacity upgrades, item transfer, and read-only inspection support.

    Credits:
    - emperor_d3st, original DInventory system
    - Tasyen, Warcraft III frame guidance

    How to install:
    Import after Table, SharedDInvLib, and Interface. Configure capacity and the
    inventory ability in DConfigurationArea.

    API:
    - call DInvShowUnitForPlayer(viewer, unit, inspectMode)
    - call DInvToggleUnitForPlayer(viewer, unit, inspectMode)
    - call DInvCloseForPlayer(viewer)

**/

library DInventory initializer Init requires Table, SharedDInvLib, Interface, optional UnitStats

globals
trigger trg_OpenDInvAbilityUsed = CreateTrigger()
trigger trg_AutoAddNewHeroToDInv = CreateTrigger()
trigger trg_ItemObtainedDI = CreateTrigger()
trigger trg_InventoryToggleButtonClicked = CreateTrigger()
trigger trg_DInvGiveButtonClicked = CreateTrigger()
trigger trg_DInvGiveUnitSelected = CreateTrigger()
trigger trg_DInvGiveUnitDeselected = CreateTrigger()

// LowestFrame is the parent used to hold all the inventory related frames
framehandle array InventoryLowestFrame[24]
string DIBlankTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
framehandle array InventoryMainFrame[24]
// CONFIGURE if you want: Below you can adjust the background of your inventory. The default UI textures do not offer much variety or aesthetics.
//string InventoryBackgroundTexture = "UI\\Widgets\\Console\\Human\\human-inventory-slotfiller.blp"
//string InventoryBackgroundTexture = "UI\\Widgets\\Console\\Human\\human-transport-slot.blp"
string InventoryBackgroundTexture = "UI\\Widgets\\Console\\Human\\human-console-button-back-active.blp"
// Distance between slots:
// Configure if you want. Gap is the space between item icons. The SlotSize is the size of item icons.
// The size of the main body of the inventory, as well as the location of other buttons will change automatically, so no need to worry about those.
real InventorySlotGap = 0.006
//If you adjust the slotsize also adjust the InventorySlotModelScale size
real InventorySlotSize = 0.03
string array InventoryTitle
// CONFIGURE if you want: the TopLeft coordinates will tell you where your inventory background will be created.
// Its bottomright coordinates will be calculated later based on the rows, column, slot size, and gap size. So don't touch that.
// Visit this tutorial, if you wonder about what these numbers mean:
//
real InventoryTopLeftX = 0.336
real InventoryTopLeftY = 0.544
// NEEDTODO: Use size instead of BotRight?
// Do NOT configure the BotRight values. In the current system they are automatically calculated based on the TopLeft values you gave, as well as your SlotGap and SlotSize.
real InventoryBotRightX = -666
real InventoryBotRightY = -666

// Slots
real DoubleClickSensitivity = 0.5 //in seconds
timer array DInvDoubleClickTimer[24]
framehandle array InventorySlotButtonFrame[8160]
framehandle array InventorySlotButtonIconFrame[8160]
framehandle array InventorySlotButtonModelFrame[8160]
string InventorySlotModel = "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx"
// This scales the size of the model you selected above for indicating that the slot is active and selected. The number means the relative size of the model in percent.
real InventorySlotModelScale = 0.76
string InventorySlotEmptyTexture = "ui\\widgets\\escmenu\\human\\quest-completed-background.blp"
string InventorySlotForbiddenTexture = "UI\\Widgets\\Console\\Human\\human-console-button-back-disabled.blp"
framehandle array InventorySlotStacksFrame[8160]
trigger trg_InventorySlotClicked = CreateTrigger()

unit array DInvCurrentUnit[24]
unit array DEqCurrentUnit[24]
boolean array DInvCurrentInspectMode[24]
integer array DInvCurrentUnitHandleId[24]
integer array CurrentBID[24]
integer array CurrentEQId[24]

integer array DInvCurrentPage[24]
integer array SourceDItemSlotIdActive[24]
integer array SourceDItemFrameIdActive[24]
integer array SourceDItemPage[24]
integer array TargetDItemSlotId[24]
integer array DEqCurrentSlotIdActive[24]
integer array DEqCurrentFrameIdActive[24]

// Tooltip
framehandle array InventoryTooltipBackdropFrame[8160]
framehandle array InventoryTooltipText[8160]
framehandle array InventoryTooltipItemIconFrame[8160]
framehandle array InventoryTooltipGoldIconFrame[8160]
framehandle array InventoryTooltipSeparatorFrame[8160]
string InventoryTooltipGoldIconTexture = "UI\\Widgets\\ToolTips\\Human\\ToolTipGoldIcon.blp"

// Close / X Button
framehandle array InventoryXButtonFrame[24]
framehandle array InventoryXButtonIconFrame[24]
framehandle array InventoryGiveButtonFrame[24]
unit array DInvGiveSelectedUnit[24]
string InventoryXButtonIconTexture = "UI\\Widgets\\EscMenu\\Human\\checkbox-background-disabled.blp"
//CONFIGURE in function LoadBugProtectionActions: These are actually set up in loadbug protection actions, because they rely on the slots being drawn and calculated
real InventoryCloseTopLeftX = 0
real InventoryCloseTopLeftY = 0
real InventoryCloseBotRightX = 0
real InventoryCloseBotRightY = 0
real InventoryGiveTopLeftX = 0
real InventoryGiveTopLeftY = 0
real InventoryGiveBotRightX = 0
real InventoryGiveBotRightY = 0
framehandle array InventoryXButtonTipFrame[24]
framehandle array InventoryXButtonTipTextFrame[24]

// Page Buttons
framehandle array InventoryPageLeftButtonFrame[24]
framehandle array InventoryPageRightButtonFrame[24]
framehandle array InventoryPageLeftButtonIconFrame[24]
framehandle array InventoryPageRightButtonIconFrame[24]
framehandle array InventoryPageCounterTextFrame[24]
framehandle array InventoryCapacityTextFrame[24]
trigger trg_PageLeftClicked = CreateTrigger()
trigger trg_PageRightClicked = CreateTrigger()
string InventoryPageLeftTexture = "ReplaceableTextures\\CommandButtons\\BTNReplay-SpeedDown.blp"
string InventoryPageRightTexture = "ReplaceableTextures\\CommandButtons\\BTNReplay-SpeedUp.blp"
//Below variables: CONFIGURE in function LoadBugProtectionActions: These are actually set up in loadbug protection actions, because they rely on the slots being drawn and calculated
real InventoryPageRightTopLeftX = 0
real InventoryPageRightTopLeftY = 0
real InventoryPageLeftTopLeftX = 0
real InventoryPageLeftTopLeftY = 0
real InventoryPageLeftBotRightX = 0
real InventoryPageLeftBotRightY = 0
real InventoryPageRightBotRightX = 0
real InventoryPageRightBotRightY = 0
real InventoryPageCounterTextTopLeftX = 0
real InventoryPageCounterTextTopLeftY = 0
real InventoryPageCounterTextBotRightX = 0
real InventoryPageCounterTextBotRightY = 0

// Stacking
// Note: The DInventory will only stack items that are of categories in the Object Editor: Power Up, Charged, Purchasable. If you want to change that you need to edit the code.
// Or you can just set your item to be in these categories.
framehandle array InfiniteStackingCheckBoxFrame[24]
framehandle array InfiniteStackingCheckBoxIconFrame[24]
string StackingCheckBoxEmptyTexture = "UI\\Widgets\\EscMenu\\Human\\checkbox-background.blp"
string StackingCheckBoxCheckedTexture = "UI\\Widgets\\EscMenu\\Human\\checkbox-check.blp"
framehandle array StackingTextFrame[24]
trigger trg_InfiniteStackingButtonClicked = CreateTrigger()
real StackingTextTopLeftX = 0
real StackingTextTopLeftY = 0
real StackingTextBotRightX = 0
real StackingTextBotRightY = 0
real InfiniteStackingCheckBoxTopLeftX = 0
real InfiniteStackingCheckBoxTopLeftY = 0
real InfiniteStackingCheckBoxBotRightX = 0
real InfiniteStackingCheckBoxBotRightY = 0
// 0 No stacking   1 Autostack items   2 Infinite stacking (code for normal stacking has been removed, because of a bug in Warcraft III)
integer array PlayerStackingMode[24]

//NEEDTODO: create a system where you can adjust your inventory ui position
real UIMinimumWidth = 0
real UIMinimumHeight = 0
integer array DInventoryItemPlayerExclusionListLength[25]
trigger trg_LoadBugProtection = CreateTrigger()
trigger trg_DInventoryNoDesyncInit = CreateTrigger()
endglobals



function SlotFrame2FrameId takes framehandle fr returns integer
// Not needed?
call PIDSlotFrame2FrameId(0, fr)
return 0
endfunction


/*
Makes no sense in this format

function DInvStoreItemForUnit takes item it, unit u returns integer
local integer ihndl = GetHandleId(it)
return StoreItemForPIDBID(it, GetPIDOfItem(it), BIDOfItem(it), eqid)
endfunction
*/


function DInvGetUnusedBID takes integer pid returns integer
local integer i = 1
if InventoryParadigm == "1PerPlayer" then
return pid
endif
// Needtodo: Where is EQIDCounter increased?
// Needtodo: ummmm, BID starts from 0 or 1?
return EQIDCounter+1
endfunction



function DInvSetCurrentUnit takes unit u returns nothing
local integer pid = GetPlayerId(GetOwningPlayer(u))
set DInvCurrentUnit[pid] = u
set DInvCurrentUnitHandleId[pid] = GetHandleId(u)
set CurrentBID[pid] = BIDOfUnit(u)
set CurrentEQId[pid] = EQIDOfUnit(u)
set DInvCurrentInspectMode[pid] = FALSE
//call BJDebugMsg("DInvSetCurrentUnit bid = "+I2S(CurrentBID[pid]))
set u = null
endfunction



function DInvSetCurrentUnitForPlayer takes player viewer, unit u, boolean inspectMode returns boolean
local integer pid = GetPlayerId(viewer)
if DInvCanPlayerUseInventoryFrames(pid) == FALSE or u == null or BIDOfUnit(u) < 1 then
set viewer = null
set u = null
return FALSE
endif
set DInvCurrentUnit[pid] = u
set DInvCurrentUnitHandleId[pid] = GetHandleId(u)
set CurrentBID[pid] = BIDOfUnit(u)
set CurrentEQId[pid] = EQIDOfUnit(u)
set DInvCurrentInspectMode[pid] = inspectMode
set viewer = null
set u = null
return TRUE
endfunction



function DInvIsPlayerInspecting takes integer pid returns boolean
if pid < 0 or pid > 23 then
return FALSE
endif
return DInvCurrentInspectMode[pid]
endfunction



function DInvGiveSetButtonVisible takes integer pid, boolean visible returns nothing
if InventoryGiveButtonFrame[pid] != null and GetLocalPlayer() == Player(pid) then
call BlzFrameSetVisible(InventoryGiveButtonFrame[pid], visible)
endif
endfunction



function DInvGiveRefreshButtonForPlayer takes player viewer returns nothing
local integer pid = GetPlayerId(viewer)
local integer bid = CurrentBID[pid]
local integer slotId = SourceDItemSlotIdActive[pid]
local unit targetUnit = DInvGiveSelectedUnit[pid]
if DInvCurrentInspectMode[pid] == FALSE and DInvCurrentUnit[pid] != null and targetUnit != null and targetUnit != DInvCurrentUnit[pid] and UnitAlive(targetUnit) == TRUE and bid > 0 and slotId > -1 and DInventoryDB[bid].item[slotId] != null then
call DInvGiveSetButtonVisible(pid, TRUE)
else
call DInvGiveSetButtonVisible(pid, FALSE)
endif
set viewer = null
set targetUnit = null
endfunction



function DeactivateActiveDItemSlotIds takes integer pid returns nothing
////call BJDebugMsg("Deactivating frameId: "+I2S(pid*340+SourceDItemFrameIdActive[pid]))
call BlzFrameSetVisible(InventorySlotButtonModelFrame[pid*340+SourceDItemFrameIdActive[pid]], FALSE)
set SourceDItemSlotIdActive[pid] = -1
set SourceDItemFrameIdActive[pid] = -1
set SourceDItemPage[pid] = -1
call DInvGiveRefreshButtonForPlayer(Player(pid))
endfunction



function ActivateCurrentFrameIds takes integer pid returns nothing
////call BJDebugMsg("Activating frameId: "+I2S(pid*340+SourceDItemFrameIdActive[pid]))
call BlzFrameSetVisible(InventorySlotButtonModelFrame[pid*340+SourceDItemFrameIdActive[pid]], TRUE)
call DInvGiveRefreshButtonForPlayer(Player(pid))
endfunction



function StorePIDOfItem takes item it, integer pid returns nothing
//This will always store PID + 1 because this way it can act as a check to see if the item is stored anywhere
set DInvItemHandleDB[GetHandleId(it)].integer[0] = pid + 1
set it = null
endfunction



function DInvPlayerHasItem takes integer pid, item it returns boolean
if pid == GetPIDOfItem(it) then
set it = null
return TRUE
else
set it = null
return FALSE
endif
endfunction



function StoreBIDOfItem takes item it, integer bid returns nothing
set DInvItemHandleDB[GetHandleId(it)].integer[1] = bid
set it = null
endfunction



function InitializeDInventoryForUnit takes unit u returns integer
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer bid = DInvGetUnusedBID(pid)
local integer eqid = EQIDCounter + 1
local integer uhndl = GetHandleId(u)
if DInvCanPlayerOwnInventoryUnit(pid) == TRUE then
// Player and computer heroes can own DInventory data. Frames are still user-only.
    if EQIDOfUnit(u) > 0 then
    //Unit has been initialized already - Protect against double initialization
        set bid = BIDOfUnit(u)
        set u = null
        return bid
    else
        set EQIDCounter = EQIDCounter + 1 
        call UnitAddAbility(u, OpenDInventoryAbilityId)
        set DInvUnits.unit[eqid] = u
        set EQIDDB[eqid][0].integer[1] = pid
        set EQIDDB[eqid][0].integer[2] = bid
        set DInvUnitHandleDB[uhndl][0].unit[0] = u
        set DInvUnitHandleDB[uhndl][0].integer[1] = pid + 1
        set DInvUnitHandleDB[uhndl][0].integer[2] = bid
        set DInvUnitHandleDB[uhndl][0].integer[3] = eqid
        set BIDDB[bid][0].integer[4] = DINV_BAG_TIER_STARTING

        // set stacking automatically to infinite stacking for the player
        set PlayerStackingMode[pid] = 2
    //call BJDebugMsg("DBTest GetUnitName(DInvUnits.unit[eqid]): "+GetUnitName(DInvUnits.unit[eqid]))
    //call BJDebugMsg("DBTest: EQIDDB[eqid][0].integer[2]"+I2S(EQIDDB[eqid][0].integer[2]))
        set u = null
        return bid
    endif
endif
set u = null
return -1
endfunction



function DInvDropMarkedItemsOnDeathForUnit takes unit u returns nothing
// This goes through the inventory of a unit, check for the items that are marked in the Oject Editor as "Dropped When Carrier Dies - TRUE", and drops them on the ground where the unit is
// Warning! this does not update open inventory icons
local integer slotId = 0
local integer maxCapacity = MaxDInvCapacityOfUnit(u)
local real x = GetUnitX(u)
local real y = GetUnitY(u)
local integer bid = BIDOfUnit(u)
local item it = null
if bid == -1 then
// do nothing the unit has no inventory, why did you call this function? hmm, don't make me get the belt!!
else
    loop
    set it = DInventoryDB[bid].item[slotId]
        if BlzGetItemBooleanField(it, ITEM_BF_DROPPED_WHEN_CARRIER_DIES) == TRUE then
        call FromItemHeavenToGround(it, x, y)
        call DeleteItemFromDInventory(it)
        endif
    set slotId = slotId + 1
    exitwhen slotId > maxCapacity
    endloop
endif
set it = null
set u = null
endfunction



//NEEDTODO
function DInvAssignBIDOwnershipToUnit takes integer pid, integer bid, unit newOwner returns nothing
// Maybe the user wants to remove a hero unit from the game and replace it with a different unit
// clear current unit data
// if eqidcounter is unit's eqid and bid then decrease the eqid counter
// add new unit's data
endfunction



function UnitDInventoryMoveItemToVanillaInv takes unit u, item it returns nothing
//NEEDTODO: remember, you may need to create a new item if we are talking about stackables
if 1 == 1 then
set u = null
set it = null
//return null if unit does not have item
//automatically checks player if paradigm is player
else
set u = null
set it = null
endif
endfunction



function IsItemOnExclusionListOfPlayer takes item it, integer pid returns boolean
local integer i = 0
if ItemExclusionListLengthForPlayer[pid] == 0 then
// Player item exclusion list is 0 large
set it = null
return FALSE
endif
loop 
    if ItemExclusionListForPlayer[pid].item[i] == it then
    set it = null
    return TRUE
    else
    endif
set i = i + 1 
exitwhen i >= ItemExclusionListLengthForPlayer[pid]
endloop
// not on the list
set it = null
return FALSE
endfunction



function IsItemOnExclusionListOfBID takes item it, integer bid returns boolean
// This does NOT check player exclusion list, so also call IsItemOnExclusionListOfPlayer if needed.
local integer i = 0
local integer lngth = BIDDB[bid][0].integer[3]

if lngth == 0 then
set it = null
return FALSE
endif

loop
    if BIDDB[bid][2].item[i] == it then
    set it = null
    return TRUE
    endif
set i = i + 1
exitwhen i >= lngth
endloop

set it = null
return FALSE
endfunction



function IsItemOnExclusionListOfUnit takes item it, unit u returns boolean
// This does NOT check player exclusion list, so also call IsItemOnExclusionListOfPlayer if needed.
local integer bid = BIDOfUnit(u)
local boolean result = IsItemOnExclusionListOfBID(it, bid)
set it = null
set u = null
return result
endfunction



function IsItemTypeOnExclusionListOfPlayer takes integer iid, integer pid returns boolean
local integer i = 0

if ItemTypeExclusionListLengthForPlayer[pid] == 0 then
// Player item exclusion list is 0 large
return FALSE
endif

loop 
    if DInvItemTypeExclusionListForPlayer[pid].integer[i] == iid then
    return TRUE
    else
    endif
set i = i + 1 
exitwhen i >= ItemTypeExclusionListLengthForPlayer[pid]
endloop
// not on the list
return FALSE
endfunction



function IsItemTypeOnExclusionListOfBID takes integer iid, integer bid returns boolean
// This does NOT check player exclusion list, so also call IsItemTypeOnExclusionListOfPlayer if needed.
local integer i = 0
local integer lngth = BIDDB[bid][0].integer[2]

if lngth == 0 then
return FALSE
endif

loop
    if BIDDB[bid][1].integer[i] == iid then
    return TRUE
    endif
set i = i + 1
exitwhen i >= lngth
endloop

return FALSE
endfunction



function IsItemTypeOnExclusionListOfUnit takes integer iid, unit u returns boolean
// This does NOT check player exclusion list, so also call IsItemTypeOnExclusionListOfPlayer if needed.
local integer bid = BIDOfUnit(u)
local boolean result = IsItemTypeOnExclusionListOfBID(iid, bid)
set u = null
return result
endfunction



function AddItemToPlayerExclusionList takes item it, integer pid returns nothing
if IsItemOnExclusionListOfPlayer(it, pid) == TRUE then
// Do nothing if already on the list
else
    // Exclusion list will never have null values, so set the length-th item
    set ItemExclusionListForPlayer[pid].item[ItemExclusionListLengthForPlayer[pid]] = it
    // Increase Exclusion list length of player
    set ItemExclusionListLengthForPlayer[pid] = ItemExclusionListLengthForPlayer[pid] + 1
endif
set it = null
endfunction



function RemoveItemFromPlayerExclusionList takes item it, integer pid returns nothing
local integer i = 0
local integer length = ItemExclusionListLengthForPlayer[pid]
loop
    if ItemExclusionListForPlayer[pid].item[i] == it then
        if i == length-1 then
        // remove item. the -1 is because we start storing on index 0, not 1, so length 5 means index 0,1,2,3,4 have an item
        set ItemExclusionListForPlayer[pid].item[i] = null
        else
        // swap last item on the list with the current one
        set ItemExclusionListForPlayer[pid].item[i] = ItemExclusionListForPlayer[pid].item[length-1]
        set ItemExclusionListForPlayer[pid].item[length-1] = null
        // exit loop
        set i = length
        endif
        // Decrease Exclusion list length of player
        set ItemExclusionListLengthForPlayer[pid] = ItemExclusionListLengthForPlayer[pid] - 1
    else
    endif
set i = i + 1
exitwhen i > length
endloop
set it = null
endfunction



function AddItemToBIDExclusionList takes item it, integer bid returns nothing
if bid < 0 then
// Could not find this hero in the DInventory system, exit
elseif IsItemOnExclusionListOfBID(it, bid) == TRUE then
// Do nothing if already on the list
else
    // Exclusion list will never have null values, so set the length-th item, which is null, because counting starts from 0..
    set BIDDB[bid][2].item[BIDDB[bid][0].integer[3]] = it
    // Increase Exclusion list length of unit
    set BIDDB[bid][0].integer[3] = BIDDB[bid][0].integer[3] + 1
endif
set it = null
endfunction



function AddItemToUnitExclusionList takes item it, unit u returns nothing
local integer bid = BIDOfUnit(u)
call AddItemToBIDExclusionList(it, bid)
set it = null
set u = null
endfunction



function RemoveItemFromBIDExclusionList takes item it, integer bid returns nothing
local integer i = 0
local integer length = BIDDB[bid][0].integer[3]
if bid == -1 then
// Could not find this hero in the DInventory system, exit
else
loop
    if BIDDB[bid][2].item[i] == it then
        if i == length-1 then
        // remove item. the -1 is because we start storing on index 0, not 1, so length 5 means index 0,1,2,3,4 have an item
        set BIDDB[bid][2].item[i] = null
        else
        // swap last item on the list with the current one
        // -1 because the first item is  stored on 0
        set BIDDB[bid][2].item[i] = BIDDB[bid][2].item[length-1]
        set BIDDB[bid][2].item[length-1] = null
        // exit loop:
        set i = length
        endif
        // Decrease Exclusion list length of unit
        set BIDDB[bid][0].integer[3] = BIDDB[bid][0].integer[3] - 1
    else
endif
set i = i + 1
exitwhen i > length
endloop
endif
set it = null
endfunction



function RemoveItemFromUnitExclusionList takes item it, unit u returns nothing
local integer bid = BIDOfUnit(u)
call RemoveItemFromBIDExclusionList(it, bid)
set it = null
set u = null
endfunction



function AddItemTypeToPlayerExclusionList takes integer iid, integer pid returns nothing
if IsItemTypeOnExclusionListOfPlayer(iid, pid) == TRUE then
// Do nothing if already on the list
else
    // Exclusion list will never have null values, so set the length-th item
    set DInvItemTypeExclusionListForPlayer[pid].integer[ItemTypeExclusionListLengthForPlayer[pid]] = iid
    // Increase Exclusion list length of player
    set ItemTypeExclusionListLengthForPlayer[pid] = ItemTypeExclusionListLengthForPlayer[pid] + 1
endif
endfunction



function RemoveItemTypeFromPlayerExclusionList takes integer iid, integer pid returns nothing
local integer i = 0
local integer length = ItemTypeExclusionListLengthForPlayer[pid]
loop
    if DInvItemTypeExclusionListForPlayer[pid].integer[i] == iid then
        if i == length-1 then
        // remove itemtypeid. the -1 is because we start storing on index 0, not 1, so length 5 means index 0,1,2,3,4 have an itemtypeid
        set DInvItemTypeExclusionListForPlayer[pid].integer[i] = 0
        else
        // swap last iid on the list with the current one
        set DInvItemTypeExclusionListForPlayer[pid].integer[i] = DInvItemTypeExclusionListForPlayer[pid].integer[length-1]
        set DInvItemTypeExclusionListForPlayer[pid].integer[length-1] = 0
        // exit loop:
        set i = length
        endif
    else
    endif
set i = i + 1
exitwhen i > length
endloop

// Decrease Exclusion list length of player
set ItemTypeExclusionListLengthForPlayer[pid] = ItemTypeExclusionListLengthForPlayer[pid] - 1
endfunction



function AddItemTypeToBIDExclusionList takes integer iid, integer bid returns nothing
if bid < 0 then
// Could not find this hero in the DInventory system, exit
elseif IsItemTypeOnExclusionListOfBID(iid, bid) == TRUE then
// Do nothing if already on the list
else
    // Exclusion list will never have null values, so set the length-th item, which is null, because counting starts from 0..
    set BIDDB[bid][1].integer[BIDDB[bid][0].integer[2]] = iid
    // Increase Exclusion list length of unit
    set BIDDB[bid][0].integer[2] = BIDDB[bid][0].integer[2] + 1
endif
endfunction



function AddItemTypeToUnitExclusionList takes integer iid, unit u returns nothing
local integer bid = BIDOfUnit(u)
call AddItemTypeToBIDExclusionList(iid, bid)
set u = null
endfunction



function RemoveItemTypeFromBIDExclusionList takes integer iid, integer bid returns nothing
local integer i = 0
local integer length = BIDDB[bid][0].integer[2]
if bid < 0 then
// Could not find this hero in the DInventory system, exit
elseif length == 0 then
// is empty, do nothing
else
    loop
        if BIDDB[bid][1].integer[i] == iid then
            if i == length-1 then
            // remove itemtypeid. the -1 is because we start storing on i 0, not 1, so length 5 means i 0,1,2,3,4 have an itemtypeid
            set BIDDB[bid][1].integer[i] = 0
            else
            // swap last iid on the list with the current one
            set BIDDB[bid][1].integer[i] = BIDDB[bid][1].integer[length-1]
            set BIDDB[bid][1].integer[length-1] = 0
            // exit loop
            set i = length
            endif
        endif
    set i = i + 1
    exitwhen i > length
    endloop

    // Decrease Exclusion list length of player
    set BIDDB[bid][0].integer[2] = BIDDB[bid][0].integer[2] - 1
endif
endfunction



function RemoveItemTypeFromUnitExclusionList takes integer iid, unit u returns nothing
local integer bid = BIDOfUnit(u)
call RemoveItemTypeFromBIDExclusionList(iid, bid)
set u = null
endfunction



function IsItemStoreableForPIDBID takes item it, integer pid, integer bid returns boolean
local integer iid = GetItemTypeId(it)
if DInvIsItemIdOnGlobalExclusionList(iid) == TRUE then
    // This ItemId is configured not to be put into the DInventory of ANY players
    set it = null
////call BJDebugMsg("This ItemId is configured not to be put into the DInventory of ANY players")
    return FALSE
endif

if ItemTypeExclusionListLengthForPlayer[pid] > 0 then
// There are some item IDs on Player's Item ID exclusion list
////call BJDebugMsg("There are some item IDs on Player's Item ID exclusion list")
    if IsItemTypeOnExclusionListOfPlayer(iid, pid) == TRUE then
    set it = null
////call BJDebugMsg("Item ID is on Player's Item ID exclusion list")
    return FALSE
    endif
endif

if ItemExclusionListLengthForPlayer[pid] > 0 then
//There are some items on Player's Item exclusion list
////call BJDebugMsg("There are some items on Player's Item exclusion list")
    if IsItemOnExclusionListOfPlayer(it, pid) == TRUE then
    // Item is on shitlist
////call BJDebugMsg("Item is on shitlist of player")
    set it = null
    return FALSE
    endif
endif

if BIDDB[bid][0].integer[2] > 0 then
    if IsItemTypeOnExclusionListOfBID(iid, bid) == TRUE then
    set it = null
    return FALSE
    endif
endif

if BIDDB[bid][0].integer[3] > 0 then
    if IsItemOnExclusionListOfBID(it, bid) == TRUE then
    set it = null
    return FALSE
    endif
endif

if MakeDInventoryAcceptUndroppableItems == FALSE and BlzGetItemBooleanField(it, ConvertItemBooleanField('idro')) == FALSE then
////call BJDebugMsg("idro is false Item is undroppable. System is configured not to store undroppable items")
// Items that say "Droppable = False" in the Object Editor may be configured to be stored or not stored by adjusting global variable: MakeDInventoryAcceptUndroppableItems
// ('idro')) == 1 means item is set to be Droppable in the Object Editor, 0 means it is Undroppable
set it = null
return FALSE
endif

////call BJDebugMsg("No problem. Item is storeable, return true")
set it = null
return TRUE
endfunction



function DInvIsItemStoreableForUnit takes item it, unit u returns boolean
local integer iid = GetItemTypeId(it)
local integer pid = GetPlayerId(GetTriggerPlayer()) 
local integer bid = BIDOfUnit(u)
local boolean result = IsItemStoreableForPIDBID(it, pid, bid)
set it = null
set u = null
return result
endfunction



function DInvActivatePIDFrameId takes integer pid, integer frameId, boolean active returns nothing
//only let it happen if there is an item in the slot
//show the autocast frame model
if frameId == -1 then
// do nothing, itemSlotId is not on current page
else
call BlzFrameSetVisible(InventorySlotButtonModelFrame[pid*340+frameId], active)
endif
endfunction



function DInvActivatePIDBIDSlotId takes integer pid, integer bid, integer slotId, boolean active returns nothing
//only let it happen if there is an item in the slot
//show the autocast frame model
local integer frameId = DItemSlotId2SlotFrameId(pid, slotId)
call DInvActivatePIDFrameId(pid, frameId, active)
endfunction



function CloseDInventory takes integer pid returns nothing
local integer localplyr = GetPlayerId(GetLocalPlayer())
////call BJDebugMsg("CloseDInventory started")
if pid == localplyr then
// do whatever you need to do with the inventory item DB
if InventoryMainFrame[pid] != null and BlzFrameIsVisible(InventoryMainFrame[pid]) then
call Interface_NotifyInventoryClosed()
endif
call BlzFrameSetVisible(InventoryLowestFrame[pid], FALSE)
call BlzFrameSetVisible(InventoryMainFrame[pid], FALSE)
call BlzFrameSetVisible(InventoryXButtonFrame[pid], FALSE)
call BlzFrameSetVisible(InventoryXButtonIconFrame[pid], FALSE)
call BlzFrameSetVisible(InventoryGiveButtonFrame[pid], FALSE)
//Page buttons here
call BlzFrameSetVisible(InventoryPageLeftButtonFrame[pid], false)
call BlzFrameSetVisible(InventoryPageRightButtonFrame[pid], false)
call BlzFrameSetVisible(InventoryPageCounterTextFrame[pid], false)
call BlzFrameSetVisible(InventoryCapacityTextFrame[pid], false)
call DeactivateActiveDItemSlotIds(pid)
endif
////call BJDebugMsg("CloseDInventory finished")
endfunction



function InventorySlotClickedActions takes nothing returns nothing
local integer pid = GetPlayerId(GetTriggerPlayer())
local integer lp = GetPlayerId(GetLocalPlayer())
local integer bid = CurrentBID[pid]
local unit u = DInvCurrentUnit[pid]
local framehandle meinFrame = BlzGetTriggerFrame()
local integer frameId = 0
local integer slotId = 0
local item auxit = null
local integer uhndl = GetHandleId(u)
local integer eqid = DInvUnitHandleDB[uhndl][0].integer[3]
local integer cap = MaxBagCapacityOfBID(pid, bid)

if pid == lp then
// This is needed to avoid the frame/camera bug
    call BlzFrameSetEnable(meinFrame, false)
    call BlzFrameSetEnable(meinFrame, true)
    call StopCamera()
endif
        
//if hid < 0 and InventoryParadigm == "1PerHero" or GetWidgetLife(u) < 0.405 or u == null then
if (bid < 0 and InventoryParadigm == "1PerHero") or UnitAlive(u) == FALSE or u == null then
// Unit is dead, or hid is invalid, close DInv
call CloseDInventory(pid)
    if EquipmentSystemUsed == TRUE then
    call CloseDEqUI(pid)
    endif
elseif DInvCurrentInspectMode[pid] == TRUE then
// Inspect mode is read-only. Tooltips and page buttons still work.
else
//call BJDebugMsg("current page: "+I2S(DInvCurrentPage[pid]))
set frameId = PIDSlotFrame2FrameId(pid, meinFrame)
//call BJDebugMsg(I2S(frameId)+" clicked frameId")
set slotId = SlotFrameId2DItemSlotId(pid, frameId)
//call BJDebugMsg(I2S(slotId)+" clicked slotId")
    if slotId < cap then
        if SourceDItemSlotIdActive[pid] == -1 then
        // no DInv slots are active
        
            if DEqCurrentSlotIdActive[pid] < 1 then
                
                if DInventoryDB[bid].item[slotId] == null then
                //this slot has no item, do nothing?
                //call BJDebugMsg("clicked slot has no item")
        
                else
                // activate model
                set SourceDItemSlotIdActive[pid] = slotId
                set SourceDItemFrameIdActive[pid] = frameId
                set SourceDItemPage[pid] = DInvCurrentPage[pid]
                call ActivateCurrentFrameIds(pid)
                call TimerStart(DInvDoubleClickTimer[pid], DoubleClickSensitivity, FALSE, null)
                endif
                
            else
            // a DEq slot is active
                if DInventoryDB[bid].item[slotId] == null then
                //this slot has no item, so:
                // Unequip item, put it in DInv
                call UnequipDEqItemToDInvSlot(pid, bid, eqid, u, uhndl, EQIDDB[eqid][4].item[DEqCurrentSlotIdActive[pid]], slotId, DEqCurrentSlotIdActive[pid])
                else
                //swap equipment from DInv
                    if DEqCanUnitEquipItemInSlot(DInvCurrentUnit[pid], DInventoryDB[bid].item[slotId], DEqCurrentSlotIdActive[pid]) == TRUE then
                    // Can equip
                        if UnequipDEqItemToDInvSlot(pid, bid, eqid, u, uhndl, EQIDDB[eqid][4].item[DEqCurrentSlotIdActive[pid]], FirstFreeDInvSlotOfBID(pid, bid), DEqCurrentSlotIdActive[pid]) == TRUE then
                        call EquipDInvItemToDEqSlot(pid, bid, eqid, u, uhndl, DInventoryDB[bid].item[slotId], slotId, DEqCurrentSlotIdActive[pid])
                        else
                        // Unequip was not successful -> maybe there was no free DInv slot
                        endif
                    else
                    // Can't equip. Do nothing
                    endif
                endif
                call DeactivateActiveDEqSlotIds(pid)
            endif
        
        else
            if slotId == SourceDItemSlotIdActive[pid] then
                if TimerGetRemaining(DInvDoubleClickTimer[pid]) > 0.0 then
                // Doubleclick - drop to ground
    //call BJDebugMsg("dropping to ground")
                call FromItemHeavenToGround(DInventoryDB[bid].item[slotId], GetUnitX(u), GetUnitY(u))
                //call TriggerSleepAction(1)
                call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
                else
                // Single click - move to vanilla inventory
    //call BJDebugMsg("moving to vanilla")
                if DInvCanItemUseVanillaInventory(DInventoryDB[bid].item[slotId]) == FALSE then
                call DInvPlayInventoryErrorForUnit(u, "Equipment can not be moved to the vanilla inventory.")
                else
                set DInvItemHandleDB[GetHandleId(DInventoryDB[bid].item[slotId])].integer[3] = 1
                call FromItemHeavenToVanillaInventory(DInventoryDB[bid].item[slotId], u)
                //call TriggerSleepAction(1)
                call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
                endif
                endif
                
            call DInvSlotDataIntoFrame(pid, bid, slotId, frameId)
            call DeactivateActiveDItemSlotIds(pid)
            else
            // swap item A with item B
    //call BJDebugMsg("swapping items")
                if DInventoryDB[bid].item[slotId] == null then
                // Moving item to empty slot
                set DInventoryDB[bid].item[slotId] = DInventoryDB[bid].item[SourceDItemSlotIdActive[pid]]
                // Update handle DB with new slot ID
                set DInvItemHandleDB[GetHandleId(DInventoryDB[bid].item[slotId])].integer[2] = slotId
                call DInventoryDB[bid].item.remove(SourceDItemSlotIdActive[pid])
                else
                // Swapping two items
                set auxit = DInventoryDB[bid].item[SourceDItemSlotIdActive[pid]]
                set DInventoryDB[bid].item[SourceDItemSlotIdActive[pid]] = DInventoryDB[bid].item[slotId]
                set DInventoryDB[bid].item[slotId] = auxit
                // CRITICAL FIX: Update handle DB for both swapped items
                set DInvItemHandleDB[GetHandleId(DInventoryDB[bid].item[slotId])].integer[2] = slotId
                set DInvItemHandleDB[GetHandleId(DInventoryDB[bid].item[SourceDItemSlotIdActive[pid]])].integer[2] = SourceDItemSlotIdActive[pid]
                endif
                        
                if SourceDItemPage[pid] == DInvCurrentPage[pid] then
                call DInvSlotDataIntoFrame(pid, bid, SourceDItemSlotIdActive[pid], SourceDItemFrameIdActive[pid])
                endif
                
                call DInvSlotDataIntoFrame(pid, bid, slotId, frameId)
                call DeactivateActiveDItemSlotIds(pid)
            endif
        endif
    else
    // do nothing, slot is disabled due to capacity
    endif
endif

//call BJDebugMsg("Inv Click finished")
call DInvRefreshCapacityTextForBID(bid)

set meinFrame = null
set u = null
set auxit = null
endfunction



function DItemSlotRefreshStackFrame takes integer pid, integer bid, integer itemSlot, integer slotFrameId returns nothing
call BlzFrameSetText(InventorySlotStacksFrame[slotFrameId], I2S(GetItemCharges(DInventoryDB[bid].item[itemSlot])))
endfunction



function PlayerDInventoryDBIntoDInventoryFrames takes integer pid returns nothing
// Needtodo: does this make any sense? Not used anywhere. Rethink later.
call UnitDInventoryDBIntoDInventoryFrames(pid, CurrentBID[pid])
endfunction



function OpenDInventory takes integer pid returns nothing
local integer localplyr = GetPlayerId(GetLocalPlayer())
local unit u = DInvCurrentUnit[pid]
local integer bid = CurrentBID[pid]
local integer ownerPid = DInvGetInventoryOwnerPidForViewer(pid)
local integer invCap = 0
local integer maxPage = MaxPageCountOfPIDBID(ownerPid, bid)
////call BJDebugMsg("OpenDInventory started")

//set InventorySlotIdOfCurrentTooltip[pid] = -1
set SourceDItemPage[pid] = -1
set SourceDItemFrameIdActive[pid] = -1
set SourceDItemSlotIdActive[pid] = -1
set DEqCurrentSlotIdActive[pid] = -1
set DEqCurrentFrameIdActive[pid] = -1

if maxPage < DInvCurrentPage[pid] then
set DInvCurrentPage[pid] = maxPage 
elseif DInvCurrentPage[pid] < 1 then
set DInvCurrentPage[pid] = 1
endif

if pid == localplyr then
    if bid == -1 then
    // do not open inventory for unauthorized units
    else
////call BJDebugMsg("hid in opendinventory = "+I2S(hid))            
    if InventoryMainFrame[pid] != null and not BlzFrameIsVisible(InventoryMainFrame[pid]) then
    call Interface_NotifyInventoryOpened()
    endif
    call BlzFrameSetVisible(InventoryLowestFrame[pid], TRUE)
    call BlzFrameSetVisible(InventoryMainFrame[pid], TRUE)
    call BlzFrameSetVisible(InventoryXButtonFrame[pid], TRUE)
    call BlzFrameSetVisible(InventoryXButtonIconFrame[pid], TRUE)
    call BlzFrameSetVisible(InventoryCapacityTextFrame[pid], TRUE)
    call BlzFrameSetLevel(InventoryMainFrame[pid], 3)

    set invCap = MaxBagCapacityOfBID(ownerPid, bid)
    call DInvApplyCapacityLayout(pid, invCap)

        if I2R(invCap) / I2R(ColXRow) > 1.0 then
        //Page buttons here
        call BlzFrameSetVisible(InventoryPageLeftButtonFrame[pid], TRUE)
        call BlzFrameSetVisible(InventoryPageRightButtonFrame[pid], TRUE)
        call BlzFrameSetVisible(InventoryPageCounterTextFrame[pid], TRUE)
        else
        call BlzFrameSetVisible(InventoryPageLeftButtonFrame[pid], FALSE)
        call BlzFrameSetVisible(InventoryPageRightButtonFrame[pid], FALSE)
        call BlzFrameSetVisible(InventoryPageCounterTextFrame[pid], FALSE)
        endif

        if InfiniteStackingSystemAllowed == TRUE then
        call BlzFrameSetVisible(StackingTextFrame[pid], TRUE)
        call BlzFrameSetVisible(InfiniteStackingCheckBoxFrame[pid], TRUE)
        call BlzFrameSetVisible(InfiniteStackingCheckBoxIconFrame[pid], TRUE)
        endif

        call UnitDInventoryDBIntoDInventoryFrames(pid, bid)
        call DInvGiveRefreshButtonForPlayer(Player(pid))
    endif
endif
////call BJDebugMsg("OpenDInventory finished")
endfunction



function DInvCloseForPlayer takes player viewer returns nothing
local integer pid = GetPlayerId(viewer)
call CloseDInventory(pid)
set DInvCurrentUnit[pid] = null
set DInvCurrentUnitHandleId[pid] = 0
set CurrentBID[pid] = -1
set CurrentEQId[pid] = -1
set DInvCurrentInspectMode[pid] = FALSE
set viewer = null
endfunction



function DInvShowUnitForPlayer takes player viewer, unit u, boolean inspectMode returns boolean
local integer pid = GetPlayerId(viewer)
if DInvCanPlayerUseInventoryFrames(pid) == FALSE or u == null then
set viewer = null
set u = null
return FALSE
endif
if DInvCurrentUnit[pid] != null and (DInvCurrentUnit[pid] != u or DInvCurrentInspectMode[pid] != inspectMode) then
call CloseDInventory(pid)
endif
if DInvSetCurrentUnitForPlayer(viewer, u, inspectMode) == FALSE then
set viewer = null
set u = null
return FALSE
endif
call OpenDInventory(pid)
set viewer = null
set u = null
return TRUE
endfunction



function DInvToggleUnitForPlayer takes player viewer, unit u, boolean inspectMode returns boolean
local integer pid = GetPlayerId(viewer)

//call BJDebugMsg("ToggleInventory started")

if DInvCanPlayerUseInventoryFrames(pid) == FALSE or u == null then
set viewer = null
set u = null
return FALSE
endif

if u == DInvCurrentUnit[pid] and DInvCurrentInspectMode[pid] == inspectMode then
// Was open
call CloseDInventory(pid)
set DInvCurrentUnit[pid] = null
set DInvCurrentUnitHandleId[pid] = 0
set CurrentBID[pid] = -1
set CurrentEQId[pid] = -1
set DInvCurrentInspectMode[pid] = FALSE

else
    if DInvCurrentUnit[pid] == null then
    // was closed
    else
    // was open for another unit
    call CloseDInventory(pid)
    endif
if DInvSetCurrentUnitForPlayer(viewer, u, inspectMode) == FALSE then
set viewer = null
set u = null
return FALSE
endif
//call BJDebugMsg("DInvCurrentUnit[pid] ="+GetUnitName(DInvCurrentUnit[pid]))
call OpenDInventory(pid)
//call BJDebugMsg("After openinventory DInvCurrentUnit[pid] ="+GetUnitName(DInvCurrentUnit[pid]))
endif

set viewer = null
set u = null
return TRUE
endfunction



function DInvOpenInspectForPlayer takes player viewer, unit target returns boolean
return DInvShowUnitForPlayer(viewer, target, TRUE)
endfunction



function DInvGetInspectTargetForPlayer takes player viewer, unit caster returns unit
local integer eqid = 1
local unit u = null
loop
    exitwhen eqid > EQIDCounter
    set u = DInvUnits.unit[eqid]
    if u != null and u != caster and DInvCanPlayerInspectUnit(viewer, u) == TRUE and IsUnitSelected(u, viewer) then
    set viewer = null
    set caster = null
    return u
    endif
    set eqid = eqid + 1
endloop
set viewer = null
set caster = null
set u = null
return null
endfunction



function ToggleInventory takes integer pid returns nothing
local unit u = GetTriggerUnit()
call DInvToggleUnitForPlayer(Player(pid), u, FALSE)
set u = null
endfunction



function DoesItemDropOnDeath takes item it returns boolean
local boolean b = BlzGetItemBooleanField(it, ITEM_BF_DROPPED_WHEN_CARRIER_DIES)
set it = null
return b
endfunction



// NEEDTODO
function GetPageOfItemSlot takes integer pid, integer bid, integer slotId returns integer
return -999
endfunction



function IsInventoryOpen takes integer pid returns boolean
if DInvCurrentUnit[pid] == null then
return FALSE
else
return TRUE
endif
endfunction



function InfiniteStackingButtonClickedActions takes nothing returns nothing
local integer pid = GetPlayerId(GetTriggerPlayer())
local framehandle meinFrame = BlzGetTriggerFrame()
if PlayerStackingMode[pid] == 0 then
set PlayerStackingMode[pid] = 2
call BlzFrameSetTexture(InfiniteStackingCheckBoxIconFrame[pid], StackingCheckBoxCheckedTexture, 0, TRUE)
else
set PlayerStackingMode[pid] = 0
call BlzFrameSetTexture(InfiniteStackingCheckBoxIconFrame[pid], StackingCheckBoxEmptyTexture, 0, TRUE)
endif
if GetPlayerId(GetLocalPlayer()) == pid then
call BlzFrameSetEnable(meinFrame, false)
call BlzFrameSetEnable(meinFrame, true)
endif
////call BJDebugMsg("Inf stacking butt clicked")
set meinFrame = null
endfunction



function PageLeftClickedActions takes nothing returns nothing
// NEEDTODO: Does this desync???
local integer pid = GetPlayerId(GetTriggerPlayer())
local integer bid = CurrentBID[pid]
local unit u = DInvCurrentUnit[pid]
local integer ownerPid = DInvGetInventoryOwnerPidForViewer(pid)
local integer maxPages = MaxPageCountOfPIDBID(ownerPid, bid)
local framehandle meinFrame = BlzGetTriggerFrame()
local integer eqid = CurrentEQId[pid]

if GetPlayerId(GetLocalPlayer()) == pid then
call BlzFrameSetEnable(meinFrame, false)
call BlzFrameSetEnable(meinFrame, true)
call StopCamera()
endif

if eqid < 1 then
call CloseDInventory(pid)
else

    if DInvCurrentPage[pid] == 1 then
    set DInvCurrentPage[pid] = maxPages
    else
    set DInvCurrentPage[pid] = DInvCurrentPage[pid] - 1 
    endif

    if DInvCurrentPage[pid] < 1 then
    set DInvCurrentPage[pid] = 1
    endif

    call BlzFrameSetText(InventoryPageCounterTextFrame[pid], I2S(DInvCurrentPage[pid]))
    call UnitDInventoryDBIntoDInventoryFrames(pid, bid)
endif

set u = null
set meinFrame = null
endfunction



function PageRightClickedActions takes nothing returns nothing
// NEEDTODO: Does this desync???
local integer pid = GetPlayerId(GetTriggerPlayer())
local integer bid = CurrentBID[pid]
local unit u = DInvCurrentUnit[pid]
local integer ownerPid = DInvGetInventoryOwnerPidForViewer(pid)
local integer maxPages = MaxPageCountOfPIDBID(ownerPid, bid)
local framehandle meinFrame = BlzGetTriggerFrame()
local integer eqid = CurrentEQId[pid]

if GetPlayerId(GetLocalPlayer()) == pid then
call BlzFrameSetEnable(meinFrame, false)
call BlzFrameSetEnable(meinFrame, true)
call StopCamera()
endif

if eqid < 0 then
call CloseDInventory(pid)
else

    if DInvCurrentPage[pid] == maxPages then
    set DInvCurrentPage[pid] = 1
    else
    set DInvCurrentPage[pid] = DInvCurrentPage[pid] + 1 
    endif

    if DInvCurrentPage[pid] < 1 then
    set DInvCurrentPage[pid] = 1
    endif

    call BlzFrameSetText(InventoryPageCounterTextFrame[pid], I2S(DInvCurrentPage[pid]))
    call UnitDInventoryDBIntoDInventoryFrames(pid, bid)
endif

set u = null
set meinFrame = null
endfunction



function DInvUnitAddItem takes unit u, item it returns nothing
// NEEDTODO: figure out if this is needed and in what format
// check inventory paradigm
// check if it can be stacked
// check if DInventory is full
// check if vanilla Inventory is full
// if yes, put it on the ground
local integer iid = GetItemTypeId(it)
local integer bid = BIDOfUnit(u)
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer ihndl = GetHandleId(it)
local integer eqid = DInvUnitHandleDB[GetHandleId(u)][0].integer[3]
    
// NeedToDo: Possible issue: If you set a variable the value of an item that got stored into the DInventory, you need to have a feature so you don't lose that item variable
// or need to put that item into the exception list --> have an item array that acts as an exception list?
    
////call BJDebugMsg("ItemPickedUpActions fired")
if DInvItemHandleDB[ihndl].integer[3] == 1 then
// item has a lock on it because of DInv -> Inv transfer
// remove the semaphor
set DInvItemHandleDB[ihndl].integer[3] = 0
else
    if BlzGetItemBooleanField(it, ConvertItemBooleanField('ipow')) == TRUE then
    // Item is to be used automatically on pickup, so do nothing
    else
////call BJDebugMsg("ItemPickedUpActions : DInvItemHandleDB[ihndl].integer[0]"+I2S(DInvItemHandleDB[ihndl].integer[0]))
        if eqid < 1 then
        //Do nothing, this unit is not authorized to use the DInventory system
////call BJDebugMsg("eqid < 1: "+I2S(eqid))
        else
            if IsItemStoreableForPIDBID(it, pid, bid) == FALSE then
            // Do nothing, item must not be stored
////call BJDebugMsg("Item is not storeable")
                if DInvCanItemUseVanillaInventory(it) == FALSE then
                call DInvRejectVanillaEquipmentItem(u, it)
                endif
            elseif IsItemStoredInDInv(it) == TRUE then
////call BJDebugMsg("Item is flagged as buffered")
            // Item is already in some unit's DInv
            // so do nothing
            elseif IsBIDInventoryFull(pid, bid) == TRUE then
////call BJDebugMsg("Inventory is full")
            // DInventory is full
            // This will automatically check also the player inventory if paradigm is set to 1 Inventory Per Player
                if DInvCanItemUseVanillaInventory(it) == FALSE then
                call DInvRejectVanillaEquipmentItem(u, it)
                else
                call UnitAddItem(u, it)
                endif
            else
            // This also checks if local player has the inventory open and refreshes the frames
////call BJDebugMsg("Before firing of StoreItemForPIDBID. Pid: "+I2S(pid)+" hid: "+I2S(hid))
            call StoreItemForPIDBID(it, pid, bid, eqid)
            endif
        endif
    endif
endif
set it = null
set u = null
endfunction



function ItemPickedUpActions takes nothing returns nothing
local item it = GetManipulatedItem()
local integer iid = GetItemTypeId(it)
local unit u = GetTriggerUnit()
local integer bid = BIDOfUnit(u)
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer ihndl = GetHandleId(it)
local integer eqid = DInvUnitHandleDB[GetHandleId(u)][0].integer[3]

// NeedToDo: Possible issue: If you set a variable the value of an item that got stored into the DInventory, you need to have a feature so you don't lose that item variable
// or need to put that item into the exception list --> have an item array that acts as an exception list?
    
////call BJDebugMsg("ItemPickedUpActions fired")
if DInvItemHandleDB[ihndl].integer[3] == 1 then
// item has a lock on it because of DInv -> Inv transfer
// remove the semaphor
set DInvItemHandleDB[ihndl].integer[3] = 0
else
    if BlzGetItemBooleanField(it, ConvertItemBooleanField('ipow')) == TRUE then
    // Item is to be used automatically on pickup, so do nothing
    else
////call BJDebugMsg("ItemPickedUpActions : DInvItemHandleDB[ihndl].integer[0]"+I2S(DInvItemHandleDB[ihndl].integer[0]))
        if eqid < 1 then
        //Do nothing, this unit is not authorized to use the DInventory system
////call BJDebugMsg("hid == -1 and InventoryParadigm == 1PerPlayer")
        else
            if IsItemStoreableForPIDBID(it, pid, bid) == FALSE then
            // Do nothing, item must not be stored
////call BJDebugMsg("Item is not storeable")
                if DInvCanItemUseVanillaInventory(it) == FALSE then
                call DInvRejectVanillaEquipmentItem(u, it)
                endif
            elseif IsBIDInventoryFull(pid, bid) == TRUE then
////call BJDebugMsg("Inventory is full")
            // Do nothing, DInventory is full
            // This will automatically check also the player inventory if paradigm is set to 1 Inventory Per Player
                if DInvCanItemUseVanillaInventory(it) == FALSE then
                call DInvRejectVanillaEquipmentItem(u, it)
                endif
            elseif IsItemStoredInDInv(it) == TRUE then
////call BJDebugMsg("Item is flagged as buffered")
            // Item is in the buffer, because it was just removed from the DInventory
            // so do nothing
            else
            // This also checks if local player has the inventory open and refreshes the frames
////call BJDebugMsg("Before firing of StoreItemForPIDBID. Pid: "+I2S(pid)+" hid: "+I2S(hid))
            call StoreItemForPIDBID(it, pid, bid, eqid)
            
            // Recalculate hero stats after item transfer to DInventory
            // This fixes the bug where item stats persist even after item is stored
            if IsUnitType(u, UNIT_TYPE_HERO) then
                call UnitStats_RecalculateHero(u)
            endif
            endif
        endif
    endif
endif
set it = null
set u = null
endfunction



function CreateInventoryUI takes integer pid returns nothing
local integer i = 0
local integer j = 0
local integer currInt = 0
local real auxjx = 0
local real auxiy = 0
local real ttXa = 0.4-InventorySlotSize
//local real ttXaa = 0.4-InventorySlotSize-0.25
local real ttXb = 0.4+InventorySlotSize
//local real ttXbb = 0.4+InventorySlotSize+0.25
//set InventoryLowestFrame[pid] = BlzCreateFrameByType("BACKDROP", "InvLowest"+I2S(pid), BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 1)
//set InventoryLowestFrame[pid] = BlzCreateFrameByType("ConsoleUIBackdrop", "InvLowest"+I2S(pid), BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "", 1)
set InventoryLowestFrame[pid] = BlzCreateFrameByType("BACKDROP", "InvLowest"+I2S(pid), BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "", 1)
call BlzFrameSetTexture(InventoryLowestFrame[pid], DIBlankTexture, 0, TRUE)
//call BlzFrameSetTexture(InventoryLowestFrame[pid], "UI\\Widgets\\ToolTips\\Human\\human-tooltip-background.blp", 0, TRUE)
set InventoryMainFrame[pid] = BlzCreateFrameByType("BACKDROP", "InvMain"+I2S(pid), InventoryLowestFrame[pid], "", 1)
call BlzFrameSetLevel(InventoryMainFrame[pid], 3)
call BlzFrameSetAbsPoint(InventoryLowestFrame[pid], FRAMEPOINT_TOPLEFT, InventoryTopLeftX-0.06, InventoryTopLeftY+0.06)
call BlzFrameSetAbsPoint(InventoryLowestFrame[pid], FRAMEPOINT_BOTTOMRIGHT, InventoryBotRightX+0.06, InventoryBotRightY-0.06)
call BlzFrameSetAbsPoint(InventoryMainFrame[pid], FRAMEPOINT_TOPLEFT, InventoryTopLeftX, InventoryTopLeftY)
call BlzFrameSetAbsPoint(InventoryMainFrame[pid], FRAMEPOINT_BOTTOMRIGHT, InventoryBotRightX, InventoryBotRightY)
// BlzFrameSetTexture - flag, 0 for stretched mode; 1 for tile mode
call BlzFrameSetTexture(InventoryMainFrame[pid], "UI\\Widgets\\Console\\Human\\human-console-button-back-active.blp", 1, TRUE) 
//call BlzFrameSetTexture(InventoryMainFrame[pid], InventoryBackgroundTexture, 1, TRUE)    

loop
    loop
        set currInt = pid*340+i*InventoryColumns+j
        set auxjx = InventoryTopLeftX+InventorySlotGap+j*(InventorySlotGap+InventorySlotSize)
        set auxiy = InventoryTopLeftY-InventorySlotGap-i*(InventorySlotGap+InventorySlotSize)

        set InventorySlotButtonFrame[currInt] = BlzCreateFrameByType("GLUEBUTTON", "Slot"+I2S(currInt)+"p"+I2S(pid), InventoryMainFrame[pid], "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetAbsPoint(InventorySlotButtonFrame[currInt], FRAMEPOINT_TOPLEFT, auxjx, auxiy)
        call BlzFrameSetAbsPoint(InventorySlotButtonFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, auxjx+InventorySlotSize, auxiy-InventorySlotSize)
        call BlzFrameSetTexture(InventorySlotButtonFrame[currInt], InventorySlotEmptyTexture, 0, TRUE)

//set InventoryPageRightButtonFrame[pid] = BlzCreateFrameByType("GLUEBUTTON", "PageRightButt"+I2S(pid), InventoryLowestFrame[pid], "ScoreScreenTabButtonTemplate", 0)
//set InventoryPageLeftButtonIconFrame[pid] = BlzCreateFrameByType("BACKDROP", "PageLeftButtIcon"+I2S(pid), InventoryPageLeftButtonFrame[pid], "IconButtonTemplate", 0)

        set InventorySlotButtonIconFrame[currInt] = BlzCreateFrameByType("BACKDROP", "SlotIc"+I2S(pid), InventorySlotButtonFrame[currInt], "IconButtonTemplate", 0)
        call BlzFrameSetAllPoints(InventorySlotButtonIconFrame[currInt], InventorySlotButtonFrame[currInt])
        call BlzFrameSetTexture(InventorySlotButtonIconFrame[currInt], InventorySlotEmptyTexture, 0, TRUE)

        set InventorySlotStacksFrame[currInt] = BlzCreateFrameByType("TEXT", "StackTxt"+I2S(currInt)+"p"+I2S(pid), InventorySlotButtonFrame[currInt], "", 1)
        call BlzFrameSetText(InventorySlotStacksFrame[currInt], "0")
        call BlzFrameSetTextAlignment(InventorySlotStacksFrame[currInt], TEXT_JUSTIFY_BOTTOM, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetScale(InventorySlotStacksFrame[currInt], 1)
        call BlzFrameSetAbsPoint(InventorySlotStacksFrame[currInt], FRAMEPOINT_TOPLEFT, auxjx, auxiy-InventorySlotSize+0.01)
        call BlzFrameSetAbsPoint(InventorySlotStacksFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, auxjx+InventorySlotSize, auxiy-InventorySlotSize)
        // Disable, so the text does not obstruct clicks from the button
        call BlzFrameSetEnable(InventorySlotStacksFrame[currInt], FALSE)

        // Create Rarity Outline models
        if DInvRarityModuleUsed == TRUE or DEqRarityModuleUsed == TRUE then
        //set DInvSlotOutlineModelFrame[currInt] = BlzCreateFrameByType("SPRITE", "ROutLine"+I2S(currInt)+"p"+I2S(pid), InventorySlotButtonFrame[currInt], "", 0)
        set DInvSlotOutlineModelFrame[currInt] = BlzCreateFrameByType("SPRITE", "ROutLine"+I2S(currInt)+"p"+I2S(pid), InventoryMainFrame[pid], "", 0)
        call BlzFrameSetAbsPoint(DInvSlotOutlineModelFrame[currInt], FRAMEPOINT_BOTTOMLEFT, auxjx-0.003, auxiy-InventorySlotSize-0.003)
        call BlzFrameSetAbsPoint(DInvSlotOutlineModelFrame[currInt], FRAMEPOINT_TOPRIGHT, auxjx-0.002, auxiy-InventorySlotSize-0.002)
        //call BlzFrameSetSize(DInvSlotOutlineModelFrame[currInt], 0.00001, 0.00001)
        //call BlzFrameSetSize(DInvSlotOutlineModelFrame[currInt], 1.0, 1.0)
        //call BlzFrameSetModel(DInvSlotOutlineModelFrame[currInt], InventorySlotModel, 0)
        call BlzFrameSetScale(DInvSlotOutlineModelFrame[currInt], 0.55)
        call BlzFrameSetVisible(DInvSlotOutlineModelFrame[currInt], false)
        call BlzFrameSetEnable(DInvSlotOutlineModelFrame[currInt], false)
        endif

        // Selection model frame
        set InventorySlotButtonModelFrame[currInt] = BlzCreateFrameByType("SPRITE", "SlotMo"+I2S(currInt)+"p"+I2S(pid), InventorySlotButtonFrame[currInt], "", 0)
        call BlzFrameSetAllPoints(InventorySlotButtonModelFrame[currInt], InventorySlotButtonFrame[currInt])
        call BlzFrameSetModel(InventorySlotButtonModelFrame[currInt], InventorySlotModel, 0)
        call BlzFrameSetScale(InventorySlotButtonModelFrame[currInt], InventorySlotModelScale)

        call BlzTriggerRegisterFrameEvent(trg_InventorySlotClicked, InventorySlotButtonFrame[currInt], FRAMEEVENT_CONTROL_CLICK)

    //Inkább BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0) legyen a parent?
        //set InventoryTooltipBackdropFrame[currInt] = BlzCreateFrameByType("BACKDROP", "TTBackdrop"+I2S(currInt), InventoryLowestFrame[pid], "QuestButtonBaseTemplate", 0)
        set InventoryTooltipBackdropFrame[currInt] = BlzCreateFrame("QuestButtonBaseTemplate", InventoryLowestFrame[pid], 0, 0)
        set InventoryTooltipText[currInt] = BlzCreateFrameByType("TEXT", "TTText"+I2S(pid), InventoryTooltipBackdropFrame[currInt], "MyScriptDialogButtonTooltip", 0)
        set InventoryTooltipGoldIconFrame[currInt] = BlzCreateFrameByType("BACKDROP", "TTg"+I2S(currInt), InventoryTooltipText[currInt], "IconButtonTemplate", 0)

set ttXa = auxjx-0.01-0.25
set ttXb = auxjx+InventorySlotSize+0.02

        if auxjx > 0.4 then
        // x = 0.4 is the middle of the screen
        // slotbutton is on the right side, create tooltip on the left
        call BlzFrameSetAbsPoint(InventoryTooltipText[currInt], FRAMEPOINT_TOPLEFT, ttXa, 0.5)
        //call BlzFrameSetAbsPoint(InventoryTooltipBackdropFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, ttXa, 0.2)
        call BlzFrameSetAbsPoint(InventoryTooltipGoldIconFrame[currInt], FRAMEPOINT_TOPLEFT, ttXa, 0.483)
        call BlzFrameSetAbsPoint(InventoryTooltipGoldIconFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, ttXa+0.01, 0.473)
        else
        call BlzFrameSetAbsPoint(InventoryTooltipText[currInt], FRAMEPOINT_TOPLEFT, ttXb, 0.5)
        //call BlzFrameSetAbsPoint(InventoryTooltipBackdropFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, ttXbb, 0.2)
        call BlzFrameSetAbsPoint(InventoryTooltipGoldIconFrame[currInt], FRAMEPOINT_TOPLEFT, ttXb, 0.483)
        call BlzFrameSetAbsPoint(InventoryTooltipGoldIconFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, ttXb+0.01, 0.473)
        endif
        
        call BlzFrameSetTexture(InventoryTooltipGoldIconFrame[currInt], InventoryTooltipGoldIconTexture, 0, TRUE)

        //call BlzFrameSetPoint(InventoryTooltipText[currInt], FRAMEPOINT_TOPLEFT, InventoryTooltipBackdropFrame[currInt], FRAMEPOINT_TOPLEFT, 0.01, -0.01)
        //call BlzFrameSetPoint(InventoryTooltipText[currInt], FRAMEPOINT_BOTTOMRIGHT, InventoryTooltipBackdropFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, -0.01, 0.01)
        call BlzFrameSetSize(InventoryTooltipText[currInt], 0.25, 0)
        call BlzFrameSetTooltip(InventorySlotButtonFrame[currInt], InventoryTooltipBackdropFrame[currInt])
        call BlzFrameSetPoint(InventoryTooltipBackdropFrame[currInt], FRAMEPOINT_BOTTOMLEFT, InventoryTooltipText[currInt], FRAMEPOINT_BOTTOMLEFT, -0.01, -0.01)
        call BlzFrameSetPoint(InventoryTooltipBackdropFrame[currInt], FRAMEPOINT_TOPRIGHT, InventoryTooltipText[currInt], FRAMEPOINT_TOPRIGHT, 0.01, 0.01)
        // Disable mouse control for the text:
        call BlzFrameSetEnable(InventoryTooltipText[currInt], FALSE)

        call BlzFrameSetVisible(InventorySlotButtonFrame[currInt], false)
        call BlzFrameSetVisible(InventorySlotButtonIconFrame[currInt], false)
        call BlzFrameSetVisible(InventorySlotButtonModelFrame[currInt], false)

        call BlzFrameSetVisible(InventoryTooltipGoldIconFrame[currInt], TRUE)

        call BlzFrameSetVisible(InventorySlotButtonFrame[currInt], TRUE)
        call BlzFrameSetVisible(InventorySlotButtonIconFrame[currInt], TRUE)

        call BlzFrameSetVisible(InventoryTooltipBackdropFrame[currInt], false)

    set j = j + 1 
    exitwhen j >= InventoryColumns
    endloop
set j = 0
set i = i + 1
exitwhen i >= InventoryRows
endloop
   
//Close X button
set InventoryXButtonFrame[pid] = BlzCreateFrameByType("GLUETEXTBUTTON", "CloseButt"+I2S(pid), InventoryLowestFrame[pid], "ScriptDialogButton", 0)
call BlzFrameSetText(InventoryXButtonFrame[pid], " X")
call BlzFrameSetTextAlignment(InventoryXButtonFrame[pid], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
call BlzFrameSetAbsPoint(InventoryXButtonFrame[pid], FRAMEPOINT_TOPLEFT, InventoryCloseTopLeftX, InventoryCloseTopLeftY)
call BlzFrameSetAbsPoint(InventoryXButtonFrame[pid], FRAMEPOINT_BOTTOMRIGHT, InventoryCloseBotRightX, InventoryCloseBotRightY)
set InventoryXButtonIconFrame[pid] = BlzCreateFrameByType("BACKDROP", "CloseButtIcon"+I2S(pid), InventoryXButtonFrame[pid], "IconButtonTemplate", 0)
call BlzFrameSetTexture(InventoryXButtonIconFrame[pid], InventoryXButtonIconTexture, 0, TRUE)
call BlzFrameSetAllPoints(InventoryXButtonIconFrame[pid], InventoryXButtonFrame[pid])
// Tooltip for X button
set InventoryXButtonTipFrame[pid] = BlzCreateFrame("QuestButtonBaseTemplate", InventoryLowestFrame[pid], 0, 0)
set InventoryXButtonTipTextFrame[pid] = BlzCreateFrameByType("TEXT", "TXTText"+I2S(pid), InventoryXButtonTipFrame[pid], "MyScriptDialogButtonTooltip", 0)
call BlzFrameSetAbsPoint(InventoryXButtonTipTextFrame[pid], FRAMEPOINT_TOPLEFT, ttXa, 0.5)
call BlzFrameSetText(InventoryXButtonTipTextFrame[pid], "How to use:|nClick on an item to select it.|nClick on it again immediately to drop it to the ground.|nOR wait a very short time (~0.5s) to send it to vanilla inventory.|nOR Click on an equipment slot to equip it.|nOR Click on another inventory slot to move it to another slot.|n|nStat values displayed, such as STR, Armor, etc., are not the unit's total STR, Armor, etc., but the amount changed by the equipment of this system.")
call BlzFrameSetTooltip(InventoryXButtonFrame[pid], InventoryXButtonTipFrame[pid])
        call BlzFrameSetPoint(InventoryXButtonTipFrame[pid], FRAMEPOINT_BOTTOMLEFT, InventoryXButtonTipTextFrame[pid], FRAMEPOINT_BOTTOMLEFT, -0.01, -0.01)
        call BlzFrameSetPoint(InventoryXButtonTipFrame[pid], FRAMEPOINT_TOPRIGHT, InventoryXButtonTipTextFrame[pid], FRAMEPOINT_TOPRIGHT, 0.01, 0.01)
        // Disable mouse control for the text:
        call BlzFrameSetEnable(InventoryXButtonTipTextFrame[pid], FALSE)
        call BlzFrameSetVisible(InventoryXButtonTipFrame[pid], false)

set InventoryGiveButtonFrame[pid] = BlzCreateFrameByType("GLUETEXTBUTTON", "GiveButt"+I2S(pid), InventoryLowestFrame[pid], "ScriptDialogButton", 0)
call BlzFrameSetText(InventoryGiveButtonFrame[pid], "Give")
call BlzFrameSetTextAlignment(InventoryGiveButtonFrame[pid], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
call BlzFrameSetLevel(InventoryGiveButtonFrame[pid], 8)
call BlzFrameSetScale(InventoryGiveButtonFrame[pid], 0.9)
call BlzFrameSetAbsPoint(InventoryGiveButtonFrame[pid], FRAMEPOINT_TOPLEFT, InventoryGiveTopLeftX, InventoryGiveTopLeftY)
call BlzFrameSetAbsPoint(InventoryGiveButtonFrame[pid], FRAMEPOINT_BOTTOMRIGHT, InventoryGiveBotRightX, InventoryGiveBotRightY)
call BlzFrameSetVisible(InventoryGiveButtonFrame[pid], false)
//Page buttons here
set InventoryPageLeftButtonFrame[pid] = BlzCreateFrameByType("GLUEBUTTON", "PageLeftButt"+I2S(pid), InventoryLowestFrame[pid], "ScoreScreenTabButtonTemplate", 0)
set InventoryPageRightButtonFrame[pid] = BlzCreateFrameByType("GLUEBUTTON", "PageRightButt"+I2S(pid), InventoryLowestFrame[pid], "ScoreScreenTabButtonTemplate", 0)
set InventoryPageLeftButtonIconFrame[pid] = BlzCreateFrameByType("BACKDROP", "PageLeftButtIcon"+I2S(pid), InventoryPageLeftButtonFrame[pid], "IconButtonTemplate", 0)
set InventoryPageRightButtonIconFrame[pid] = BlzCreateFrameByType("BACKDROP", "PageRightButtIcon"+I2S(pid), InventoryPageLeftButtonFrame[pid], "IconButtonTemplate", 0)
set InventoryPageCounterTextFrame[pid] = BlzCreateFrameByType("TEXT", "CloseButtTxt"+I2S(pid), InventoryLowestFrame[pid], "", 0)
call BlzFrameSetText(InventoryPageCounterTextFrame[pid], I2S(DInvCurrentPage[pid]))
call BlzFrameSetTextAlignment(InventoryPageCounterTextFrame[pid], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
call BlzFrameSetTextSizeLimit(InventoryPageCounterTextFrame[pid], 11)
call BlzFrameSetScale(InventoryPageCounterTextFrame[pid], 2)
call BlzFrameSetAbsPoint(InventoryPageCounterTextFrame[pid], FRAMEPOINT_TOPLEFT, InventoryPageCounterTextTopLeftX, InventoryPageCounterTextTopLeftY)
call BlzFrameSetAbsPoint(InventoryPageCounterTextFrame[pid], FRAMEPOINT_BOTTOMRIGHT, InventoryPageCounterTextBotRightX, InventoryPageCounterTextBotRightY)
set InventoryCapacityTextFrame[pid] = BlzCreateFrameByType("TEXT", "DInvCapacityTxt"+I2S(pid), InventoryLowestFrame[pid], "", 0)
call BlzFrameSetText(InventoryCapacityTextFrame[pid], "Bag: 0/"+I2S(DInvBagCapacityStarting))
call BlzFrameSetTextAlignment(InventoryCapacityTextFrame[pid], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
call BlzFrameSetScale(InventoryCapacityTextFrame[pid], 0.90)
call BlzFrameSetPoint(InventoryCapacityTextFrame[pid], FRAMEPOINT_TOPRIGHT, InventoryMainFrame[pid], FRAMEPOINT_BOTTOMRIGHT, 0.0, -0.006)
call BlzFrameSetSize(InventoryCapacityTextFrame[pid], 0.065, 0.024)
call BlzFrameSetEnable(InventoryCapacityTextFrame[pid], FALSE)
call BlzFrameSetAbsPoint(InventoryPageLeftButtonFrame[pid], FRAMEPOINT_TOPLEFT, InventoryPageLeftTopLeftX, InventoryPageLeftTopLeftY)
call BlzFrameSetAbsPoint(InventoryPageLeftButtonFrame[pid], FRAMEPOINT_BOTTOMRIGHT, InventoryPageLeftBotRightX, InventoryPageLeftBotRightY)
call BlzFrameSetAbsPoint(InventoryPageRightButtonFrame[pid], FRAMEPOINT_TOPLEFT, InventoryPageRightTopLeftX, InventoryPageRightTopLeftY)
call BlzFrameSetAbsPoint(InventoryPageRightButtonFrame[pid], FRAMEPOINT_BOTTOMRIGHT, InventoryPageRightBotRightX, InventoryPageRightBotRightY)
call BlzFrameSetTexture(InventoryPageLeftButtonIconFrame[pid], InventoryPageLeftTexture, 0, TRUE)
call BlzFrameSetTexture(InventoryPageRightButtonIconFrame[pid], InventoryPageRightTexture, 0, TRUE)
call BlzFrameSetAllPoints(InventoryPageLeftButtonIconFrame[pid], InventoryPageLeftButtonFrame[pid])
call BlzFrameSetAllPoints(InventoryPageRightButtonIconFrame[pid], InventoryPageRightButtonFrame[pid])
//Stacking buttons
if InfiniteStackingSystemAllowed == TRUE then
    set StackingTextFrame[pid] = BlzCreateFrameByType("TEXT", "StackingTxt"+I2S(pid), InventoryLowestFrame[pid], "", 0)
    call BlzFrameSetText(StackingTextFrame[pid], "Infinite|nStack")
    call BlzFrameSetTextAlignment(StackingTextFrame[pid], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(StackingTextFrame[pid], 0.9)
    call BlzFrameSetAbsPoint(StackingTextFrame[pid], FRAMEPOINT_TOPLEFT, StackingTextTopLeftX, StackingTextTopLeftY)
    call BlzFrameSetAbsPoint(StackingTextFrame[pid], FRAMEPOINT_BOTTOMRIGHT, StackingTextBotRightX, StackingTextBotRightY)
    call BlzFrameSetVisible(StackingTextFrame[pid], false)

    set InfiniteStackingCheckBoxFrame[pid] = BlzCreateFrameByType("GLUEBUTTON", "InfStackingButt"+I2S(pid), InventoryLowestFrame[pid], "ScoreScreenTabButtonTemplate", 0)
    call BlzFrameSetAbsPoint(InfiniteStackingCheckBoxFrame[pid], FRAMEPOINT_TOPLEFT, InfiniteStackingCheckBoxTopLeftX, InfiniteStackingCheckBoxTopLeftY)
    call BlzFrameSetAbsPoint(InfiniteStackingCheckBoxFrame[pid], FRAMEPOINT_BOTTOMRIGHT, InfiniteStackingCheckBoxBotRightX, InfiniteStackingCheckBoxBotRightY)
    call BlzFrameSetVisible(InfiniteStackingCheckBoxFrame[pid], false)

    set InfiniteStackingCheckBoxIconFrame[pid] = BlzCreateFrameByType("BACKDROP", "InfStackButtIcon"+I2S(pid), InfiniteStackingCheckBoxFrame[pid], "IconButtonTemplate", 0)
    if PlayerStackingMode[pid] == 0 then
    call BlzFrameSetTexture(InfiniteStackingCheckBoxIconFrame[pid], StackingCheckBoxEmptyTexture, 0, TRUE)
    else
    call BlzFrameSetTexture(InfiniteStackingCheckBoxIconFrame[pid], StackingCheckBoxCheckedTexture, 0, TRUE)
    endif
    call BlzFrameSetAllPoints(InfiniteStackingCheckBoxIconFrame[pid], InfiniteStackingCheckBoxFrame[pid])
    call BlzFrameSetVisible(InfiniteStackingCheckBoxIconFrame[pid], false)
endif
//Hide them all:
call BlzFrameSetVisible(InventoryPageLeftButtonFrame[pid], false)
call BlzFrameSetVisible(InventoryPageRightButtonFrame[pid], false)
call BlzFrameSetVisible(InventoryPageCounterTextFrame[pid], false)
call BlzFrameSetVisible(InventoryCapacityTextFrame[pid], false)
call BlzFrameSetVisible(InventoryXButtonIconFrame[pid], false)
call BlzFrameSetVisible(InventoryXButtonFrame[pid], false)
call BlzFrameSetVisible(InventoryGiveButtonFrame[pid], false)
call BlzFrameSetVisible(InventoryMainFrame[pid], false)
call BlzFrameSetVisible(InventoryLowestFrame[pid], false)
endfunction



function InventoryButtonClicked takes nothing returns nothing
local player localplyr = GetLocalPlayer()
local player plyr = GetTriggerPlayer()
local integer pid = GetPlayerId(plyr)
local framehandle myFrame = BlzGetTriggerFrame()

if plyr == localplyr then      
// This below is needed to avoid the frame focus bug which locks player control in a weird way when clicking buttonz
call BlzFrameSetVisible(myFrame, false)
call BlzFrameSetVisible(myFrame, true)
call StopCamera()
endif

call DInvCloseForPlayer(plyr)

set myFrame = null
set localplyr = null
set plyr = null
endfunction



function DInvGiveUnitSelectedActions takes nothing returns nothing
local player plyr = GetTriggerPlayer()
set DInvGiveSelectedUnit[GetPlayerId(plyr)] = GetTriggerUnit()
call DInvGiveRefreshButtonForPlayer(plyr)
set plyr = null
endfunction



function DInvGiveUnitDeselectedActions takes nothing returns nothing
local integer pid = GetPlayerId(GetTriggerPlayer())
if DInvGiveSelectedUnit[pid] == GetTriggerUnit() then
set DInvGiveSelectedUnit[pid] = null
endif
call DInvGiveRefreshButtonForPlayer(GetTriggerPlayer())
endfunction



function DInvGiveButtonClickedActions takes nothing returns nothing
local player localplyr = GetLocalPlayer()
local player plyr = GetTriggerPlayer()
local integer pid = GetPlayerId(plyr)
local unit sourceUnit = DInvCurrentUnit[pid]
local unit targetUnit = DInvGiveSelectedUnit[pid]
local integer sourceSlotId = SourceDItemSlotIdActive[pid]
local integer result = DINV_TRANSFER_RESULT_INVALID
local framehandle myFrame = BlzGetTriggerFrame()
if plyr == localplyr then
call BlzFrameSetEnable(myFrame, false)
call BlzFrameSetEnable(myFrame, true)
call StopCamera()
endif
if sourceUnit == null or sourceSlotId < 0 or targetUnit == null or targetUnit == sourceUnit or UnitAlive(targetUnit) == FALSE then
call DInvPlayInventoryErrorForUnit(sourceUnit, "Target unit doesn't have inventory.")
elseif DInvCurrentInspectMode[pid] == TRUE then
call DInvGiveSetButtonVisible(pid, FALSE)
else
set result = DInvTransferStoredItemToUnit(sourceUnit, sourceSlotId, targetUnit)
    if result == DINV_TRANSFER_RESULT_TARGET_FULL then
    call DInvPlayInventoryErrorForUnit(sourceUnit, "Target unit inventory is full.")
    elseif result == DINV_TRANSFER_RESULT_NO_TARGET_INVENTORY then
    call DInvPlayInventoryErrorForUnit(sourceUnit, "Target unit doesn't have inventory.")
    elseif result == DINV_TRANSFER_RESULT_DINV or result == DINV_TRANSFER_RESULT_VANILLA then
    call DeactivateActiveDItemSlotIds(pid)
    else
    call DInvGiveRefreshButtonForPlayer(plyr)
    endif
endif
set localplyr = null
set plyr = null
set sourceUnit = null
set targetUnit = null
set myFrame = null
endfunction



function LoadBugProtectionActions takes nothing returns nothing
// As of 2023 September, there is a bug in Warcraft III's current patch, where logic containing frames always crashes the game upon loading a save game
// Because of that, we set certain variables during EVENT_GAME_LOADED rather than map initialization
local integer i = 0
////call BJDebugMsg("LoadBugProtectionActions function started")
call DestroyTrigger(trg_InventoryToggleButtonClicked)
call DestroyTrigger(trg_PageLeftClicked)
call DestroyTrigger(trg_PageRightClicked)
call DestroyTrigger(trg_InfiniteStackingButtonClicked)
call DestroyTrigger(trg_InventorySlotClicked)
call DestroyTrigger(trg_DInvGiveButtonClicked)

set trg_InventoryToggleButtonClicked = CreateTrigger()
set trg_DInvGiveButtonClicked = CreateTrigger()

set trg_PageLeftClicked = CreateTrigger()
set trg_PageRightClicked = CreateTrigger()

if InfiniteStackingSystemAllowed == TRUE then
set trg_InfiniteStackingButtonClicked = CreateTrigger()
endif

set trg_InventorySlotClicked = CreateTrigger()

set InventoryBotRightX = InventorySlotGap + InventoryTopLeftX + InventoryColumns * (InventorySlotGap + InventorySlotSize)
set InventoryBotRightY = -InventorySlotGap + InventoryTopLeftY - InventoryRows * (InventorySlotGap + InventorySlotSize)

// CONFIGURE if you want:
// By default the close inventory X button will be on the top right of the inventory.
// You can put it whenever you want. Keep in mind that the childframe has to be on the parent frame to be visible. X button's parent is InventoryLowestFrame.
set InventoryCloseTopLeftX = InventoryBotRightX
set InventoryCloseTopLeftY = InventoryTopLeftY
set InventoryCloseBotRightX = InventoryCloseTopLeftX + 0.03
set InventoryCloseBotRightY = InventoryCloseTopLeftY - 0.03
set InventoryGiveTopLeftX = InventoryTopLeftX
set InventoryGiveTopLeftY = InventoryBotRightY - 0.006
set InventoryGiveBotRightX = InventoryGiveTopLeftX + 0.08
set InventoryGiveBotRightY = InventoryGiveTopLeftY - 0.03

set InventoryPageLeftTopLeftX = InventoryBotRightX
set InventoryPageLeftTopLeftY = InventoryTopLeftY - 0.03 - 0.03 - InventorySlotGap - InventorySlotGap - InventorySlotGap
set InventoryPageLeftBotRightX = InventoryPageLeftTopLeftX + 0.03
set InventoryPageLeftBotRightY = InventoryPageLeftTopLeftY - 0.03
set InventoryPageRightTopLeftX = InventoryBotRightX
set InventoryPageRightTopLeftY = InventoryTopLeftY - 0.03 - InventorySlotGap - InventorySlotGap
set InventoryPageRightBotRightX = InventoryPageLeftBotRightX
set InventoryPageRightBotRightY = InventoryPageRightTopLeftY - 0.03

set InventoryPageCounterTextTopLeftX = InventoryBotRightX
set InventoryPageCounterTextTopLeftY = InventoryPageLeftTopLeftY - 0.03
set InventoryPageCounterTextBotRightX = InventoryPageCounterTextTopLeftX + 0.03
set InventoryPageCounterTextBotRightY = InventoryPageCounterTextTopLeftY - 0.03

set StackingTextTopLeftX = InventoryPageCounterTextTopLeftX
set StackingTextTopLeftY = InventoryPageCounterTextTopLeftY - 0.03
set StackingTextBotRightX = InventoryPageCounterTextTopLeftX + 0.03
set StackingTextBotRightY = StackingTextTopLeftY - 0.03
set InfiniteStackingCheckBoxTopLeftX = InventoryPageCounterTextTopLeftX
set InfiniteStackingCheckBoxTopLeftY = StackingTextBotRightY
set InfiniteStackingCheckBoxBotRightX = InventoryPageCounterTextTopLeftX + 0.03
set InfiniteStackingCheckBoxBotRightY = InfiniteStackingCheckBoxTopLeftY - 0.03
/*
//NEEDTODO: create a configuration option for bot / top / left / right alignment for the inventory menu
Settings for TOP TOP LEFT alignment
    real InventoryPageLeftTopLeftX = InventoryTopLeftX + InventorySlotGap
    real InventoryPageLeftTopLeftY = InventoryTopLeftY + InventorySlotGap + 0.03
    real InventoryPageLeftBotRightX = InventoryPageLeftTopLeftX + 0.03
    real InventoryPageLeftBotRightY = InventoryPageLeftTopLeftY - 0.03
    real InventoryPageRightTopLeftX = InventoryPageLeftTopLeftX + InventorySlotGap + 0.03
    real InventoryPageRightTopLeftY = InventoryPageLeftTopLeftY
    real InventoryPageRightBotRightX = InventoryPageLeftBotRightX + InventorySlotGap + 0.03
    real InventoryPageRightBotRightY = InventoryPageLeftBotRightY
*/
set i = 0
loop
    if GetPlayerSlotState(Player(i))==PLAYER_SLOT_STATE_PLAYING and GetPlayerController(Player(i))==MAP_CONTROL_USER then
    call CreateInventoryUI(i)
    call BlzTriggerRegisterFrameEvent(trg_PageLeftClicked, InventoryPageLeftButtonFrame[i], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(trg_PageRightClicked, InventoryPageRightButtonFrame[i], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(trg_InventoryToggleButtonClicked, InventoryXButtonFrame[i], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(trg_DInvGiveButtonClicked, InventoryGiveButtonFrame[i], FRAMEEVENT_CONTROL_CLICK)
        if InfiniteStackingSystemAllowed == TRUE then
        call BlzTriggerRegisterFrameEvent(trg_InfiniteStackingButtonClicked, InfiniteStackingCheckBoxFrame[i], FRAMEEVENT_CONTROL_CLICK)
        endif
    endif
set i = i + 1
exitwhen i > 23
endloop

call TriggerAddAction(trg_InventoryToggleButtonClicked, function InventoryButtonClicked)
call TriggerAddAction(trg_PageLeftClicked, function PageLeftClickedActions)
call TriggerAddAction(trg_PageRightClicked, function PageRightClickedActions)
call TriggerAddAction(trg_InventorySlotClicked, function InventorySlotClickedActions)
call TriggerAddAction(trg_DInvGiveButtonClicked, function DInvGiveButtonClickedActions)
call TriggerAddAction(trg_InfiniteStackingButtonClicked, function InfiniteStackingButtonClickedActions)
////call BJDebugMsg("LoadBugProtectionActions function finished")
endfunction



function OpenDInvAbilityUsedActions takes nothing returns nothing
local player viewer = GetTriggerPlayer()
local unit u = GetTriggerUnit()
call DInvToggleUnitForPlayer(viewer, u, FALSE)
////call BJDebugMsg("OpenDInvAbilityUsedActions "+GetUnitName(u))
set viewer = null
set u = null
endfunction



function OpenDInvAbilityUsedCond takes nothing returns boolean
if GetSpellAbilityId() == OpenDInventoryAbilityId then
return TRUE
endif
return FALSE
endfunction



function AutoAddNewHeroToDInvActions takes nothing returns nothing
local unit u = GetTriggerUnit()
if IsUnitType(u, UNIT_TYPE_HERO) == true and IsUnitType(u, UNIT_TYPE_SUMMONED) == false then
call InitializeDInventoryForUnit(u)
endif
////call BJDebugMsg("AutoAddNewHeroToDInvActions "+GetUnitName(u))
set u = null
endfunction



function DInvHeroAutoAddFilter takes nothing returns boolean
local unit u = GetFilterUnit()
if IsUnitType(u, UNIT_TYPE_HERO) == true and IsUnitType(u, UNIT_TYPE_SUMMONED) == false then
//if IsHeroUnitId(GetUnitTypeId(u)) == TRUE and  then
call InitializeDInventoryForUnit(u)
////call BJDebugMsg("DInvHeroAutoAddFilter "+GetUnitName(GetFilterUnit()))
set u = null
return TRUE
endif
set u = null
return FALSE
endfunction



function DInvNoDesyncInitActions takes nothing returns nothing
local integer i = 0
local group ug = CreateGroup()
set MapMinX = GetCameraBoundMinX()-GetCameraMargin(CAMERA_MARGIN_LEFT) +50
set MapMinY = GetCameraBoundMinY()-GetCameraMargin(CAMERA_MARGIN_BOTTOM) +50

set DInvUnits = Table.create()
set DInvItemTypeExclusionListForPlayer = TableArray[25]
set ItemExclusionListForPlayer = TableArray[25]
set DInvItemHandleDB = Table2DT.create()
set DInvUnitHandleDB = Table3DT.create()
set DEqItemTypeDefinitionDB = Table3DT.create()
set DItemRarityDB = Table.create()
set DInventoryDB = TableArray[2500]
set NamedItemTypeDB = Table4D.create()
set DEqSetDB = Table4D.create()
set DEqTroveDB = Table3DT.create()
set DInvBeam = Table.create()
set EQIDDB = Table3DT.create()
set BIDDB = Table3DT.create()

loop
    if DInvCanPlayerOwnInventoryUnit(i) == TRUE then
        if AutomaticDInventoryStorage == TRUE then
        call TriggerRegisterPlayerUnitEvent(trg_ItemObtainedDI, Player(i), EVENT_PLAYER_UNIT_PICKUP_ITEM, null)
        endif

        if AutomaticallyAddHeroesToTheSystem == TRUE then
        call GroupEnumUnitsOfPlayer(ug, Player(i), function DInvHeroAutoAddFilter)
        endif
    endif

    if DInvCanPlayerUseInventoryFrames(i) == TRUE then
        ////call BJDebugMsg("Player "+I2S(i)+" is a real boi")
        set DInvCurrentPage[i] = 1

        set DInvTotalPlayers = DInvTotalPlayers + 1

        call TriggerRegisterPlayerUnitEvent( trg_OpenDInvAbilityUsed, Player(i), EVENT_PLAYER_UNIT_SPELL_EFFECT, null )
        call TriggerRegisterPlayerUnitEvent(trg_DInvGiveUnitSelected, Player(i), EVENT_PLAYER_UNIT_SELECTED, null)
        call TriggerRegisterPlayerUnitEvent(trg_DInvGiveUnitDeselected, Player(i), EVENT_PLAYER_UNIT_DESELECTED, null)

        set DInvDoubleClickTimer[i] = CreateTimer()
    endif
set i = i + 1
exitwhen i > 23
endloop

if AutomaticDInventoryStorage == TRUE then
call TriggerAddAction(trg_ItemObtainedDI, function ItemPickedUpActions)
endif

if AutomaticallyAddHeroesToTheSystem == TRUE then
//call ForGroup(ug, function DInvHeroAutoAddFunc)
call TriggerRegisterEnterRectSimple( trg_AutoAddNewHeroToDInv, GetWorldBounds() )
call TriggerAddAction( trg_AutoAddNewHeroToDInv, function AutoAddNewHeroToDInvActions )
endif

call TriggerAddCondition(trg_OpenDInvAbilityUsed, function OpenDInvAbilityUsedCond)
call TriggerAddAction(trg_OpenDInvAbilityUsed, function OpenDInvAbilityUsedActions)
call TriggerAddAction(trg_DInvGiveUnitSelected, function DInvGiveUnitSelectedActions)
call TriggerAddAction(trg_DInvGiveUnitDeselected, function DInvGiveUnitDeselectedActions)

call LoadBugProtectionActions()

endfunction



private function Init takes nothing returns nothing
//////call BJDebugMsg("Init started")
call TriggerRegisterGameEvent(trg_LoadBugProtection, EVENT_GAME_LOADED)
call TriggerAddAction(trg_LoadBugProtection, function LoadBugProtectionActions)
// Certain actions during "Map initialization" do not work properly or cause desyncs, so this is the real init:
call TriggerRegisterTimerEvent( trg_DInventoryNoDesyncInit, 0.01, false )
call TriggerAddAction(trg_DInventoryNoDesyncInit, function DInvNoDesyncInitActions)
//////call BJDebugMsg("Init finished")
endfunction

endlibrary
