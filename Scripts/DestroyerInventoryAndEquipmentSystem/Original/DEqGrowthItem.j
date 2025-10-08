library DEqGrowthItem initializer Init requires DEquipment

function DefineGrowthCreditNeeded takes integer gid, integer lvl, integer req returns nothing
set GrowthDB[gid][1].integer[lvl] = req
endfunction



function DefineGrowthText takes integer gid, integer lvl, string txt returns nothing
set GrowthDB[gid][0].string[lvl] = txt
endfunction



function DEqGetGrowthLevel takes item it returns integer
return DEqTroveDB[DInvItemHandleDB[GetHandleId(it)].integer[5]][0].integer[5]
endfunction



function DEqSetGrowthLevel takes item it, integer lvl returns nothing
set DEqTroveDB[DInvItemHandleDB[GetHandleId(it)].integer[5]][0].integer[5] = lvl
endfunction



function DEqIcreaseGrowthLevel takes item it returns nothing
local integer tid = DInvItemHandleDB[GetHandleId(it)].integer[5]
// NEEDTODO: this needs to take into consideration the possibility of jumping more than 1 lvls??
//make the levelups 1 by 1, then at the very end check if GrowthCredit warrants another levelup, and then recursively call the function again
set DEqTroveDB[tid][0].integer[5] = DEqTroveDB[tid][0].integer[5] + 1
// Remember to remove the xp at levelup
// Refresh tooltip if dinv is open, including DEq UI
//
set it = null
endfunction



function DEqGetGrowthCredit takes item it returns integer
return DEqTroveDB[DInvItemHandleDB[GetHandleId(it)].integer[5]][0].integer[4]
endfunction



function DEqSetGrowthCredit takes item it, integer xp returns nothing
local integer ihndl = GetHandleId(it)
local integer tid = DInvItemHandleDB[ihndl].integer[5]
local integer glvl = DEqTroveDB[tid][0].integer[5]
local integer gid = DEqTroveDB[tid][0].integer[6]
set DEqTroveDB[tid][0].integer[4] = xp
if DEqTroveDB[tid][0].integer[4] < GrowthDB[gid][1].integer[glvl] then
// do nothing
else
call DEqIcreaseGrowthLevel(it)
endif
endfunction



function DEqDeltaGrowthCredit takes item it, integer deltaxp returns nothing
local integer ihndl = GetHandleId(it)
local integer tid = DInvItemHandleDB[ihndl].integer[5]
local integer glvl = DEqTroveDB[tid][0].integer[5]
local integer gid = DEqTroveDB[tid][0].integer[6]
set DEqTroveDB[tid][0].integer[4] = DEqTroveDB[tid][0].integer[4] + deltaxp
if DEqTroveDB[tid][0].integer[4] < GrowthDB[gid][1].integer[glvl] then
// do nothing
else
call DEqIcreaseGrowthLevel(it)
endif
endfunction



private function Init takes nothing returns nothing
set DEqGrowthItemModuleUsed = TRUE
endfunction

endlibrary