/**
    AI_Warrior

    Author: Valdemar
    Version:

    Description:
    Warrior AI profile registration. Detailed Warrior ability rotation will be
    layered into this library after the master AI registry is verified.

    Credits:
    - Old GUI HeroWarrior triggers

    How to install:
    Requires `AI.j`.

    API:
    call AIWarrior_Register(unit whichUnit)
    call AIWarrior_ConfigureProfile(profileId)

**/
library AIWarrior initializer Init requires AI

globals
    constant integer AI_WARRIOR_UNIT_HORDE = 'O629'
    constant integer AI_WARRIOR_ABILITY_BATTLE_SHOUT = 'A6FO'
    constant integer AI_WARRIOR_ABILITY_BLOODRAGE = 'A00G'
    constant integer AI_WARRIOR_ABILITY_CHARGE = 'A00H'
    constant integer AI_WARRIOR_ABILITY_HEROIC_STRIKE = 'A6FL'
    constant integer AI_WARRIOR_ABILITY_REND = 'A00F'
    constant integer AI_WARRIOR_ABILITY_SUNDER_ARMOR = 'A6FS'
    constant integer AI_WARRIOR_ABILITY_THUNDER_CLAP = 'A6FK'
    constant integer AI_WARRIOR_ABILITY_CHALLENGING_SHOUT = 'A6FN'
    constant integer AI_WARRIOR_ABILITY_RETALIATION = 'A6FP'
    constant integer AI_WARRIOR_ABILITY_RECKLESSNESS = 'A6FT'
    constant integer AI_WARRIOR_ORDER_THUNDER_CLAP = 852097
    integer AI_Warrior_ClassId = 0
    integer AI_Warrior_ProfileId = 0
endglobals

private function RegisterBarks takes nothing returns nothing
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_GREET, "Strength and honor to you, traveler.", "HeroWarrior_Greet1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_GREET, "What do you require of my strength?", "HeroWarrior_Greet2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_FAREWELL, "May your path be steady and strong.", "HeroWarrior_Farewell1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_FAREWELL, "Farewell, until we meet again.", "HeroWarrior_Farewell2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_PASSIVE, "Where you lead, I will tread with purpose.", "HeroWarrior_Passive1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_PASSIVE, "My strength stands ready.", "HeroWarrior_Passive2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_NORMAL, "Lead on; my fists are yours to command.", "HeroWarrior_Normal1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_NORMAL, "This warrior is ready for action.", "HeroWarrior_Normal2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_AGGRESSIVE, "For the ancestors, we fight!", "HeroWarrior_Aggressive1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_AGGRESSIVE, "Honor demands action!", "HeroWarrior_Aggressive2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_HOLD, "I will hold this ground, unshaken.", "HeroWarrior_HoldPositions1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_HOLD, "The mountains do not bow, and neither will I.", "HeroWarrior_HoldPositions2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_DROP_ITEMS, "Here you go.", "HeroWarrior_DropItems1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_DROP_ITEMS, "Take them.", "HeroWarrior_DropItems2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_IDLE, "Even a warrior needs moments of stillness.", "HeroWarrior_Idle1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_IDLE, "Patience is the most valuable asset.", "HeroWarrior_Idle2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_MOVING, "Have you seen any strong shield that I could use?", "HeroWarrior_Moving1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_MOVING, "I am eager for battle... Let's find some worthy opponents!", "HeroWarrior_Moving2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_CASTING, "A warrior's body is their weapon.", "HeroWarrior_Casting1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_CASTING, "Strength flows from the wrists!", "HeroWarrior_Casting2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_ATTACKING, "The earth shakes with my fury!", "HeroWarrior_Attack1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_ATTACKING, "You dare challenge the might of a tauren?", "HeroWarrior_Attack2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_KILLING, "Another foe falls.", "HeroWarrior_UnitDies1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_KILLING, "His journey ends here.", "HeroWarrior_UnitDies2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_KILLING, "Let this defeat serve as a warning to others.", "HeroWarrior_UnitDies3")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_KICKED, "Hmph. A warrior walks alone, if they must.", "HeroWarrior_Kicked1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_KICKED, "You reject my strength? So be it.", "HeroWarrior_Kicked2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_COMPANION_DIES, "A warrior's end, as it should be.", "HeroWarrior_CompanionDies1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_COMPANION_DIES, "He fought with honor; we must carry on.", "HeroWarrior_CompanionDies2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_ITEM_GIVEN, "This will aid me in the battles ahead.", "HeroWarrior_GiveItem1")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_ITEM_GIVEN, "This will serve me well.", "HeroWarrior_GiveItem2")
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_ITEM_GIVEN, "Does it have any good stats?", "HeroWarrior_GiveItem3")
endfunction

private function RegisterAbilities takes integer profileId returns nothing
    call AI_AddProfileStartingAbility(profileId, AI_WARRIOR_ABILITY_BATTLE_SHOUT)
    call AI_AddProfileStartingAbility(profileId, AI_WARRIOR_ABILITY_BLOODRAGE)
    call AI_AddProfileStartingAbility(profileId, AI_WARRIOR_ABILITY_CHARGE)
    call AI_AddProfileStartingAbility(profileId, AI_WARRIOR_ABILITY_HEROIC_STRIKE)
    call AI_AddProfileStartingAbility(profileId, AI_WARRIOR_ABILITY_REND)
    call AI_AddProfileStartingAbility(profileId, AI_WARRIOR_ABILITY_SUNDER_ARMOR)
    call AI_AddProfileStartingAbility(profileId, AI_WARRIOR_ABILITY_THUNDER_CLAP)
    call AI_AddProfileStartingAbility(profileId, AI_WARRIOR_ABILITY_CHALLENGING_SHOUT)
    call AI_AddProfileStartingAbility(profileId, AI_WARRIOR_ABILITY_RETALIATION)
    call AI_AddProfileAbility(profileId, AI_WARRIOR_ABILITY_BATTLE_SHOUT)
    call AI_AddProfileAbility(profileId, AI_WARRIOR_ABILITY_BLOODRAGE)
    call AI_AddProfileAbility(profileId, AI_WARRIOR_ABILITY_CHARGE)
    call AI_AddProfileAbility(profileId, AI_WARRIOR_ABILITY_HEROIC_STRIKE)
    call AI_AddProfileAbility(profileId, AI_WARRIOR_ABILITY_REND)
    call AI_AddProfileAbility(profileId, AI_WARRIOR_ABILITY_SUNDER_ARMOR)
    call AI_AddProfileAbility(profileId, AI_WARRIOR_ABILITY_THUNDER_CLAP)
    call AI_AddProfileAbility(profileId, AI_WARRIOR_ABILITY_CHALLENGING_SHOUT)
    call AI_AddProfileAbility(profileId, AI_WARRIOR_ABILITY_RETALIATION)
    call AI_AddProfileAbility(profileId, AI_WARRIOR_ABILITY_RECKLESSNESS)
endfunction

private function Think takes nothing returns nothing
    local unit warrior = AI_EventUnit
    local unit target = AI_EventTarget
    local integer enemyCount
    local integer roll
    local real lifePercent
    if warrior == null or target == null then
        set warrior = null
        set target = null
        return
    endif
    set enemyCount = AI_CountNearbyEnemies(warrior, 600.00)
    set roll = GetRandomInt(1, 100)
    set lifePercent = AI_GetUnitLifePercent(warrior)
    if enemyCount <= 0 then
        call IssueTargetOrder(warrior, "attack", target)
    elseif enemyCount >= 3 and lifePercent >= 25.00 and roll <= 20 and AI_TryCastImmediate(warrior, AI_WARRIOR_ABILITY_CHALLENGING_SHOUT, "taunt", 1.00) then
        call AI_RequestBark(warrior, AI_BARK_CASTING)
    elseif enemyCount >= 2 and roll <= 42 and AI_TryCastImmediateById(warrior, AI_WARRIOR_ABILITY_THUNDER_CLAP, AI_WARRIOR_ORDER_THUNDER_CLAP, 1.00) then
        call AI_RequestBark(warrior, AI_BARK_CASTING)
    elseif roll <= 55 and AI_TryCastImmediate(warrior, AI_WARRIOR_ABILITY_BATTLE_SHOUT, "roar", 1.00) then
        call AI_RequestBark(warrior, AI_BARK_CASTING)
    elseif lifePercent >= 55.00 and roll <= 68 and AI_TryCastImmediate(warrior, AI_WARRIOR_ABILITY_BLOODRAGE, "avatar", 1.00) then
        call AI_RequestBark(warrior, AI_BARK_CASTING)
    elseif roll <= 80 and AI_TryCastTarget(warrior, target, AI_WARRIOR_ABILITY_CHARGE, "absorb", 1.00) then
        call AI_RequestBark(warrior, AI_BARK_CASTING)
    elseif roll <= 88 and AI_TryCastTarget(warrior, target, AI_WARRIOR_ABILITY_SUNDER_ARMOR, "faeriefire", 1.00) then
        call AI_RequestBark(warrior, AI_BARK_CASTING)
    elseif roll <= 94 and AI_TryCastTarget(warrior, target, AI_WARRIOR_ABILITY_REND, "parasite", 1.00) then
        call AI_RequestBark(warrior, AI_BARK_CASTING)
    elseif enemyCount >= 2 and lifePercent >= 35.00 and GetRandomInt(1, 2) == 1 and AI_TryCastImmediate(warrior, AI_WARRIOR_ABILITY_RETALIATION, "berserk", 1.00) then
        call AI_RequestBark(warrior, AI_BARK_CASTING)
    elseif lifePercent >= 45.00 and GetRandomInt(1, 3) == 1 and AI_TemporaryAbilitySwap(warrior, AI_WARRIOR_ABILITY_RETALIATION, AI_WARRIOR_ABILITY_RECKLESSNESS, GetUnitAbilityLevel(warrior, AI_WARRIOR_ABILITY_RETALIATION), 1.00) and AI_TryCastImmediate(warrior, AI_WARRIOR_ABILITY_RECKLESSNESS, "fanofknives", 1.00) then
        call AI_RequestBark(warrior, AI_BARK_CASTING)
    elseif AI_TryCastTarget(warrior, target, AI_WARRIOR_ABILITY_HEROIC_STRIKE, "stormbolt", 1.00) then
        call AI_RequestBark(warrior, AI_BARK_CASTING)
    else
        call IssueTargetOrder(warrior, "attack", target)
    endif
    set warrior = null
    set target = null
endfunction

public function Register takes unit whichUnit returns integer
    return AI_RegisterUnit(whichUnit, AI_Warrior_ProfileId, 0)
endfunction

public function ConfigureProfile takes integer profileId returns nothing
    if profileId <= 0 then
        return
    endif
    call AI_SetProfileNoManaRestore(profileId, true)
    call AI_SetProfileCompanionRetreat(profileId, false)
    call AI_SetProfileThinkCallback(profileId, function Think)
    call AI_AddProfileProfession(profileId, AI_PROFESSION_MINING)
    call RegisterAbilities(profileId)
    call AI_AddDefaultShopItems(profileId)
endfunction

private function Init takes nothing returns nothing
    set AI_Warrior_ClassId = AI_RegisterClass("Warrior")
    set AI_Warrior_ProfileId = AI_RegisterProfile(AI_Warrior_ClassId, AI_WARRIOR_UNIT_HORDE, "Horde Warrior")
    call AI_SetProfileSpawnOwner(AI_Warrior_ProfileId, Player(1))
    call AIWarrior_ConfigureProfile(AI_Warrior_ProfileId)
    call AI_AddRandomSpawnProfile(AI_Warrior_ProfileId)
    call RegisterBarks()
endfunction

endlibrary
