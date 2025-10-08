/*
DEquipment by emperor_d3st
Hiveworkshop link
Github link

Version 1.0.0
2024 August 4

Version history:

Special thanks to Tasyen's truly heroic efforts to educate us about the wonders (and nasty bugs) of Frames:
https://www.hiveworkshop.com/threads/the-big-ui-frame-tutorial.335296/

Thanks to Tasyen for his GetMainSelectedUnit library
https://www.hiveworkshop.com/threads/getmainselectedunit.325337/
*/

library DEquipment initializer Init requires DInventory, Table, SharedDInvLib, GetItemCost

globals
trigger trg_AutoAddNewHeroToDEq = CreateTrigger()

/*
Slots:
1 - Head					7 - Gloves
2 - Neck					8 - Ring1
3 - Shoulders				9 - Ring2
4 - Back					10 - Belt
5 - Chest					11 - Legs
6 - Bracer					12 - Boots
Configure this! You can enable, disable 14 equipment slots in total. Maybe in your game you only want to have helm + armor + weapon + ring + boots? Have it your way.
Slots 13, 14, 15, 16, 17, 18 are not defined. I think even 14 types of slots are probably too much for a Warcraft III map, unless you are doing some really long ARPG or campaign, but you do you.
The system itself supports 14 items out of the box, and is programmed to draw 6 more if you enable slots 13-18
19 - Main Hand				20 - Offhand ( 2h weapons dummy to this slot )
*/

trigger trg_DEqPreDefinedItems = CreateTrigger()
integer array SourceDEqSlotIdActive[24]
trigger trg_DEqSlotClicked = CreateTrigger()
framehandle array EquipmentBackDropFrame[24]
real DEqBackDropTopLeftX = 0.04
real DEqBackDropTopLeftY = 0.56
real DEqBackDropBottomRightX = 0.3
real DEqBackDropBottomRightY = 0.2
framehandle array EquipmentAvgItemLevelText[24]
real DEqILvlTextTopLeftX = 0.0
real DEqILvlTextTopLeftY = 0.0
real DEqILvlTextBottomRightX = 0.0
real DEqILvlTextBottomRightY = 0.0
//string InventorySlotModel = "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx"
real DEqSlotModelScale = 1.04
string Slot20ForbiddenTexture = "ReplaceableTextures\\CommandButtonsDisabled\\DISPASEquipmentSlotMainHand.blp"
framehandle array DEqHeroModel[24]
framehandle array DEqHeroIcon[24]
real DEqHeroIconTopLeftX = (DEqBackDropTopLeftX+DEqBackDropBottomRightX)/2-0.025
real DEqHeroIconTopLeftY = 0.0
real DEqHeroIconBottomRightX = DEqHeroIconTopLeftX + 0.05
real DEqHeroIconBottomRightY = 0.0
framehandle array DEqCStatSheet[24]

//CONFIGURE THIS at the very bottom of this code inside "private function Init"
framehandle array EquipmentSlotButtonFrame[481]
framehandle array EquipmentSlotButtonIconFrame[481]
framehandle array EquipmentSlotButtonModelFrame[481]
framehandle array DEqHeroNameFrame[21]
boolean array DEqEnabledSlots[21]
string array DEqSlotName[21]
string array DEqSlotIconPath[21]
real array DEqSlotTopLeftX[21]
real array DEqSlotTopLeftY[21]
real array DEqSlotBotRightX[21]
real array DEqSlotBotRightY[21]

// Tooltip
framehandle array DEqTooltipBackdropFrame[481]
framehandle array DEqTooltipText[481]
framehandle array DEqTooltipItemIconFrame[481]
framehandle array DEqTooltipGoldIconFrame[481]
framehandle array DEqInventoryTooltipSeparatorFrame[481]

//CONFIGURE THIS
boolean DEqRandomModifierSystemEnabled = TRUE

trigger trg_DEqLoadBugProtection = CreateTrigger()
trigger trg_DEqNoDesyncInit = CreateTrigger()
timer array DEqDoubleClickTimer[24]
endglobals



function InitializeDEquipmentForUnit takes unit u returns integer
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer eqid = EQIDOfUHndl(GetHandleId(u))
if GetPlayerSlotState(Player(pid)) == PLAYER_SLOT_STATE_PLAYING and GetPlayerController(Player(pid)) == MAP_CONTROL_USER then
// Only for player units
    if eqid > 0 then
    // eqid is already there - Protect against double initialization
        if EQIDDB[eqid][0].integer[0] == 0 then
        set EQIDDB[eqid][0].integer[0] = 1
        set u = null
        return eqid
        endif
    else
        call InitializeDInventoryForUnit(u)
        set EQIDDB[eqid][0].integer[0] = 1
        set u = null
        return eqid
    endif
endif
// Player pid is not a real boi:
set u = null
return -1
endfunction



function DEqItemTypeDefineGoldValue takes integer iid, integer g returns nothing
set DEqItemTypeDefinitionDB[iid][0].integer[3] = g
endfunction



function DEqItemTypeDefineReqHeroLevel takes integer iid, integer hlvl returns nothing
// If you also set the level requirement of an existing item during the game, then that will overwrite this requirement
set DEqItemTypeDefinitionDB[iid][0].integer[0] = hlvl
endfunction



function DEqItemTypeDefineAs2Handed takes integer iid returns nothing
set DEqItemTypeDefinitionDB[iid][0].integer[1] = 1
//call BJDebugMsg("DEqItemTypeDefineAs2Handed "+I2S(DEqItemTypeDefinitionDB[iid][0].integer[1]))
endfunction



function DEqItemTypeDefineReqClass takes integer iid, integer uid returns nothing
//By default all classes may equip an item.
//Adding a required class will make only the required classes able to equip the item
//Adding forbidden classes only do anything if there are no required classes configured
local integer loopi = 1
loop
exitwhen DEqItemTypeDefinitionDB[iid][1].integer[loopi] == 0
set loopi = loopi + 1
endloop
set DEqItemTypeDefinitionDB[iid][1].integer[loopi] = uid
endfunction



function DEqItemTypeDefineReqClassForbiddden takes integer iid, integer uid returns nothing
//By default all classes may equip an item.
//Adding a required class will make only the required classes able to equip the item
//Adding forbidden classes only do anything if there are no required classes configured
local integer loopi = 1
loop
exitwhen DEqItemTypeDefinitionDB[iid][2].integer[loopi] == 0
set loopi = loopi + 1
endloop
set DEqItemTypeDefinitionDB[iid][2].integer[loopi] = uid
endfunction



function DEqItemTypeDefineReqAbility takes integer iid, integer abid, integer ablev returns nothing
//By default there are no ability based restrictions.
//Adding a required ability will make only units with the required ability and its level able to equip the item
//Adding forbidden abilities only do anything if there are no required abilities configured
local integer loopi = 1
loop
exitwhen DEqItemTypeDefinitionDB[iid][3].integer[loopi] == 0
set loopi = loopi + 1
endloop
set DEqItemTypeDefinitionDB[iid][3].integer[loopi] = abid
set DEqItemTypeDefinitionDB[iid][4].integer[loopi] = ablev
endfunction



function DEqItemTypeDefineReqAbilityForbiddden takes integer iid, integer abid, integer ablev returns nothing
//By default there are no ability based restrictions.
//Adding a required ability will make only units with the required ability and its level able to equip the item
//Adding forbidden abilities only do anything if there are no required abilities configured
local integer loopi = 1
loop
exitwhen DEqItemTypeDefinitionDB[iid][5].integer[loopi] == 0
set loopi = loopi + 1
endloop
set DEqItemTypeDefinitionDB[iid][5].integer[loopi] = abid
set DEqItemTypeDefinitionDB[iid][6].integer[loopi] = ablev
endfunction




function DEqItemTypeDefineReqStatById takes integer iid, integer statid, real amount returns nothing
//Defines what stats are required to equip the item
//These are the same stats that you named and stored in DEqStatNames
//Could be Strength, MaxMana, etc.
//They are checked in function
set DEqItemTypeDefinitionDB[iid][8].real[statid] = amount
endfunction



function DEqItemTypeDefineReqStatByName takes integer iid, string statname, real amount returns nothing
//Defines what stats are required to equip the item
//These are the same stats that you named and stored in DEqStatNames
//Could be Strength, MaxMana, etc.
//They are checked in function
call DEqItemTypeDefineReqStatById(iid, DEqStatNameToStatId(statname), amount)
endfunction



function DEqItemTypeDefineAllowedSlotId takes integer iid, integer slotid returns nothing
//call BJDebugMsg("DEqItemTypeDefineAllowedSlotId started")
// If you set multiple slots, item will be accepted in those slots as well
set DEqItemTypeDefinitionDB[iid][9].integer[slotid] = 1
// This just tells the system that it is an equipment:
set DEqItemTypeDefinitionDB[iid][0].integer[2] = 1
//call BJDebugMsg("DEqItemTypeDefinitionDB[iid][0].integer[2] = "+I2S(DEqItemTypeDefinitionDB[iid][0].integer[2]))
//call BJDebugMsg("DEqItemTypeDefineAllowedSlotId finished")
endfunction



function DEqSlotNameToId takes string name returns integer
local integer i = 1
loop
exitwhen DEqSlotName[i] == name or i > HighestSlotNumber
set i = i + 1
endloop
if i > HighestSlotNumber then
call BJDebugMsg("Wrong item definition. No such slot name: "+name)
return 1
else
return i
endif
endfunction



function DEqItemTypeDefineAllowedSlotByName takes integer iid, string name returns nothing
call DEqItemTypeDefineAllowedSlotId(iid, DEqSlotNameToId(name))
endfunction



function DEqItemTypeDefineStatGrantedById takes integer iid, integer statid, real amount returns nothing
set DEqItemTypeDefinitionDB[iid][10].real[statid] = amount
endfunction



function DEqItemTypeDefineStatGrantedByName takes integer iid, string statname, real amount returns nothing
call DEqItemTypeDefineStatGrantedById(iid, DEqStatNameToStatId(statname), amount)
endfunction



function DEqItemTypeDefineAbilityGranted takes integer iid, integer abid, integer ablev returns nothing
local integer loopi = 1
loop
exitwhen DEqItemTypeDefinitionDB[iid][7].integer[loopi] == 0
set loopi = loopi + 1
endloop
set DEqItemTypeDefinitionDB[iid][7].integer[loopi] = abid
set DEqItemTypeDefinitionDB[iid][11].integer[loopi] = ablev
endfunction



function DisableEquipmentForUnit takes unit u returns nothing
local integer eqid = EQIDOfUHndl(GetHandleId(u))
set EQIDDB[eqid][0].integer[0] = 0
set u = null
endfunction



//NEEDTODO:
function DEqAssignEQIdOwnershipToUnit takes integer pid, integer eqid, unit newOwner returns nothing
// Maybe the user wants to remove a unit from the game and replace it with a different unit
// clear old unit's data
    
// add new unit's data
set newOwner = null
endfunction



function DEqSlotClickedActions takes nothing returns nothing
local integer pid = GetPlayerId(GetTriggerPlayer())
local integer lp = GetPlayerId(GetLocalPlayer())
local integer bid = CurrentBID[pid]
local unit u = DInvCurrentUnit[pid]
local framehandle meinFrame = BlzGetTriggerFrame()
local integer frameId = PIDDEqSlotFrame2FrameId(pid, meinFrame)
local integer deqslotId = frameId
local integer dinvslotId = SourceDItemSlotIdActive[pid]
local item auxit = null
local integer auxi = 0
local integer uhndl = GetHandleId(u)
local integer eqid = EQIDOfUHndl(uhndl)

if pid == lp then
// This is needed to avoid the frame/camera bug
    call BlzFrameSetEnable(meinFrame, false)
    call BlzFrameSetEnable(meinFrame, true)
    call StopCamera()
endif

//call BJDebugMsg("DEq slot clicked")
//call BJDebugMsg("DEqCurrentSlotIdActive[pid] = "+I2S(DEqCurrentSlotIdActive[pid]))
//call BJDebugMsg("SourceDItemSlotIdActive[pid] = "+I2S(SourceDItemSlotIdActive[pid]))
if UnitAlive(u) == FALSE or u == null then
// Unit is dead close DInv and DEq
call CloseDInventory(pid)
    call CloseDEqUI(pid)

else
set frameId = frameId + pid*20
if DEqCurrentSlotIdActive[pid] < 0 then
// no current DEq slot active
    if SourceDItemSlotIdActive[pid] < 0 then
    // No current DInv slot active
        if EQIDDB[eqid][4].item[deqslotId] == null then
        // DEq slot empty, do nothing
        else
        // Activate DEq slot
        set DEqCurrentFrameIdActive[pid] = frameId
        set DEqCurrentSlotIdActive[pid] = deqslotId
            if lp == pid then
            call BlzFrameSetVisible(EquipmentSlotButtonModelFrame[frameId], TRUE)
            endif
        endif
        
    else
    // DInv slot active, check if DItem can be equipped, then equip it
        if DEqCanUnitEquipItemInSlot(DInvCurrentUnit[pid], DInventoryDB[bid].item[dinvslotId], deqslotId) == TRUE then
        // Unit can equip item
            if EQIDDB[eqid][4].item[deqslotId] == null then
            // DEq slot is empty, equip
            call EquipDInvItemToDEqSlot(pid, bid, eqid, u, uhndl, DInventoryDB[bid].item[dinvslotId], dinvslotId, deqslotId)
            //call BJDebugMsg("DEqSlotClickedActions if branch 01 completed")
            else
            // DEq slot is occuppied, unequip then equip
                if FirstFreeDInvSlotOfBID(pid, bid) > -1 then
                    if UnequipDEqItemToDInvSlot(pid, bid, eqid, u, uhndl, EQIDDB[eqid][4].item[deqslotId], FirstFreeDInvSlotOfBID(pid, bid), deqslotId) == TRUE then
                    call EquipDInvItemToDEqSlot(pid, bid, eqid, u, uhndl, DInventoryDB[bid].item[dinvslotId], dinvslotId, deqslotId)
                    //call BJDebugMsg("DEqSlotClickedActions if branch 02 completed")
                    else
                    // Unequip was not successful -> maybe there was no free DInv slot
                    endif
                endif
            endif
            
        call DeactivateActiveDEqSlotIds(pid)
        call DeactivateActiveDItemSlotIds(pid)
        
        else
        // Do nothing
        endif
    endif
else
// Already a current DEq slot active
    if DEqCurrentFrameIdActive[pid] == frameId then
    // same DEq slot clicked twice -> unequip if DInventory is not full
    set auxi = FirstFreeDInvSlotOfBID(pid, bid)
        if auxi == -1 then
        // Inventory is full
        else
        call UnequipDEqItemToDInvSlot(pid, bid, eqid, u, uhndl, EQIDDB[eqid][4].item[deqslotId], auxi, deqslotId)
        endif
    else
    // different DEq slot clicked, deactivate
    endif

call DeactivateActiveDEqSlotIds(pid)
call DeactivateActiveDItemSlotIds(pid)

endif
endif
set auxit = null
set meinFrame = null
set u = null
endfunction



function XCloseDEqUI takes nothing returns nothing
local integer pid = GetPlayerId(GetTriggerPlayer())
set DEqCurrentUnit[pid] = null
set CurrentEQId[pid] = -1
call CloseDEqUI(pid)
endfunction



function OpenDEqUI takes integer pid returns nothing
//NEEDTODO: Remove u, not needed, just for testing purposes
local unit u = GetTriggerUnit()
local integer lp = GetPlayerId(GetLocalPlayer())
local integer uhndl = GetHandleId(u)
//call BJDebugMsg("OpenDEqUI started")
//call BJDebugMsg("testing name: "+GetUnitName(u))
//Needtodo: will this desync? names -> localizations, different values for global integer variables... I think not? do I need getlocalizedstring function?

if pid == lp then
call BlzFrameSetVisible(EquipmentBackDropFrame[pid], TRUE)
call BlzFrameSetTexture(DEqHeroIcon[pid], BlzGetAbilityIcon(GetUnitTypeId(DInvCurrentUnit[pid])), 0, TRUE)
call UpdateDEqCSheet(pid, u, uhndl, EQIDOfUHndl(uhndl))
    if IsHeroUnitId(GetUnitTypeId(DInvCurrentUnit[pid])) == TRUE then
    call BlzFrameSetText(DEqHeroNameFrame[pid], "|cffff8000"+GetHeroProperName(DInvCurrentUnit[pid])+"|r")
    else
    call BlzFrameSetText(DEqHeroNameFrame[pid], GetUnitName(DInvCurrentUnit[pid]))
    endif
call DEqDBIntoFrames(pid, CurrentEQId[pid])
endif
endfunction



function ToggleDEqUI takes integer pid returns nothing
local unit u = GetTriggerUnit()
local integer eqid = EQIDOfUHndl(GetHandleId(u))

//call BJDebugMsg("ToggleDEqUI started")

if u == DEqCurrentUnit[pid] then
// Was open
call CloseDEqUI(pid)
set DEqCurrentUnit[pid] = null
set CurrentEQId[pid] = -1
    
else
    if DEqCurrentUnit[pid] == null then
    // was closed
    else
    // was open for another unit
    call CloseDEqUI(pid)
    endif
    
    if EQIDDB[eqid][0].integer[0] == 1 then
    // check if equipment is enabled for this unit
    set DEqCurrentUnit[pid] = u
    set CurrentEQId[pid] = eqid
    call OpenDEqUI(pid)
    endif
endif

//call BJDebugMsg("CurrentEQId[pid]: "+I2S(CurrentEQId[pid]))

set u = null
endfunction



function InventoryButtonClickedDEq takes nothing returns nothing
local integer pid = GetPlayerId(GetTriggerPlayer())
call ToggleDEqUI(pid)
endfunction



function CreateDEqUI takes integer pid returns nothing
local integer j = 1
local integer currInt = 0
//local real ttxa = 0.4-InventorySlotSize-0.25
//local real ttxb = 0.4+InventorySlotSize
local real ttxa = 0
local real ttxb = 0


set EquipmentBackDropFrame[pid] = BlzCreateFrameByType("BACKDROP", "DEqLowest"+I2S(pid), BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "EscMenuBackdrop", 1)
//set EquipmentBackDropFrame[pid] = BlzCreateFrameByType("BACKDROP", "DEqLowest"+I2S(pid), BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "", 0)
    //call BlzFrameSetTexture(InventoryLowestFrame[pid], "UI\\Widgets\\ToolTips\\Human\\human-tooltip-background.blp", 0, TRUE)
call BlzFrameSetAbsPoint(EquipmentBackDropFrame[pid], FRAMEPOINT_TOPLEFT, DEqBackDropTopLeftX, DEqBackDropTopLeftY)
call BlzFrameSetAbsPoint(EquipmentBackDropFrame[pid], FRAMEPOINT_BOTTOMRIGHT, DEqBackDropBottomRightX, DEqBackDropBottomRightY)
    // BlzFrameSetTexture - flag, 0 for stretched mode; 1 for tile mode
    //call BlzFrameSetTexture(InventoryMainFrame[pid], "UI\\Widgets\\Console\\Human\\human-console-button-back-active.blp", 1, TRUE)
//set DEqHeroNameFrame[pid] = BlzCreateFrameByType("TEXT", "HeroNameTxt"+"p"+I2S(pid), EquipmentBackDropFrame[pid], "LadderNameTextTemplate", 0)

set DEqHeroNameFrame[pid] = BlzCreateFrameByType("TEXT", "HeroNameTxt"+"p"+I2S(pid), EquipmentBackDropFrame[pid], "", 0)
call BlzFrameSetText(DEqHeroNameFrame[pid], "Yoloman")
call BlzFrameSetTextAlignment(DEqHeroNameFrame[pid], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
call BlzFrameSetScale(DEqHeroNameFrame[pid], 1)
call BlzFrameSetAbsPoint(DEqHeroNameFrame[pid], FRAMEPOINT_TOPLEFT, DEqBackDropTopLeftX, DEqBackDropTopLeftY-0.014)
call BlzFrameSetAbsPoint(DEqHeroNameFrame[pid], FRAMEPOINT_BOTTOMRIGHT, DEqBackDropBottomRightX, DEqBackDropTopLeftY-0.034)
// Disable, so the text does not obstruct clicks from the button
call BlzFrameSetEnable(DEqHeroNameFrame[pid], FALSE)

set DEqHeroIcon[pid] = BlzCreateFrameByType("BACKDROP", "DEqHeroIcp"+I2S(pid), EquipmentBackDropFrame[pid], "IconButtonTemplate", 0)
call BlzFrameSetAbsPoint(DEqHeroIcon[pid], FRAMEPOINT_TOPLEFT, DEqHeroIconTopLeftX, DEqHeroIconTopLeftY)
call BlzFrameSetAbsPoint(DEqHeroIcon[pid], FRAMEPOINT_BOTTOMRIGHT, DEqHeroIconBottomRightX, DEqHeroIconBottomRightY)

call BlzFrameSetVisible(EquipmentBackDropFrame[pid], FALSE)

//call BlzLoadTOCFile("UI\\Frames\\framedef\\ui\\escmenutemplates.fdf​")
set DEqCStatSheet[pid] = BlzCreateFrameByType("TEXT", "CSheet"+"p"+I2S(pid), EquipmentBackDropFrame[pid], "", 0)
//set DEqCStatSheet[pid] = BlzCreateFrame("EscMenuTextAreaTemplate", EquipmentBackDropFrame[pid], 0, 0)
//set DEqCStatSheet[pid] = BlzCreateFrameByType("TEXTAREA", "CSheet"+"p"+I2S(pid), EquipmentBackDropFrame[pid], "EscMenuTextAreaTemplate", 0)
call BlzFrameSetAbsPoint(DEqCStatSheet[pid], FRAMEPOINT_TOPLEFT, 0.10, DEqHeroIconBottomRightY)
call BlzFrameSetAbsPoint(DEqCStatSheet[pid], FRAMEPOINT_BOTTOMRIGHT, 0.237, DEqBackDropBottomRightY)
call BlzFrameSetSize(DEqCStatSheet[pid], 0.25, 0.25)
call BlzFrameSetTextAlignment(DEqCStatSheet[pid], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
// Disable, so the text does not obstruct clicks
call BlzFrameSetEnable(DEqCStatSheet[pid], FALSE)

loop

if DEqEnabledSlots[j] == TRUE then
set currInt = pid*20+j
////call BJDebugMsg("drawing DEq: "+I2S(currInt))
set EquipmentSlotButtonFrame[currInt] = BlzCreateFrameByType("GLUEBUTTON", "DEqSlot"+I2S(currInt)+"p"+I2S(pid), EquipmentBackDropFrame[pid], "ScoreScreenTabButtonTemplate", 0)
call BlzFrameSetAbsPoint(EquipmentSlotButtonFrame[currInt], FRAMEPOINT_TOPLEFT, DEqSlotTopLeftX[j], DEqSlotTopLeftY[j])
call BlzFrameSetAbsPoint(EquipmentSlotButtonFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, DEqSlotBotRightX[j], DEqSlotBotRightY[j])
call BlzFrameSetTexture(EquipmentSlotButtonFrame[currInt], DEqSlotIconPath[j], 0, TRUE)

set EquipmentSlotButtonIconFrame[currInt] = BlzCreateFrameByType("BACKDROP", "DEqSlotIc"+I2S(currInt)+"p"+I2S(pid), EquipmentSlotButtonFrame[currInt], "IconButtonTemplate", 0)
call BlzFrameSetAllPoints(EquipmentSlotButtonIconFrame[currInt], EquipmentSlotButtonFrame[currInt])
call BlzFrameSetTexture(EquipmentSlotButtonIconFrame[currInt], DEqSlotIconPath[j], 0, TRUE)

set EquipmentSlotButtonModelFrame[currInt] = BlzCreateFrameByType("SPRITE", "DEqSlotMo"+I2S(currInt)+"p"+I2S(pid), EquipmentSlotButtonFrame[currInt], "", 0)
call BlzFrameSetAllPoints(EquipmentSlotButtonModelFrame[currInt], EquipmentSlotButtonFrame[currInt])
call BlzFrameSetModel(EquipmentSlotButtonModelFrame[currInt], InventorySlotModel, 0)
call BlzFrameSetScale(EquipmentSlotButtonModelFrame[currInt], DEqSlotModelScale)

//set DEqTooltipBackdropFrame[currInt] = BlzCreateFrameByType("BACKDROP", "DEqTTBdrop"+I2S(pid), EquipmentBackDropFrame[pid], "QuestButtonBaseTemplate", 1)
set DEqTooltipBackdropFrame[currInt] = BlzCreateFrame("QuestButtonBaseTemplate", EquipmentBackDropFrame[pid], 0, 0)

set DEqTooltipText[currInt] = BlzCreateFrameByType("TEXT", "DEqTTTxt"+I2S(pid), DEqTooltipBackdropFrame[currInt], "StandardInfoTextTemplate", 1)

set DEqTooltipGoldIconFrame[currInt] = BlzCreateFrameByType("BACKDROP", "TTEqg"+I2S(currInt), DEqTooltipText[currInt], "IconButtonTemplate", 1)

set ttxa = DEqSlotTopLeftX[j]-0.01-0.25
set ttxb = DEqSlotTopLeftX[j]+InventorySlotSize+0.02

    if DEqSlotTopLeftX[j] > 0.4 then
    // x = 0.4 is the middle of the screen
    // slotbutton is on the right side, create tooltip on the left
    call BlzFrameSetAbsPoint(DEqTooltipText[currInt], FRAMEPOINT_TOPLEFT, ttxa, 0.5)
    //call BlzFrameSetAbsPoint(DEqTooltipBackdropFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, ttxaa, 0.2)
    call BlzFrameSetAbsPoint(DEqTooltipGoldIconFrame[currInt], FRAMEPOINT_TOPLEFT, ttxa, 0.483)
    call BlzFrameSetAbsPoint(DEqTooltipGoldIconFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, ttxa+0.01, 0.473)
    else
    call BlzFrameSetAbsPoint(DEqTooltipText[currInt], FRAMEPOINT_TOPLEFT, ttxb, 0.5)
    //call BlzFrameSetAbsPoint(DEqTooltipBackdropFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, ttxbb, 0.2)
    call BlzFrameSetAbsPoint(DEqTooltipGoldIconFrame[currInt], FRAMEPOINT_TOPLEFT, ttxb, 0.483)
    call BlzFrameSetAbsPoint(DEqTooltipGoldIconFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, ttxb+0.01, 0.473)
    endif

call BlzFrameSetTexture(DEqTooltipGoldIconFrame[currInt], InventoryTooltipGoldIconTexture, 0, TRUE)

//call BlzFrameSetPoint(DEqTooltipText[currInt], FRAMEPOINT_TOPLEFT, DEqTooltipBackdropFrame[currInt], FRAMEPOINT_TOPLEFT, 0.01, -0.01)
//call BlzFrameSetPoint(DEqTooltipText[currInt], FRAMEPOINT_BOTTOMRIGHT, DEqTooltipBackdropFrame[currInt], FRAMEPOINT_BOTTOMRIGHT, -0.01, 0.01)
call BlzFrameSetSize(DEqTooltipText[currInt], 0.25, 0)
call BlzFrameSetTooltip(EquipmentSlotButtonFrame[currInt], DEqTooltipBackdropFrame[currInt])
call BlzFrameSetPoint(DEqTooltipBackdropFrame[currInt], FRAMEPOINT_BOTTOMLEFT, DEqTooltipText[currInt], FRAMEPOINT_BOTTOMLEFT, -0.01, -0.01)
call BlzFrameSetPoint(DEqTooltipBackdropFrame[currInt], FRAMEPOINT_TOPRIGHT, DEqTooltipText[currInt], FRAMEPOINT_TOPRIGHT, 0.01, 0.01)
// Disable mouse control for the text:
call BlzFrameSetEnable(DEqTooltipText[currInt], FALSE)

call BlzFrameSetVisible(DEqTooltipBackdropFrame[currInt], false)
call BlzFrameSetVisible(EquipmentSlotButtonFrame[currInt], false)
call BlzFrameSetVisible(EquipmentSlotButtonIconFrame[currInt], false)
call BlzFrameSetVisible(EquipmentSlotButtonModelFrame[currInt], false)
call BlzFrameSetVisible(EquipmentSlotButtonFrame[currInt], TRUE)
call BlzFrameSetVisible(EquipmentSlotButtonIconFrame[currInt], TRUE)

call BlzTriggerRegisterFrameEvent(trg_DEqSlotClicked, EquipmentSlotButtonFrame[currInt], FRAMEEVENT_CONTROL_CLICK)

endif

set j = j + 1
exitwhen j > 20
endloop
//call BJDebugMsg("CreateDEqUI finished")
endfunction



function DEqLoadBugProtectionActions02s takes nothing returns nothing
local integer pid = 0

call DestroyTrigger(trg_DEqSlotClicked)
set trg_DEqSlotClicked = CreateTrigger()

    loop
        if GetPlayerSlotState(Player(pid)) == PLAYER_SLOT_STATE_PLAYING and GetPlayerController(Player(pid)) == MAP_CONTROL_USER then
            call CreateDEqUI(pid)
        endif
    set pid = pid + 1
    exitwhen pid > 23
    endloop

call TriggerAddAction(trg_InventoryToggleButtonClicked, function XCloseDEqUI)
call TriggerAddAction(trg_DEqSlotClicked, function DEqSlotClickedActions)
call DestroyTimer(GetExpiredTimer())
//call BJDebugMsg("DEqLoadBugProtectionActions ran")
endfunction



function DEqLoadBugProtectionActions takes nothing returns nothing
call TimerStart(CreateTimer(), 0.02, false, function DEqLoadBugProtectionActions02s)
endfunction



function AutoAddNewHeroToDEqActions takes nothing returns nothing
local unit u = GetTriggerUnit()
call InitializeDEquipmentForUnit(u)
set u = null
endfunction



function DEqHeroAutoAddFilter takes nothing returns boolean
local unit u = GetFilterUnit()
if IsHeroUnitId(GetUnitTypeId(u)) then
call InitializeDEquipmentForUnit(u)
////call BJDebugMsg("DInvHeroAutoAddFilter "+GetUnitName(GetFilterUnit()))
set u = null
return TRUE
endif
set u = null
return FALSE
endfunction



function DEqNoDesyncInitActions takes nothing returns nothing
local integer i = 0
local group ug = CreateGroup()

loop
    if GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING and GetPlayerController(Player(i)) == MAP_CONTROL_USER then
    set DEqDoubleClickTimer[i] = CreateTimer()
    
        if AutomaticallyAddHeroesToTheDEqSystem == TRUE then
        call GroupEnumUnitsOfPlayer(ug, Player(i), function DEqHeroAutoAddFilter)
        endif
    endif

set i = i + 1
exitwhen i > 23
endloop
    
if AutomaticallyAddHeroesToTheSystem == TRUE then
call TriggerRegisterEnterRectSimple( trg_AutoAddNewHeroToDEq, GetWorldBounds() )
call TriggerAddAction( trg_AutoAddNewHeroToDEq, function AutoAddNewHeroToDEqActions )
endif

call TriggerAddAction(trg_OpenDInvAbilityUsed, function InventoryButtonClickedDEq)

call DEqLoadBugProtectionActions()
call DestroyGroup(ug)
endfunction



private function Init takes nothing returns nothing
local integer i = 0
// This tells the Inventory system that the Equipment system is also used
set EquipmentSystemUsed = TRUE

//CONFIGURATION AREA
set DEqEnabledSlots[1] = TRUE
set DEqSlotName[1] = "Head"
set DEqSlotIconPath[1] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotHelmet.blp"
set DEqSlotTopLeftX[1] = 0.06
set DEqSlotTopLeftY[1] = 0.51
set DEqSlotBotRightX[1] = 0.10
set DEqSlotBotRightY[1] = 0.47

set DEqEnabledSlots[2] = TRUE
set DEqSlotName[2] = "Neck"
set DEqSlotIconPath[2] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotNecklace.blp"
set DEqSlotTopLeftX[2] = DEqSlotTopLeftX[1]
set DEqSlotTopLeftY[2] = DEqSlotTopLeftY[1]-0.042
set DEqSlotBotRightX[2] = DEqSlotBotRightX[1]
set DEqSlotBotRightY[2] = DEqSlotBotRightY[1]-0.042

set DEqEnabledSlots[3] = TRUE
set DEqSlotName[3] = "Shoulder"
set DEqSlotIconPath[3] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotPauldrons.blp"
set DEqSlotTopLeftX[3] = DEqSlotTopLeftX[1]
set DEqSlotTopLeftY[3] = DEqSlotTopLeftY[1]-0.084
set DEqSlotBotRightX[3] = DEqSlotBotRightX[1]
set DEqSlotBotRightY[3] = DEqSlotBotRightY[1]-0.084

set DEqEnabledSlots[4] = TRUE
set DEqSlotName[4] = "Back"
set DEqSlotIconPath[4] = "ReplaceableTextures\\CommandButtonsDisabled\\DISPASEquipmentSlotBack.blp"
set DEqSlotTopLeftX[4] = DEqSlotTopLeftX[1]
set DEqSlotTopLeftY[4] = DEqSlotTopLeftY[1]-0.126
set DEqSlotBotRightX[4] = DEqSlotBotRightX[1]
set DEqSlotBotRightY[4] = DEqSlotBotRightY[1]-0.126

set DEqEnabledSlots[5] = TRUE
set DEqSlotName[5] = "Chest"
set DEqSlotIconPath[5] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotChestplate.blp"
set DEqSlotTopLeftX[5] = DEqSlotTopLeftX[1]
set DEqSlotTopLeftY[5] = DEqSlotTopLeftY[1]-0.168
set DEqSlotBotRightX[5] = DEqSlotBotRightX[1]
set DEqSlotBotRightY[5] = DEqSlotBotRightY[1]-0.168

set DEqEnabledSlots[6] = TRUE
set DEqSlotName[6] = "Bracers"
set DEqSlotIconPath[6] = "ReplaceableTextures\\CommandButtonsDisabled\\DISPASEquipmentSlotWrist.blp"
set DEqSlotTopLeftX[6] = DEqSlotTopLeftX[1]
set DEqSlotTopLeftY[6] = DEqSlotTopLeftY[1]-0.210
set DEqSlotBotRightX[6] = DEqSlotBotRightX[1]
set DEqSlotBotRightY[6] = DEqSlotBotRightY[1]-0.210

set DEqEnabledSlots[7] = TRUE
set DEqSlotName[7] = "Gloves"
set DEqSlotIconPath[7] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotGloves.blp"
set DEqSlotTopLeftX[7] = DEqSlotTopLeftX[1]+0.179
set DEqSlotTopLeftY[7] = DEqSlotTopLeftY[1]
set DEqSlotBotRightX[7] = DEqSlotBotRightX[1]+0.179
set DEqSlotBotRightY[7] = DEqSlotBotRightY[1]

set DEqEnabledSlots[8] = TRUE
set DEqSlotName[8] = "Ring"
set DEqSlotIconPath[8] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotRing.blp"
set DEqSlotTopLeftX[8] = DEqSlotTopLeftX[7]
set DEqSlotTopLeftY[8] = DEqSlotTopLeftY[2]
set DEqSlotBotRightX[8] = DEqSlotBotRightX[7]
set DEqSlotBotRightY[8] = DEqSlotBotRightY[2]

set DEqEnabledSlots[9] = TRUE
set DEqSlotName[9] = "Ring"
set DEqSlotIconPath[9] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotRing.blp"
set DEqSlotTopLeftX[9] = DEqSlotTopLeftX[7]
set DEqSlotTopLeftY[9] = DEqSlotTopLeftY[3]
set DEqSlotBotRightX[9] = DEqSlotBotRightX[7]
set DEqSlotBotRightY[9] = DEqSlotBotRightY[3]

set DEqEnabledSlots[10] = TRUE
set DEqSlotName[10] = "Belt"
set DEqSlotIconPath[10] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotBelt.blp"
set DEqSlotTopLeftX[10] = DEqSlotTopLeftX[7]
set DEqSlotTopLeftY[10] = DEqSlotTopLeftY[4]
set DEqSlotBotRightX[10] = DEqSlotBotRightX[7]
set DEqSlotBotRightY[10] = DEqSlotBotRightY[4]

set DEqEnabledSlots[11] = TRUE
set DEqSlotName[11] = "Legs"
set DEqSlotIconPath[11] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotLeggings.blp"
set DEqSlotTopLeftX[11] = DEqSlotTopLeftX[7]
set DEqSlotTopLeftY[11] = DEqSlotTopLeftY[5]
set DEqSlotBotRightX[11] = DEqSlotBotRightX[7]
set DEqSlotBotRightY[11] = DEqSlotBotRightY[5]

set DEqEnabledSlots[12] = TRUE
set DEqSlotName[12] = "Boots"
set DEqSlotIconPath[12] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotBoots.blp"
set DEqSlotTopLeftX[12] = DEqSlotTopLeftX[7]
set DEqSlotTopLeftY[12] = DEqSlotTopLeftY[6]
set DEqSlotBotRightX[12] = DEqSlotBotRightX[7]
set DEqSlotBotRightY[12] = DEqSlotBotRightY[6]


set DEqEnabledSlots[13] = FALSE
/*
set DEqSlotName[13] = ""
set DEqSlotIconPath[13] = "ReplaceableTextures\\PassiveButtons\\.blp"
set DEqSlotTopLeftX[13] = 0
set DEqSlotTopLeftY[13] = 0
set DEqSlotBotRightX[13] = 0
set DEqSlotBotRightY[13] = 0
*/

set DEqEnabledSlots[14] = FALSE
/*
set DEqSlotName[14] = ""
set DEqSlotIconPath[14] = "ReplaceableTextures\\PassiveButtons\\.blp"
set DEqSlotTopLeftX[14] = 0
set DEqSlotTopLeftY[14] = 0
set DEqSlotBotRightX[14] = 0
set DEqSlotBotRightY[14] = 0
*/

set DEqEnabledSlots[15] = FALSE
/*
set DEqSlotName[15] = ""
set DEqSlotIconPath[15] = "ReplaceableTextures\\PassiveButtons\\.blp"
set DEqSlotTopLeftX[15] = 0
set DEqSlotTopLeftY[15] = 0
set DEqSlotBotRightX[15] = 0
set DEqSlotBotRightY[15] = 0
*/

set DEqEnabledSlots[16] = FALSE
/*
set DEqSlotName[16] = ""
set DEqSlotIconPath[16] = "ReplaceableTextures\\PassiveButtons\\.blp"
set DEqSlotTopLeftX[16] = 0
set DEqSlotTopLeftY[16] = 0
set DEqSlotBotRightX[16] = 0
set DEqSlotBotRightY[16] = 0
*/

set DEqEnabledSlots[17] = FALSE
/*
set DEqSlotName[17] = ""
set DEqSlotIconPath[17] = "ReplaceableTextures\\PassiveButtons\\.blp"
set DEqSlotTopLeftX[17] = 0
set DEqSlotTopLeftY[17] = 0
set DEqSlotBotRightX[17] = 0
set DEqSlotBotRightY[17] = 0
*/

set DEqEnabledSlots[18] = FALSE
/*
set DEqSlotName[18] = ""
set DEqSlotIconPath[18] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotTrinket.blp"
set DEqSlotTopLeftX[18] = 0
set DEqSlotTopLeftY[18] = 0
set DEqSlotBotRightX[18] = 0
set DEqSlotBotRightY[18] = 0
*/

//Warning: Slot 19's enable / disable status should always be the same as 20's, unless you rewrite the code about 2h weapons / dual wield
set DEqEnabledSlots[19] = TRUE
set DEqSlotName[19] = "MainHand"
set DEqSlotIconPath[19] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotMainHand.blp"
set DEqSlotTopLeftX[19] = DEqSlotTopLeftX[1]
set DEqSlotTopLeftY[19] = DEqSlotTopLeftY[1]-0.252
set DEqSlotBotRightX[19] = DEqSlotBotRightX[1]
set DEqSlotBotRightY[19] = DEqSlotBotRightY[1]-0.252

//Warning: Slot 19's enable / disable status should always be the same as 20's, unless you rewrite the code about 2h weapons / dual wield
set DEqEnabledSlots[20] = TRUE
set DEqSlotName[20] = "OffHand"
set DEqSlotIconPath[20] = "ReplaceableTextures\\PassiveButtons\\PASEquipmentSlotOffHand.blp"
set DEqSlotTopLeftX[20] = DEqSlotTopLeftX[7]
set DEqSlotTopLeftY[20] = DEqSlotTopLeftY[19]
set DEqSlotBotRightX[20] = DEqSlotBotRightX[7]
set DEqSlotBotRightY[20] = DEqSlotBotRightY[19]
//set Slot20ForbiddenTexture = "UI\\Widgets\\Console\\Human\\human-console-button-back-disabled.blp"

// Important to set this if you decided to create a slot 66 or whatever
set HighestSlotNumber = 20

set DEqHeroIconTopLeftY = DEqBackDropTopLeftY-0.035
set DEqHeroIconBottomRightY = DEqHeroIconTopLeftY - 0.05

//CONFIGURE!
//Stat names are defined here and are associated a serial number, which is the array index
//You may define your own if you wish.
//They need to start from 1.
//Do not leave any gaps (if you define 24 and 26, make sure 25 is also defined)
//You then need to DEqStatTranslator and set up what these stats actually do


set DEqStatNames[1] = "Strength"
set DEqStatNames[2] = "Agility"
set DEqStatNames[3] = "Intelligence"
set DEqStatNames[4] = "Hitpoints"
set DEqStatNames[5] = "Hitpoint regeneration"
set DEqStatNames[6] = "HP Pct Per Sec"
set DisplayAsPercent[6] = TRUE
set DEqStatNames[7] = "Mana"
set DEqStatNames[8] = "Mana regeneration"
set DEqStatNames[9] = "Mana Pct Per Sec"
set DisplayAsPercent[9] = TRUE
set DEqStatNames[10] = "Critical Chance"
set DisplayAsPercent[10] = TRUE
set DEqStatNames[11] = "Critical Damage"
set DisplayAsPercent[11] = TRUE
set DEqStatNames[12] = "Damage"
set DEqStatNames[13] = "Damage Pct"
set DisplayAsPercent[13] = TRUE
set DEqStatNames[14] = "Melee Damage"
set DEqStatNames[15] = "Melee DMG Pct"
set DisplayAsPercent[15] = TRUE
set DEqStatNames[16] = "Ranged Damage"
set DEqStatNames[17] = "Ranged DMG Pct"
set DisplayAsPercent[17] = TRUE
set DEqStatNames[18] = "Cleave Pct"
set DisplayAsPercent[18] = TRUE
set DEqStatNames[19] = "Cleave Damage"
set DEqStatNames[20] = "Attack Speed"
set DisplayAsPercent[20] = TRUE
set DEqStatNames[21] = "Attack Range"
set DEqStatNames[22] = "Lifesteal Pct"
set DisplayAsPercent[22] = TRUE
set DEqStatNames[23] = "Thorns"
set DEqStatNames[24] = "Thorns Pct"
set DisplayAsPercent[24] = TRUE
set DEqStatNames[25] = "Armor"
set DEqStatNames[26] = "Armor Pct"
set DisplayAsPercent[26] = TRUE
set DEqStatNames[27] = "Dodge"
set DisplayAsPercent[27] = TRUE
set DEqStatNames[28] = "Spell Damage Taken Pct"
set DisplayAsPercent[28] = TRUE
set DEqStatNames[29] = "Melee Damage Taken Pct"
set DisplayAsPercent[29] = TRUE
set DEqStatNames[30] = "Pierce Damage Taken Pct"
set DisplayAsPercent[30] = TRUE
set DEqStatNames[31] = "Movement Speed"
set DEqStatNames[32] = "MoveSPD Pct"
set DisplayAsPercent[32] = TRUE
set DEqStatNames[33] = "Sight Range"
set DEqStatNames[34] = "Inventory Space"
set DEqStatNames[35] = "Block Chance"
set DisplayAsPercent[35] = TRUE
set DEqStatNames[36] = "Hit Chance"
set DisplayAsPercent[36] = TRUE
set DEqStatNames[37] = "Spell Power Pct"
set DisplayAsPercent[37] = TRUE
set DEqStatNames[38] = "Spell Power"
set DisplayAsPercent[38] = TRUE
set DEqStatNames[39] = "Healing Power"
set DisplayAsPercent[39] = TRUE

//call BJDebugMsg("before DEqStatsCounter")

loop
exitwhen DEqStatNames[DEqStatsCounter+1] == null
set DEqStatsCounter = DEqStatsCounter + 1
endloop

//call BJDebugMsg("after DEqStatsCounter")

call TriggerRegisterGameEvent(trg_DEqLoadBugProtection, EVENT_GAME_LOADED)
call TriggerAddAction(trg_DEqLoadBugProtection, function DEqLoadBugProtectionActions)
// Certain actions during "Map initialization" do not work properly or cause desyncs, so this is the real init:
call TriggerRegisterTimerEvent( trg_DEqNoDesyncInit, 0.05, false )
call TriggerAddAction(trg_DEqNoDesyncInit, function DEqNoDesyncInitActions)

call BlzLoadTOCFile("UI\\Frames\\framedef\\ui\\escmenutemplates.toc​")
endfunction

endlibrary