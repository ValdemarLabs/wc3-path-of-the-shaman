library DEqItemLevelDefinitions initializer Init requires DEqItemLevel

function DEqPreDefineItemLevelsHere takes nothing returns nothing
// If a lvl1 item gives 100 HP, and this variable is set to 0.05, then a lvl51 item will provide 1+50*0.05 times, in other words 2.5 times as much stats, in other words 350 HP instead of 100.
set DEqIlvlStatX = 0.05
set DEqIlvlGoldX = 0.05

call DestroyTimer(GetExpiredTimer())
endfunction

private function Init takes nothing returns nothing
call TimerStart(CreateTimer(), 0.1, FALSE, function DEqPreDefineItemLevelsHere)
endfunction

endlibrary