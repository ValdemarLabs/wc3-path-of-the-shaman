library DItemRarityDefinitions initializer Init requires DItemRarity

globals
trigger trg_DInvPreDefineRaritiesHere = CreateTrigger()
endglobals

function DInvPreDefineRaritiesHere takes nothing returns nothing
// -1 means do not apply any rarities to items that are not assigned one
// if I set this variable to 3, all items would be legendary by default
set DInvRarityDefaultRarity = -1

// Always start Rarities from 1, system will skip 0
set NonEqRarityName[1] = "Uncommon"
// You can skip this line. Color is not mandatory. Will only affect DInv tooltips
set NonEqRarityColor[1] = "|cffbfff81"
// You can skip the next 4 lines. Outline Model is not mandatory, will show a sprite around the icon of the item in the DInv
set NonEqRarityOutlineModel[1] = "DInv\\aganim_sprite.mdx"
// Scale of said model, if the inventory slot size is set to 0.03
set NonEqRarityScale[1] = 0.55
// X and Y coordinate offset of the sprite model
set NonEqRarityOSX[1] = -0.004
set NonEqRarityOSY[1] = -0.004

set NonEqRarityName[2] = "Rare"
set NonEqRarityColor[2] = "|c006969FF"
set NonEqRarityOutlineModel[2] = "DInv\\blue_energy_sprite.mdx"
set NonEqRarityScale[2] = 0.55
set NonEqRarityOSX[2] = -0.004
set NonEqRarityOSY[2] = -0.004

set NonEqRarityName[3] = "Epic"
set NonEqRarityColor[3] = "|cffbd00ff"
set NonEqRarityOutlineModel[3] = "DInv\\violet_border_sprite.mdx"
set NonEqRarityScale[3] = 0.55
set NonEqRarityOSX[3] = -0.004
set NonEqRarityOSY[3] = -0.004

set NonEqRarityName[4] = "Legendary"
set NonEqRarityColor[4] = "|c00fEBA0E"
set NonEqRarityOutlineModel[4] = "DInv\\fireframe.mdx"
set NonEqRarityScale[4] = 0.35
set NonEqRarityOSX[4] = 0.04
set NonEqRarityOSY[4] = 0.04

// Healing Potion
call SetDItemRarity('pghe', 1)
// Scroll of Healing
call SetDItemRarity('shea', 2)
// Ivory Tower
call SetDItemRarity('tsct', 3)
// Tiny Castle
call SetDItemRarity('tgrh', 4)

call DestroyTimer(GetExpiredTimer())
endfunction

private function Init takes nothing returns nothing
call TriggerAddAction(trg_DInvPreDefineRaritiesHere, function DInvPreDefineRaritiesHere)
call TriggerRegisterTimerEvent(trg_DInvPreDefineRaritiesHere, 0.01, FALSE)
//call TimerStart(CreateTimer(), 0.01, FALSE, function )
endfunction

endlibrary