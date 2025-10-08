library DEqSetItem initializer Init requires DEquipment

function DEqDeclareItemSet takes integer setID, string setName returns nothing
set DEqSetDB[setID][0][0].string[0] = setName
endfunction



function DEqAddSetMargin takes integer setID, integer numberOfItems returns nothing
local integer i = 1
loop
exitwhen DEqSetDB[setID][0][0].integer[i] == 0
set i = i + 1
endloop

set DEqSetDB[setID][0][0].integer[i] = numberOfItems

if numberOfItems > DEqSetDB[setID][0][1].integer[0] then
set DEqSetDB[setID][0][1].integer[0] = numberOfItems
endif
endfunction



function DEqAddSetBonusByStatID takes integer setID, integer threshold, integer statID, real amount returns nothing
set DEqSetDB[setID][1][threshold].real[statID] = amount
endfunction



function DEqAddSetBonusAbility takes integer setID, integer threshold, integer abID, integer amount returns nothing
local integer i = 1
loop
exitwhen DEqSetDB[setID][2][threshold].integer[i] == 0
set i = i + 1
endloop
set DEqSetDB[setID][2][threshold].integer[i] = abID
set DEqSetDB[setID][3][threshold].integer[i] = amount
endfunction



function DEqAddSetBonusByStatName takes integer setID, integer threshold, string statName, real amount returns nothing
set DEqSetDB[setID][1][threshold].real[DEqStatNameToStatId(statName)] = amount
endfunction




function DEqConvertTID2Set takes integer tid, integer setID returns nothing
set DEqTroveDB[tid][0].integer[10] = setID
endfunction



function DEqConvertItem2Set takes item it, integer setID returns nothing
local integer tid = DInvItemHandleDB[GetHandleId(it)].integer[5]
if tid == 0 then 
call AddItemToTroveId(it)
endif
set it = null
call DEqConvertTID2Set(tid, setID)
endfunction



private function Init takes nothing returns nothing
set SetItemModuleUsed = TRUE
endfunction

endlibrary