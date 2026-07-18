/**
    AI_Paladin

    Author: Valdemar
    Version:

    Description:
    Paladin AI profile registration. Detailed Paladin support and defensive
    spell logic will be layered into this library after the master AI registry
    is verified.

    Credits:
    - Old GUI Riverbane Paladin triggers

    How to install:
    Requires `AI.j` and `AbilitiesLiteUI.j`.

    API:
    call AIPaladin_Register(unit whichUnit)

**/
library AIPaladin initializer Init requires AI, AbilitiesLiteUI, VoicelinesPaladin

globals
    constant integer AI_PALADIN_UNIT_RIVERBANE = 'H60Y'
    constant integer AI_PALADIN_ABILITY_JUDGEMENT_STRIKE = 'A00O'
    constant integer AI_PALADIN_ABILITY_HOLY_LIGHT = 'A00P'
    constant integer AI_PALADIN_ABILITY_DIVINE_SHIELD = 'A00Q'
    constant integer AI_PALADIN_ABILITY_INNER_FIRE = 'A00R'
    constant integer AI_PALADIN_ABILITY_LAY_ON_HANDS = 'A00S'
    constant integer AI_PALADIN_ABILITY_TAUNT = 'A00T'
    constant integer AI_PALADIN_ABILITY_BLESSING_OF_LIGHT = 'A00U'
    integer AI_Paladin_ClassId = 0
    integer AI_Paladin_ProfileId = 0
endglobals

private function RegisterBarks takes nothing returns nothing
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_GREET, VL_PALADIN_HEROPALADIN_GREET1_TEXT, VL_PALADIN_HEROPALADIN_GREET1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_GREET, VL_PALADIN_HEROPALADIN_GREET2_TEXT, VL_PALADIN_HEROPALADIN_GREET2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_GREET, VL_PALADIN_HEROPALADIN_GREET3_TEXT, VL_PALADIN_HEROPALADIN_GREET3_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_FAREWELL, VL_PALADIN_HEROPALADIN_FAREWELL1_TEXT, VL_PALADIN_HEROPALADIN_FAREWELL1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_FAREWELL, VL_PALADIN_HEROPALADIN_FAREWELL2_TEXT, VL_PALADIN_HEROPALADIN_FAREWELL2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_FAREWELL, VL_PALADIN_HEROPALADIN_FAREWELL3_TEXT, VL_PALADIN_HEROPALADIN_FAREWELL3_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_PASSIVE, VL_PALADIN_HEROPALADIN_PASSIVE1_TEXT, VL_PALADIN_HEROPALADIN_PASSIVE1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_PASSIVE, VL_PALADIN_HEROPALADIN_PASSIVE2_TEXT, VL_PALADIN_HEROPALADIN_PASSIVE2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_PASSIVE, VL_PALADIN_HEROPALADIN_PASSIVE3_TEXT, VL_PALADIN_HEROPALADIN_PASSIVE3_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_NORMAL, VL_PALADIN_HEROPALADIN_NORMAL1_TEXT, VL_PALADIN_HEROPALADIN_NORMAL1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_NORMAL, VL_PALADIN_HEROPALADIN_NORMAL2_TEXT, VL_PALADIN_HEROPALADIN_NORMAL2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_NORMAL, VL_PALADIN_HEROPALADIN_NORMAL3_TEXT, VL_PALADIN_HEROPALADIN_NORMAL3_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_AGGRESSIVE, VL_PALADIN_HEROPALADIN_AGGRESSIVE1_TEXT, VL_PALADIN_HEROPALADIN_AGGRESSIVE1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_AGGRESSIVE, VL_PALADIN_HEROPALADIN_AGGRESSIVE2_TEXT, VL_PALADIN_HEROPALADIN_AGGRESSIVE2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_AGGRESSIVE, VL_PALADIN_HEROPALADIN_AGGRESSIVE3_TEXT, VL_PALADIN_HEROPALADIN_AGGRESSIVE3_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_HOLD, VL_PALADIN_HEROPALADIN_HOLDPOSITIONS1_TEXT, VL_PALADIN_HEROPALADIN_HOLDPOSITIONS1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_HOLD, VL_PALADIN_HEROPALADIN_HOLDPOSITIONS2_TEXT, VL_PALADIN_HEROPALADIN_HOLDPOSITIONS2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_DROP_ITEMS, VL_PALADIN_HEROPALADIN_DROPITEMS1_TEXT, VL_PALADIN_HEROPALADIN_DROPITEMS1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_DROP_ITEMS, VL_PALADIN_HEROPALADIN_DROPITEMS2_TEXT, VL_PALADIN_HEROPALADIN_DROPITEMS2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_DROP_ITEMS, VL_PALADIN_HEROPALADIN_DROPITEMS3_TEXT, VL_PALADIN_HEROPALADIN_DROPITEMS3_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_IDLE, VL_PALADIN_HEROPALADIN_IDLE1_TEXT, VL_PALADIN_HEROPALADIN_IDLE1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_IDLE, VL_PALADIN_HEROPALADIN_IDLE2_TEXT, VL_PALADIN_HEROPALADIN_IDLE2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_MOVING, VL_PALADIN_HEROPALADIN_MOVING1_TEXT, VL_PALADIN_HEROPALADIN_MOVING1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_MOVING, VL_PALADIN_HEROPALADIN_MOVING2_TEXT, VL_PALADIN_HEROPALADIN_MOVING2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_MOVING, VL_PALADIN_HEROPALADIN_MOVING3_TEXT, VL_PALADIN_HEROPALADIN_MOVING3_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_CASTING, VL_PALADIN_HEROPALADIN_CASTING1_TEXT, VL_PALADIN_HEROPALADIN_CASTING1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_CASTING, VL_PALADIN_HEROPALADIN_CASTING2_TEXT, VL_PALADIN_HEROPALADIN_CASTING2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ATTACKING, VL_PALADIN_HEROPALADIN_ATTACK1_TEXT, VL_PALADIN_HEROPALADIN_ATTACK1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ATTACKING, VL_PALADIN_HEROPALADIN_ATTACK2_TEXT, VL_PALADIN_HEROPALADIN_ATTACK2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ATTACKING, VL_PALADIN_HEROPALADIN_ATTACK3_TEXT, VL_PALADIN_HEROPALADIN_ATTACK3_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_KILLING, VL_PALADIN_HEROPALADIN_UNITKILLED1_TEXT, VL_PALADIN_HEROPALADIN_UNITKILLED1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_KILLING, VL_PALADIN_HEROPALADIN_UNITKILLED2_TEXT, VL_PALADIN_HEROPALADIN_UNITKILLED2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_KILLING, VL_PALADIN_HEROPALADIN_UNITKILLED3_TEXT, VL_PALADIN_HEROPALADIN_UNITKILLED3_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_KICKED, VL_PALADIN_HEROPALADIN_KICKED1_TEXT, VL_PALADIN_HEROPALADIN_KICKED1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_KICKED, VL_PALADIN_HEROPALADIN_KICKED2_TEXT, VL_PALADIN_HEROPALADIN_KICKED2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_COMPANION_DIES, VL_PALADIN_HEROPALADIN_COMPANIONDIES1_TEXT, VL_PALADIN_HEROPALADIN_COMPANIONDIES1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_COMPANION_DIES, VL_PALADIN_HEROPALADIN_COMPANIONDIES2_TEXT, VL_PALADIN_HEROPALADIN_COMPANIONDIES2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ITEM_GIVEN, VL_PALADIN_HEROPALADIN_GIVEITEM1_TEXT, VL_PALADIN_HEROPALADIN_GIVEITEM1_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ITEM_GIVEN, VL_PALADIN_HEROPALADIN_GIVEITEM2_TEXT, VL_PALADIN_HEROPALADIN_GIVEITEM2_KEY)
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ITEM_GIVEN, VL_PALADIN_HEROPALADIN_GIVEITEM3_TEXT, VL_PALADIN_HEROPALADIN_GIVEITEM3_KEY)
endfunction

private function RegisterAbilities takes nothing returns nothing
    call AI_AddProfileStartingAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_BLESSING_OF_LIGHT)
    call AI_AddProfileStartingAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_DIVINE_SHIELD)
    call AI_AddProfileStartingAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_HOLY_LIGHT)
    call AI_AddProfileStartingAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_INNER_FIRE)
    call AI_AddProfileStartingAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_JUDGEMENT_STRIKE)
    call AI_AddProfileStartingAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_LAY_ON_HANDS)
    call AI_AddProfileStartingAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_TAUNT)
    call AI_AddProfileAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_DIVINE_SHIELD)
    call AI_AddProfileAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_HOLY_LIGHT)
    call AI_AddProfileAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_INNER_FIRE)
    call AI_AddProfileAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_JUDGEMENT_STRIKE)
    call AI_AddProfileAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_LAY_ON_HANDS)
    call AI_AddProfileAbility(AI_Paladin_ProfileId, AI_PALADIN_ABILITY_TAUNT)
endfunction

private function RegisterAbilityTemplates takes nothing returns nothing
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_PALADIN_UNIT_RIVERBANE, AI_PALADIN_ABILITY_BLESSING_OF_LIGHT, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_PALADIN_UNIT_RIVERBANE, AI_PALADIN_ABILITY_DIVINE_SHIELD, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_PALADIN_UNIT_RIVERBANE, AI_PALADIN_ABILITY_HOLY_LIGHT, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_PALADIN_UNIT_RIVERBANE, AI_PALADIN_ABILITY_INNER_FIRE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_PALADIN_UNIT_RIVERBANE, AI_PALADIN_ABILITY_JUDGEMENT_STRIKE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_PALADIN_UNIT_RIVERBANE, AI_PALADIN_ABILITY_LAY_ON_HANDS, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_PALADIN_UNIT_RIVERBANE, AI_PALADIN_ABILITY_TAUNT, "", "")
endfunction

private function Think takes nothing returns nothing
    local unit paladin = AI_EventUnit
    local unit target = AI_EventTarget
    local unit ally
    local integer enemyCount
    local integer roll
    local real paladinLife
    local real allyLife
    if paladin == null then
        set paladin = null
        return
    endif
    set ally = AI_FindLowestHealthAlly(paladin, 800.00, true)
    set enemyCount = AI_CountNearbyEnemies(paladin, 600.00)
    set roll = GetRandomInt(1, 100)
    set paladinLife = AI_GetUnitLifePercent(paladin)
    if ally != null then
        set allyLife = AI_GetUnitLifePercent(ally)
    else
        set allyLife = 100.00
    endif
    if paladinLife <= 20.00 and AI_TryCastImmediate(paladin, AI_PALADIN_ABILITY_DIVINE_SHIELD, "divineshield", 2.00) then
        call AI_RequestBark(paladin, AI_BARK_CASTING)
    elseif ally != null and allyLife <= 25.00 and AI_TemporaryAbilitySwap(paladin, AI_PALADIN_ABILITY_HOLY_LIGHT, AI_PALADIN_ABILITY_LAY_ON_HANDS, GetUnitAbilityLevel(paladin, AI_PALADIN_ABILITY_HOLY_LIGHT), 3.50) and AI_TryCastTarget(paladin, ally, AI_PALADIN_ABILITY_LAY_ON_HANDS, "holybolt", 2.00) then
        call AI_RequestBark(paladin, AI_BARK_CASTING)
    elseif ally != null and allyLife <= 70.00 and roll <= 50 and AI_TryCastTarget(paladin, ally, AI_PALADIN_ABILITY_HOLY_LIGHT, "holybolt", 3.00) then
        call AI_RequestBark(paladin, AI_BARK_CASTING)
    elseif enemyCount >= 2 and paladinLife >= 25.00 and roll <= 65 and AI_TryCastImmediate(paladin, AI_PALADIN_ABILITY_TAUNT, "taunt", 2.00) then
        call AI_RequestBark(paladin, AI_BARK_CASTING)
    elseif ally != null and roll <= 78 and AI_TryCastTarget(paladin, ally, AI_PALADIN_ABILITY_INNER_FIRE, "innerfire", 2.00) then
        call AI_RequestBark(paladin, AI_BARK_CASTING)
    elseif target != null and roll <= 92 and AI_TryCastTarget(paladin, target, AI_PALADIN_ABILITY_JUDGEMENT_STRIKE, "stormbolt", 2.00) then
        call AI_RequestBark(paladin, AI_BARK_CASTING)
    elseif target != null then
        call IssueTargetOrder(paladin, "attack", target)
    endif
    set paladin = null
    set target = null
    set ally = null
endfunction

public function Register takes unit whichUnit returns integer
    return AI_RegisterUnit(whichUnit, AI_Paladin_ProfileId, 0)
endfunction

private function Init takes nothing returns nothing
    set AI_Paladin_ClassId = AI_RegisterClass("Paladin")
    set AI_Paladin_ProfileId = AI_RegisterProfile(AI_Paladin_ClassId, AI_PALADIN_UNIT_RIVERBANE, "Riverbane Paladin")
    call AI_SetProfileFaction(AI_Paladin_ProfileId, "Riverbane")
    call AI_SetProfileSpawnOwner(AI_Paladin_ProfileId, Player(14))
    call AI_SetProfileCompanionRetreat(AI_Paladin_ProfileId, false)
    call AI_SetProfileThinkCallback(AI_Paladin_ProfileId, function Think)
    call RegisterAbilities()
    call RegisterAbilityTemplates()
    call AI_AddDefaultShopItems(AI_Paladin_ProfileId)
    call AI_AddRandomSpawnProfile(AI_Paladin_ProfileId)
    call RegisterBarks()
endfunction

endlibrary
