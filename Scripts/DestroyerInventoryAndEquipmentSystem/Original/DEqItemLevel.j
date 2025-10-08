library DEqItemLevel initializer Init requires DEquipment

function DEqSetItemLevelOfItem takes item it, integer ilvl returns nothing
local integer ihndl = GetHandleId(it)
local integer tid = DInvItemHandleDB[ihndl].integer[5]
local integer pid = DInvItemHandleDB[ihndl].integer[0] - 1
local integer bid = 0
local unit u = DInvWhichUnitHasItem(it)
local integer uhndl = GetHandleId(u)
local integer eqid = 0
local integer deqslot = 0
local integer lp = GetPlayerId(GetLocalPlayer())
if tid == 0 then
// Assign a trove ID
set TroveCounter = TroveCounter + 1
set tid = TroveCounter
set DInvItemHandleDB[ihndl].integer[5] = tid
set DEqTroveDB[tid][0].integer[7] = ihndl
endif

// check if item is with any player:
if pid > -1 then
// Needtodo: check if item is already equipped, if yes, unequip; set rarity; equip
set deqslot = DInvItemHandleDB[ihndl].integer[4]
    // Check if item is equipped in any slot
    if deqslot > 0 then
    set eqid = DInvUnitHandleDB[uhndl][0].integer[3]
    call RemoveDEqStatsOfItemFromUnit(pid, eqid, deqslot, it, u)
    set DEqTroveDB[tid][0].integer[2] = ilvl
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
    set DEqTroveDB[tid][0].integer[2] = ilvl
    set deqslot = DInvItemHandleDB[ihndl].integer[2]
        if u == DInvCurrentUnit[pid] then
            if lp == pid then
            call DInvSlotDataIntoFrame(pid, bid, deqslot, SlotFrameId2DItemSlotId(pid, deqslot))
            // NEEDTODO: Update DInv outline
            endif
        endif
    endif
else
// Item is not with any player
set DEqTroveDB[tid][0].integer[2] = ilvl
endif

set u = null
set it = null
endfunction



private function Init takes nothing returns nothing
set DEqItemLevelModuleUsed = TRUE
endfunction

endlibrary