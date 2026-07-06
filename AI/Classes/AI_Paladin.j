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
    Requires `AI.j`.

    API:
    call AIPaladin_Register(unit whichUnit)

**/
library AIPaladin initializer Init requires AI

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
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_GREET, "The Light guides us both, even if our paths differ.", "HeroPaladin_Greet1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_GREET, "A Shaman, hmm? I suppose we can work together.", "HeroPaladin_Greet2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_GREET, "Your presence is surprising, but welcome.", "HeroPaladin_Greet3")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_FAREWELL, "May the Light keep you safe on your journey.", "HeroPaladin_Farewell1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_FAREWELL, "Go with honor, Shaman.", "HeroPaladin_Farewell2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_FAREWELL, "We'll meet again, if fate wills it.", "HeroPaladin_Farewell3")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_PASSIVE, "I'll watch your back, but don't betray my trust.", "HeroPaladin_Passive1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_PASSIVE, "Where you lead, the Light will follow.", "HeroPaladin_Passive2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_PASSIVE, "Fine, I'll keep an eye on you... and your allies.", "HeroPaladin_Passive3")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_NORMAL, "I am ready to serve, for the Light and justice.", "HeroPaladin_Normal1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_NORMAL, "Together, we'll purge the darkness.", "HeroPaladin_Normal2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_NORMAL, "A righteous path is never walked alone.", "HeroPaladin_Normal3")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_AGGRESSIVE, "Let the Light judge the wicked!", "HeroPaladin_Aggressive1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_AGGRESSIVE, "By the Light, they will fall!", "HeroPaladin_Aggressive2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_AGGRESSIVE, "I'll show them the might of righteousness!", "HeroPaladin_Aggressive3")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_HOLD, "This ground shall not fall to evil!", "HeroPaladin_HoldPositions1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_HOLD, "I'll hold the line, no matter the cost.", "HeroPaladin_HoldPositions2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_DROP_ITEMS, "Take them; they serve the cause better in your hands.", "HeroPaladin_DropItems1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_DROP_ITEMS, "Here, may it aid you in the fight.", "HeroPaladin_DropItems2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_DROP_ITEMS, "Use them wisely, Shaman.", "HeroPaladin_DropItems3")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_IDLE, "Even paladins need a moment of prayer.", "HeroPaladin_Idle1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_IDLE, "Evil doesn't rest, but I suppose we must.", "HeroPaladin_Idle2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_MOVING, "The road is long, but the Light is with us.", "HeroPaladin_Moving1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_MOVING, "Forward, always forward.", "HeroPaladin_Moving2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_MOVING, "Walking with a Shaman. My mentors would be perplexed.", "HeroPaladin_Moving3")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_CASTING, "By the Light, be cleansed!", "HeroPaladin_Casting1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_CASTING, "The Light purges all who stand against it!", "HeroPaladin_Casting2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ATTACKING, "For the Light and for justice!", "HeroPaladin_Attack1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ATTACKING, "Feel the wrath of the righteous!", "HeroPaladin_Attack2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ATTACKING, "The Light's fury strikes you down!", "HeroPaladin_Attack3")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_KILLING, "Another soul judged by the Light.", "HeroPaladin_UnitKilled1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_KILLING, "Justice has been served.", "HeroPaladin_UnitKilled2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_KILLING, "The Light is victorious once again.", "HeroPaladin_UnitKilled3")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_KICKED, "Perhaps we were too different after all.", "HeroPaladin_Kicked1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_KICKED, "You walk your path, and I'll walk mine.", "HeroPaladin_Kicked2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_COMPANION_DIES, "A tragic loss...", "HeroPaladin_CompanionDies1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_COMPANION_DIES, "Evil has claimed another. We must press on.", "HeroPaladin_CompanionDies2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ITEM_GIVEN, "This will strengthen my resolve.", "HeroPaladin_GiveItem1")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ITEM_GIVEN, "Thank you. I'll use it wisely.", "HeroPaladin_GiveItem2")
    call AI_RegisterBarkLine(AI_Paladin_ProfileId, AI_BARK_ITEM_GIVEN, "The Light provides... with your help.", "HeroPaladin_GiveItem3")
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
    call AI_SetProfileSpawnOwner(AI_Paladin_ProfileId, Player(14))
    call AI_SetProfileThinkCallback(AI_Paladin_ProfileId, function Think)
    call RegisterAbilities()
    call AI_AddDefaultShopItems(AI_Paladin_ProfileId)
    call AI_AddRandomSpawnProfile(AI_Paladin_ProfileId)
    call RegisterBarks()
endfunction

endlibrary
