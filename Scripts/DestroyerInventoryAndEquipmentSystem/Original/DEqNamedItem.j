library DEqNamedItem initializer Init requires DEquipment

function DEqGetNidOfIid takes integer iid, string name returns integer
local integer i = 1
local string cn = NamedItemTypeDB[iid][i][0].string[1]
loop
set cn = NamedItemTypeDB[iid][i][0].string[1]
exitwhen cn == name or cn == null
set i = i + 1
endloop
//call TriggerSleepAction(0.1)
//call BJDebugMsg("s1 "+NamedItemTypeDB[iid][1][0].string[1])
//call BJDebugMsg("s2 "+NamedItemTypeDB[iid][2][0].string[1])
//call BJDebugMsg("s3 "+NamedItemTypeDB[iid][3][0].string[1])
return i
endfunction



function DEqNamedItemDefineIcon takes integer iid, string name, string icon returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
set NamedItemTypeDB[iid][nid][0].string[3] = icon
endfunction



function DEqNamedItemDefineAsSet takes integer iid, string name, integer setID returns nothing
// This will make all named items of this name be set items of the set with the ID of setID
// You can define sets in DEqSetItemDefinitions
// You can assign a setID to 1.) Item Types 2.) Named Items 3.) Individual items
// The system only handles 1 set per item. You can not have an item with multiple sets.
// If you are a little funny bunny, and for some reason define a setID for 1. 2. and 3. then the system will check them in this sequence: 3., 2., 1. If it finds a setID, it will not check the next.
// In other words, if you had an item type that you defined as a set item, but for some reason you also made that individual item part of another set, then the individual item setID will be active.
local integer nid = DEqGetNidOfIid(iid, name)
set NamedItemTypeDB[iid][nid][0].integer[1] = setID
endfunction



function DEqNamedItemDefineReqHeroLevel takes integer iid, string name, integer hlvl returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
// If you also set the level requirement of an existing item during the game, then that will overwrite this requirement
set NamedItemTypeDB[iid][nid][0].integer[0] = hlvl
endfunction



function DEqNamedItemDefineReqClass takes integer iid, string name, integer uid returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
//By default all classes may equip an item.
//Adding a required class will make only the required classes able to equip the item
//Adding forbidden classes only do anything if there are no required classes configured
local integer loopi = 1
loop
exitwhen NamedItemTypeDB[iid][nid][1].integer[loopi] == 0
set loopi = loopi + 1
endloop
set NamedItemTypeDB[iid][nid][1].integer[loopi] = uid
endfunction



function DEqNamedItemDefineReqClassForbiddden takes integer iid, string name, integer uid returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
//By default all classes may equip an item.
//Adding a required class will make only the required classes able to equip the item
//Adding forbidden classes only do anything if there are no required classes configured
local integer loopi = 1
loop
exitwhen NamedItemTypeDB[iid][nid][2].integer[loopi] == 0
set loopi = loopi + 1
endloop
set NamedItemTypeDB[iid][nid][2].integer[loopi] = uid
endfunction



function DEqNamedItemDefineReqAbility takes integer iid, string name, integer abid, integer ablev returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
//By default there are no ability based restrictions.
//Adding a required ability will make only units with the required ability and its level able to equip the item
//Adding forbidden abilities only do anything if there are no required abilities configured
local integer loopi = 1
loop
exitwhen NamedItemTypeDB[iid][nid][3].integer[loopi] == 0
set loopi = loopi + 1
endloop
set NamedItemTypeDB[iid][nid][3].integer[loopi] = abid
set NamedItemTypeDB[iid][nid][4].integer[loopi] = ablev
endfunction



function DEqNamedItemDefineReqAbilityForbiddden takes integer iid, string name, integer abid, integer ablev returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
//By default there are no ability based restrictions.
//Adding a required ability will make only units with the required ability and its level able to equip the item
//Adding forbidden abilities only do anything if there are no required abilities configured
local integer loopi = 1
loop
exitwhen NamedItemTypeDB[iid][nid][5].integer[loopi] == 0
set loopi = loopi + 1
endloop
set NamedItemTypeDB[iid][nid][5].integer[loopi] = abid
set NamedItemTypeDB[iid][nid][6].integer[loopi] = ablev
endfunction



function DEqNamedItemDefineReqStatById takes integer iid, string name, integer statid, real amount returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
//Defines what stats are required to equip the item
//These are the same stats that you named and stored in DEqStatNames
//Could be Strength, MaxMana, etc.
//They are checked in function
set NamedItemTypeDB[iid][nid][8].real[statid] = amount
endfunction



function DEqNamedItemDefineReqStatByName takes integer iid, string name, string statname, real amount returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
//Defines what stats are required to equip the item
//These are the same stats that you named and stored in DEqStatNames
//Could be Strength, MaxMana, etc.
//They are checked in function
call DEqNamedItemDefineReqStatById(iid, name, DEqStatNameToStatId(statname), amount)
endfunction



function DEqNamedItemDefineStatGrantedById takes integer iid, string name, integer statid, real amount returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
set NamedItemTypeDB[iid][nid][10].real[statid] = amount
set NamedItemTypeDB[1][1][10].real[1] = 1337
//call BJDebugMsg("NamedItemTypeDB[iid][nid][10].real[statid] "+R2S(NamedItemTypeDB[iid][nid][10].real[statid]))
//call TriggerSleepAction(0.1)
//call BJDebugMsg("NamedItemTypeDB[iid][nid][10].real[statid] "+R2S(NamedItemTypeDB[iid][nid][10].real[statid]))
endfunction



function DEqNamedItemDefineStatGrantedByName takes integer iid, string name, string statname, real amount returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
call DEqNamedItemDefineStatGrantedById(iid, name, DEqStatNameToStatId(statname), amount)
endfunction



function DEqNamedItemDefineAbilityGranted takes integer iid, string name, integer abid, integer ablev returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
local integer loopi = 1
loop
exitwhen NamedItemTypeDB[iid][nid][7].integer[loopi] == 0
set loopi = loopi + 1
endloop
set NamedItemTypeDB[iid][nid][7].integer[loopi] = abid
set NamedItemTypeDB[iid][nid][11].integer[loopi] = ablev
endfunction



function DEqNamedItemDefineGoldX takes integer iid, string name, real gx returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
set NamedItemTypeDB[iid][nid][0].real[2] = gx
endfunction


/*
function DEqDefineNamedItem takes integer iid, string name returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
local string s = name
call BJDebugMsg("DEqDefineNamedItem nid: "+I2S(nid))
call BJDebugMsg("DEqDefineNamedItem name: "+s)
set NamedItemTypeDB[iid][nid][0].string[1] = s
call BJDebugMsg(NamedItemTypeDB[iid][nid][0].string[1])
//set NamedItemTypeDB[1835823988][3][10].string[102] = "yolo2"

call TriggerSleepAction(0.2)
call BJDebugMsg(NamedItemTypeDB[iid][nid][0].string[1])
endfunction
*/

function DEqDefineNamedItem takes integer iid, string name returns nothing
local integer nid = DEqGetNidOfIid(iid, name)
//call BJDebugMsg("DEqDefineNamedItem nid: "+I2S(nid))
//call BJDebugMsg("DEqDefineNamedItem name: "+name)
set NamedItemTypeDB[iid][nid][0].string[1] = name
//call BJDebugMsg(NamedItemTypeDB[iid][nid][0].string[1])

//call TriggerSleepAction(0.2)
//call BJDebugMsg(NamedItemTypeDB[iid][nid][0].string[1])
endfunction


function DEqMakeItemNamed takes item it, string n returns nothing
local integer ihndl = GetHandleId(it)
local integer tid = DInvItemHandleDB[ihndl].integer[5]
local integer pid = DInvItemHandleDB[ihndl].integer[0] - 1
local integer bid = 0
local unit u = DInvWhichUnitHasItem(it)
local integer uhndl = GetHandleId(u)
local integer eqid = 0
local integer deqslot = 0
local integer lp = GetPlayerId(GetLocalPlayer())
local integer iid = GetItemTypeId(it)
local integer nid = DEqGetNidOfIid(iid, n)
//call BJDebugMsg("DEqMakeItemNamed nid "+I2S(nid))
if tid == 0 then
// Assign a trove ID
set TroveCounter = TroveCounter + 1
set tid = TroveCounter
set DInvItemHandleDB[ihndl].integer[5] = tid
set DEqTroveDB[tid][0].integer[7] = ihndl
endif

//call BJDebugMsg("DEqMakeItemNamed tid "+I2S(tid))
// check if item is with any player:
if pid > -1 then
// Needtodo: check if item is already equipped, if yes, unequip; set rarity; equip
set deqslot = DInvItemHandleDB[ihndl].integer[4]
    // Check if item is equipped in any slot
    if deqslot > 0 then
    set eqid = DInvUnitHandleDB[uhndl][0].integer[3]
    call RemoveDEqStatsOfItemFromUnit(pid, eqid, deqslot, it, u)
        if DEqTroveDB[tid][0].integer[8] == 0 then
        set DEqTroveDB[tid][0].integer[8] = nid
        call BlzSetItemName(it, n)
        call BlzSetItemIconPath(it, NamedItemTypeDB[iid][nid][0].string[3])
        endif
    call AddDEqStatsOfItemToUnit(pid, eqid, deqslot, it, u)
        if u == DEqCurrentUnit[pid] then
            if lp == pid then
            call DEqSlotDataIntoFrame(pid, uhndl, deqslot)
            // NEEDTODO: Update DEq outline
            endif
        endif
    else
    // item is in the DInv
    set bid = BIDOfUHndl(uhndl)
        if DEqTroveDB[tid][0].integer[8] == 0 then
        set DEqTroveDB[tid][0].integer[8] = nid
        call BlzSetItemName(it, n)
        call BlzSetItemIconPath(it, NamedItemTypeDB[iid][nid][0].string[3])
        endif
    set deqslot = DInvItemHandleDB[ihndl].integer[2]
        if u == DInvCurrentUnit[pid] then
            if lp == pid then
            call DInvSlotDataIntoFrame(pid, bid, deqslot, SlotFrameId2DItemSlotId(pid, deqslot))
            // NEEDTODO: Update DInv outline
            endif
        endif
    endif
else
// item is not with any player
//call BJDebugMsg("DEqMakeItemNamed fu")
set DEqTroveDB[tid][0].integer[8] = nid
call BlzSetItemName(it, n)
call BlzSetItemIconPath(it, NamedItemTypeDB[iid][nid][0].string[3])
//call BJDebugMsg("DEqMakeItemNamed fu2")
endif

// NEEDTODO: apply named item effects
// Needtodo: Add random affixes
set u = null
set it = null
//call BJDebugMsg("DEqMakeItemNamed over")
endfunction



private function Init takes nothing returns nothing
set DEqNamedItemModuleUsed = TRUE
endfunction

endlibrary