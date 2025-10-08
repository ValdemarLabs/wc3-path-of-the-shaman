library DEqSetItemDefinitions initializer Init requires DEqSetItem

function DEqPreDefineSetItemsHere takes nothing returns nothing
call DestroyTimer(GetExpiredTimer())

/*

// Crown Jewels
call DEqDeclareItemSet(1, "Crown Jewels") //IMPORTANT: 1 here is the serial number of the set
call DEqAddSetMargin(1, 2) //1 here is the serial number of the set. 2 here means: there is a set bonus when at least 2 items of the set are equipped.
call DEqAddSetBonusByStatName(1, 2, "Armor", 6.5)
call DEqAddSetBonusByStatID(1, 2, 1, 10)

// Illustrious Set of Testing
call DEqDeclareItemSet(2, "Illustrious Set of Testing")
call DEqAddSetMargin(2, 2) //This means there is a set bonus when at least 2 items of the set are equipped
call DEqAddSetBonusByStatName(2, 2, "INT", 6)
call DEqAddSetBonusAbility(2, 2, 'ACmf', 1)
call DEqAddSetMargin(2, 4) //This means there is a set bonus when at least 4 items of the set are equipped
call DEqAddSetBonusByStatName(2, 4, "INT", 3)
call DEqAddSetBonusByStatName(2, 4, "Mana", 100)
call DEqAddSetMargin(2, 6) //This means there is a set bonus when at least 6 items of the set are equipped
call DEqAddSetBonusByStatName(2, 6, "Mana", 50)
call DEqAddSetBonusByStatID(2, 6, 8, 1.5)
// IMPORTANT: always define these margins in an ascending numerical order.

// Paradox
call DEqDeclareItemSet(3, "Paradox") //IMPORTANT: 3 here is the serial number of the set
call DEqAddSetMargin(3, 2) //3 here is the serial number of the set. 2 here means: there is a set bonus when at least 2 items of the set are equipped.
call DEqAddSetBonusByStatName(3, 2, "Armor", -10)
call DEqAddSetBonusByStatID(3, 2, 1, 10)
call DEqAddSetBonusByStatName(3, 2, "Pierce DMG Taken Pct", -0.2)
call DEqAddSetBonusAbility(3, 2, 'ACbh', 1)

*/

endfunction

private function Init takes nothing returns nothing
call TimerStart(CreateTimer(), 0.1, FALSE, function DEqPreDefineSetItemsHere)
endfunction

endlibrary