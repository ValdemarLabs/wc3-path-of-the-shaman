library SharedDInvLib initializer Init requires DConfigurationArea

globals
// Core
// QUIRK / POSSIBLE ERROR: The items you store in the DInventory will not be destroyed (except for stacking, if stacking is enabled).
// They will actually be made invisible, for the purpose of you being able to refer to them as variables and as trigger events.
// This means that if you use triggers that remove items then nothing bad happens, because this system will just create a new item for you if you drop it from the DInventory.
// However, you might come accross bugs I did not fend against if you keep manipulating ALL items on the map (or specificaly the absolute bottom left corner)
real MapMinX = 0
real MapMinY = 0
integer DInvTotalPlayers = 0
// When adding a new unit to the system this will be the counter that is equal to the EQID if the equipment system is enabled.
// If not, and the DInv paradigm is 1 per Hero, then this is also the BID counter
integer EQIDCounter = 0
Table DInvUnits
integer array DInvMaxSlotModifierForPlayer[25]
integer array ItemTypeExclusionListLengthForPlayer[25]
integer array ItemExclusionListLengthForPlayer[25]
TableArray DInvItemTypeExclusionListForPlayer
TableArray ItemExclusionListForPlayer
Table2DT DInvItemHandleDB
Table3DT DInvUnitHandleDB
TableArray DInventoryDB

// DEquipment and its modules
string array DEqStatNames
//Determine whether to display stat in tooltips as a percent
boolean array DisplayAsPercent
integer DEqStatsCounter = 0
integer HighestSlotNumber = 20
Table3DT DEqItemTypeDefinitionDB
Table3DT DEqTroveDB
integer TroveCounter = 0
Table DEqEnchantDB
Table3DT EQIDDB
Table3DT BIDDB

// Item Rarity
string array NonEqRarityName
string array NonEqRarityColor
string array NonEqRarityOutlineModel
framehandle array DInvSlotOutlineModelFrame[8160]
real array NonEqRarityScale
real array NonEqRarityOSX
real array NonEqRarityOSY
Table DItemRarityDB

// DEq Rarity
string array DEqRarityName
string array DEqRarityColor
string array DEqRarityOutlineModel
real array DEqRarityStatX
real array DEqRarityGoldX
real array DEqRarityScale
real array DEqRarityOSX
real array DEqRarityOSY
integer array DEqRarityR
integer array DEqRarityG
integer array DEqRarityB

// Rarity beams
Table DInvBeam

// Ilvl
real DEqIlvlStatX = 0.0
real = DEqIlvlGoldX = 0.0

// Growth
Table3DT GrowthDB

// Named Items
Table4D NamedItemTypeDB

// Item Sets
Table4D DEqSetDB

// Stash
Table DStash

endglobals



native UnitAlive takes unit id returns boolean



function D100K takes integer i returns boolean
if GetRandomInt(0, 99999) < i then
return TRUE
endif
return FALSE
endfunction



function SUAL takes unit u, integer aid, integer al returns nothing
//SetUnitAbilityLevel
//Sets! Not changes by delta! SETS!
if al < 1 then
call UnitRemoveAbility(u, aid)
else
    if GetUnitAbilityLevel(u, aid) == 0 then
    call UnitAddAbility(u, aid)
    else
    endif
    call SetUnitAbilityLevel(u, aid, al)
endif
set u = null
endfunction



function DUAL takes unit u, integer aid, integer delta returns nothing
//Changes ability level by delta
call SUAL(u, aid, GetUnitAbilityLevel(u, aid)+delta)
set u = null
endfunction



function TroveIdOfItem takes item it returns integer
local integer ihndl = GetHandleId(it)
set it = null
return DInvItemHandleDB[ihndl].integer[5]
endfunction



function AddItemToTroveId takes item it returns nothing
local integer ihndl = GetHandleId(it)
if DInvItemHandleDB[ihndl].integer[5] == 0 then
    set TroveCounter = TroveCounter + 1
    set DInvItemHandleDB[ihndl].integer[5] = TroveCounter
    set DEqTroveDB[TroveCounter][0].integer[7] = ihndl
endif
endfunction



function GetDEqSlotIdOfItem takes item it returns integer
local integer result = DInvItemHandleDB[GetHandleId(it)].integer[4]
set it = null
// Returning 0 means it is not equipped
return result
endfunction



function DEqDUAL takes unit u, integer eqid, integer abid, integer delta, integer abserial returns nothing
local integer cLvl = GetUnitAbilityLevel(u, abid)
local integer nLvl = 0
local integer diff = 0

// 7 = Total ability levels on Equipment
// 8 = System thinks the "natural" ability level of the hero is this much
// 10 = Netto ability levels given (can't bring ability level below 0 or above max ability lvl)

if cLvl != EQIDDB[eqid][8].integer[abserial] + EQIDDB[eqid][10].integer[abserial] then
// ability probably leveled up or was granted or taken away via some other triggers
set EQIDDB[eqid][8].integer[abserial] = cLvl - EQIDDB[eqid][10].integer[abserial]
endif

// Set how many levels DEquipment abilities provide in total.
set EQIDDB[eqid][7].integer[abserial] = EQIDDB[eqid][7].integer[abserial] + delta

call SUAL(u, abid, EQIDDB[eqid][8].integer[abserial] + EQIDDB[eqid][7].integer[abserial])

set nLvl = GetUnitAbilityLevel(u, abid)

set diff = nLvl - cLvl

if diff != 0 then
// Set how many levels DEquipment abilities provide netto.
set EQIDDB[eqid][10].integer[abserial] = EQIDDB[eqid][10].integer[abserial] + diff
endif

set u = null
endfunction



function CanNotEquipMsg takes integer p, string msg returns nothing
if GetLocalPlayer() == Player(p) then
call DisplayTimedTextToPlayer(Player(p),0,0,20,"Can not equip item: "+msg)
// NeedToDo: Sound?
endif
endfunction



function BeamTimerFunc takes nothing returns nothing
local timer t = GetExpiredTimer()
local integer hn = GetHandleId(t)
local effect e = DInvBeam.effect[hn]

call DestroyTimer(t)
call DestroyEffect(e)
set DInvBeam.effect[hn] = null
set t = null
set e = null
endfunction



function CreateTemporaryLootBeam takes real x, real y, real dur, real scale, integer r, integer g, integer b returns nothing
// This places the beam on the ground, not the item
local effect e = AddSpecialEffect("DInv/Chest_Beam.mdx", x, y)
local timer t = CreateTimer()
call BlzSetSpecialEffectColor(e, r, g, b)
call BlzSetSpecialEffectScale(e, scale)

set DInvBeam.effect[GetHandleId(t)] = e
call TimerStart(t, dur, FALSE, function BeamTimerFunc)

set e = null
set t = null
endfunction


/*
function AttachPermanentLootBeam takes widget it, real scale, integer r, integer g, integer b returns nothing
// This places the beam on the item permanently
local effect e = AddSpecialEffectTarget("DInv/Chest_Beam.mdx", it, "origin")
call BlzSetSpecialEffectColor(e, r, g, b)
call BlzSetSpecialEffectScale(e, scale)
endfunction
*/


function SlotFrameId2DItemSlotId takes integer pid, integer slotFrameId returns integer
return (DInvCurrentPage[pid]-1) * ColXRow + slotFrameId
endfunction



function PIDSlotFrame2FrameId takes integer pid, framehandle fr returns integer
local integer loopi = 0
local integer dexter = 340*pid
loop
exitwhen fr == InventorySlotButtonFrame[dexter+loopi]
set loopi = loopi + 1
endloop

set fr = null
// return -1 if frame is not found (e.g. not the player pid's)
if loopi == dexter + 340 then
set loopi = -1
endif
////call BJDebugMsg("PIDSlotFrame2FrameId loopi: "+I2S(loopi))
return loopi
endfunction



function CloseDEqUI takes integer pid returns nothing
//call BJDebugMsg("CloseDEqUI started")
set DEqCurrentSlotIdActive[pid] = 0
set DEqCurrentUnit[pid] = null
set CurrentEQId[pid] = -1
call BlzFrameSetVisible(EquipmentBackDropFrame[pid], FALSE)
endfunction



function GetPIDOfItem takes item it returns integer
local integer ihndl = GetHandleId(it)
local integer result = DInvItemHandleDB[ihndl].integer[0] - 1
//call BJDebugMsg("GetPIDOfItem it = "+GetItemName(it))
//call BJDebugMsg("GetPIDOfItem DInvItemHandleDB[ihndl].integer[0] = "+ I2S(DInvItemHandleDB[ihndl].integer[0]))
//This will always store PID + 1 because this way it can act as a check to see if the item is stored anywhere
//Receiving -1 means the item is not stored in any DInv
set it = null
return result
endfunction



function GetPIDOfIhndl takes integer ihndl returns integer
//This will always store PID + 1 because this way it can act as a check to see if the item is stored anywhere
//Receiving -1 means the item is not stored in any DInv
return DInvItemHandleDB[ihndl].integer[0] - 1
endfunction



function BIDOfIHndl takes integer ihndl returns integer
return DInvItemHandleDB[ihndl].integer[1]
// A return of <1 is not a valid Bag ID
// Outside this function you can check the IsItemStoredInDInv function
endfunction



function BIDOfItem takes item it returns integer
local integer result = DInvItemHandleDB[GetHandleId(it)].integer[1]
// A return of <1 is not a valid Bag ID
// Outside this function you can check the IsItemStoredInDInv function
set it = null
return result
endfunction



function BIDOfUHndl takes integer uhndl returns integer
return DInvUnitHandleDB[uhndl][0].integer[2]
// A return of <1 is not a valid Bag ID
// Outside this function you can check the IsItemStoredInDInv function
endfunction



function BIDOfUnit takes unit u returns integer
local integer result = DInvUnitHandleDB[GetHandleId(u)][0].integer[2]
// A return of <1 is not a valid Bag ID
// NEEDTODO : UNLESSSSSS... paradigm is 1 bag per player, then player(0)'s BID is 0
// Outside this function you can check the IsItemStoredInDInv function
set u = null
return result
endfunction



function EQIDOfUnit takes unit u returns integer
local integer eqid = DInvUnitHandleDB[GetHandleId(u)][0].integer[3]
// A return of <1 is not a valid Equipment ID
// Outside this function you can check the IsItemStoredInDInv function
set u = null
return eqid
endfunction



function EQIDOfUHndl takes integer uhndl returns integer
return DInvUnitHandleDB[uhndl][0].integer[3]
// A return of <1 is not a valid Equipment ID
// Outside this function you can check the IsItemStoredInDInv function
endfunction



function UnitOfEQID takes integer eqid returns unit
return DInvUnits.unit[eqid]
endfunction



function EQID2BID takes integer eqid returns integer
local unit u = DInvUnits.unit[eqid]
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer result = 0

if InventoryParadigm == "1PerPlayer" then
// NEEDTODO: pid or pid+1?????
return pid+1
elseif u == null then
////call BJDebugMsg("EQID2BID u == null")
    // Return -1 means: Could not find it
    return -1
else
////call BJDebugMsg("EQID2BID bid: "+I2S(EQIDDB[eqid][0].integer[2]))        
    set result = DInvUnitHandleDB[GetHandleId(u)][0].integer[2]
    set u = null
    return result
endif
endfunction



function IsItemStoredInDInv takes item it returns boolean
// NEEDTODECIDE: This is kinda redundant because of GetPIDOfItem
if DInvItemHandleDB[GetHandleId(it)].integer[0] == 0 then
set it = null
return FALSE
else
set it = null
return TRUE
endif
endfunction



function GetDInvSlotIdOfItem takes item it returns integer
// Returns -1 if not stored in DInv
local integer result = 0
if DInvItemHandleDB[GetHandleId(it)].integer[0] == 0 then
// Item not stored in DInv
    set it = null
    return -1
else
// Item is stored in DInv
    set result = DInvItemHandleDB[GetHandleId(it)].integer[2]
    set it = null
return result
endif
endfunction



function TroveIdOfIHndl takes integer i returns integer
return DInvItemHandleDB[i].integer[5]
endfunction



function DEqIsItASetItem takes integer iid, integer tid, integer nid returns integer
local integer setID = 0
if tid > 0 then
    set nid = DEqTroveDB[tid][0].integer[8]
    if DEqTroveDB[tid][0].integer[10] > 0 then
    set setID = DEqTroveDB[tid][0].integer[10]
    elseif NamedItemTypeDB[iid][nid][0].integer[1] > 0 then
    set setID = NamedItemTypeDB[iid][nid][0].integer[1]
    endif
elseif DEqItemTypeDefinitionDB[iid][0].integer[4] > 0 then
set setID = DEqItemTypeDefinitionDB[iid][0].integer[4]
endif
// Returns 0 if it is not a set
return setID
endfunction



function DEqIsItemASetItem takes item it returns integer
// You can assign a setID to 1.) Item Types 2.) Named Items 3.) Individual items
// The system only handles 1 set per item. You can not have an item belonging to multiple sets.
// If you are a little funny bunny, and for some reason define a setID for 1. 2. and 3. then the system will check them in this sequence: 3., 2., 1. If it finds a setID, it will not check the next.
// In other words, if you had an item type that you defined as a set item, but for some reason you also made that individual item part of another set, then the individual item setID will be active.
local integer setID = 0
local integer troveID = DInvItemHandleDB[GetHandleId(it)].integer[5]
local integer iid = GetItemTypeId(it)
local integer nid = 0
if troveID > 0 then
    set nid = DEqTroveDB[troveID][0].integer[8]
    if DEqTroveDB[troveID][0].integer[10] > 0 then
    set setID = DEqTroveDB[troveID][0].integer[10]
    elseif NamedItemTypeDB[iid][nid][0].integer[1] > 0 then
    set setID = NamedItemTypeDB[iid][nid][0].integer[1]
    endif
elseif DEqItemTypeDefinitionDB[iid][0].integer[4] > 0 then
set setID = DEqItemTypeDefinitionDB[iid][0].integer[4]
endif
set it = null
// Returns 0 if it is not a set
return setID
endfunction



function DEqGetItemLevelOfItem takes item it returns integer
// Returns the itemlevel of an item in the world
local integer result = DEqTroveDB[DInvItemHandleDB[GetHandleId(it)].integer[5]][0].integer[2]
set it = null
return result
endfunction



function DItemSlotId2SlotFrameId takes integer pid, integer itemSlot returns integer
// NEEDTODO Quirk: is it not accurate if pid is not local player?
// If not on the current page, then return -1
local integer aux = itemSlot - (DInvCurrentPage[pid]-1) * ColXRow
// itemSlot = (DInvCurrentPage[pid]-1) * ColXRow + slotFrameId
// 0 = (DInvCurrentPage[pid]-1) * ColXRow - itemSlot
// - slotFrameId = (DInvCurrentPage[pid]-1) * ColXRow - itemSlot
// slotFrameId = -(DInvCurrentPage[pid]-1) * ColXRow + itemSlot
// slotFrameId = itemSlot - (DInvCurrentPage[pid]-1) * ColXRow

if aux > -1 and aux <  ColXRow then
return aux
else
// If not on the current page, then return -1
return -1
endif
endfunction



function GoToItemHeaven takes item it returns nothing
call SetItemPosition(it, MapMinX, MapMinY)
call SetItemVisible(it, FALSE)
set it = null
endfunction



function DInventoryIsItemStackable takes item it returns boolean
local itemtype IT = GetItemType(it)
//////call BJDebugMsg("DInventoryIsItemStackable fired")
if IT == ITEM_TYPE_CHARGED or IT == ITEM_TYPE_PURCHASABLE or IT == ITEM_TYPE_POWERUP then
// Configure if you want: you can put in more conditions here if you want less or more stuff to be stackable
////call BJDebugMsg("DInventoryIsItemStackable says this is STACKABLE")
    set IT = null
    set it = null
    return TRUE
endif
////call BJDebugMsg("DInventoryIsItemStackable says this is not not not stackymecky")
set IT = null
set it = null
return FALSE
endfunction



function MaxBagCapacityOfBID takes integer pid, integer bid returns integer
if InventoryParadigm == "1PerPlayer" then
////call BJDebugMsg("InventoryCapacity of pid("+I2S(pid)+") hid("+I2S(hid)+"): "+I2S(InventoryCapacityBase + DInvMaxSlotModifierForPlayer[pid]))
return InventoryCapacityBase + DInvMaxSlotModifierForPlayer[pid]
elseif bid < 1 then
return 0
else
////call BJDebugMsg("InventoryCapacity of pid("+I2S(pid)+") hid("+I2S(hid)+"): "+I2S(InventoryCapacityBase + DInvMaxSlotModifierForPlayer[pid] + BIDDB[bid][0].integer[1]))
return InventoryCapacityBase + DInvMaxSlotModifierForPlayer[pid] + BIDDB[bid][0].integer[1]
endif
endfunction



function FirstFreeDInvSlotOfBID takes integer pid, integer bid returns integer
local integer slotId = 0
local integer capacity = MaxBagCapacityOfBID(pid, bid)
if bid < 1 then
// Could not find this unit in the DInventory system's list of heroes, so there is no inventory to check
else
    loop
        if DInventoryDB[bid].item[slotId] == null then
        // Found an empty slot
        return slotId
        endif
    set slotId = slotId + 1
    exitwhen slotId >= capacity
    endloop
endif
return -1
endfunction



function IsItemDEquipment takes item it returns boolean
local boolean result = FALSE
if DEqItemTypeDefinitionDB[GetItemTypeId(it)][0].integer[2] == 1 then
set result = TRUE
endif
set it = null
return result
endfunction



function DEqIsItemId2Handed takes integer iid returns boolean
if DEqItemTypeDefinitionDB[iid][0].integer[1] == 1 then
return TRUE
endif
return FALSE
endfunction



function R2Dec2S takes real r returns string
local string s = R2S(r)
local integer dotI = 0
// Converts reals to 0.12 format. Removes dumb 0s.
loop
exitwhen SubString(s, dotI, dotI+1) == "."
set dotI = dotI + 1
endloop
if SubString(s, dotI, dotI+3) == ".00" then
set s = SubString(s, 0, dotI)
elseif SubString(s, dotI+2, dotI+3) == "0" then
set s = SubString(s, 0, dotI+2)
else
set s = SubString(s, 0, dotI+3)
endif
return s
endfunction



function DEqGetPreviousSetMarginSerial takes integer setID, integer setLvl returns integer
// If you have 4 items from the set equipped, and there is a margin for bonus at 4 items equipped, then the previous lvl will be 4.
local integer i = 1
loop
if DEqSetDB[setID][0][0].integer[i] == 0 or DEqSetDB[setID][0][0].integer[i] > setLvl then
return i-1
endif
set i = i + 1
endloop
return 0
endfunction



function DEqGetPreviousSetMarginLvl takes integer setID, integer setLvl returns integer
// If you have 4 items from the set equipped, and there is a margin for bonus at 4 items equipped, then the previous lvl will be 4.
local integer i = 1
loop
if DEqSetDB[setID][0][0].integer[i] == 0 or DEqSetDB[setID][0][0].integer[i] > setLvl then
return DEqSetDB[setID][0][0].integer[i-1]
endif
set i = i + 1
endloop
return 0
endfunction



function DEqGetNextSetMarginSerial takes integer setID, integer setLvl returns integer
// If you have 4 items from the set equipped, and there is a margin for bonus at 4 items equipped, then the next lvl will be the one after 4 - if there is such.
local integer i = 1
loop
if DEqSetDB[setID][0][0].integer[i] == 0 then
return i-1
elseif DEqSetDB[setID][0][0].integer[i] > setLvl then
return i
endif
set i = i + 1
endloop
return 0
endfunction



function DEqGetNextSetMarginLvl takes integer setID, integer setLvl returns integer
// If you have 4 items from the set equipped, and there is a margin for bonus at 4 items equipped, then the next lvl will be the one after 4 - if there is such.
local integer i = 1
loop
if DEqSetDB[setID][0][0].integer[i] == 0 then
return DEqSetDB[setID][0][0].integer[i-1]
elseif DEqSetDB[setID][0][0].integer[i] > setLvl then
return DEqSetDB[setID][0][0].integer[i]
endif
set i = i + 1
endloop
return 0
endfunction



function DEqGetCurrentSetLvlOfUnit takes integer eqid, integer setID returns integer
return EQIDDB[eqid][9].integer[setID]
endfunction



function DEqGetHighestSetMargin takes integer setID returns integer
return DEqSetDB[setID][0][1].integer[0]
endfunction



function FindUnitDEqAbilitySerial takes integer eqid, integer abid returns integer
local integer i = 1
local integer ttl = EQIDDB[eqid][6].integer[0]

loop
exitwhen i > ttl
if EQIDDB[eqid][6].integer[i] == abid then
return i
endif
set i = i + 1
endloop

//return 9999 if not found
return 9999
endfunction



function FirstStackableItemSlotOfBID takes item it, integer pid, integer bid returns integer
local integer iid = GetItemTypeId(it)
local integer loopi = 0
local integer capacity = MaxBagCapacityOfBID(pid, bid)
if bid < 1 then
// Could not find this unit in the DInventory system's list of heroes, so there is no inventory to check
else
    loop
        if GetItemTypeId(DInventoryDB[bid].item[loopi]) == iid then
        // Found item of same type
            if DInventoryIsItemStackable(DInventoryDB[bid].item[loopi]) == TRUE then
            // Item is stackable
////call BJDebugMsg("FirstStackableItemSlotOfBID returning "+I2S(loopi))
                set it = null
                return loopi
            endif
        endif
    set loopi = loopi + 1
    exitwhen loopi >= capacity
    endloop
endif
set it = null
// returns -1 if bid is not valid
return -1
endfunction



function DeactivateActiveDEqSlotIds takes integer pid returns nothing
call BlzFrameSetVisible(EquipmentSlotButtonModelFrame[DEqCurrentFrameIdActive[pid]], FALSE)
set DEqCurrentSlotIdActive[pid] = -1
set DEqCurrentFrameIdActive[pid] = -1
endfunction



function PIDDEqSlotFrame2FrameId takes integer pid, framehandle fr returns integer
// frame ID and slot ID are 1-20 for equipment
// This does NOT add the +20*pid to the return, you have to add that outside
local integer loopi = 1
local integer dexter = 20*pid
loop
exitwhen fr == EquipmentSlotButtonFrame[dexter+loopi]
set loopi = loopi + 1
endloop
set fr = null
////call BJDebugMsg("This was loopi: "+I2S(loopi))
return loopi
endfunction



function DEqStatNameToStatId takes string s returns integer
local integer i = 1
loop
if s == DEqStatNames[i] then
return i
endif
set i = i + 1
exitwhen i > DEqStatsCounter
endloop
call BJDebugMsg("ERROR: There is no such stat: "+s)
return 0
endfunction



function DEqStatIdToStatName takes integer id returns string
return DEqStatNames[id]
endfunction



function DEqGetUnitStatById takes unit u, integer statId returns real
// Many stats will only return the value in the Equipment system. Because the system has no way of checking them.
local real rresult
local integer eqid = DInvUnitHandleDB[GetHandleId(u)][0].integer[3]
if statId == 1 then
// STR
set rresult =I2R(GetHeroStr(u, TRUE))
set u = null
return rresult

elseif statId == 2 then
// AGI
set rresult = I2R(GetHeroAgi(u, TRUE))
set u = null
return rresult

elseif statId == 3 then
// INT
set rresult = I2R(GetHeroInt(u, TRUE))
set u = null
return rresult

elseif statId == 4 then
// MaxHP
set rresult = GetUnitState(u, UNIT_STATE_MAX_LIFE)
set u = null
return rresult

elseif statId == 5 then
// HPS
set rresult = BlzGetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE)
set u = null
return rresult

elseif statId == 7 then
// MaxMana
set rresult = GetUnitState(u, UNIT_STATE_MAX_MANA)
set u = null
return rresult

elseif statId == 8 then
// MPS
set rresult = BlzGetUnitRealField(u, UNIT_RF_MANA_REGENERATION)
set u = null
return rresult

elseif statId == 31 then
// MoveSpeed
set rresult = GetUnitMoveSpeed(u)
set u = null
return rresult

elseif statId == 21 then
// +Attack Range
// This returns the extra attack range, because the unit can have up to 2 different attacks, with different range, so I will only return the extra attack range from all the equipment
set rresult = EQIDDB[eqid][5].real[21]
set u = null
return rresult

elseif statId == 25 then
// Armor
set rresult = BlzGetUnitArmor(u)
set u = null
return rresult

elseif statId == 33 then
// Sight Range
set rresult = BlzGetUnitRealField(u, ConvertUnitRealField('usir'))
set u = null
return rresult

else
set rresult = EQIDDB[eqid][5].real[statId]
set u = null
return rresult
endif
endfunction



function DEqGetUnitStatByName takes unit u, string statname returns real
local real result = DEqGetUnitStatById(u, DEqStatNameToStatId(statname))
set u = null
return result
endfunction



function UpdateDEqCSheet takes integer pid, unit u, integer uhndl, integer eqid returns nothing
local string s = null

if EQIDDB[eqid][5].real[1] == 0.0 then
else
set s = s + "STR: " + R2Dec2S(EQIDDB[eqid][5].real[1])+ "|n"
endif

if EQIDDB[eqid][5].real[2] == 0.0 then
else
set s = s + "AGI: " + R2Dec2S(EQIDDB[eqid][5].real[2])+ "|n"
endif

if EQIDDB[eqid][5].real[3] == 0.0 then
else
set s = s + "INT: " + R2Dec2S(EQIDDB[eqid][5].real[3])+ "|n"
endif

if EQIDDB[eqid][5].real[4] == 0.0 then
else
set s = s + "HP: " + R2Dec2S(EQIDDB[eqid][5].real[4])+ "|n"
endif

if EQIDDB[eqid][5].real[5] == 0.0 then
else
set s = s + "HPS: " + R2Dec2S(EQIDDB[eqid][5].real[5])+ "|n"
endif

if EQIDDB[eqid][5].real[6] == 0.0 then
else
set s = s + "HPctPS: " + R2Dec2S(EQIDDB[eqid][5].real[6]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[7] == 0.0 then
else
set s = s + "Mana: " + R2Dec2S(EQIDDB[eqid][5].real[7])+ "|n"
endif

if EQIDDB[eqid][5].real[8] == 0.0 then
else
set s = s + "MPS: " + R2Dec2S(EQIDDB[eqid][5].real[8])+ "|n"
endif

if EQIDDB[eqid][5].real[9] == 0.0 then
else
set s = s + "MPctPS: " + R2Dec2S(EQIDDB[eqid][5].real[9]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[10] == 0.0 then
else
set s = s + "Crit: " + R2Dec2S(EQIDDB[eqid][5].real[10]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[11] == 0.0 then
else
set s = s + "Crit DMG: " + R2Dec2S((DefaultCritMultiplier + EQIDDB[eqid][5].real[11])*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[12] == 0.0 then
else
set s = s + "DMG: " + R2Dec2S(EQIDDB[eqid][5].real[12])+ "|n"
endif

if EQIDDB[eqid][5].real[13] == 0.0 then
else
set s = s + "DMG%%: " + R2Dec2S(EQIDDB[eqid][5].real[13]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[14] == 0.0 then
else
set s = s + "Melee DMG: " + R2Dec2S(EQIDDB[eqid][5].real[14])+ "|n"
endif

if EQIDDB[eqid][5].real[15] == 0.0 then
else
set s = s + "Melee DMG%%: " + R2Dec2S(EQIDDB[eqid][5].real[15]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[16] == 0.0 then
else
set s = s + "Ranged DMG: " + R2Dec2S(EQIDDB[eqid][5].real[16])+ "|n"
endif

if EQIDDB[eqid][5].real[17] == 0.0 then
else
set s = s + "Ranged DMG%%: " + R2Dec2S(EQIDDB[eqid][5].real[17]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[18] == 0.0 then
else
set s = s + "Cleave: " + R2Dec2S(EQIDDB[eqid][5].real[18]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[19] == 0.0 then
else
set s = s + "Cleave Area: " + R2Dec2S(150.0+EQIDDB[eqid][5].real[19])+ "|n"
endif

if EQIDDB[eqid][5].real[20] == 0.0 then
else
set s = s + "AtkSpeed: " + R2Dec2S(EQIDDB[eqid][5].real[20]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[21] == 0.0 then
else
set s = s + "AtkRange: " + R2Dec2S(EQIDDB[eqid][5].real[21])+ "|n"
endif

if EQIDDB[eqid][5].real[22] == 0.0 then
else
set s = s + "Lifesteal: " + R2Dec2S(EQIDDB[eqid][5].real[22]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[23] == 0.0 then
else
set s = s + "Thorns: " + R2Dec2S(EQIDDB[eqid][5].real[23])+ "|n"
endif

if EQIDDB[eqid][5].real[24] == 0.0 then
else
set s = s + "Thorns%%: " + R2Dec2S(EQIDDB[eqid][5].real[24]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[25] == 0.0 then
else
set s = s + "Armor: " + R2Dec2S(EQIDDB[eqid][5].real[25])+ "|n"
endif

if EQIDDB[eqid][5].real[26] == 0.0 then
else
set s = s + "Armor%%: " + R2Dec2S(EQIDDB[eqid][5].real[26]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[27] == 0.0 then
else
set s = s + "Evasion: " + R2Dec2S(EQIDDB[eqid][5].real[27]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[28] == 0.0 then
else
    if 1+EQIDDB[eqid][5].real[28] < MagicDMGTakenPctLowCap then
    set s = s + "SpellDMG Taken%%: " + R2Dec2S(MagicDMGTakenPctLowCap) + "%%|n"
    else
    set s = s + "SpellDMG Taken%%: " + R2Dec2S((1.0+EQIDDB[eqid][5].real[28])*100.0) + "%%|n"
    endif
endif

if EQIDDB[eqid][5].real[29] == 0.0 then
else
    if 1+EQIDDB[eqid][5].real[29] < MeleeDMGTakenPctLowCap then
    set s = s + "MeleeDMG Taken%%: " + R2Dec2S(MeleeDMGTakenPctLowCap) + "%%|n"
    else
    set s = s + "MeleeDMG Taken%%: " + R2Dec2S((1.0+EQIDDB[eqid][5].real[29])*100.0) + "%%|n"
    endif
endif

if EQIDDB[eqid][5].real[30] == 0.0 then
else
    if 1+EQIDDB[eqid][5].real[30] < PierceDMGTakenPctLowCap then
    set s = s + "PierceDMG Taken%%: " + R2Dec2S(PierceDMGTakenPctLowCap) + "%%|n"
    else
    set s = s + "PierceDMG Taken%%: " + R2Dec2S((1.0+EQIDDB[eqid][5].real[30])*100.0) + "%%|n"
    endif
endif

if EQIDDB[eqid][5].real[31] == 0.0 then
else
set s = s + "MoveSpeed: " + R2Dec2S(EQIDDB[eqid][5].real[31])+ "|n"
endif

if EQIDDB[eqid][5].real[32] == 0.0 then
else
set s = s + "MoveSpeed%%: " + R2Dec2S(EQIDDB[eqid][5].real[32]*100.0)+ "%%|n"
endif

if EQIDDB[eqid][5].real[33] == 0.0 then
else
set s = s + "Sight Range: " + R2Dec2S(EQIDDB[eqid][5].real[33])+ "|n"
endif

call BlzFrameSetText(DEqCStatSheet[pid], s)

set u = null
endfunction



function GetUnitThatEquipsDItem takes item it returns unit
local integer ihndl = GetHandleId(it)
local integer eqid = DInvItemHandleDB[ihndl].integer[6]

if eqid == 0 then
set it = null
return null
else
set it = null
    if DInvItemHandleDB[ihndl].integer[4] > 0 then
    return DInvUnits.unit[eqid]
    else
    // return null if the item is not EQUIPPED
    return null
    endif
endif
endfunction



function DInvWhichUnitHasItem takes item it returns unit
local integer ihndl = GetHandleId(it)
local integer bid = DInvItemHandleDB[ihndl].integer[1]
local integer eqid = DInvItemHandleDB[ihndl].integer[6]
if bid < 1 then
return GetUnitThatEquipsDItem(it)
else
set it = null
return DInvUnits.unit[eqid]
endif
endfunction



function IsDItemEquipped takes item it returns boolean
local boolean result = FALSE
if DInvItemHandleDB[GetHandleId(it)].integer[4] > 0 then
set result = TRUE
endif
set it = null
return result
endfunction



function GetItemBaseGoldCost takes item it returns integer
local integer iid = GetItemTypeId(it)
local integer g = DEqItemTypeDefinitionDB[iid][0].integer[3]
set it = null
return g
endfunction



function GetItemGoldCostMultiplicative takes item it returns integer
local integer iid = GetItemTypeId(it)
local integer ihndl = GetHandleId(it)
local real g = I2R(DEqItemTypeDefinitionDB[iid][0].integer[3])
local integer tid = DInvItemHandleDB[ihndl].integer[5]
local integer nid = 0
local integer rid = 0
local integer sid = DEqIsItemASetItem(it)
local integer ilvl = 0
local real gx = 0

if sid > 0 then
set gx = DEqSetDB[sid][0][1].real[1]
    if gx == 0.0 then
    else
    set g = g * gx
    endif
endif

if tid > 0 then
set nid = DEqTroveDB[tid][0].integer[8]
set rid = DEqTroveDB[tid][0].integer[3]
set ilvl = DEqTroveDB[tid][0].integer[2]
//call BJDebugMsg("nid "+I2S(nid))
    if nid > 0 then
    set gx = NamedItemTypeDB[iid][nid][0].real[2]
        if gx == 0.0 then
        else
        set g = g * gx
        endif
    endif
//call BJDebugMsg("tid "+I2S(tid))
    set gx = DEqTroveDB[tid][0].real[9]
        if gx == 0.0 then
        else
        set g = g * gx
        endif
//call BJDebugMsg("rid "+I2S(rid))
    set gx = DEqRarityGoldX[rid]
        if gx == 0.0 then
        else
        set g = g * gx
        endif
//call BJDebugMsg("ilvl "+I2S(ilvl))
    set gx = DEqIlvlGoldX*ilvl+1
        if gx == 1.0 then
        else
        set g = g * gx
        endif
endif

set it = null
return R2I(g)
endfunction



function GetItemGoldCostAdditive takes item it returns integer
local integer iid = GetItemTypeId(it)
local integer ihndl = GetHandleId(it)
local real g = I2R(DEqItemTypeDefinitionDB[iid][0].integer[3])
local integer tid = DInvItemHandleDB[ihndl].integer[5]
local integer nid = 0
local integer rid = 0
local integer sid = DEqIsItemASetItem(it)
local integer ilvl = 0
local real gx = 0.0
local real ga = 1.0

if sid > 0 then
set gx = DEqSetDB[sid][0][1].real[1]
    if gx == 0.0 then
    else
    set ga = ga + gx
    endif
endif

if tid > 0 then
set nid = DEqTroveDB[tid][0].integer[8]
set rid = DEqTroveDB[tid][0].integer[3]
set ilvl = DEqTroveDB[tid][0].integer[2]
//call BJDebugMsg("nid "+I2S(nid))
    if nid > 0 then
    set gx = NamedItemTypeDB[iid][nid][0].real[2]
        if gx == 0.0 then
        else
        set ga = ga + gx
        endif
    endif
//call BJDebugMsg("tid "+I2S(tid))
    set gx = DEqTroveDB[tid][0].real[9]
        if gx == 0.0 then
        else
        set ga = ga + gx
        endif
//call BJDebugMsg("rid "+I2S(rid))
    set gx = DEqRarityGoldX[rid]
        if gx == 0.0 then
        else
        set ga = ga + gx
        endif
//call BJDebugMsg("ilvl "+I2S(ilvl))
    set gx = DEqIlvlGoldX*ilvl
        if gx == 0.0 then
        else
        set ga = ga + gx
        endif
endif

set it = null
return R2I(g*ga)
endfunction



function GetItemGoldCost takes item it returns integer
local integer i = 0
if MultiplicativeItemGoldCost == TRUE then
set i = GetItemGoldCostMultiplicative(it)
elseif AdditiveItemGoldCost == TRUE then
set i = GetItemGoldCostAdditive(it)
else
set i = DEqItemTypeDefinitionDB[GetHandleId(it)][0].integer[3]
endif
set it = null
return i
endfunction



function GenerateDEqTooltip takes integer iid, item it, framehandle ttfr, integer frind returns nothing
local integer i = 0
local integer j = 0
local integer k = 0
local string s = null
local string sgranted = null
local string sabgranted = null
local string sreq = null
local string sreqcl = null
local string sreqab = null
local string sreqstats = null
local string sforbcl = null
local string sforbab = null
local string sset = null
local real amount = 0
local integer ihndl = GetHandleId(it)
local integer tid = DInvItemHandleDB[ihndl].integer[5]
local integer nid = 0
local integer rid = 0
local integer ilvl = 0
local Table tabl = Table.create()
local integer array ia
local integer statid = 0
local integer pid = DInvItemHandleDB[ihndl].integer[0] - 1
local unit u = DInvCurrentUnit[pid]
local integer uhndl = GetHandleId(u)
local integer auxi = 0
local integer g = 0
local integer sid = 0
local integer sequipped = 0
local string utt = BlzGetItemExtendedTooltip(it)
local integer eqid = DInvUnitHandleDB[uhndl][0].integer[3]
//call BJDebugMsg("GenerateDEqTooltip ihndl: "+ I2S(ihndl))
//call BJDebugMsg("GenerateDEqTooltip pid: "+ I2S(pid))
//call BJDebugMsg("DInvItemHandleDB[ihndl].integer[0] "+ I2S(DInvItemHandleDB[ihndl].integer[0]))
//call BJDebugMsg("Current item: "+ GetItemName(it))
//call BJDebugMsg("Current unit: "+ GetUnitName(u))
//call BJDebugMsg("Current unit player 0: "+ GetUnitName(DInvCurrentUnit[0]))
//call BJDebugMsg("tid = DInvItemHandleDB[ihndl].integer[5] "+ I2S(tid))

if tid > 0 then
set nid = DEqTroveDB[tid][0].integer[8]
set rid = DEqTroveDB[tid][0].integer[3]
set ilvl = DEqTroveDB[tid][0].integer[2]
endif

if it == null then
// item is null
call BlzFrameSetText(ttfr, null)
    if frind < 0 then
    call BlzFrameSetVisible(DEqTooltipGoldIconFrame[-frind], false)
    else
    // NEEDTODO: This does not work
    call BlzFrameSetVisible(InventoryTooltipGoldIconFrame[frind], false)
    endif

else
set sid = DEqIsItASetItem(iid, tid, nid)
// Item exists

    if rid > 0 then
        if DEqRarityColor[rid] == null then
        else
        set s = DEqRarityColor[rid] + GetItemName(it)+ "|r|n|n"
        endif
    endif

if s == null then
set s = GetItemName(it)+"|n|n"
endif

set g = GetItemGoldCost(it)
if frind < 0 then
// in equipment slot
call BlzFrameSetVisible(DEqTooltipGoldIconFrame[-frind], TRUE)
set s = s + "     " + I2S(g) + "|n"
else
    /*if g == 0 then
    call BlzFrameSetVisible(InventoryTooltipGoldIconFrame[frind], false)
    else
    */
    call BlzFrameSetVisible(InventoryTooltipGoldIconFrame[frind], TRUE)
    set s = s + "     " + I2S(g) + "|n"
    //endif
endif

set i = 1
loop
    if DEqItemTypeDefinitionDB[iid][9].integer[i] == 0 then
    else
    set s = s + " " + DEqSlotName[i]
    endif
set i = i + 1
exitwhen i > HighestSlotNumber
endloop

if rid > 0 then
set s = s + " "+DEqRarityName[rid]
endif

if ilvl > 0 then
set s = s + " ilvl"+I2S(ilvl)
endif

if DEqItemTypeDefinitionDB[iid][0].integer[1] > 0 then
// item is 2 handed weapon
set s = s + " 2handed"
//call BJDebugMsg("this is a 2h weapon")
endif
set s = s + "|n"

set i = 1 
loop
//call BJDebugMsg("looping")
    if DEqItemTypeDefinitionDB[iid][10].real[i] == 0.0 and NamedItemTypeDB[iid][nid][10].real[i] == 0.0 then
//call BJDebugMsg("no stat here")
    // no stat here
    else
    // stat found
//call BJDebugMsg("stat found")
    set amount = DEqItemTypeDefinitionDB[iid][10].real[i]

        // Named
        if nid > 0 then
        set amount = amount + NamedItemTypeDB[iid][nid][10].real[i]
        endif
        // Rarity
        if rid > 0 then
        set amount = amount * DEqRarityStatX[rid]
        endif
        // ilvl
        if ilvl > 1 then
        set amount = amount * (1+(ilvl-1)*DEqIlvlStatX)
        endif

        if DisplayAsPercent[i] == TRUE then
        // Stat display has to be multiplied by 100, add percent
        set sgranted = sgranted + "|n" + DEqStatNames[i] + " " + R2Dec2S(amount*100)+"%%"
        //set sgranted = sgranted + DEqStatNames[i] + " " + R2Dec2S(amount*100)+"%%|n"
        else
        set sgranted = sgranted + "|n" + DEqStatNames[i] + " " + R2Dec2S(amount)
        //set sgranted = sgranted + DEqStatNames[i] + " " + R2Dec2S(amount)+"|n"
        //set sgranted = sgranted + DEqStatIdToStatName(i) + " " + R2S(DEqItemTypeDefinitionDB[iid][10].real[i])+"|n"
        endif
    endif
set i = i + 1
exitwhen i > DEqStatsCounter
endloop
//call BJDebugMsg("BB after stats")

// Abilities granted from itemtypedef
set i = 1
set statid = 1
loop
exitwhen DEqItemTypeDefinitionDB[iid][7].integer[statid] == 0
set tabl.integer[DEqItemTypeDefinitionDB[iid][7].integer[statid]] = DEqItemTypeDefinitionDB[iid][11].integer[statid]
set ia[i] = DEqItemTypeDefinitionDB[iid][7].integer[statid]
set i = i + 1
set statid = statid + 1
endloop

// from Named items
if nid > 0 then
set statid = 1        
loop
exitwhen NamedItemTypeDB[iid][nid][7].integer[statid] == 0
set i = 1
    loop
    exitwhen ia[i] == 0 or ia[i] == NamedItemTypeDB[iid][nid][7].integer[statid]
    set i = i + 1
    endloop
set tabl.integer[NamedItemTypeDB[iid][nid][7].integer[statid]] = tabl.integer[NamedItemTypeDB[iid][nid][7].integer[statid]] + NamedItemTypeDB[iid][nid][11].integer[statid]
set ia[i] = NamedItemTypeDB[iid][nid][7].integer[statid]
set statid = statid + 1
endloop
endif

set i = 1
loop
exitwhen ia[i] == 0
set auxi = FindUnitDEqAbilitySerial(uhndl, ia[i])
set amount = I2R(tabl.integer[ia[i]])
// from Rarity
if rid > 0 then
set amount = amount * DEqRarityStatX[rid]
endif
// from Ilvl
if ilvl > 1 then
set amount = amount * (1+(ilvl-1)*DEqIlvlStatX)
endif
set sabgranted = sabgranted + "|n" + GetObjectName(ia[i]) + " " + I2S(R2I(amount))
//set sabgranted = sabgranted + GetObjectName(ia[i]) + " " + I2S(R2I(amount)) + "|n"
set i = i +1
endloop

// Required level
set i = DEqItemTypeDefinitionDB[iid][0].integer[0]
if nid > 0 then
    set auxi = NamedItemTypeDB[iid][nid][0].integer[0]
    if auxi > 0 then
    set i = auxi
    endif
endif
if MakeILvlTheMinimumRequiredLvl == TRUE then
// DEqGetItemLevelOfItem(it)
    set auxi = DEqTroveDB[tid][0].integer[2]
    if auxi > 0 then
    set i = auxi
    endif
endif
set auxi = DEqTroveDB[tid][0].integer[0]
if auxi > 0 then
    set i = auxi
endif
if i == 0 then
// no req level
else
set sreq = "Hero lvl "+I2S(i) +"|n"
endif

if DEqItemTypeDefinitionDB[iid][1].integer[1] == 0 then
// no class required
else
// some class required
set sreqcl = "Class: " + GetObjectName(DEqItemTypeDefinitionDB[iid][1].integer[1])
set i = 1
loop
set i = i + 1
    if DEqItemTypeDefinitionDB[iid][1].integer[i] == 0 then
    else
    set sreqcl = sreqcl + ", " + GetObjectName(DEqItemTypeDefinitionDB[iid][1].integer[i])
    endif
exitwhen DEqItemTypeDefinitionDB[iid][1].integer[i] == 0
endloop
set sreqcl = sreqcl + "|n"
endif

//Ability requirements
if DEqItemTypeDefinitionDB[iid][3].integer[1] == 0 then
// No ability requirements, do nothing
else
// some ability required

    if DEqItemTypeDefinitionDB[iid][4].integer[1] > 0 then
    set sreqab = "Ability: " + GetObjectName(DEqItemTypeDefinitionDB[iid][3].integer[1])
    set sreqab = sreqab + " " + I2S(DEqItemTypeDefinitionDB[iid][4].integer[1])

    set i = 1

    loop
    set i = i + 1
    exitwhen DEqItemTypeDefinitionDB[iid][3].integer[i] == 0
    set sreqab = sreqab + ", " + GetObjectName(DEqItemTypeDefinitionDB[iid][3].integer[i])
        if DEqItemTypeDefinitionDB[iid][4].integer[i] == 0 then
        else
        set sreqab = sreqab + " " + I2S(DEqItemTypeDefinitionDB[iid][4].integer[i])
        endif
    endloop
    set sreqab = sreqab + "|n"
    endif
endif

// stat requirements
set i = 1
loop
    if DEqItemTypeDefinitionDB[iid][8].real[i] > 0.0 then
    set sreqstats = sreqstats + DEqStatNames[i] + " " + R2Dec2S(DEqItemTypeDefinitionDB[iid][8].real[i])+ " "
    endif
set i = i + 1
exitwhen i > DEqStatsCounter
endloop
if sreqstats == null then
else
set sreqstats = sreqstats //+ "|n"
endif

//call BJDebugMsg(" after requirements")

//forbidden classes
set i = 1
if sreqcl == null then
    if DEqItemTypeDefinitionDB[iid][2].integer[1] == 0 then
    else
    set sforbcl = GetObjectName(DEqItemTypeDefinitionDB[iid][2].integer[1])

    loop
    set i = i + 1
    exitwhen DEqItemTypeDefinitionDB[iid][2].integer[i] == 0
    set sforbcl = sforbcl + ", " + GetObjectName(DEqItemTypeDefinitionDB[iid][2].integer[i])
    endloop
    endif
else
// Don't do forbidden classes if there are required classes, because all that is not required in the case of class
endif

if DEqItemTypeDefinitionDB[iid][5].integer[1] == 0 then
// no forbidden ability found
set i = 1
else
set sforbab = GetObjectName(DEqItemTypeDefinitionDB[iid][5].integer[1])
    if DEqItemTypeDefinitionDB[iid][6].integer[1] > 1 then
    set sforbab = sforbab + GetObjectName(DEqItemTypeDefinitionDB[iid][6].integer[1])
    endif
loop
set i = i + 1
exitwhen DEqItemTypeDefinitionDB[iid][5].integer[i] == 0
set sforbab = sforbab + ", " + GetObjectName(DEqItemTypeDefinitionDB[iid][5].integer[i])
    if DEqItemTypeDefinitionDB[iid][6].integer[i] > 1 then
    set sforbab = sforbab + GetObjectName(DEqItemTypeDefinitionDB[iid][6].integer[i])
    endif
endloop
endif
//call BJDebugMsg(" after forbiddens")

set sreq = sreq + sreqcl + sreqab + sreqstats
    if sreq == null then
    // do nothing
    else
    set sreq = "|n|nRequires:|n"+sreq //+"|n"
    endif

set sforbcl = sforbcl + sforbab
    if sforbcl == null then
    // do nothing
    else
    set sforbcl = "|nForbidden:|n" + sforbcl //+ "|n"
    endif

// Sets
if sid > 0 then
    // How many already equipped
    set auxi = EQIDDB[eqid][9].integer[sid]
//call BJDebugMsg("uhndl értéke: " + I2S(uhndl))    
//call BJDebugMsg("Auxi értéke: " + I2S(auxi))
    // Highest set margin
    set g = DEqSetDB[sid][0][1].integer[0]
    set sset = "|n|n|c0000FF00" + "Set: " + DEqSetDB[sid][0][0].string[0] + " (" + I2S(auxi) + "/"+ I2S(g) + ")|r"
    set i = 1
    loop
    // loop through thresholds
    set k = DEqSetDB[sid][0][0].integer[i]
    exitwhen k == 0
    if k > auxi then
    // current loop threshold is bigger than equipped number of items from set
    set sset = sset + "|n|cff00781e   " + I2S(k) + " pieces:"
    else
    set sset = sset + "|n|c0096FF96   " + I2S(k) + " pieces:"
    endif
        // j will be our looping statid
        set j = 1
        loop
        exitwhen j > DEqStatsCounter
            if DEqSetDB[sid][1][k].real[j] == 0.0 then
            // stat not granted by item
            else
            set amount = DEqSetDB[sid][1][k].real[j]
                if DisplayAsPercent[j] == TRUE then
                // Stat display has to be multiplied by 100, add percent
                set sset = sset + "|n" + DEqStatNames[j] + " " + R2Dec2S(amount*100)+"%%"
                //set sset = sset + DEqStatNames[j] + " " + R2Dec2S(amount*100)+"%%|n"
                else
                set sset = sset +"|n"+ DEqStatNames[j] + " " + R2Dec2S(amount)
                //set sset = sset + DEqStatNames[j] + " " + R2Dec2S(amount)+"|n"
                endif
            endif
        set j = j+1
        endloop
        
        // now loop for abilities
        set j = 1
        loop
        exitwhen DEqSetDB[sid][2][k].integer[j] == 0
        set sset = sset + "|n" + GetObjectName(DEqSetDB[sid][2][k].integer[j]) + " " + I2S(DEqSetDB[sid][3][k].integer[j])
        //set sset = sset + GetObjectName(DEqSetDB[sid][2][k].integer[j]) + " " + I2S(DEqSetDB[sid][3][k].integer[j]) + "|n"
        set j = j + 1
        endloop
    set sset = sset + "|r"
    set i = i +1
    endloop
endif

//call BJDebugMsg("Tooltips should be generated")
//    if sset == null then
        if utt == "" then
//    call BJDebugMsg("utt == üres")
        call BlzFrameSetText(ttfr, s + sgranted + sabgranted + sreq + sforbcl + sset)
        else
//    call BJDebugMsg("utt az valami")
        call BlzFrameSetText(ttfr, s + sgranted + sabgranted + sreq + sforbcl + sset + "|n|n" + utt)
        endif
  //  else
    //call BlzFrameSetText(ttfr, s + sgranted + sabgranted + sreq + sforbcl + sset + utt)
    //endif
endif
set ttfr = null
set it = null
call tabl.destroy()
set u = null
endfunction



function DInvSlotDataIntoFrame takes integer pid, integer bid, integer slotId, integer slotFrameId returns nothing
local integer frind = pid*340+slotFrameId
local item it = DInventoryDB[bid].item[slotId]
local integer iid = GetItemTypeId(it)
local integer i = 0
local string s = null
local integer ihndl = GetHandleId(it)
local integer tid = DInvItemHandleDB[ihndl].integer[5]
local integer g = 0
// NEEDTODO : localplayer if block before this
////call BJDebugMsg("DInvSlotDataIntoFrame bid = "+I2S(bid))
////call BJDebugMsg("DInvSlotDataIntoFrame frind = "+I2S(frind))
//call BJDebugMsg("DInvSlotDataIntoFrame it = "+GetItemName(it))
// WARNING Localplayer stuff should happen outside this function
//call BlzFrameSetEnable(InventorySlotButtonFrame[frind], TRUE)
//call BlzFrameSetAlpha(InventoryTooltipBackdropFrame[frind], 255)

// Hide rarity outline
if DInvRarityModuleUsed == TRUE or DEqRarityModuleUsed == TRUE then
    if GetPlayerId(GetLocalPlayer()) == pid then
    call BlzFrameSetVisible(DInvSlotOutlineModelFrame[frind], FALSE)
    endif
endif

if it == null then
// no item lives here, set empty texture
call BlzFrameSetTexture(InventorySlotButtonFrame[frind], InventorySlotEmptyTexture, 0, TRUE)
call BlzFrameSetTexture(InventorySlotButtonIconFrame[frind], InventorySlotEmptyTexture, 0, TRUE)
call BlzFrameSetVisible(InventorySlotStacksFrame[frind], FALSE)
call BlzFrameSetText(InventoryTooltipText[frind], "")
else
// there is an item here
//call BJDebugMsg(BlzGetItemIconPath(it))
//call BJDebugMsg(I2S(DEqItemTypeDefinitionDB[iid][0].integer[1]))
    // Check for rarity
    if DInvRarityModuleUsed == TRUE then
        set i = DItemRarityDB.integer[iid]
        if i > 0 then
            if GetPlayerId(GetLocalPlayer()) == pid then
                if NonEqRarityOutlineModel[i] == null then
                else
                call BlzFrameSetModel(DInvSlotOutlineModelFrame[frind], NonEqRarityOutlineModel[i], 0)
                call BlzFrameSetVisible(DInvSlotOutlineModelFrame[frind], TRUE)
                call BlzFrameSetPoint(DInvSlotOutlineModelFrame[frind], FRAMEPOINT_BOTTOMLEFT, InventorySlotButtonFrame[frind], FRAMEPOINT_BOTTOMLEFT, NonEqRarityOSX[i], NonEqRarityOSY[i])
                call BlzFrameSetPoint(DInvSlotOutlineModelFrame[frind], FRAMEPOINT_TOPRIGHT, InventorySlotButtonFrame[frind], FRAMEPOINT_BOTTOMLEFT, NonEqRarityOSX[i]+0.0001, NonEqRarityOSY[i]+0.0001)
                call BlzFrameSetScale(DInvSlotOutlineModelFrame[frind], NonEqRarityScale[i])
                endif
            endif
        endif
    endif

// IsItemDEquipment function: DEqItemTypeDefinitionDB[iid][0].integer[2] == 1
    if EquipmentSystemUsed == TRUE and DEqItemTypeDefinitionDB[iid][0].integer[2] == 1 then
        if DEqRarityModuleUsed == TRUE  then
        set i = DEqTroveDB[tid][0].integer[3]
        
            if i < 1 then
                if DEqRarityDefaultRarity == -1 then
                else
                set i = DEqRarityDefaultRarity
                endif
            endif
            
            if i > 0 then
                if GetPlayerId(GetLocalPlayer()) == pid then
                    if DEqRarityOutlineModel[i] == null then
                    call BlzFrameSetVisible(DInvSlotOutlineModelFrame[frind], FALSE)
                    else
                    call BlzFrameSetModel(DInvSlotOutlineModelFrame[frind], DEqRarityOutlineModel[i], 0)
                    call BlzFrameSetVisible(DInvSlotOutlineModelFrame[frind], TRUE)
                    // Offset coordinates of the sprites, because not all those gifs have the same dimensions
                    call BlzFrameSetPoint(DInvSlotOutlineModelFrame[frind], FRAMEPOINT_BOTTOMLEFT, InventorySlotButtonFrame[frind], FRAMEPOINT_BOTTOMLEFT, DEqRarityOSX[i], DEqRarityOSY[i])
                    call BlzFrameSetPoint(DInvSlotOutlineModelFrame[frind], FRAMEPOINT_TOPRIGHT, InventorySlotButtonFrame[frind], FRAMEPOINT_BOTTOMLEFT, DEqRarityOSX[i]+0.0001, DEqRarityOSY[i]+0.0001)
                    call BlzFrameSetScale(DInvSlotOutlineModelFrame[frind], DEqRarityScale[i])
                    endif
                endif
            endif
        endif

        if DEqTooltipAutoReadReq == TRUE then
        call GenerateDEqTooltip(iid, it, InventoryTooltipText[frind], frind)
        else
        // Tooltips are not auto generated
//call BJDebugMsg("Tooltips are not auto generated")
        set s = GetItemName(it)+"|n|n|n" + BlzGetItemExtendedTooltip(it)
        call BlzFrameSetText(InventoryTooltipText[frind], s)
        endif

    else
    // Equipment system is not used or item is not equipment

        if DInvRarityModuleUsed == TRUE then
        set i = DItemRarityDB.integer[iid]
            if i > 0 then
            set s = NonEqRarityColor[i] + GetItemName(it) + "|r|n|n"
            else
                if DInvRarityDefaultRarity == -1 then
                set s = GetItemName(it)+"|n|n"
                else
                set i = DInvRarityDefaultRarity
                set s = NonEqRarityColor[i] + GetItemName(it) + "|r|n|n"
                endif
            endif
        else
        set s = GetItemName(it)+"|n|n"
        endif
    set g = GetItemGoldCost(it)
    set s = s + "     " + I2S(g) 
    set i = GetItemCharges(it)
    if i > 1 then
    set s = s + " (" + I2S(g*GetItemCharges(it)) + ")|n" + BlzGetItemExtendedTooltip(it)
    else
    set s = s + "|n" + BlzGetItemExtendedTooltip(it)
    endif
    
    call BlzFrameSetText(InventoryTooltipText[frind], s)
    endif

    call BlzFrameSetTexture(InventorySlotButtonIconFrame[frind], BlzGetItemIconPath(it), 0, TRUE)
    if DInventoryIsItemStackable(it) == TRUE or GetItemCharges(it) > 0 then
////call BJDebugMsg("DInvSlotDataIntoFrame thinks this is stackable")
////call BJDebugMsg("DInvSlotDataIntoFrame thinks it charges: "+I2S(GetItemCharges(it)))
////call BJDebugMsg("DInvSlotDataIntoFrame thinks frind: "+I2S(frind))
    call BlzFrameSetText(InventorySlotStacksFrame[frind], I2S(GetItemCharges(it)))
    call BlzFrameSetVisible(InventorySlotStacksFrame[frind], TRUE)
////call BJDebugMsg("DInvSlotDataIntoFrame refreshed InventorySlotStacksFrame[frind]")
    else
    // item not stackable
////call BJDebugMsg("NOT stackable, yours truly - DInvSlotDataIntoFrame")
    call BlzFrameSetVisible(InventorySlotStacksFrame[frind], FALSE)
    endif
endif
set it = null
endfunction



function DEqSlotDataIntoFrame takes integer pid, integer uhndl, integer slotId returns nothing
// Local player stuff has to be done outside
local integer eqid = DInvUnitHandleDB[uhndl][0].integer[3]
local integer frameId = pid*20 + slotId
// frame is the same as slotId + pid*20
local item it = EQIDDB[eqid][4].item[slotId]
local integer iid = GetItemTypeId(it)

//call BJDebugMsg("DEqSlotDataIntoFrame = " + GetItemName(it))

if it == null then
// empty deq slot
call BlzFrameSetAlpha(DEqTooltipBackdropFrame[frameId], 0)
call BlzFrameSetTexture(EquipmentSlotButtonIconFrame[frameId], DEqSlotIconPath[slotId], 0, TRUE)
call BlzFrameSetText(DEqTooltipText[frameId], " ")

    if slotId == 19 then
    // extra assurance for 2handed wpns
        if EQIDDB[eqid][4].item[20] == null then
        call BlzFrameSetTexture(EquipmentSlotButtonIconFrame[frameId+1], DEqSlotIconPath[20], 0, TRUE)
        // set tooltip
        call GenerateDEqTooltip(0, null, DEqTooltipText[frameId+1], -frameId)
        endif
    endif

else
// not empty
// set icon
call BlzFrameSetTexture(EquipmentSlotButtonIconFrame[frameId], BlzGetItemIconPath(it), 0, TRUE)

    if slotId == 19 then
    // if it's slot19 2handed, set 2hdisabled icon for slot20
        if DEqItemTypeDefinitionDB[GetItemTypeId(it)][0].integer[1] > 0 and GetUnitAbilityLevel(DInvUnitHandleDB[uhndl][0].unit[0], 'DQTG') == 0 then
        // item is 2handed and there is no titan's grip
        call BlzFrameSetTexture(EquipmentSlotButtonIconFrame[frameId+1], Slot20ForbiddenTexture, 0, TRUE)
        // set tooltip
        call GenerateDEqTooltip(0, null, DEqTooltipText[frameId+1], -frameId)
        endif
    endif

// set tooltip
call GenerateDEqTooltip(iid, it, DEqTooltipText[frameId], -frameId)
endif

if slotId == 20 then
// if it's slot20 offhand, possibly it unequipped a slot19 2handed
    if EQIDDB[eqid][4].item[19] == null then
    // no item in 19
    // set tooltip
    call GenerateDEqTooltip(GetItemTypeId(EQIDDB[eqid][4].item[19]), EQIDDB[eqid][4].item[19], DEqTooltipText[frameId-1], -frameId)
    endif
endif

// NEEDTODO decide: set rarity visuals?

set it = null
endfunction


    
function DEqDBIntoFrames takes integer pid, integer eqid returns nothing
local integer loopFrI = pid * 20 + 1
local integer slotId = 1
//local integer frLimit = loopFrI + HighestSlotNumber - 1
local integer uhndl = GetHandleId(DInvUnits.unit[eqid])

////call BJDebugMsg("DEqDBIntoFrames eqid: " + I2S(eqid))

if pid == GetPlayerId(GetLocalPlayer()) then   
    if eqid < 1 then
    // not a valid equipment id
    else
        if eqid == CurrentEQId[pid] then
        loop
////call BJDebugMsg("DEqDBIntoFrames loopFrI: " + I2S(loopFrI))
        call DEqSlotDataIntoFrame(pid, uhndl, slotId)
        set loopFrI = loopFrI + 1
        set slotId = slotId + 1
        exitwhen slotId > HighestSlotNumber
        endloop
        endif
    endif
endif
endfunction



function MaxDInvCapacityOfUnit takes unit u returns integer
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer bid = BIDOfUnit(u)
set u = null
return MaxBagCapacityOfBID(pid, bid)
endfunction



function MaxPageCountOfPIDBID takes integer pid, integer bid returns integer
local real auxr = I2R(MaxBagCapacityOfBID(pid, bid)) / I2R(ColXRow)
local integer auxi = R2I(auxr)
////call BJDebugMsg("auxr = "+R2S(auxr))
////call BJDebugMsg("auxi = "+I2S(auxi))
if auxr > auxi then
    set auxi = auxi + 1
endif
////call BJDebugMsg("Page Count of pid("+I2S(pid)+") hid("+I2S(hid)+"): "+I2S(auxi))
return auxi
endfunction



function FirstFreeDInvSlotOfUnit takes unit u returns integer
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer bid = BIDOfUnit(u)
////call BJDebugMsg("FAKK JÚ "+I2S(bid))
set u = null
return FirstFreeDInvSlotOfBID(pid, bid)
endfunction



function FirstFreeDInvSlotOfPlayer takes integer pid returns integer
return FirstFreeDInvSlotOfBID(pid, pid)
endfunction



function FirstStackableItemSlotOfUnit takes item it, unit u returns integer
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer bid = BIDOfUnit(u)
local integer result = FirstStackableItemSlotOfBID(it, pid, bid)
set u = null
set it = null
return result
endfunction



function StoreDInvSlotIdOfItem takes item it, integer slotId returns nothing
set DInvItemHandleDB[GetHandleId(it)].integer[2] = slotId
set it = null
endfunction



function DInvUnitHasItem takes unit u, item it returns boolean
local integer bid = BIDOfUnit(u)
if bid == BIDOfItem(it) then
set u = null
set it = null
return TRUE
else
set u = null
set it = null
return FALSE
endif
endfunction



// This will bruteforce search for an item in a bag, in case for some reason the SlotID was not stored in DInvItemHandleDB[ItemHandleID].integer[2]
function GetDInvSlotIdOfItemOfBID takes integer pid, integer bid, item it returns integer
local integer slotId = 0
local integer capacity = MaxBagCapacityOfBID(pid, bid)
loop
    if DInventoryDB[bid].item[slotId] == it then
    set it = null
    return slotId
    endif
set slotId = slotId + 1
exitwhen slotId >= capacity
endloop
set it = null
return -1
endfunction



// This will bruteforce search for an item in a bag, in case for some reason the SlotID was not stored in DInvItemHandleDB[ItemHandleID].integer[2]
function GetDInvSlotIdOfItemOfUnit takes unit u, item it returns integer
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer bid = BIDOfUnit(u)
local integer result = GetDInvSlotIdOfItemOfBID(pid, bid, it)
set it = null
return result
endfunction



function DeleteBIDSlotIdItemFromDInventory takes integer bid, integer slotId returns nothing
local integer ihndl = GetHandleId(DInventoryDB[bid].item[slotId])
// NUCLEAR : this does not unequip the item, and might screw things up if the item is deleted from the inv while equipped
// Warning: this will essentially leave the item invisible in the bottom left of the map.
// NEEDTODO: decide if it should also delete the item from  the world
// This will also not adjust the icons of currently open DInventories
set DInvItemHandleDB[ihndl].integer[0] = 0
set DInvItemHandleDB[ihndl].integer[1] = 0
set DInvItemHandleDB[ihndl].integer[2] = 0
set DInvItemHandleDB[ihndl].integer[3] = 0
set DInvItemHandleDB[ihndl].integer[4] = 0
//Trove ID should not get deleted. I suppose. set DInvItemHandleDB[ihndl].integer[4] = 0 
set DInvItemHandleDB[ihndl].integer[6] = 0
// NEEDTODO: Remove further data from future systems and modules?
call DInventoryDB[bid].item.remove(slotId)
//call BJDebugMsg("Delete-FromDInventory Nulling slotId "+I2S(slotId))
endfunction



function DeleteItemFromDInventory takes item it returns nothing
// Warning: this will essentially leave the item invisible in the bottom left of the screen.
// NEEDTODO: decide if it should:
// This will also not adjust the icons of currently open DInventories
local integer bid = BIDOfItem(it)
local integer slotId = GetDInvSlotIdOfItem(it)
call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
set it = null
endfunction



function IsVanillaInventoryFull takes unit u returns boolean
local integer vanillaInvCap = UnitInventorySize(u)-1
//Subtracting 1, because slots are numbered 0-5
local integer loopi = 0
////call BJDebugMsg("vanillaInvCap = "+I2S(vanillaInvCap))
loop
    if UnitItemInSlot(u, loopi) == null then
////call BJDebugMsg("inv slot "+I2S(loopi)+" = "+GetItemName(UnitItemInSlot(u, loopi)))
    set u = null
    return FALSE
    endif
    exitwhen loopi >= vanillaInvCap
set loopi = loopi + 1
endloop
set u = null
////call BJDebugMsg("Vannilla inv is full")
return TRUE
endfunction



function DInvUnitHasItemType takes unit u, integer iid returns boolean
local integer slotId = 0
local integer maxCapacity = MaxDInvCapacityOfUnit(u)
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer bid = BIDOfUnit(u)
local item it
if bid == -1 then
// do nothing the unit has no inventory, why did you call this function? hmm, don't make me get the belt!!
else
    loop
    set it = DInventoryDB[bid].item[slotId]
        if GetItemTypeId(it) == iid then
        set it = null
        set u = null
        return TRUE
        endif
    set slotId = slotId + 1
    exitwhen slotId > maxCapacity
    endloop
endif
set it = null
set u = null
return FALSE
endfunction



function DInvUnitGetItemSlotOfFirstItemByItemType takes unit u, integer iid returns integer
local integer slotId = 0
local integer maxCapacity = MaxDInvCapacityOfUnit(u)
local integer bid = BIDOfUnit(u)
local item it
if bid == -1 then
// do nothing the unit has no inventory, why did you call this function? hmm, don't make me get the belt!!
else
    loop
    set it = DInventoryDB[bid].item[slotId]
        if GetItemTypeId(it) == iid then
        set it = null
        set u = null
        return slotId
        endif
    set slotId = slotId + 1
    exitwhen slotId > maxCapacity
    endloop
endif
set it = null
set u = null
return -1
endfunction



function DInvUnitCountItemsOfItemType takes unit u, integer iid returns integer
local integer slotId = 0
local integer maxCapacity = MaxDInvCapacityOfUnit(u)
local integer bid = BIDOfUnit(u)
local item it = null
local integer counter = 0
if bid == -1 then
// do nothing the unit has no inventory, why did you call this function? hmm, don't make me get the belt!!
else
    loop
    set it = DInventoryDB[bid].item[slotId]
        if GetItemTypeId(it) == iid then
        set counter = counter + 1
        endif
    set slotId = slotId + 1
    exitwhen slotId > maxCapacity
    endloop
endif
set it = null
set u = null
return counter
endfunction



function FromItemHeavenToGround takes item it, real x, real y returns nothing
call SetItemVisible(it, TRUE)
call SetItemPosition(it, x, y)
set it = null
endfunction



function FromItemHeavenToVanillaInventory takes item it, unit u returns nothing
if IsVanillaInventoryFull(u) == TRUE then
call FromItemHeavenToGround(it, GetUnitX(u), GetUnitY(u))
else
call SetItemVisible(it, TRUE)
call UnitAddItem(u, it)
endif
set it = null
set u = null
endfunction



function IsBIDInventoryFull takes integer pid, integer bid returns boolean
local integer slotId = 0
local integer capacity = MaxBagCapacityOfBID(pid, bid)
if bid < 0 then
// Could not find this unit in the DInventory system's list of heroes, so there is no inventory to check
else
    loop
        if DInventoryDB[bid].item[slotId] == null then
        // Found an empty slot
        return FALSE
        endif
    set slotId = slotId + 1
    exitwhen slotId >= capacity
    endloop
endif
return TRUE
endfunction



function IsUnitDInventoryFull takes unit u returns boolean
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer bid = BIDOfUnit(u)
local boolean result = IsBIDInventoryFull(pid, bid)
set u = null
return result
endfunction



function CountBIDDInventoryFreeSpace takes integer pid, integer bid returns integer
local integer slotId = 0
local integer capacity = MaxBagCapacityOfBID(pid, bid)
local integer countI = 0
if bid < 0 then
// Could not find this unit in the DInventory system's list of heroes, so there is no inventory to check
else
    loop
        if DInventoryDB[bid].item[slotId] == null then
        // Found an empty slot
        set countI = countI + 1
        endif
    set slotId = slotId + 1
    exitwhen slotId >= capacity
    endloop
endif
return countI
endfunction



function CountUnitDInventoryFreeSpace takes unit u returns integer
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer bid = BIDOfUnit(u)
set u = null
return CountBIDDInventoryFreeSpace(pid, bid)
endfunction



function DInvDeltaAdditionalSlotsForPlayer takes integer pid, integer d returns nothing
// You can use this function to increase or decrease the bag size of a player
set DInvMaxSlotModifierForPlayer[pid] = DInvMaxSlotModifierForPlayer[pid] + d
endfunction



function DInvDeltaAdditionalSlotsForBID takes integer bid, integer d returns nothing
local integer aux = BIDDB[bid][0].integer[1]
// You can use this function to increase or decrease the bag size of an individual hero if the DInventory paradigm is 1 Inventory Per Hero
if bid < 0 then
// Not a proper bag
else
// This does not drop overflown items
set BIDDB[bid][0].integer[1] = aux + d
endif
endfunction



function HowManyDInvSlotsOnPage takes integer pid, integer bid, integer page returns integer
local integer MaxPageCount = MaxPageCountOfPIDBID(pid, bid)
if DInvCurrentPage[pid] < MaxPageCount then
return ColXRow
else
return MaxBagCapacityOfBID(pid, bid) - (MaxPageCount-1) * ColXRow
endif
endfunction



function UnitDInventoryDBIntoDInventoryFrames takes integer pid, integer bid returns nothing
local integer loopFrI = 0
local integer slotId = (DInvCurrentPage[pid]-1) * ColXRow
local integer frLimit = ColXRow
local integer slLimit = HowManyDInvSlotsOnPage(pid, bid, DInvCurrentPage[pid])
local integer maxPage = MaxPageCountOfPIDBID(pid, bid)

if maxPage < DInvCurrentPage[pid] then
set DInvCurrentPage[pid] = maxPage 
elseif DInvCurrentPage[pid] < 1 then
set DInvCurrentPage[pid] = 1
endif

if pid == GetPlayerId(GetLocalPlayer()) then
    if bid < 0 then
    // not a valid hero id
    else
        if bid == CurrentBID[pid] then
        loop
        call DInvSlotDataIntoFrame(pid, bid, slotId, loopFrI)
        set slotId = slotId + 1
        set loopFrI = loopFrI + 1
        // equal, because slot numbering starts with 0 rather than 1
        exitwhen loopFrI >= slLimit
        endloop

        loop
        exitwhen loopFrI >= frLimit
        //call BlzFrameSetAlpha(InventoryTooltipBackdropFrame[loopFrI], 100)
        //call BlzFrameSetVisible(InventoryTooltipBackdropFrame[loopFrI], FALSE)
        call BlzFrameSetTexture(InventorySlotButtonFrame[loopFrI], InventorySlotForbiddenTexture, 0, TRUE)
        call BlzFrameSetTexture(InventorySlotButtonIconFrame[loopFrI], InventorySlotForbiddenTexture, 0, TRUE)
        call BlzFrameSetVisible(InventorySlotStacksFrame[loopFrI], FALSE)
        call BlzFrameSetVisible(DInvSlotOutlineModelFrame[loopFrI], FALSE)
        call BlzFrameSetText(InventoryTooltipText[loopFrI], " ")
        set loopFrI = loopFrI + 1
        endloop
        endif
    endif
endif
endfunction



function DInvDeltaAdditionalSlotsForUnit takes unit u, integer d returns nothing
// You can use this function to increase or decrease the bag size of an individual hero if the DInventory paradigm is 1 Inventory Per Hero
local integer bid = BIDOfUnit(u)
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer cap = MaxBagCapacityOfBID(pid, bid)
local integer slotId = 0
local integer limit = (MaxPageCountOfPIDBID(pid, bid) - 1) * ColXRow
local boolean bagFull = FALSE
local integer firstFreeSlot = 0
//call BJDebugMsg("DInvDeltaAdditionalSlotsForUnit called")
// You can use this function to increase or decrease the bag size of an individual hero if the DInventory paradigm is 1 Inventory Per Hero
if bid < 0 then
// Not a proper bag
else
// NEEDTODO: egy algoritmus, ami megnézi, hogy ha negatív a delta, akkor az inventoryn kívül ragadt itemeket berakja az első üres slotba, vagy ha nincs, akkor kidobja a vanilla inventoryba (a lockot előtte rátenni?)
    if d < 0 then
    //call BJDebugMsg("d < 0")
    set slotId = cap + d
    loop
        if slotId > -1 then
            if DInventoryDB[bid].item[slotId] == null then
            else
                if bagFull == FALSE then
                    loop 
                    exitwhen DInventoryDB[bid].item[firstFreeSlot] == null or firstFreeSlot > cap
                    set firstFreeSlot = firstFreeSlot + 1
                    endloop
                    
                    if firstFreeSlot > cap then
                    set bagFull = TRUE
                    endif
                endif
                
                if bagFull == TRUE then
                    if IsVanillaInventoryFull(u) == TRUE then
                    call FromItemHeavenToGround(DInventoryDB[bid].item[slotId], GetUnitX(u), GetUnitY(u))
                    call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
                    else
                    set DInvItemHandleDB[GetHandleId(DInventoryDB[bid].item[slotId])].integer[3] = 1
                    call FromItemHeavenToVanillaInventory(DInventoryDB[bid].item[slotId], u)
                    call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
                    endif
                else
                // move item to first free slot
                set DInventoryDB[bid].item[firstFreeSlot] = DInventoryDB[bid].item[slotId]
                call DInventoryDB[bid].item.remove(slotId)
                endif
            endif
        endif
    set slotId = slotId + 1
    exitwhen slotId > cap
    endloop
    endif
set BIDDB[bid][0].integer[1] = BIDDB[bid][0].integer[1] + d
    if d != 0 then
    // redraw UI if page was open and slots were taken away
        if DInvCurrentUnit[pid] == u then
        call UnitDInventoryDBIntoDInventoryFrames(pid, bid)
        endif
    endif
endif
set u = null
endfunction



function RemoveDEqStatsOfItemFromUnit takes integer pid, integer eqid, integer slotId, item it, unit u returns nothing
local integer statid = 1
local integer iid = GetItemTypeId(it)
local integer ihndl = GetHandleId(it)
local integer uhndl = GetHandleId(u)
local integer auxi = 0
local real auxr = 0
local real amount = 0
local integer abid = 0
local integer uablev = 0
local ability a = null
local integer tid = DInvItemHandleDB[ihndl].integer[5]
local integer nid = 0
local integer rid = 0
local integer ilvl = 0
local Table tabl = Table.create()
local integer i = 0
local integer array ia

if tid > 0 then
set nid = DEqTroveDB[tid][0].integer[8]
set rid = DEqTroveDB[tid][0].integer[3]
set ilvl = DEqTroveDB[tid][0].integer[2]
endif

loop
// From ItemType definition
set amount = DEqItemTypeDefinitionDB[iid][10].real[statid]

// Named
if nid > 0 then
set amount = amount + NamedItemTypeDB[iid][nid][10].real[statid]
endif
// Rarity
if rid > 0 then
set amount = amount * DEqRarityStatX[rid]
endif
if ilvl > 1 then
set amount = amount * (1+(ilvl-1)*DEqIlvlStatX)
endif
    if amount == 0 then
    //do nothing
    else
        if statid == 1 then
        // STR
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call SetHeroStr(u, GetHeroStr(u, FALSE)-auxi, TRUE)
        elseif statid == 2 then
        // AGI
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call SetHeroAgi(u, GetHeroAgi(u, FALSE)-auxi, TRUE)
        elseif statid == 3 then
        // INT
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call SetHeroInt(u, GetHeroInt(u, FALSE)-auxi, TRUE)
        elseif statid == 4 then
        // HP
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call BlzSetUnitMaxHP(u, R2I(GetUnitState(u, UNIT_STATE_MAX_LIFE)-auxi))
        elseif statid == 5 then
        // HPS
        call BlzSetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE, BlzGetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE) - amount)
        elseif statid == 6 then
        // HP Percent Per Sec
            if EQIDDB[eqid][5].real[6] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQLR')
            else
                if GetUnitAbilityLevel(u, 'DQLR') < 1 then
                call UnitAddAbility(u, 'DQLR')
                endif
            set a = BlzGetUnitAbility(u, 'DQLR')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Oar1'), 0, EQIDDB[eqid][5].real[6] - amount)
            call IncUnitAbilityLevel(u, 'DQLR')
            call DecUnitAbilityLevel(u, 'DQLR')
            endif
        elseif statid == 7 then
        // Mana
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call BlzSetUnitMaxMana(u, R2I(GetUnitState(u, UNIT_STATE_MAX_MANA)-auxi))
        elseif statid == 8 then
        // MPS
        call BlzSetUnitRealField(u, UNIT_RF_MANA_REGENERATION,  BlzGetUnitRealField(u, UNIT_RF_MANA_REGENERATION) - amount)
        elseif statid == 9 then
        // Mana Percent Per Sec
            if EQIDDB[eqid][5].real[9] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQMR')
            else
                if GetUnitAbilityLevel(u, 'DQMR') < 1 then
                call UnitAddAbility(u, 'DQMR')
                endif
            set a = BlzGetUnitAbility(u, 'DQMR')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Arm1'), 0, EQIDDB[eqid][5].real[9] - amount)
            call IncUnitAbilityLevel(u, 'DQMR')
            call DecUnitAbilityLevel(u, 'DQMR')
            endif
        elseif statid == 12 then
        // Damage
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call BlzSetUnitBaseDamage(u, BlzGetUnitBaseDamage(u, 0)-auxi, 0)
        call BlzSetUnitBaseDamage(u, BlzGetUnitBaseDamage(u, 1)-auxi, 1)
        elseif statid == 13 then
        // DMG Pct - using both a melee and a ranged Trueshot Aura in order to reduce the number of abilities needed and aura buffs displayed
                // Melee DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTM')
            else
                if GetUnitAbilityLevel(u, 'DQTM') < 1 then
                call UnitAddAbility(u, 'DQTM')
                call BlzUnitDisableAbility(u, 'DQTM', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTM')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] - amount)
            call IncUnitAbilityLevel(u, 'DQTM')
            call DecUnitAbilityLevel(u, 'DQTM')
            endif
            // Ranged DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTS')
            else
                if GetUnitAbilityLevel(u, 'DQTS') < 1 then
                call UnitAddAbility(u, 'DQTS')
                call BlzUnitDisableAbility(u, 'DQTS', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTS')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] - amount)
            call IncUnitAbilityLevel(u, 'DQTS')
            call DecUnitAbilityLevel(u, 'DQTS')
            endif
        elseif statid == 31 then
        // Movement Speed
            if GetUnitAbilityLevel(u, 'DQMS') < 1 then
            call UnitAddAbility(u, 'DQMS')
            endif
        set a = BlzGetUnitAbility(u, 'DQMS')
        call BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_MOVEMENT_SPEED_BONUS, 0, R2I(EQIDDB[eqid][5].real[31] - amount))
        call IncUnitAbilityLevel(u, 'DQMS')
        call DecUnitAbilityLevel(u, 'DQMS')
        elseif statid == 20 then
        // IAS
            if GetUnitAbilityLevel(u, 'DQAS') < 1 then
            call UnitAddAbility(u, 'DQAS')
            endif
        set a = BlzGetUnitAbility(u, 'DQAS')
        call BlzSetAbilityRealLevelField(a, ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1, 0, EQIDDB[eqid][5].real[20] - amount)
        call IncUnitAbilityLevel(u, 'DQAS')
        call DecUnitAbilityLevel(u, 'DQAS')
        elseif statid == 21 then
        // Attack Range
        call BlzSetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 0, BlzGetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 0) - amount)
        call BlzSetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 1, BlzGetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 1) - amount)
        elseif statid == 25 then
        // Armor
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)-(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]))
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)+(EQIDDB[eqid][5].real[25]-amount)*(1.0+EQIDDB[eqid][5].real[26]))
        elseif statid == 33 then
        // Sight Range
        call BlzSetUnitRealField(u, ConvertUnitRealField('usir'), BlzGetUnitRealField(u, ConvertUnitRealField('usir')) - amount)
        elseif statid == 27 then
        // Evasion
            if GetUnitAbilityLevel(u, 'DQEV') < 1 then
            call UnitAddAbility(u, 'DQEV')
            call BlzUnitDisableAbility(u, 'DQEV', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEV')
            if EvasionMaxCap == -9999.0 then 
            // There is no evasion max cap
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EQIDDB[eqid][5].real[27] - amount)
            else
                if EQIDDB[eqid][5].real[27] - amount > EvasionMaxCap then
                call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EvasionMaxCap)
                else
                call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EQIDDB[eqid][5].real[27] - amount)
                endif
            endif
            call IncUnitAbilityLevel(u, 'DQEV')
            call DecUnitAbilityLevel(u, 'DQEV')
        elseif statid == 22 then
        // Lifesteal Percent
            if EQIDDB[eqid][5].real[22] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQLS')
            else
                if GetUnitAbilityLevel(u, 'DQLS') < 1 then
                call UnitAddAbility(u, 'DQLS')
                endif
            set a = BlzGetUnitAbility(u, 'DQLS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_LIFE_STOLEN_PER_ATTACK, 0, EQIDDB[eqid][5].real[22] - amount)
            call IncUnitAbilityLevel(u, 'DQLS')
            call DecUnitAbilityLevel(u, 'DQLS')
            endif
        elseif statid == 23 then
        // Thorns flat
            if EQIDDB[eqid][5].real[23] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTF')
            else
                if GetUnitAbilityLevel(u, 'DQTF') < 1 then
                call UnitAddAbility(u, 'DQTF')
                call BlzUnitDisableAbility(u, 'DQTF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Eah1'), 0, EQIDDB[eqid][5].real[23] - amount)
            call IncUnitAbilityLevel(u, 'DQTF')
            call DecUnitAbilityLevel(u, 'DQTF')            
            endif
        elseif statid == 28 then
        // SpellDMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQEG') < 1 then
            call UnitAddAbility(u, 'DQEG')
            call BlzUnitDisableAbility(u, 'DQEG', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEG')
            if 1+EQIDDB[eqid][5].real[28] - amount < MagicDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5, 0, MagicDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5, 0, 1.0 + EQIDDB[eqid][5].real[28] - amount)       
            endif
        elseif statid == 32 then
        // Movement Speed Percent
            if EQIDDB[eqid][5].real[32] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQHM')
            else
                if GetUnitAbilityLevel(u, 'DQHM') < 1 then
                call UnitAddAbility(u, 'DQHM')
                endif
            set a = BlzGetUnitAbility(u, 'DQHM')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MOVEMENT_SPEED_INCREASE_PERCENT_UAU1, 0, EQIDDB[eqid][5].real[32] - amount)       
            call BlzUnitDisableAbility(u, 'DQHM', TRUE, TRUE)
            call UnitRemoveAbility(u, 'BDQ0')
            call BlzUnitDisableAbility(u, 'DQHM', FALSE, TRUE)
            call BlzUnitDisableAbility(u, 'BDQ0', FALSE, TRUE)
            endif
        elseif statid == 15 then
        // Melee DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTM')
            else
                if GetUnitAbilityLevel(u, 'DQTM') < 1 then
                call UnitAddAbility(u, 'DQTM')
                call BlzUnitDisableAbility(u, 'DQTM', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTM')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] - amount)
            call IncUnitAbilityLevel(u, 'DQTM')
            call DecUnitAbilityLevel(u, 'DQTM')
            endif
        elseif statid == 17 then
        // Ranged DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTS')
            else
                if GetUnitAbilityLevel(u, 'DQTS') < 1 then
                call UnitAddAbility(u, 'DQTS')
                call BlzUnitDisableAbility(u, 'DQTS', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTS')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] - amount)
            call IncUnitAbilityLevel(u, 'DQTS')
            call DecUnitAbilityLevel(u, 'DQTS')
            endif
        elseif statid == 26 then
        // Armor Percent
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)-(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]))
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)+(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]-amount))
            elseif statid == 14 then
        // Melee DMG Flat
            if EQIDDB[eqid][5].real[14] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQMF')
            else
                if GetUnitAbilityLevel(u, 'DQMF') < 1 then
                call UnitAddAbility(u, 'DQMF')
                call BlzUnitDisableAbility(u, 'DQMF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQMF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[14] - amount)
            call IncUnitAbilityLevel(u, 'DQMF')
            call DecUnitAbilityLevel(u, 'DQMF')
            endif
        elseif statid == 16 then
        // Ranged DMG Flat
            if EQIDDB[eqid][5].real[16] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQRF')
            else
                if GetUnitAbilityLevel(u, 'DQRF') < 1 then
                call UnitAddAbility(u, 'DQRF')
                call BlzUnitDisableAbility(u, 'DQRF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQRF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[16] - amount)
            call IncUnitAbilityLevel(u, 'DQRF')
            call DecUnitAbilityLevel(u, 'DQRF')
            endif
        elseif statid == 24 then
        // Thorns Pct
            if EQIDDB[eqid][5].real[24] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQSC')
            else
                if GetUnitAbilityLevel(u, 'DQSC') < 1 then
                call UnitAddAbility(u, 'DQSC')
                call BlzUnitDisableAbility(u, 'DQSC', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQSC')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts1'), 0, EQIDDB[eqid][5].real[24] - amount)
            endif
        elseif statid == 29 then
        // Melee DMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQSC') < 1 then
            call UnitAddAbility(u, 'DQSC')
            call BlzUnitDisableAbility(u, 'DQSC', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQSC')
            if 1+EQIDDB[eqid][5].real[29] - amount < MeleeDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts2'), 0, MeleeDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts2'), 0, 1.0 + EQIDDB[eqid][5].real[29] - amount)       
            endif
        elseif statid == 30 then
        // Pierce DMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQEG') < 1 then
            call UnitAddAbility(u, 'DQEG')
            call BlzUnitDisableAbility(u, 'DQEG', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEG')
            if 1+EQIDDB[eqid][5].real[30] - amount < PierceDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1, 0, PierceDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1, 0, 1.0 + EQIDDB[eqid][5].real[30] - amount)       
            endif
                elseif statid == 10 then
        //Crit Chance
            if GetUnitAbilityLevel(u, 'DQCS') < 1 then
            call UnitAddAbility(u, 'DQCS')
            call BlzUnitDisableAbility(u, 'DQCS', FALSE, TRUE)
            set a = BlzGetUnitAbility(u, 'DQCS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2, 0,  DefaultCritMultiplier + EQIDDB[eqid][5].real[11])
            endif
        set a = BlzGetUnitAbility(u, 'DQCS')
        call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ocr1'), 0, EQIDDB[eqid][5].real[10] - amount)
        elseif statid == 11 then
        //Crit DMG
            if GetUnitAbilityLevel(u, 'DQCS') < 1 then
            else
            set a = BlzGetUnitAbility(u, 'DQCS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2, 0,  DefaultCritMultiplier + EQIDDB[eqid][5].real[11] - amount)
            endif
        elseif statid == 18 then
        //Cleave Pct
            if GetUnitAbilityLevel(u, 'DQCL') < 1 then
            call UnitAddAbility(u, 'DQCL')
            call BlzUnitDisableAbility(u, 'DQCL', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQCL')
        call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DISTRIBUTED_DAMAGE_FACTOR_NCA1, 0, EQIDDB[eqid][5].real[18] - amount)
        elseif statid == 19 then
        //Cleave Area
            if GetUnitAbilityLevel(u, 'DQCL') < 1 then
            call UnitAddAbility(u, 'DQCL')
            call BlzUnitDisableAbility(u, 'DQCL', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQCL')
        call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('aare'), 0, CleaveBaseArea + EQIDDB[eqid][5].real[19] - amount)
        elseif statid == 34 then
        // Inventory Space
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call DInvDeltaAdditionalSlotsForUnit(u, -auxi)
        endif

    set EQIDDB[eqid][5].real[statid] = EQIDDB[eqid][5].real[statid] - amount

    endif
set statid = statid +1
exitwhen statid > DEqStatsCounter
endloop

set i = 1
set statid = 1
loop
exitwhen DEqItemTypeDefinitionDB[iid][7].integer[statid] == 0
set tabl.integer[DEqItemTypeDefinitionDB[iid][7].integer[statid]] = DEqItemTypeDefinitionDB[iid][11].integer[statid]
set ia[i] = DEqItemTypeDefinitionDB[iid][7].integer[statid]
set i = i + 1
set statid = statid + 1
endloop

if nid > 0 then
set statid = 1
loop
exitwhen NamedItemTypeDB[iid][nid][7].integer[statid] == 0

set i = 1
    loop
    exitwhen ia[i] == 0 or ia[i] == NamedItemTypeDB[iid][nid][7].integer[statid]
    set i = i + 1
    endloop

set tabl.integer[NamedItemTypeDB[iid][nid][7].integer[statid]] = tabl.integer[NamedItemTypeDB[iid][nid][7].integer[statid]] + NamedItemTypeDB[iid][nid][11].integer[statid]
set ia[i] = NamedItemTypeDB[iid][nid][7].integer[statid]
set statid = statid + 1
endloop
endif

set i = 1
loop
exitwhen ia[i] == 0

set auxi = FindUnitDEqAbilitySerial(uhndl, ia[i])
set amount = I2R(tabl.integer[ia[i]])

// Rarity
if rid > 0 then
set amount = amount * DEqRarityStatX[rid]
endif
if ilvl > 1 then
set amount = amount * (1+(ilvl-1)*DEqIlvlStatX)
endif

call DEqDUAL(u, uhndl, ia[i], R2I(-amount), i)

set i = i +1
endloop

set a = null
set it = null
set u = null
call tabl.destroy()
endfunction



function AddDEqStatsOfItemToUnit takes integer pid, integer eqid, integer slotId, item it, unit u returns nothing
local integer statid = 1
local integer iid = GetItemTypeId(it)
local integer ihndl = GetHandleId(it)
local integer uhndl = GetHandleId(u)
local integer auxi = 0
local real auxr = 0
local real amount = 0
local integer uablvl = 0
local ability a = null
local integer tid = DInvItemHandleDB[ihndl].integer[5]
local integer nid = 0 
local integer rid = 0
local integer ilvl = 0
local Table tabl = Table.create()
local integer i = 0
local integer array ia

//call BJDebugMsg("AddStat 1")

if tid > 0 then
set nid = DEqTroveDB[tid][0].integer[8]
set rid = DEqTroveDB[tid][0].integer[3]
set ilvl = DEqTroveDB[tid][0].integer[2]
endif

loop
// From ItemType definition
set amount = DEqItemTypeDefinitionDB[iid][10].real[statid]

// Named
if nid > 0 then
set amount = amount + NamedItemTypeDB[iid][nid][10].real[statid]
endif
// Rarity
if rid > 0 then
set amount = amount * DEqRarityStatX[rid]
endif
if ilvl > 1 then
set amount = amount * (1+(ilvl-1)*DEqIlvlStatX)
endif
    if amount == 0 then
    //do nothing
    else
        if statid == 1 then
        // STR
                // total stats of this type given by items for this unit
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call SetHeroStr(u, GetHeroStr(u, FALSE)+auxi, TRUE)
        elseif statid == 2 then
        // AGI
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call SetHeroAgi(u, GetHeroAgi(u, FALSE)+auxi, TRUE)
        elseif statid == 3 then
        // INT
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call SetHeroInt(u, GetHeroInt(u, FALSE)+auxi, TRUE)
        elseif statid == 4 then
        // HP
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call BlzSetUnitMaxHP(u, R2I(GetUnitState(u, UNIT_STATE_MAX_LIFE)+auxi))
        elseif statid == 5 then
        // HPS
        call BlzSetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE,  BlzGetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE) + amount)
        elseif statid == 6 then
        // HP Percent Per Sec
            if EQIDDB[eqid][5].real[6] + amount == 0.00 then
            call UnitRemoveAbility(u, 'DQLR')
            else
                if GetUnitAbilityLevel(u, 'DQLR') < 1 then
                call UnitAddAbility(u, 'DQLR')
                endif
            set a = BlzGetUnitAbility(u, 'DQLR')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Oar1'), 0, EQIDDB[eqid][5].real[6] + amount)
            call IncUnitAbilityLevel(u, 'DQLR')
            call DecUnitAbilityLevel(u, 'DQLR')
            endif
        elseif statid == 7 then
        // Mana
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call BlzSetUnitMaxMana(u, R2I(GetUnitState(u, UNIT_STATE_MAX_MANA)+auxi))
        elseif statid == 8 then
        // MPS
        call BlzSetUnitRealField(u, UNIT_RF_MANA_REGENERATION,  BlzGetUnitRealField(u, UNIT_RF_MANA_REGENERATION) + amount)
        elseif statid == 9 then
        // Mana Percent Per Sec
            if EQIDDB[eqid][5].real[9] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQMR')
            else
                if GetUnitAbilityLevel(u, 'DQMR') < 1 then
                call UnitAddAbility(u, 'DQMR')
                endif
            set a = BlzGetUnitAbility(u, 'DQMR')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Arm1'), 0, EQIDDB[eqid][5].real[9] + amount)
            call IncUnitAbilityLevel(u, 'DQMR')
            call DecUnitAbilityLevel(u, 'DQMR')
            endif
        elseif statid == 12 then
        // Damage
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call BlzSetUnitBaseDamage(u, BlzGetUnitBaseDamage(u, 0)+auxi, 0)
        call BlzSetUnitBaseDamage(u, BlzGetUnitBaseDamage(u, 1)+auxi, 1)
        elseif statid == 13 then
        // DMG Pct - using both a melee and a ranged Trueshot Aura in order to reduce the number of abilities needed and aura buffs displayed
            // Melee DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTM')
            else
                if GetUnitAbilityLevel(u, 'DQTM') < 1 then
                call UnitAddAbility(u, 'DQTM')
                call BlzUnitDisableAbility(u, 'DQTM', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTM')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] + amount)
            call IncUnitAbilityLevel(u, 'DQTM')
            call DecUnitAbilityLevel(u, 'DQTM')
            endif
            // Ranged DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTS')
            else
                if GetUnitAbilityLevel(u, 'DQTS') < 1 then
                call UnitAddAbility(u, 'DQTS')
                call BlzUnitDisableAbility(u, 'DQTS', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTS')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] + amount)
            call IncUnitAbilityLevel(u, 'DQTS')
            call DecUnitAbilityLevel(u, 'DQTS')
            endif
        elseif statid == 31 then
        // Movement Speed
            if GetUnitAbilityLevel(u, 'DQMS') < 1 then
            call UnitAddAbility(u, 'DQMS')
            endif
        set a = BlzGetUnitAbility(u, 'DQMS')
        call BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_MOVEMENT_SPEED_BONUS, 0, R2I(EQIDDB[eqid][5].real[31] + amount))
        call IncUnitAbilityLevel(u, 'DQMS')
        call DecUnitAbilityLevel(u, 'DQMS')
        elseif statid == 20 then
        // IAS
            if GetUnitAbilityLevel(u, 'DQAS') < 1 then
            call UnitAddAbility(u, 'DQAS')
            endif
        set a = BlzGetUnitAbility(u, 'DQAS')
        call BlzSetAbilityRealLevelField(a, ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1, 0, EQIDDB[eqid][5].real[20] + amount)
        call IncUnitAbilityLevel(u, 'DQAS')
        call DecUnitAbilityLevel(u, 'DQAS')
        elseif statid == 21 then
        // Attack Range
        call BlzSetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 0, BlzGetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 0) + amount)
        call BlzSetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 1, BlzGetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 1) + amount)
        elseif statid == 25 then
        // Armor
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)-(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]))
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)+(amount+EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]))
        elseif statid == 33 then
        // Sight Range
        call BlzSetUnitRealField(u, ConvertUnitRealField('usir'), BlzGetUnitRealField(u, ConvertUnitRealField('usir'))+amount)
        elseif statid == 27 then
        // Evasion
            if GetUnitAbilityLevel(u, 'DQEV') < 1 then
            call UnitAddAbility(u, 'DQEV')
            call BlzUnitDisableAbility(u, 'DQEV', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEV')
            if EvasionMaxCap == -9999.0 then 
            // There is no evasion max cap
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EQIDDB[eqid][5].real[27] + amount)
            else
                if EQIDDB[eqid][5].real[27] + amount > EvasionMaxCap then
                call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EvasionMaxCap)
                else
                call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EQIDDB[eqid][5].real[27] + amount)
                endif
            endif
            call IncUnitAbilityLevel(u, 'DQEV')
            call DecUnitAbilityLevel(u, 'DQEV')
        elseif statid == 22 then
        // Lifesteal Percent
            if EQIDDB[eqid][5].real[22] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQLS')
            else
                if GetUnitAbilityLevel(u, 'DQLS') < 1 then
                call UnitAddAbility(u, 'DQLS')
                endif
            set a = BlzGetUnitAbility(u, 'DQLS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_LIFE_STOLEN_PER_ATTACK, 0, EQIDDB[eqid][5].real[22] + amount)
            call IncUnitAbilityLevel(u, 'DQLS')
            call DecUnitAbilityLevel(u, 'DQLS')
            endif
        elseif statid == 23 then
        // Thorns flat
            if EQIDDB[eqid][5].real[23] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTF')
            else
                if GetUnitAbilityLevel(u, 'DQTF') < 1 then
                call UnitAddAbility(u, 'DQTF')
                call BlzUnitDisableAbility(u, 'DQTF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Eah1'), 0, EQIDDB[eqid][5].real[23] + amount)
            call IncUnitAbilityLevel(u, 'DQTF')
            call DecUnitAbilityLevel(u, 'DQTF')
            endif
        elseif statid == 28 then
        // SpellDMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQEG') < 1 then
            call UnitAddAbility(u, 'DQEG')
            call BlzUnitDisableAbility(u, 'DQEG', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEG')
            if 1+EQIDDB[eqid][5].real[28] + amount < MagicDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5, 0, MagicDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5, 0, 1.0 + EQIDDB[eqid][5].real[28] + amount)       
            endif
        elseif statid == 32 then
        // Movement Speed Percent
            if EQIDDB[eqid][5].real[32] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQHM')
            else
                if GetUnitAbilityLevel(u, 'DQHM') < 1 then
                call UnitAddAbility(u, 'DQHM')
                endif
            set a = BlzGetUnitAbility(u, 'DQHM')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MOVEMENT_SPEED_INCREASE_PERCENT_UAU1, 0, EQIDDB[eqid][5].real[32] + amount)       
            call BlzUnitDisableAbility(u, 'DQHM', TRUE, TRUE)
            call UnitRemoveAbility(u, 'BDQ0')
            call BlzUnitDisableAbility(u, 'DQHM', FALSE, TRUE)
            call BlzUnitDisableAbility(u, 'BDQ0', FALSE, TRUE)
            endif
        elseif statid == 15 then
        // Melee DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTM')
            else
                if GetUnitAbilityLevel(u, 'DQTM') < 1 then
                call UnitAddAbility(u, 'DQTM')
                call BlzUnitDisableAbility(u, 'DQTM', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTM')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] + amount)
            call IncUnitAbilityLevel(u, 'DQTM')
            call DecUnitAbilityLevel(u, 'DQTM')
            endif
        elseif statid == 17 then
        // Ranged DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTS')
            else
                if GetUnitAbilityLevel(u, 'DQTS') < 1 then
                call UnitAddAbility(u, 'DQTS')
                call BlzUnitDisableAbility(u, 'DQTS', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTS')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] + amount)
            call IncUnitAbilityLevel(u, 'DQTS')
            call DecUnitAbilityLevel(u, 'DQTS')
            endif
        elseif statid == 26 then
        // Armor Percent
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)-(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]))
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)+(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]+amount))
        elseif statid == 14 then
        // Melee DMG Flat
            if EQIDDB[eqid][5].real[14] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQMF')
            else
                if GetUnitAbilityLevel(u, 'DQMF') < 1 then
                call UnitAddAbility(u, 'DQMF')
                call BlzUnitDisableAbility(u, 'DQMF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQMF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[14] + amount)
            call IncUnitAbilityLevel(u, 'DQMF')
            call DecUnitAbilityLevel(u, 'DQMF')
            endif
        elseif statid == 16 then
        // Ranged DMG Flat
            if EQIDDB[eqid][5].real[16] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQRF')
            else
                if GetUnitAbilityLevel(u, 'DQRF') < 1 then
                call UnitAddAbility(u, 'DQRF')
                call BlzUnitDisableAbility(u, 'DQRF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQRF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[16] + amount)
            call IncUnitAbilityLevel(u, 'DQRF')
            call DecUnitAbilityLevel(u, 'DQRF')
            endif
        elseif statid == 24 then
        // Thorns Pct
            if EQIDDB[eqid][5].real[24] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQSC')
            else
                if GetUnitAbilityLevel(u, 'DQSC') < 1 then
                call UnitAddAbility(u, 'DQSC')
                call BlzUnitDisableAbility(u, 'DQSC', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQSC')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts1'), 0, EQIDDB[eqid][5].real[24] + amount)
            endif
        elseif statid == 29 then
        // Melee DMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQSC') < 1 then
            call UnitAddAbility(u, 'DQSC')
            call BlzUnitDisableAbility(u, 'DQSC', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQSC')
            if 1+EQIDDB[eqid][5].real[29] + amount < MeleeDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts2'), 0, MeleeDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts2'), 0, 1.0 + EQIDDB[eqid][5].real[29] + amount)
            endif
        elseif statid == 30 then
        // Pierce DMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQEG') < 1 then
            call UnitAddAbility(u, 'DQEG')
            call BlzUnitDisableAbility(u, 'DQEG', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEG')
            if 1+EQIDDB[eqid][5].real[30] + amount < PierceDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1, 0, PierceDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1, 0, 1.0 + EQIDDB[eqid][5].real[30] + amount)       
            endif
        elseif statid == 10 then
        //Crit Chance
            if GetUnitAbilityLevel(u, 'DQCS') < 1 then
            call UnitAddAbility(u, 'DQCS')
            call BlzUnitDisableAbility(u, 'DQCS', FALSE, TRUE)
            set a = BlzGetUnitAbility(u, 'DQCS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2, 0,  DefaultCritMultiplier + EQIDDB[eqid][5].real[11])
            endif
        set a = BlzGetUnitAbility(u, 'DQCS')
        call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ocr1'), 0, EQIDDB[eqid][5].real[10] + amount)
        elseif statid == 11 then
        //Crit DMG
            if GetUnitAbilityLevel(u, 'DQCS') < 1 then
            else
            set a = BlzGetUnitAbility(u, 'DQCS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2, 0,  DefaultCritMultiplier + EQIDDB[eqid][5].real[11] + amount)
            endif
        elseif statid == 18 then
        //Cleave Pct
            if GetUnitAbilityLevel(u, 'DQCL') < 1 then
            call UnitAddAbility(u, 'DQCL')
            call BlzUnitDisableAbility(u, 'DQCL', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQCL')
        call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DISTRIBUTED_DAMAGE_FACTOR_NCA1, 0, EQIDDB[eqid][5].real[18] + amount)
        elseif statid == 19 then
        //Cleave Area
            if GetUnitAbilityLevel(u, 'DQCL') < 1 then
            call UnitAddAbility(u, 'DQCL')
            call BlzUnitDisableAbility(u, 'DQCL', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQCL')
        call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('aare'), 0, CleaveBaseArea + EQIDDB[eqid][5].real[19] + amount)
        elseif statid == 34 then
        // Inventory Space
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call DInvDeltaAdditionalSlotsForUnit(u, auxi)
        endif

    set EQIDDB[eqid][5].real[statid] = EQIDDB[eqid][5].real[statid] + amount

    endif
set statid = statid +1
exitwhen statid > DEqStatsCounter
endloop

// itt egy volt
set i = 0
set statid = 1
loop
exitwhen DEqItemTypeDefinitionDB[iid][7].integer[statid] == 0
set i = i + 1
set tabl.integer[DEqItemTypeDefinitionDB[iid][7].integer[statid]] = DEqItemTypeDefinitionDB[iid][11].integer[statid]
set ia[i] = DEqItemTypeDefinitionDB[iid][7].integer[statid]

set auxi = FindUnitDEqAbilitySerial(uhndl, DEqItemTypeDefinitionDB[iid][7].integer[statid])
// Check if Ability Id already exists in unit's entry
if auxi == 9999 then
// does not exist - create entry for ability id
set EQIDDB[eqid][6].integer[0] = EQIDDB[eqid][6].integer[0] + 1
set auxi = EQIDDB[eqid][6].integer[0]
set EQIDDB[eqid][6].integer[auxi] = DEqItemTypeDefinitionDB[iid][7].integer[statid]
else
// exists - do nothing
endif

set statid = statid + 1
endloop

if nid > 0 then
set statid = 1        
loop
exitwhen NamedItemTypeDB[iid][nid][7].integer[statid] == 0
set i = 1
    loop
    exitwhen ia[i] == 0 or ia[i] == NamedItemTypeDB[iid][nid][7].integer[statid]
    set i = i + 1
    endloop

set tabl.integer[NamedItemTypeDB[iid][nid][7].integer[statid]] = NamedItemTypeDB[iid][nid][11].integer[statid]
set ia[i] = NamedItemTypeDB[iid][nid][7].integer[statid]
set auxi = FindUnitDEqAbilitySerial(uhndl, ia[i])
// Check if Ability Id already exists in unit's entry
    if auxi == 9999 then
    // does not exist - create entry for ability id
    set EQIDDB[eqid][6].integer[0] = EQIDDB[eqid][6].integer[0] + 1
    set auxi = EQIDDB[eqid][6].integer[0]
    set EQIDDB[eqid][6].integer[auxi] = ia[i]
    else
    // exists - do nothing
    endif
set statid = statid + 1
endloop
endif

set i = 1
loop
exitwhen ia[i] == 0

set auxi = FindUnitDEqAbilitySerial(uhndl, ia[i])
set amount = I2R(tabl.integer[ia[i]])

// Rarity
if rid > 0 then
set amount = amount * DEqRarityStatX[rid]
endif
if ilvl > 1 then
set amount = amount * (1+(ilvl-1)*DEqIlvlStatX)
endif

call DEqDUAL(u, uhndl, ia[i], R2I(amount), i)

set i = i +1
endloop

set a = null
set it = null
set u = null
call tabl.destroy()
endfunction



function DEqCanUnitEquipItemInSlot takes unit u, item it, integer slotId returns boolean
local integer i = 0
local integer iid = GetItemTypeId(it)
local integer auxi = 0
local integer auxi2 = 0
local boolean b = FALSE
local integer ihndl = GetHandleId(it)
local integer tid = DInvItemHandleDB[ihndl].integer[5]
local integer nid = 0 
local integer rid = 0
local integer ilvl = 0
local integer p = GetPlayerId(GetOwningPlayer(u))

if tid > 0 then
set nid = DEqTroveDB[tid][0].integer[8]
set rid = DEqTroveDB[tid][0].integer[3]
set ilvl = DEqTroveDB[tid][0].integer[2]
endif
// check for:
// slot
// hero level required
// class required
// class forbidden
// ability required
// stats required
// If you also set the level requirement of an existing item during the game, then that will overwrite this requirement

//call BJDebugMsg("DEqCanUnitEquipItemInSlot started")
//call BJDebugMsg("DEqCanUnitEquipItemInSlot slotId = "+I2S(slotId))

//slot
if DEqItemTypeDefinitionDB[iid][9].integer[slotId] > 0 then
//Is allowed in slot
//call BJDebugMsg("DEqCanUnitEquipItemInSlot item is allowed in slot")
else
    if slotId == 20 and DEqItemTypeDefinitionDB[iid][9].integer[19] > 0 then
    // A 19 slot item is trying to be used in slot 20 
        if GetUnitAbilityLevel(u, 'DQDW') > 0 then
        // Unit has dual wield
            if DEqItemTypeDefinitionDB[iid][0].integer[1] > 0 then
            // Item is 2handed
                if GetUnitAbilityLevel(u, 'DQTG') > 0 then
                // Unit has Titan's grip
                else
                // No titan's grip
                call CanNotEquipMsg(p, "You need "+GetObjectName('DQTG')+" to equip this item in this slot.")
                set u = null
                set it = null
                return FALSE
                endif
            else
            // Item is not 2 handed
            endif
        else
        // Unit has no DW
        call CanNotEquipMsg(p, "You need "+GetObjectName('DQDW')+" to equip this item in this slot.")
        set u = null
        set it = null
        return FALSE
        endif
    else
    call CanNotEquipMsg(p, "Item is not allowed in this slot.")
    set u = null
    set it = null
    return FALSE
    endif
endif


// ********************************************** Remake start
//slot
if DEqItemTypeDefinitionDB[iid][9].integer[slotId] > 0 then
//Is allowed in slot
//call BJDebugMsg("DEqCanUnitEquipItemInSlot item is allowed in slot")
else
//call BJDebugMsg("DEqCanUnitEquipItemInSlot item NOT allowed in slot")
    if slotId == 20 and DEqItemTypeDefinitionDB[iid][9].integer[19] > 0 then
    // A 19 slot item is trying to be used in slot 20 
        if GetUnitAbilityLevel(u, 'DQDW') > 0 then
        // Unit has dual wield
            if DEqItemTypeDefinitionDB[iid][0].integer[1] > 0 then
            // Item is 2handed
                if GetUnitAbilityLevel(u, 'DQTG') > 0 then
                // Unit has Titan's grip
                else
                // No titan's grip
                call CanNotEquipMsg(p, "You need "+GetObjectName('DQTG')+" to equip this item in this slot.")
                set u = null
                set it = null
                return FALSE
                endif
            else
            // Item is not 2 handed
            endif
        else
        // Unit has no DW
        call CanNotEquipMsg(p, "You need "+GetObjectName('DQDW')+" to equip this item in this slot.")
        set u = null
        set it = null
        return FALSE
        endif
    else
    call CanNotEquipMsg(p, "Item is not allowed in this slot.")
    set u = null
    set it = null
    return FALSE
    endif
endif
// ********************************************** Remake over

//call BJDebugMsg("DEqCanUnitEquipItemInSlot 1")

// Required level
set i = DEqItemTypeDefinitionDB[iid][0].integer[0]
if nid > 0 then
    set auxi = NamedItemTypeDB[iid][nid][0].integer[0]
    if auxi > 0 then
    set i = auxi
    endif
endif
if MakeILvlTheMinimumRequiredLvl == TRUE then
// DEqGetItemLevelOfItem(it)
    set auxi = DEqTroveDB[tid][0].integer[2]
    if auxi > 0 then
    set i = auxi
    endif
endif
set auxi = DEqTroveDB[tid][0].integer[0]
if auxi > 0 then
    set i = auxi
endif

//hero level
if GetHeroLevel(u) >= i then
//Hero is high enough level
else
call CanNotEquipMsg(p, "You do not meet the level requirements for this item.")
set u = null
set it = null
return FALSE
endif

//call BJDebugMsg("DEqCanUnitEquipItemInSlot 2")

//class
set auxi = GetUnitTypeId(u)
if DEqItemTypeDefinitionDB[iid][1].integer[1] == 0 then
//no classes are required
    if DEqItemTypeDefinitionDB[iid][2].integer[1] == 0 then
    // there are no forbidden classes
    else
        set i = 1
        loop
        
        if auxi == DEqItemTypeDefinitionDB[iid][2].integer[i] then
        // UnitTypeId is the same as a forbidden class
            call CanNotEquipMsg(p, "This class is forbidden to equip this item.")
            set u = null
            set it = null
            return FALSE
        endif
        
        set i = i + 1
        exitwhen 0 == DEqItemTypeDefinitionDB[iid][2].integer[i]
        endloop
    endif
else
//some classes are required
    set b = false
    set i = 1
    loop
    
    if auxi == DEqItemTypeDefinitionDB[iid][1].integer[i] then
        set b = TRUE
    endif
    
    set i = i + 1
    exitwhen b == TRUE or DEqItemTypeDefinitionDB[iid][1].integer[i] == 0
    endloop
    
    if b == FALSE then
    call CanNotEquipMsg(p, "This class can not equip this item.")
    set it = null
    set u = null
    return FALSE
    endif
endif

//call BJDebugMsg("DEqCanUnitEquipItemInSlot 3")

//abilities required
if DEqItemTypeDefinitionDB[iid][3].integer[1] == 0 then
//no abilities are required
else
//some abilities are required
    set i = 1
    loop
    if GetUnitAbilityLevel(u, DEqItemTypeDefinitionDB[iid][3].integer[i]) < DEqItemTypeDefinitionDB[iid][4].integer[i] then
    call CanNotEquipMsg(p, "You do not meet ability requirements to equip this item.")
    set it = null
    set u = null
    return FALSE
    endif
    set i = i + 1
    exitwhen DEqItemTypeDefinitionDB[iid][3].integer[i] == 0
    endloop
endif

// abilities forbidden
if DEqItemTypeDefinitionDB[iid][5].integer[1] == 0 then
// there are no forbidden abilities
else
    set i = 1
    loop
    if GetUnitAbilityLevel(u, DEqItemTypeDefinitionDB[iid][5].integer[i]) >= DEqItemTypeDefinitionDB[iid][6].integer[i] then
    // AbilityId is the same as a forbidden ability
    call CanNotEquipMsg(p, "You do not meet ability requirements to equip this item.")
    set u = null
    set it = null
    return FALSE
    endif
    set i = i + 1
    exitwhen 0 == DEqItemTypeDefinitionDB[iid][5].integer[i]
    endloop
endif

//call BJDebugMsg("DEqCanUnitEquipItemInSlot 4")

set i = 1
loop
    if DEqItemTypeDefinitionDB[iid][8].real[i] == 0 then
    // There is no such stat requirement
    else
    // This stat is needed
        if DEqGetUnitStatById(u, i) < DEqItemTypeDefinitionDB[iid][8].real[i] then
        // Unit's stat is lower than the required stat
        call CanNotEquipMsg(p, "You do not meet stat requirements to equip this item.")
        set it = null
        set u = null
        return FALSE
        endif
    endif
set i = i + 1
exitwhen i > DEqStatsCounter
endloop

//call BJDebugMsg("DEqCanUnitEquipItemInSlot 5")

set u = null
set it = null
//call BJDebugMsg("DEqCanUnitEquipItemInSlot finished")
return TRUE
endfunction


/*
Once upon a time these were started as "unequip item and move to inventory" functions, but got scrapped in favor of others... Delete?

function DEqSlotToDInvSlot takes integer pid, integer hid, unit u, integer deqslot, integer dinvslot returns nothing
local integer dexter = bid
endfunction



function UnitDEqToDInv takes integer pid, integer hid, unit u, integer deqslot, integer dinvslot returns nothing
local integer dexter = bid

if DInventoryDB[dexter].item[dinvslot] == null then
    call DEqSlotToDInvSlot(pid, hid, u, deqslot, dinvslot)
else
// DInventory Item slot is not empty
// Do nothing
endif
set u = null
endfunction
*/



/*
function UnequipDEqSlotOfUnit takes integer deqslot, unit u returns nothing
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer hid = BIDOfUnit(u)
local integer dexter = bid
local integer invslot = FirstFreeDInvSlotOfBID(pid, hid)

if invslot > -1 then
    call DEqSlotToDInvSlot(pid, hid, u, deqslot, dinvslot)
else
// DInventory Item slot is not empty
// Do nothing
endif
set u = null
endfunction
*/



function StoreItemForPIDBID takes item it, integer pid, integer bid, integer eqid returns integer
local integer targetSlot = -1
local integer ihndl = GetHandleId(it)
if InfiniteStackingSystemAllowed == TRUE then
// Infinite Stacking system is enabled
////call BJDebugMsg("StoreItemForPIDBID Stacking system is enabled")
////call BJDebugMsg("StoreItemForPIDBID it is: "+GetItemName(it))
    if DInventoryIsItemStackable(it) == TRUE then
    // Item is stackable
////call BJDebugMsg("StoreItemForPIDBID Item is stackable")
////call BJDebugMsg("StoreItemForPIDBID stackDelta = "+I2S(GetItemCharges(it)))
        if PlayerStackingMode[pid] == 2 then
        // Infinite stacking is enabled
        set targetSlot = FirstStackableItemSlotOfBID(it, pid, bid)
            if targetSlot > -1 then
            // Found it -> start infinite stacking
            call SetItemCharges(DInventoryDB[bid].item[targetSlot], GetItemCharges(DInventoryDB[bid].item[targetSlot])+GetItemCharges(it))
                if pid == GetPlayerId(GetLocalPlayer()) then
                    //check if inventory is open
////call BJDebugMsg("StoreItemForPIDBID Yes, pid is localP")
                    if BlzFrameIsVisible(InventoryLowestFrame[pid]) == TRUE then
                        // Is Player viewing the page of targetslot
                        if DItemSlotId2SlotFrameId(pid, targetSlot) == -1 then
////call BJDebugMsg("StoreItemForPIDBIDpid is "+I2S(pid))
////call BJDebugMsg("StoreItemForPIDBIDbid is "+I2S(bid))
////call BJDebugMsg("StoreItemForPIDBID1st branchtargetslot is "+I2S(targetSlot))
                        // not
                        else
////call BJDebugMsg("StoreItemForPIDBID pid is "+I2S(pid))
////call BJDebugMsg("StoreItemForPIDBID bid is "+I2S(bid))
////call BJDebugMsg("StoreItemForPIDBID targetslot is "+I2S(targetSlot))
//call BJDebugMsg("1 DItemSlotId2SlotFrameId(pid, targetSlot = "+I2S(DItemSlotId2SlotFrameId(pid, targetSlot)))
                            if bid == CurrentBID[pid] then
                            call DInvSlotDataIntoFrame(pid, bid, targetSlot, DItemSlotId2SlotFrameId(pid, targetSlot))
                            endif
                        endif
                    else
////call BJDebugMsg("StoreItemForPIDBID Lowestframe is NOT visible")                        
                    endif
                else
////call BJDebugMsg("StoreItemForPIDBID No, pid isNOT localP")                    
                endif
            call RemoveItem(it)
            set it = null
            else
            // does not exist
            //Item will be added outside this if tree
            endif
        else
        // Infinite stacking is off
        // Normal stacking to maxStacks is not possible due to a blizzard bug - possible workarounds discarded due to reasons
        endif
    else
    // Item is not stackable
    endif
endif

if it == null then
// Item was stacked and nulled
else
// We can finally start storing the item
set targetSlot = FirstFreeDInvSlotOfBID(pid, bid)
////call BJDebugMsg("2nd branch targetSlot = "+I2S(targetSlot))
    if targetSlot == -1 then
    // inventory full or some other issue
    else
/*
I think this needs to be removed
        if GetItemCharges(it) > 0 then
        // Item has charges
            if hid == CurrentBID[pid] then
            call DInvSlotDataIntoFrame(pid, hid, targetSlot, DItemSlotId2SlotFrameId(pid, targetSlot))
            endif
call BJDebugMsg("2 DItemSlotId2SlotFrameId(pid, targetSlot = "+I2S(DItemSlotId2SlotFrameId(pid, targetSlot)))
        else
        // hide stackframe
// NEEDTODO : FIX THIS
            //call BlzFrameSetVisible(InventorySlotButtonIconFrame[DItemSlotId2SlotFrameId(pid, targetSlot)], FALSE)
        endif
*/
        
        // store item in table
        set DInventoryDB[bid].item[targetSlot] = it
        // store item data in table
        set DInvItemHandleDB[ihndl].integer[0] = pid + 1
        set DInvItemHandleDB[ihndl].integer[1] = bid
        set DInvItemHandleDB[ihndl].integer[6] = eqid
        // set trove ID
// NEEDTODO: various modules affect the gold value of the item!

        // make item not visible
        // move item to item heaven
        call GoToItemHeaven(it)
    endif
endif

//set text if inventory is open
if pid == GetPlayerId(GetLocalPlayer()) then
    //check if inventory is open
    if BlzFrameIsVisible(InventoryLowestFrame[pid]) == TRUE then
        // Is Player viewing the page of targetslot
        if DItemSlotId2SlotFrameId(pid, targetSlot) < 0 then
        // not
        else
            if bid == CurrentBID[pid] then
            call DInvSlotDataIntoFrame(pid, bid, targetSlot, DItemSlotId2SlotFrameId(pid, targetSlot))
            endif
//call BJDebugMsg("3 DItemSlotId2SlotFrameId(pid, targetSlot = "+I2S(DItemSlotId2SlotFrameId(pid, targetSlot)))
        endif
    endif
endif

set it = null
return targetSlot
endfunction



function RegenSetToolTip takes integer pid, integer uhndl, integer setID returns nothing
local integer i = 1
local integer J = HighestSlotNumber
local integer auxint = ColXRow
local integer pg = DInvCurrentPage[pid]
local integer k = (pg-1) * auxint
local integer L = pg * auxint
local item it = null
local integer bid = CurrentBID[pid]
local integer eqid = DInvUnitHandleDB[uhndl][0].integer[3]

// Loop through equipped items
loop
exitwhen i > J
set it = EQIDDB[eqid][4].item[i]
if it == null then
else
    if setID == DEqIsItemASetItem(it) then
    call GenerateDEqTooltip(GetItemTypeId(it), it, DEqTooltipText[i], -i)
    endif
endif
set i = i + 1
endloop

// Loop through current DInv page items
loop
exitwhen k > L
set it = DInventoryDB[bid].item[k]
if it == null then
else
    if setID == DEqIsItemASetItem(it) then
    call GenerateDEqTooltip(GetItemTypeId(it), it, InventoryTooltipText[k], k)
    endif
endif
set k = k + 1
endloop
set it = null
endfunction



function DEqGrantSetStats takes unit u, integer setID, integer margin returns nothing
local integer i = 1
local integer statid = 1
local real amount = 0.0
local integer uhndl = GetHandleId(u)
local integer auxi = 0
local real auxr = 0.0
local Table tabl = Table.create()
local integer array ia
local ability a
local integer eqid = DInvUnitHandleDB[uhndl][0].integer[3]

loop
set amount = DEqSetDB[setID][1][margin].real[statid]
    if amount == 0 then
    //do nothing
    else
        if statid == 1 then
        // STR
                // total stats of this type given by items for this unit
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call SetHeroStr(u, GetHeroStr(u, FALSE)+auxi, TRUE)
        elseif statid == 2 then
        // AGI
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call SetHeroAgi(u, GetHeroAgi(u, FALSE)+auxi, TRUE)
        elseif statid == 3 then
        // INT
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call SetHeroInt(u, GetHeroInt(u, FALSE)+auxi, TRUE)
        elseif statid == 4 then
        // HP
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call BlzSetUnitMaxHP(u, R2I(GetUnitState(u, UNIT_STATE_MAX_LIFE)+auxi))
        elseif statid == 5 then
        // HPS
        call BlzSetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE,  BlzGetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE) + amount)
        elseif statid == 6 then
        // HP Percent Per Sec
            if EQIDDB[eqid][5].real[6] + amount == 0.00 then
            call UnitRemoveAbility(u, 'DQLR')
            else
                if GetUnitAbilityLevel(u, 'DQLR') < 1 then
                call UnitAddAbility(u, 'DQLR')
                endif
            set a = BlzGetUnitAbility(u, 'DQLR')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Oar1'), 0, EQIDDB[eqid][5].real[6] + amount)
            call IncUnitAbilityLevel(u, 'DQLR')
            call DecUnitAbilityLevel(u, 'DQLR')
            endif
        elseif statid == 7 then
        // Mana
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call BlzSetUnitMaxMana(u, R2I(GetUnitState(u, UNIT_STATE_MAX_MANA)+auxi))
        elseif statid == 8 then
        // MPS
        call BlzSetUnitRealField(u, UNIT_RF_MANA_REGENERATION,  BlzGetUnitRealField(u, UNIT_RF_MANA_REGENERATION) + amount)
        elseif statid == 9 then
        // Mana Percent Per Sec
            if EQIDDB[eqid][5].real[9] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQMR')
            else
                if GetUnitAbilityLevel(u, 'DQMR') < 1 then
                call UnitAddAbility(u, 'DQMR')
                endif
            set a = BlzGetUnitAbility(u, 'DQMR')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Arm1'), 0, EQIDDB[eqid][5].real[9] + amount)
            call IncUnitAbilityLevel(u, 'DQMR')
            call DecUnitAbilityLevel(u, 'DQMR')
            endif
        elseif statid == 12 then
        // Damage
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call BlzSetUnitBaseDamage(u, BlzGetUnitBaseDamage(u, 0)+auxi, 0)
        call BlzSetUnitBaseDamage(u, BlzGetUnitBaseDamage(u, 1)+auxi, 1)
        elseif statid == 13 then
        // DMG Pct - using both a melee and a ranged Trueshot Aura in order to reduce the number of abilities needed and aura buffs displayed
            // Melee DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTM')
            else
                if GetUnitAbilityLevel(u, 'DQTM') < 1 then
                call UnitAddAbility(u, 'DQTM')
                call BlzUnitDisableAbility(u, 'DQTM', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTM')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] + amount)
            call IncUnitAbilityLevel(u, 'DQTM')
            call DecUnitAbilityLevel(u, 'DQTM')
            endif
            // Ranged DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTS')
            else
                if GetUnitAbilityLevel(u, 'DQTS') < 1 then
                call UnitAddAbility(u, 'DQTS')
                call BlzUnitDisableAbility(u, 'DQTS', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTS')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] + amount)
            call IncUnitAbilityLevel(u, 'DQTS')
            call DecUnitAbilityLevel(u, 'DQTS')
            endif
        elseif statid == 31 then
        // Movement Speed
            if GetUnitAbilityLevel(u, 'DQMS') < 1 then
            call UnitAddAbility(u, 'DQMS')
            endif
        set a = BlzGetUnitAbility(u, 'DQMS')
        call BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_MOVEMENT_SPEED_BONUS, 0, R2I(EQIDDB[eqid][5].real[31] + amount))
        call IncUnitAbilityLevel(u, 'DQMS')
        call DecUnitAbilityLevel(u, 'DQMS')
        elseif statid == 20 then
        // IAS
            if GetUnitAbilityLevel(u, 'DQAS') < 1 then
            call UnitAddAbility(u, 'DQAS')
            endif
        set a = BlzGetUnitAbility(u, 'DQAS')
        call BlzSetAbilityRealLevelField(a, ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1, 0, EQIDDB[eqid][5].real[20] + amount)
        call IncUnitAbilityLevel(u, 'DQAS')
        call DecUnitAbilityLevel(u, 'DQAS')
        elseif statid == 21 then
        // Attack Range
        call BlzSetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 0, BlzGetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 0) + amount)
        call BlzSetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 1, BlzGetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 1) + amount)
        elseif statid == 25 then
        // Armor
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)-(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]))
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)+(amount+EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]))
        elseif statid == 33 then
        // Sight Range
        call BlzSetUnitRealField(u, ConvertUnitRealField('usir'), BlzGetUnitRealField(u, ConvertUnitRealField('usir'))+amount)
        elseif statid == 27 then
        // Evasion
            if GetUnitAbilityLevel(u, 'DQEV') < 1 then
            call UnitAddAbility(u, 'DQEV')
            call BlzUnitDisableAbility(u, 'DQEV', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEV')
            if EvasionMaxCap == -9999.0 then 
            // There is no evasion max cap
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EQIDDB[eqid][5].real[27] + amount)
            else
                if EQIDDB[eqid][5].real[27] + amount > EvasionMaxCap then
                call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EvasionMaxCap)
                else
                call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EQIDDB[eqid][5].real[27] + amount)
                endif
            endif
            call IncUnitAbilityLevel(u, 'DQEV')
            call DecUnitAbilityLevel(u, 'DQEV')
        elseif statid == 22 then
        // Lifesteal Percent
            if EQIDDB[eqid][5].real[22] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQLS')
            else
                if GetUnitAbilityLevel(u, 'DQLS') < 1 then
                call UnitAddAbility(u, 'DQLS')
                endif
            set a = BlzGetUnitAbility(u, 'DQLS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_LIFE_STOLEN_PER_ATTACK, 0, EQIDDB[eqid][5].real[22] + amount)
            call IncUnitAbilityLevel(u, 'DQLS')
            call DecUnitAbilityLevel(u, 'DQLS')
            endif
        elseif statid == 23 then
        // Thorns flat
            if EQIDDB[eqid][5].real[23] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTF')
            else
                if GetUnitAbilityLevel(u, 'DQTF') < 1 then
                call UnitAddAbility(u, 'DQTF')
                call BlzUnitDisableAbility(u, 'DQTF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Eah1'), 0, EQIDDB[eqid][5].real[23] + amount)
            call IncUnitAbilityLevel(u, 'DQTF')
            call DecUnitAbilityLevel(u, 'DQTF')
            endif
        elseif statid == 28 then
        // SpellDMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQEG') < 1 then
            call UnitAddAbility(u, 'DQEG')
            call BlzUnitDisableAbility(u, 'DQEG', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEG')
            if 1+EQIDDB[eqid][5].real[28] + amount < MagicDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5, 0, MagicDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5, 0, 1.0 + EQIDDB[eqid][5].real[28] + amount )       
            endif
            //call IncUnitAbilityLevel(u, 'DQEG')
            //call DecUnitAbilityLevel(u, 'DQEG')
        elseif statid == 32 then
        // Movement Speed Percent
            if EQIDDB[eqid][5].real[32] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQHM')
            else
                if GetUnitAbilityLevel(u, 'DQHM') < 1 then
                call UnitAddAbility(u, 'DQHM')
                endif
            set a = BlzGetUnitAbility(u, 'DQHM')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MOVEMENT_SPEED_INCREASE_PERCENT_UAU1, 0, EQIDDB[eqid][5].real[32] + amount)       
            call BlzUnitDisableAbility(u, 'DQHM', TRUE, TRUE)
            call UnitRemoveAbility(u, 'BDQ0')
            call BlzUnitDisableAbility(u, 'DQHM', FALSE, TRUE)
            call BlzUnitDisableAbility(u, 'BDQ0', FALSE, TRUE)
            endif
        elseif statid == 15 then
        // Melee DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTM')
            else
                if GetUnitAbilityLevel(u, 'DQTM') < 1 then
                call UnitAddAbility(u, 'DQTM')
                call BlzUnitDisableAbility(u, 'DQTM', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTM')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] + amount)
            call IncUnitAbilityLevel(u, 'DQTM')
            call DecUnitAbilityLevel(u, 'DQTM')
            endif
        elseif statid == 17 then
        // Ranged DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTS')
            else
                if GetUnitAbilityLevel(u, 'DQTS') < 1 then
                call UnitAddAbility(u, 'DQTS')
                call BlzUnitDisableAbility(u, 'DQTS', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTS')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] + amount)
            call IncUnitAbilityLevel(u, 'DQTS')
            call DecUnitAbilityLevel(u, 'DQTS')
            endif
        elseif statid == 26 then
        // Armor Percent
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)-(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]))
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)+(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]+amount))
        elseif statid == 14 then
        // Melee DMG Flat
            if EQIDDB[eqid][5].real[14] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQMF')
            else
                if GetUnitAbilityLevel(u, 'DQMF') < 1 then
                call UnitAddAbility(u, 'DQMF')
                call BlzUnitDisableAbility(u, 'DQMF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQMF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[14] + amount)
            call IncUnitAbilityLevel(u, 'DQMF')
            call DecUnitAbilityLevel(u, 'DQMF')
            endif
        elseif statid == 16 then
        // Ranged DMG Flat
            if EQIDDB[eqid][5].real[16] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQRF')
            else
                if GetUnitAbilityLevel(u, 'DQRF') < 1 then
                call UnitAddAbility(u, 'DQRF')
                call BlzUnitDisableAbility(u, 'DQRF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQRF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[16] + amount)
            call IncUnitAbilityLevel(u, 'DQRF')
            call DecUnitAbilityLevel(u, 'DQRF')
            endif
        elseif statid == 24 then
        // Thorns Pct
            if EQIDDB[eqid][5].real[24] + amount == 0.0 then
            call UnitRemoveAbility(u, 'DQSC')
            else
                if GetUnitAbilityLevel(u, 'DQSC') < 1 then
                call UnitAddAbility(u, 'DQSC')
                call BlzUnitDisableAbility(u, 'DQSC', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQSC')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts1'), 0, EQIDDB[eqid][5].real[24] + amount)
            endif
        elseif statid == 29 then
        // Melee DMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQSC') < 1 then
            call UnitAddAbility(u, 'DQSC')
            call BlzUnitDisableAbility(u, 'DQSC', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQSC')
            if 1+EQIDDB[eqid][5].real[29] + amount < MeleeDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts2'), 0, MeleeDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts2'), 0, 1.0 + EQIDDB[eqid][5].real[29] + amount)
            endif
        elseif statid == 30 then
        // Pierce DMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQEG') < 1 then
            call UnitAddAbility(u, 'DQEG')
            call BlzUnitDisableAbility(u, 'DQEG', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEG')
            if 1+EQIDDB[eqid][5].real[30] + amount < PierceDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1, 0, PierceDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1, 0, 1.0 + EQIDDB[eqid][5].real[30] + amount)       
            endif
        elseif statid == 10 then
        //Crit Chance
            if GetUnitAbilityLevel(u, 'DQCS') < 1 then
            call UnitAddAbility(u, 'DQCS')
            call BlzUnitDisableAbility(u, 'DQCS', FALSE, TRUE)
            set a = BlzGetUnitAbility(u, 'DQCS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2, 0,  DefaultCritMultiplier + EQIDDB[eqid][5].real[11])
            endif
        set a = BlzGetUnitAbility(u, 'DQCS')
        call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ocr1'), 0, EQIDDB[eqid][5].real[10] + amount)
        elseif statid == 11 then
        //Crit DMG
            if GetUnitAbilityLevel(u, 'DQCS') < 1 then
            else
            set a = BlzGetUnitAbility(u, 'DQCS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2, 0,  DefaultCritMultiplier + EQIDDB[eqid][5].real[11] + amount)
            endif
        elseif statid == 18 then
        //Cleave Pct
            if GetUnitAbilityLevel(u, 'DQCL') < 1 then
            call UnitAddAbility(u, 'DQCL')
            call BlzUnitDisableAbility(u, 'DQCL', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQCL')
        call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DISTRIBUTED_DAMAGE_FACTOR_NCA1, 0, EQIDDB[eqid][5].real[18] + amount)
        elseif statid == 19 then
        //Cleave Area
            if GetUnitAbilityLevel(u, 'DQCL') < 1 then
            call UnitAddAbility(u, 'DQCL')
            call BlzUnitDisableAbility(u, 'DQCL', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQCL')
        call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('aare'), 0, CleaveBaseArea + EQIDDB[eqid][5].real[19] + amount)
        elseif statid == 34 then
        // Inventory Space
        set auxr = EQIDDB[eqid][5].real[statid] + amount
        set auxi = R2I(auxr) - R2I(EQIDDB[eqid][5].real[statid])
        call DInvDeltaAdditionalSlotsForUnit(u, auxi)
        endif

    set EQIDDB[eqid][5].real[statid] = EQIDDB[eqid][5].real[statid] + amount

    endif
set statid = statid +1
exitwhen statid > DEqStatsCounter
endloop

set i = 0
set statid = 1
loop
exitwhen DEqSetDB[setID][2][margin].integer[statid] == 0
set i = i + 1
set tabl.integer[DEqSetDB[setID][2][margin].integer[statid]] = DEqSetDB[setID][3][margin].integer[statid]
set ia[i] = DEqSetDB[setID][2][margin].integer[statid]
//call BJDebugMsg("This set gives ability: " + GetAbilityName(DEqSetDB[setID][2][margin].integer[statid]))

set auxi = FindUnitDEqAbilitySerial(uhndl, DEqSetDB[setID][2][margin].integer[statid])
// Check if Ability Id already exists in unit's entry
if auxi == 9999 then
// does not exist - create entry for ability id
set EQIDDB[eqid][6].integer[0] = EQIDDB[eqid][6].integer[0] + 1
set auxi = EQIDDB[eqid][6].integer[0]
set EQIDDB[eqid][6].integer[auxi] = DEqSetDB[setID][2][margin].integer[statid]
else
// exists - do nothing
endif

set statid = statid + 1
endloop

set i = 1
loop
exitwhen ia[i] == 0

set auxi = FindUnitDEqAbilitySerial(uhndl, ia[i])
set amount = I2R(tabl.integer[ia[i]])

//call BJDebugMsg("This set trying to give ability: " + GetAbilityName(ia[i]) + " lvl: " + R2S(R2I(amount)))
call DEqDUAL(u, uhndl, ia[i], R2I(amount), i)

set i = i +1
endloop

set u = null
endfunction



function DEqSubtractSetStats takes unit u, integer setID, integer margin returns nothing
local integer i = 1
local integer statid = 1
local real amount = 0.0
local integer uhndl = GetHandleId(u)
local integer auxi = 0
local real auxr = 0.0
local Table tabl = Table.create()
local integer array ia
local ability a
local integer eqid = DInvUnitHandleDB[uhndl][0].integer[3]

loop
set amount = DEqSetDB[setID][1][margin].real[statid]
    if amount == 0 then
    //do nothing
    else
        if statid == 1 then
        // STR
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call SetHeroStr(u, GetHeroStr(u, FALSE)-auxi, TRUE)
        elseif statid == 2 then
        // AGI
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call SetHeroAgi(u, GetHeroAgi(u, FALSE)-auxi, TRUE)
        elseif statid == 3 then
        // INT
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call SetHeroInt(u, GetHeroInt(u, FALSE)-auxi, TRUE)
        elseif statid == 4 then
        // HP
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call BlzSetUnitMaxHP(u, R2I(GetUnitState(u, UNIT_STATE_MAX_LIFE)-auxi))
        elseif statid == 5 then
        // HPS
        call BlzSetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE, BlzGetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE) - amount)
        elseif statid == 6 then
        // HP Percent Per Sec
            if EQIDDB[eqid][5].real[6] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQLR')
            else
                if GetUnitAbilityLevel(u, 'DQLR') < 1 then
                call UnitAddAbility(u, 'DQLR')
                endif
            set a = BlzGetUnitAbility(u, 'DQLR')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Oar1'), 0, EQIDDB[eqid][5].real[6] - amount)
            call IncUnitAbilityLevel(u, 'DQLR')
            call DecUnitAbilityLevel(u, 'DQLR')
            endif
        elseif statid == 7 then
        // Mana
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call BlzSetUnitMaxMana(u, R2I(GetUnitState(u, UNIT_STATE_MAX_MANA)-auxi))
        elseif statid == 8 then
        // MPS
        call BlzSetUnitRealField(u, UNIT_RF_MANA_REGENERATION,  BlzGetUnitRealField(u, UNIT_RF_MANA_REGENERATION) - amount)
        elseif statid == 9 then
        // Mana Percent Per Sec
            if EQIDDB[eqid][5].real[9] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQMR')
            else
                if GetUnitAbilityLevel(u, 'DQMR') < 1 then
                call UnitAddAbility(u, 'DQMR')
                endif
            set a = BlzGetUnitAbility(u, 'DQMR')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Arm1'), 0, EQIDDB[eqid][5].real[9] - amount)
            call IncUnitAbilityLevel(u, 'DQMR')
            call DecUnitAbilityLevel(u, 'DQMR')
            endif
        elseif statid == 12 then
        // Damage
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call BlzSetUnitBaseDamage(u, BlzGetUnitBaseDamage(u, 0)-auxi, 0)
        call BlzSetUnitBaseDamage(u, BlzGetUnitBaseDamage(u, 1)-auxi, 1)
        elseif statid == 13 then
        // DMG Pct - using both a melee and a ranged Trueshot Aura in order to reduce the number of abilities needed and aura buffs displayed
                // Melee DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTM')
            else
                if GetUnitAbilityLevel(u, 'DQTM') < 1 then
                call UnitAddAbility(u, 'DQTM')
                call BlzUnitDisableAbility(u, 'DQTM', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTM')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] - amount)
            call IncUnitAbilityLevel(u, 'DQTM')
            call DecUnitAbilityLevel(u, 'DQTM')
            endif
            // Ranged DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTS')
            else
                if GetUnitAbilityLevel(u, 'DQTS') < 1 then
                call UnitAddAbility(u, 'DQTS')
                call BlzUnitDisableAbility(u, 'DQTS', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTS')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] - amount)
            call IncUnitAbilityLevel(u, 'DQTS')
            call DecUnitAbilityLevel(u, 'DQTS')
            endif
        elseif statid == 31 then
        // Movement Speed
            if GetUnitAbilityLevel(u, 'DQMS') < 1 then
            call UnitAddAbility(u, 'DQMS')
            endif
        set a = BlzGetUnitAbility(u, 'DQMS')
        call BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_MOVEMENT_SPEED_BONUS, 0, R2I(EQIDDB[eqid][5].real[31] - amount))
        call IncUnitAbilityLevel(u, 'DQMS')
        call DecUnitAbilityLevel(u, 'DQMS')
        elseif statid == 20 then
        // IAS
            if GetUnitAbilityLevel(u, 'DQAS') < 1 then
            call UnitAddAbility(u, 'DQAS')
            endif
        set a = BlzGetUnitAbility(u, 'DQAS')
        call BlzSetAbilityRealLevelField(a, ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1, 0, EQIDDB[eqid][5].real[20] - amount)
        call IncUnitAbilityLevel(u, 'DQAS')
        call DecUnitAbilityLevel(u, 'DQAS')
        elseif statid == 21 then
        // Attack Range
        call BlzSetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 0, BlzGetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 0) - amount)
        call BlzSetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 1, BlzGetUnitWeaponRealField(u, ConvertUnitWeaponRealField('ua1r'), 1) - amount)
        elseif statid == 25 then
        // Armor
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)-(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]))
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)+(EQIDDB[eqid][5].real[25]-amount)*(1.0+EQIDDB[eqid][5].real[26]))
        elseif statid == 33 then
        // Sight Range
        call BlzSetUnitRealField(u, ConvertUnitRealField('usir'), BlzGetUnitRealField(u, ConvertUnitRealField('usir')) - amount)
        elseif statid == 27 then
        // Evasion
            if GetUnitAbilityLevel(u, 'DQEV') < 1 then
            call UnitAddAbility(u, 'DQEV')
            call BlzUnitDisableAbility(u, 'DQEV', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEV')
            if EvasionMaxCap == -9999.0 then 
            // There is no evasion max cap
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EQIDDB[eqid][5].real[27] - amount)
            else
                if EQIDDB[eqid][5].real[27] - amount > EvasionMaxCap then
                call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EvasionMaxCap)
                else
                call BlzSetAbilityRealLevelField(a, ABILITY_RLF_CHANCE_TO_EVADE_EEV1, 0, EQIDDB[eqid][5].real[27] - amount)
                endif
            endif
            call IncUnitAbilityLevel(u, 'DQEV')
            call DecUnitAbilityLevel(u, 'DQEV')
        elseif statid == 22 then
        // Lifesteal Percent
            if EQIDDB[eqid][5].real[22] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQLS')
            else
                if GetUnitAbilityLevel(u, 'DQLS') < 1 then
                call UnitAddAbility(u, 'DQLS')
                endif
            set a = BlzGetUnitAbility(u, 'DQLS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_LIFE_STOLEN_PER_ATTACK, 0, EQIDDB[eqid][5].real[22] - amount)
            call IncUnitAbilityLevel(u, 'DQLS')
            call DecUnitAbilityLevel(u, 'DQLS')
            endif
        elseif statid == 23 then
        // Thorns flat
            if EQIDDB[eqid][5].real[23] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTF')
            else
                if GetUnitAbilityLevel(u, 'DQTF') < 1 then
                call UnitAddAbility(u, 'DQTF')
                call BlzUnitDisableAbility(u, 'DQTF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Eah1'), 0, EQIDDB[eqid][5].real[23] - amount)
            call IncUnitAbilityLevel(u, 'DQTF')
            call DecUnitAbilityLevel(u, 'DQTF')            
            endif
        elseif statid == 28 then
        // SpellDMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQEG') < 1 then
            call UnitAddAbility(u, 'DQEG')
            call BlzUnitDisableAbility(u, 'DQEG', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEG')
            if 1+EQIDDB[eqid][5].real[28] - amount < MagicDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5, 0, MagicDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MAGIC_DAMAGE_REDUCTION_DEF5, 0, 1.0 + EQIDDB[eqid][5].real[28] - amount)       
            endif
        elseif statid == 32 then
        // Movement Speed Percent
            if EQIDDB[eqid][5].real[32] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQHM')
            else
                if GetUnitAbilityLevel(u, 'DQHM') < 1 then
                call UnitAddAbility(u, 'DQHM')
                endif
            set a = BlzGetUnitAbility(u, 'DQHM')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_MOVEMENT_SPEED_INCREASE_PERCENT_UAU1, 0, EQIDDB[eqid][5].real[32] - amount)       
            call BlzUnitDisableAbility(u, 'DQHM', TRUE, TRUE)
            call UnitRemoveAbility(u, 'BDQ0')
            call BlzUnitDisableAbility(u, 'DQHM', FALSE, TRUE)
            call BlzUnitDisableAbility(u, 'BDQ0', FALSE, TRUE)
            endif
        elseif statid == 15 then
        // Melee DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTM')
            else
                if GetUnitAbilityLevel(u, 'DQTM') < 1 then
                call UnitAddAbility(u, 'DQTM')
                call BlzUnitDisableAbility(u, 'DQTM', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTM')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[15] - amount)
            call IncUnitAbilityLevel(u, 'DQTM')
            call DecUnitAbilityLevel(u, 'DQTM')
            endif
        elseif statid == 17 then
        // Ranged DMG Percent
            if EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQTS')
            else
                if GetUnitAbilityLevel(u, 'DQTS') < 1 then
                call UnitAddAbility(u, 'DQTS')
                call BlzUnitDisableAbility(u, 'DQTS', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQTS')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[13] + EQIDDB[eqid][5].real[17] - amount)
            call IncUnitAbilityLevel(u, 'DQTS')
            call DecUnitAbilityLevel(u, 'DQTS')
            endif
        elseif statid == 26 then
        // Armor Percent
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)-(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]))
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u)+(EQIDDB[eqid][5].real[25])*(1.0+EQIDDB[eqid][5].real[26]-amount))
            elseif statid == 14 then
        // Melee DMG Flat
            if EQIDDB[eqid][5].real[14] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQMF')
            else
                if GetUnitAbilityLevel(u, 'DQMF') < 1 then
                call UnitAddAbility(u, 'DQMF')
                call BlzUnitDisableAbility(u, 'DQMF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQMF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[14] - amount)
            call IncUnitAbilityLevel(u, 'DQMF')
            call DecUnitAbilityLevel(u, 'DQMF')
            endif
        elseif statid == 16 then
        // Ranged DMG Flat
            if EQIDDB[eqid][5].real[16] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQRF')
            else
                if GetUnitAbilityLevel(u, 'DQRF') < 1 then
                call UnitAddAbility(u, 'DQRF')
                call BlzUnitDisableAbility(u, 'DQRF', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQRF')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ear1'), 0, EQIDDB[eqid][5].real[16] - amount)
            call IncUnitAbilityLevel(u, 'DQRF')
            call DecUnitAbilityLevel(u, 'DQRF')
            endif
        elseif statid == 24 then
        // Thorns Pct
            if EQIDDB[eqid][5].real[24] - amount == 0.0 then
            call UnitRemoveAbility(u, 'DQSC')
            else
                if GetUnitAbilityLevel(u, 'DQSC') < 1 then
                call UnitAddAbility(u, 'DQSC')
                call BlzUnitDisableAbility(u, 'DQSC', FALSE, TRUE)
                endif
            set a = BlzGetUnitAbility(u, 'DQSC')
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts1'), 0, EQIDDB[eqid][5].real[24] - amount)
            endif
        elseif statid == 29 then
        // Melee DMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQSC') < 1 then
            call UnitAddAbility(u, 'DQSC')
            call BlzUnitDisableAbility(u, 'DQSC', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQSC')
            if 1+EQIDDB[eqid][5].real[29] - amount < MeleeDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts2'), 0, MeleeDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Uts2'), 0, 1.0 + EQIDDB[eqid][5].real[29] - amount)       
            endif
        elseif statid == 30 then
        // Pierce DMG Taken Pct
            if GetUnitAbilityLevel(u, 'DQEG') < 1 then
            call UnitAddAbility(u, 'DQEG')
            call BlzUnitDisableAbility(u, 'DQEG', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQEG')
            if 1+EQIDDB[eqid][5].real[30] - amount < PierceDMGTakenPctLowCap then
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1, 0, PierceDMGTakenPctLowCap)
            else
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_TAKEN_PERCENT_DEF1, 0, 1.0 + EQIDDB[eqid][5].real[30] - amount)       
            endif
                elseif statid == 10 then
        //Crit Chance
            if GetUnitAbilityLevel(u, 'DQCS') < 1 then
            call UnitAddAbility(u, 'DQCS')
            call BlzUnitDisableAbility(u, 'DQCS', FALSE, TRUE)
            set a = BlzGetUnitAbility(u, 'DQCS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2, 0,  DefaultCritMultiplier + EQIDDB[eqid][5].real[11])
            endif
        set a = BlzGetUnitAbility(u, 'DQCS')
        call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('Ocr1'), 0, EQIDDB[eqid][5].real[10] - amount)
        elseif statid == 11 then
        //Crit DMG
            if GetUnitAbilityLevel(u, 'DQCS') < 1 then
            else
            set a = BlzGetUnitAbility(u, 'DQCS')
            call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DAMAGE_MULTIPLIER_OCR2, 0,  DefaultCritMultiplier + EQIDDB[eqid][5].real[11] - amount)
            endif
        elseif statid == 18 then
        //Cleave Pct
            if GetUnitAbilityLevel(u, 'DQCL') < 1 then
            call UnitAddAbility(u, 'DQCL')
            call BlzUnitDisableAbility(u, 'DQCL', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQCL')
        call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DISTRIBUTED_DAMAGE_FACTOR_NCA1, 0, EQIDDB[eqid][5].real[18] - amount)
        elseif statid == 19 then
        //Cleave Area
            if GetUnitAbilityLevel(u, 'DQCL') < 1 then
            call UnitAddAbility(u, 'DQCL')
            call BlzUnitDisableAbility(u, 'DQCL', FALSE, TRUE)
            endif
        set a = BlzGetUnitAbility(u, 'DQCL')
        call BlzSetAbilityRealLevelField(a, ConvertAbilityRealLevelField('aare'), 0, CleaveBaseArea + EQIDDB[eqid][5].real[19] - amount)
        elseif statid == 34 then
        // Inventory Space
        set auxr = EQIDDB[eqid][5].real[statid] - amount
        set auxi = R2I(EQIDDB[eqid][5].real[statid]) - R2I(auxr)
        call DInvDeltaAdditionalSlotsForUnit(u, -auxi)
        endif

    set EQIDDB[eqid][5].real[statid] = EQIDDB[eqid][5].real[statid] - amount

    endif
set statid = statid +1
exitwhen statid > DEqStatsCounter
endloop

set i = 0
set statid = 1
loop
exitwhen DEqSetDB[setID][2][margin].integer[statid] == 0
set i = i + 1
set tabl.integer[DEqSetDB[setID][2][margin].integer[statid]] = DEqSetDB[setID][3][margin].integer[statid]
set ia[i] = DEqSetDB[setID][2][margin].integer[statid]

set auxi = FindUnitDEqAbilitySerial(uhndl, DEqSetDB[setID][2][margin].integer[statid])
set EQIDDB[eqid][6].integer[auxi] = DEqSetDB[setID][2][margin].integer[statid]

set statid = statid + 1
endloop

set i = 1
loop
exitwhen ia[i] == 0

set auxi = FindUnitDEqAbilitySerial(uhndl, ia[i])
set amount = I2R(tabl.integer[ia[i]])

call DEqDUAL(u, uhndl, ia[i], R2I(-amount), i)

set i = i +1
endloop

set u = null
endfunction



function DEqDecreaseSetEquippedOnUnit takes unit u, integer setID returns nothing
local integer uhndl = GetHandleId(u)
local integer eqid = DInvUnitHandleDB[uhndl][0].integer[3]
local integer currSetLvl = EQIDDB[eqid][9].integer[setID]
local integer previousSetMargin = DEqGetPreviousSetMarginLvl(setID, currSetLvl)
if previousSetMargin == currSetLvl then
call DEqSubtractSetStats(u, setID, previousSetMargin)
endif
set EQIDDB[eqid][9].integer[setID] = EQIDDB[eqid][9].integer[setID] - 1
call RegenSetToolTip(GetPlayerId(GetOwningPlayer(u)), uhndl, setID)
set u = null
endfunction



function DEqIncreaseSetEquippedOnUnit takes unit u, integer setID returns nothing
local integer uhndl = GetHandleId(u)
local integer eqid = DInvUnitHandleDB[uhndl][0].integer[3]
local integer currSetLvl = EQIDDB[eqid][9].integer[setID]
local integer nextSetMargin = DEqGetNextSetMarginLvl(setID, currSetLvl)
set EQIDDB[eqid][9].integer[setID] = EQIDDB[eqid][9].integer[setID] + 1
if nextSetMargin == currSetLvl+1 then
call DEqGrantSetStats(u, setID, nextSetMargin)
endif
call RegenSetToolTip(GetPlayerId(GetOwningPlayer(u)), uhndl, setID)
set u = null
endfunction



function UnequipDEqItemToDInvSlot takes integer pid, integer bid, integer eqid, unit u, integer uhndl, item it, integer dInvSlotId, integer deqslot returns boolean
local integer iid = GetItemTypeId(it)
local integer lp = GetPlayerId(GetLocalPlayer())
local integer dInvFrameId = DItemSlotId2SlotFrameId(pid, dInvSlotId)
local integer sid = DEqIsItemASetItem(it)

if sid == 0 then
else
call DEqDecreaseSetEquippedOnUnit(u, sid)
endif
call RemoveDEqStatsOfItemFromUnit(pid, eqid, deqslot, it, u)

call StoreItemForPIDBID(it, pid, bid, eqid)
set DInvItemHandleDB[GetHandleId(it)].integer[4] = 0
call EQIDDB[eqid][4].item.remove(deqslot)

if u == DEqCurrentUnit[pid] then
//call BJDebugMsg("UnequipDEqItemToDInvSlot u is current")
call DEqSlotDataIntoFrame(pid, uhndl, deqslot)
endif

call UpdateDEqCSheet(pid, u, uhndl, eqid)
set it = null
set u = null
return TRUE
endfunction


    
function EquipDInvItemToDEqSlot takes integer pid, integer bid, integer eqid, unit u, integer uhndl, item it, integer dInvSlotId, integer deqslot returns boolean
// Warning: This does not check if the unit is eligible to equip an item (satisfies stat requirements, etc). Use DEqCanUnitEquipItemInSlot before this
// Warning: Unit will not equip a 2h item if it can not unequip the offhand because there is no free DInventory space, so guard against that scenario outside the function
local integer iid = GetItemTypeId(it)
local integer lp = GetPlayerId(GetLocalPlayer())
local integer dInvFrameId = DItemSlotId2SlotFrameId(pid, dInvSlotId)
local integer uneqDInvSlot = 0
local boolean uneqWasSuccess = TRUE
local integer auxi = 0
local integer sid = DEqIsItemASetItem(it)

//call BJDebugMsg("EquipDInvItemToDEqSlot started")

// if 19 is 2handed, unequip 20
if deqslot == 19 then
    if DEqItemTypeDefinitionDB[iid][0].integer[1] == 1 then
    // Weapon is 2handed
        if EQIDDB[eqid][4].item[20] == null then
        // no item in offhand
        else
            if GetUnitAbilityLevel(u, 'DQTG') > 0 then
            //Unit has Titan's grip
            else
            //Unequip offhand to DInv
            set uneqDInvSlot = FirstFreeDInvSlotOfBID(pid, bid)
                if uneqDInvSlot == -1 then
                // Abort process if there is no space in DInv
                set u = null
                set it = null
                return FALSE
                endif
            
                // This Unequips slot 20:
                set uneqWasSuccess = UnequipDEqItemToDInvSlot(pid, bid, eqid, u, uhndl, EQIDDB[eqid][4].item[20], uneqDInvSlot, 20)

                    if uneqWasSuccess == FALSE then
                    set u = null
                    set it = null
                    return FALSE
                    endif
        
                if lp == pid then
                // Set DEq slot frame icon to slot20 disabled icon
                    if eqid == CurrentEQId[pid] then
                    call DEqSlotDataIntoFrame(pid, uhndl, deqslot+1)
                    //call BlzFrameSetTexture(EquipmentSlotButtonIconFrame[pid*20+deqslot+1], Slot20ForbiddenTexture, 0, TRUE)
                    endif
                    //Update DInv UI
                    if u == DInvCurrentUnit[pid] and DItemSlotId2SlotFrameId(pid, uneqDInvSlot) > -1 then
                    call DInvSlotDataIntoFrame(pid, bid, uneqDInvSlot, DItemSlotId2SlotFrameId(pid, uneqDInvSlot))
                    endif
                endif
            endif
        endif
    else
    // Weapon is not 2handed
    endif
else
//not slot 19
endif


// if trying to equip offhand while 19 is 2handed, unequip 19
    if deqslot == 20 then
//call BJDebugMsg("deqslot is 20")
        if EQIDDB[eqid][4].item[19] == null then
        // no item in mainhand, do nothing
//call BJDebugMsg("no item in MH")
        else
//call BJDebugMsg("found item in MH")
        // there is a mainhand item
        set auxi = GetItemTypeId(EQIDDB[eqid][4].item[19])
            if DEqItemTypeDefinitionDB[auxi][0].integer[1] == 1 and GetUnitAbilityLevel(u, 'DQTG') == 0 then
//call BJDebugMsg("found 2handed item in MH")
            // MH Weapon is 2handed
            set uneqDInvSlot = FirstFreeDInvSlotOfBID(pid, bid)
                if uneqDInvSlot == -1 then
                // Abort process if there is no space in DInv
                set u = null
                set it = null
                return FALSE
                endif
                
            // This Unequips slot 19:
//call BJDebugMsg("Unequipping offhand")
            set uneqWasSuccess = UnequipDEqItemToDInvSlot(pid, bid, eqid, u, uhndl, EQIDDB[eqid][4].item[19], uneqDInvSlot, 19)
            
                if uneqWasSuccess == FALSE then
//call BJDebugMsg("Unequipping offhand failed")
                set u = null
                set it = null
                return FALSE
                endif
//call BJDebugMsg("Unequipping offhand success")
            
                if lp == pid then
                //Update DInv UI
                    if eqid == CurrentEQId[pid] and DItemSlotId2SlotFrameId(pid, uneqDInvSlot) > -1 then
                    call DInvSlotDataIntoFrame(pid, bid, uneqDInvSlot, DItemSlotId2SlotFrameId(pid, uneqDInvSlot))
                    endif
                endif
            endif
        endif
    else
    //not slot 20
    endif

/*
if EQIDDB[eqid][4].item[deqslot] == null then
// no item
else
//Unequip
set uneqDInvSlot = FirstFreeDInvSlotOfBID(pid, hid)
    if uneqDInvSlot == -1 then
    // Abort process if there is no space in DInv
    set u = null
    set it = null
    return FALSE
    endif
//Unequip
UnequipDEqItemToDInvSlot(pid, hid, eqid, u, uhndl, EQIDDB[eqid][4].item[deqslot], uneqDInvSlot, deqslot)
endif
*/

// Save equipment and its stats in the DB
set EQIDDB[eqid][4].item[deqslot] = it
// Grant equipment's stats
if sid == 0 then
else
call DEqIncreaseSetEquippedOnUnit(u, sid)
endif
call AddDEqStatsOfItemToUnit(pid, eqid, deqslot, it, u)
set DInvItemHandleDB[GetHandleId(DInventoryDB[bid].item[dInvSlotId])].integer[4] = deqslot
call DInventoryDB[bid].item.remove(dInvSlotId)
call DEqSlotDataIntoFrame(pid, uhndl, deqslot)

//Update Equipment UI
//Update DInv UI
if u == DInvCurrentUnit[pid] and DItemSlotId2SlotFrameId(pid, dInvSlotId) > -1 then
//call BJDebugMsg("EquipDInvItemToDEqSlot u is current")
call DInvSlotDataIntoFrame(pid, bid, dInvSlotId, dInvFrameId)
endif

//call BJDebugMsg("EquipDInvItemToDEqSlot finished")

call UpdateDEqCSheet(pid, u, uhndl, eqid)
set it = null
set u = null
return TRUE
endfunction



function DEqDInvSwap takes integer eqid, integer dEqSlotId, integer pid, integer bid, integer dInvSlotId returns nothing
local integer bufferindex = 1
local item itembuffer = DInventoryDB[bid].item[dInvSlotId]

// Remove stats
// NEEDTODO

endfunction



function UnitDEqDInvSwap takes unit u, integer dEqSlotId, integer dInvSlotId returns nothing
local integer pid = GetPlayerId(GetOwningPlayer(u))
local integer bid = BIDOfUnit(u)
local integer eqid = EQIDOfUnit(u)
set u = null
call DEqDInvSwap(eqid, dEqSlotId, pid, bid, dInvSlotId)
endfunction

// Added by Valdemar 27.9.2025
function GetUnitItemChargesByType takes unit u, integer itemTypeId returns integer
    local integer totalCharges = 0
    local integer i = 0
    local item it

    loop
        exitwhen i >= UnitInventorySize(u) // Iterate through all inventory slots
        set it = UnitItemInSlot(u, i)
        if it != null and GetItemTypeId(it) == itemTypeId then
            set totalCharges = totalCharges + GetItemCharges(it) // Add charges if item matches
        endif
        set i = i + 1
    endloop

    return totalCharges
endfunction

// Updated function to get total charges of an item type in the custom inventory system
function GetDInvItemChargesByType takes unit u, integer itemTypeId returns integer
    local integer totalCharges = 0
    local integer slotId = 0
    local integer bid = BIDOfUnit(u) // Get the bag ID for the unit
    local integer maxCapacity = MaxDInvCapacityOfUnit(u) // Get the max capacity of the unit's inventory
    local item it

    if bid == -1 then
        // The unit does not have a valid inventory
        return 0
    endif

    loop
        exitwhen slotId >= maxCapacity // Iterate through all slots in the custom inventory
        set it = DInventoryDB[bid].item[slotId]
        if it != null and GetItemTypeId(it) == itemTypeId then
            set totalCharges = totalCharges + GetItemCharges(it) // Add charges if item matches
        endif
        set slotId = slotId + 1
    endloop

    return totalCharges
endfunction

// New function to get total charges of an item type in the custom inventory system, stopping if a threshold is met
function GetDInvItemChargesByTypeThreshold takes unit u, integer itemTypeId, integer threshold returns boolean
    local integer totalCharges = 0
    local integer slotId = 0
    local integer bid = BIDOfUnit(u) // Get the bag ID for the unit
    local integer maxCapacity = MaxDInvCapacityOfUnit(u) // Get the max capacity of the unit's inventory
    local item it

    if bid == -1 then
        // The unit does not have a valid inventory
        return false
    endif

    call TriggerSleepAction(0.05)

    loop
        exitwhen slotId >= maxCapacity // Iterate through all slots in the custom inventory
        set it = DInventoryDB[bid].item[slotId]
        if it != null and GetItemTypeId(it) == itemTypeId then
            set totalCharges = totalCharges + GetItemCharges(it) // Add charges if item matches
            if totalCharges >= threshold then
                return true // Return true if threshold is met
            endif
        endif
        set slotId = slotId + 1
    endloop

    // Return false if threshold is not met
    return false 
endfunction

/* Example usage of get item charges by type:
local integer charges = GetDInventoryItemChargesByType(udg_TempUnit, 'I000')
call BJDebugMsg("Total charges of item type: " + I2S(charges))
*/


private function Init takes nothing returns nothing
endfunction
    
endlibrary