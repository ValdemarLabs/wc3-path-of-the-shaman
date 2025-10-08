library DEqNamedItemDefinitions initializer Init requires DEqNamedItem

globals
trigger trg_DEqPreDefineNamedItemsHere = CreateTrigger()
endglobals

function DEqPreDefineNamedItemsHere takes nothing returns nothing
call DEqDefineNamedItem('mlst', "Ignorance")
call DEqNamedItemDefineStatGrantedByName('mlst', "Ignorance", "INT", -10.0)
call DEqNamedItemDefineAbilityGranted('mlst', "Ignorance", 'AHbh', 1)
call DEqNamedItemDefineGoldX('mlst', "Ignorance", 2.0)

call DEqDefineNamedItem('mlst', "Bliss")
call DEqNamedItemDefineStatGrantedByName('mlst', "Bliss", "HP", -100.0)
call DEqNamedItemDefineAbilityGranted('mlst', "Bliss", 'AHbz', 1)
call DEqNamedItemDefineGoldX('mlst', "Bliss", 2.0)

call DEqDefineNamedItem('mlst', "Unstoppable Force")
call DEqNamedItemDefineIcon('mlst', "Unstoppable Force", "ReplaceableTextures\\CommandButtons\\BTNTransmute.blp")
call DEqNamedItemDefineStatGrantedByName('mlst', "Unstoppable Force", "STR", 10.0)
call DEqNamedItemDefineAbilityGranted('mlst', "Unstoppable Force", 'AHbh', 2)
call DEqNamedItemDefineGoldX('mlst', "Unstoppable Force", 3.0)

call DEqDefineNamedItem('fwss', "Immovable Object")
call DEqNamedItemDefineStatGrantedByName('fwss', "Immovable Object", "MoveSPD Pct", -0.2)
call DEqNamedItemDefineStatGrantedByName('fwss', "Immovable Object", "Melee DMG Taken Pct", -0.2)
call DEqNamedItemDefineGoldX('fwss', "Immovable Object", 3.0)

//Also adding these to set serial number 3, aka "Paradox", as defined in the DEqSetItemDefinitions
call DEqNamedItemDefineAsSet('mlst', "Unstoppable Force", 3)
call DEqNamedItemDefineAsSet('fwss', "Immovable Object", 3)

endfunction

private function Init takes nothing returns nothing
call TriggerRegisterTimerEvent(trg_DEqPreDefineNamedItemsHere, 1.11, FALSE)
call TriggerAddAction(trg_DEqPreDefineNamedItemsHere, function DEqPreDefineNamedItemsHere)
//call TimerStart(CreateTimer(), 3.1, FALSE, function DEqPreDefineNamedItemsHere)
endfunction

endlibrary