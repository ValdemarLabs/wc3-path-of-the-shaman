library DDropTableDefinitions initializer Init requires DPersonalLootSys
// DEquipment is not required if you are not using it

function DEqPreDefineDropTablesHere takes nothing returns nothing
call DestroyTimer(GetExpiredTimer())

endfunction

private function Init takes nothing returns nothing
call TimerStart(CreateTimer(), 0.1, FALSE, function DEqPreDefineDropTablesHere)
endfunction

endlibrary