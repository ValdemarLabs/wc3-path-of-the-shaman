library DEqRarityDefinitions initializer Init requires DEqRarity

globals
trigger trg_DEqPreDefineRaritiesHere = CreateTrigger()
endglobals

function DEqPreDefineRaritiesHere takes nothing returns nothing
// -1 means do not apply any rarities to items that are not assigned one
// if I set this variable to 3, all items would be legendary by default
set DEqRarityDefaultRarity = -1

// Always start Rarities from 1, system will skip 0
set DEqRarityName[1] = "Uncommon"
// You can skip this line. Color is not mandatory. Will only affect DInv tooltips
set DEqRarityColor[1] = "|cffbfff81"
// You can skip the next 4 lines. Outline Model is not mandatory, will show a sprite around the icon of the item in the DInv
set DEqRarityOutlineModel[1] = "DInv\\aganim_sprite.mdx"
set DEqRarityScale[1] = 0.55
set DEqRarityOSX[1] = -0.004
set DEqRarityOSY[1] = -0.004
// You can skip this line. GoldX is not mandatory.
set DEqRarityGoldX[1] = 1.3
// You can skip this line. StatX is not mandatory.
set DEqRarityStatX[1] = 1.15
// You can skip the next 3 lines. Colors items in the world, not mandatory, just delete these lines and your item models (the treasure chest by default) will not be colored
set DEqRarityR[1] = 120
set DEqRarityG[1] = 150
set DEqRarityB[1] = 255

set DEqRarityName[2] = "Rare"
set DEqRarityColor[2] = "|c006969FF"
set DEqRarityOutlineModel[2] = "DInv\\blue_energy_sprite.mdx"
set DEqRarityScale[2] = 0.55
set DEqRarityOSX[2] = -0.004
set DEqRarityOSY[2] = -0.004
set DEqRarityGoldX[2] = 1.6
set DEqRarityStatX[2] = 1.3
set DEqRarityR[2] = 30
set DEqRarityG[2] = 60
set DEqRarityB[2] = 255

set DEqRarityName[3] = "Epic"
set DEqRarityColor[3] = "|cffbd00ff"
set DEqRarityOutlineModel[3] = "DInv\\violet_border_sprite.mdx"
set DEqRarityScale[3] = 0.55
set DEqRarityOSX[3] = -0.004
set DEqRarityOSY[3] = -0.004
set DEqRarityGoldX[3] = 1.9
set DEqRarityStatX[3] = 1.45
set DEqRarityR[3] = 200
set DEqRarityG[3] = 100
set DEqRarityB[3] = 255

set DEqRarityName[4] = "Legendary"
set DEqRarityColor[4] = "|c00fEBA0E"
set DEqRarityOutlineModel[4] = "DInv\\fireframe.mdx"
set DEqRarityScale[4] = 0.35
set DEqRarityOSX[4] = 0.04
set DEqRarityOSY[4] = 0.04
set DEqRarityGoldX[4] = 2.2
set DEqRarityStatX[4] = 1.6
set DEqRarityR[4] = 200
set DEqRarityG[4] = 140
set DEqRarityB[4] = 100

//call DestroyTimer(GetExpiredTimer())
endfunction

private function Init takes nothing returns nothing
call TriggerRegisterTimerEvent(trg_DEqPreDefineRaritiesHere, 0.1, FALSE)
call TriggerAddAction(trg_DEqPreDefineRaritiesHere, function DEqPreDefineRaritiesHere)
//call TimerStart(CreateTimer(), 0.1, FALSE, function DEqPreDefineRaritiesHere)
endfunction

endlibrary