library DEqGrowthItemDefinitions initializer Init requires DEqGrowthItem

function DEqPreDefineGrowthItemsHere takes nothing returns nothing
call DestroyTimer(GetExpiredTimer())
endfunction

private function Init takes nothing returns nothing
call TimerStart(CreateTimer(), 0.1, FALSE, function DEqPreDefineGrowthItemsHere)
endfunction

endlibrary