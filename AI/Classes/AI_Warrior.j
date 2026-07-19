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
    Requires `AI.j` and `AbilitiesLiteUI.j`.

    API:
    call AIWarrior_Register(unit whichUnit)
    call AIWarrior_ConfigureProfile(profileId)
    call AIWarrior_RegisterAbilityTemplatesForUnitType(unitTypeId)

**/
library AIWarrior initializer Init requires AI, AbilitiesLiteUI, StatsLiteUI, StatsUI, VoicelinesWarrior

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
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_GREET, VL_WARRIOR_HEROWARRIOR_GREET1_TEXT, VL_WARRIOR_HEROWARRIOR_GREET1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_GREET, VL_WARRIOR_HEROWARRIOR_GREET2_TEXT, VL_WARRIOR_HEROWARRIOR_GREET2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_FAREWELL, VL_WARRIOR_HEROWARRIOR_FAREWELL1_TEXT, VL_WARRIOR_HEROWARRIOR_FAREWELL1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_FAREWELL, VL_WARRIOR_HEROWARRIOR_FAREWELL2_TEXT, VL_WARRIOR_HEROWARRIOR_FAREWELL2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_PASSIVE, VL_WARRIOR_HEROWARRIOR_PASSIVE1_TEXT, VL_WARRIOR_HEROWARRIOR_PASSIVE1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_PASSIVE, VL_WARRIOR_HEROWARRIOR_PASSIVE2_TEXT, VL_WARRIOR_HEROWARRIOR_PASSIVE2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_NORMAL, VL_WARRIOR_HEROWARRIOR_NORMAL1_TEXT, VL_WARRIOR_HEROWARRIOR_NORMAL1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_NORMAL, VL_WARRIOR_HEROWARRIOR_NORMAL2_TEXT, VL_WARRIOR_HEROWARRIOR_NORMAL2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_AGGRESSIVE, VL_WARRIOR_HEROWARRIOR_AGGRESSIVE1_TEXT, VL_WARRIOR_HEROWARRIOR_AGGRESSIVE1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_AGGRESSIVE, VL_WARRIOR_HEROWARRIOR_AGGRESSIVE2_TEXT, VL_WARRIOR_HEROWARRIOR_AGGRESSIVE2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_HOLD, VL_WARRIOR_HEROWARRIOR_HOLDPOSITIONS1_TEXT, VL_WARRIOR_HEROWARRIOR_HOLDPOSITIONS1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_HOLD, VL_WARRIOR_HEROWARRIOR_HOLDPOSITIONS2_TEXT, VL_WARRIOR_HEROWARRIOR_HOLDPOSITIONS2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_DROP_ITEMS, VL_WARRIOR_HEROWARRIOR_DROPITEMS1_TEXT, VL_WARRIOR_HEROWARRIOR_DROPITEMS1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_DROP_ITEMS, VL_WARRIOR_HEROWARRIOR_DROPITEMS2_TEXT, VL_WARRIOR_HEROWARRIOR_DROPITEMS2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_IDLE, VL_WARRIOR_HEROWARRIOR_IDLE1_TEXT, VL_WARRIOR_HEROWARRIOR_IDLE1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_IDLE, VL_WARRIOR_HEROWARRIOR_IDLE2_TEXT, VL_WARRIOR_HEROWARRIOR_IDLE2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_MOVING, VL_WARRIOR_HEROWARRIOR_MOVING1_TEXT, VL_WARRIOR_HEROWARRIOR_MOVING1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_MOVING, VL_WARRIOR_HEROWARRIOR_MOVING2_TEXT, VL_WARRIOR_HEROWARRIOR_MOVING2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_CASTING, VL_WARRIOR_HEROWARRIOR_CASTING1_TEXT, VL_WARRIOR_HEROWARRIOR_CASTING1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_CASTING, VL_WARRIOR_HEROWARRIOR_CASTING2_TEXT, VL_WARRIOR_HEROWARRIOR_CASTING2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_ATTACKING, VL_WARRIOR_HEROWARRIOR_ATTACK1_TEXT, VL_WARRIOR_HEROWARRIOR_ATTACK1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_ATTACKING, VL_WARRIOR_HEROWARRIOR_ATTACK2_TEXT, VL_WARRIOR_HEROWARRIOR_ATTACK2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_KILLING, VL_WARRIOR_HEROWARRIOR_UNITDIES1_TEXT, VL_WARRIOR_HEROWARRIOR_UNITDIES1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_KILLING, VL_WARRIOR_HEROWARRIOR_UNITDIES2_TEXT, VL_WARRIOR_HEROWARRIOR_UNITDIES2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_KILLING, VL_WARRIOR_HEROWARRIOR_UNITDIES3_TEXT, VL_WARRIOR_HEROWARRIOR_UNITDIES3_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_KICKED, VL_WARRIOR_HEROWARRIOR_KICKED1_TEXT, VL_WARRIOR_HEROWARRIOR_KICKED1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_KICKED, VL_WARRIOR_HEROWARRIOR_KICKED2_TEXT, VL_WARRIOR_HEROWARRIOR_KICKED2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_COMPANION_DIES, VL_WARRIOR_HEROWARRIOR_COMPANIONDIES1_TEXT, VL_WARRIOR_HEROWARRIOR_COMPANIONDIES1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_COMPANION_DIES, VL_WARRIOR_HEROWARRIOR_COMPANIONDIES2_TEXT, VL_WARRIOR_HEROWARRIOR_COMPANIONDIES2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_ITEM_GIVEN, VL_WARRIOR_HEROWARRIOR_GIVEITEM1_TEXT, VL_WARRIOR_HEROWARRIOR_GIVEITEM1_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_ITEM_GIVEN, VL_WARRIOR_HEROWARRIOR_GIVEITEM2_TEXT, VL_WARRIOR_HEROWARRIOR_GIVEITEM2_KEY)
    call AI_RegisterBarkLine(AI_Warrior_ProfileId, AI_BARK_ITEM_GIVEN, VL_WARRIOR_HEROWARRIOR_GIVEITEM3_TEXT, VL_WARRIOR_HEROWARRIOR_GIVEITEM3_KEY)
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

public function RegisterAbilityTemplatesForUnitType takes integer unitTypeId returns nothing
    if unitTypeId == 0 then
        return
    endif
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARRIOR_ABILITY_BATTLE_SHOUT, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARRIOR_ABILITY_BLOODRAGE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARRIOR_ABILITY_CHARGE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARRIOR_ABILITY_HEROIC_STRIKE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARRIOR_ABILITY_REND, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARRIOR_ABILITY_SUNDER_ARMOR, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARRIOR_ABILITY_THUNDER_CLAP, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARRIOR_ABILITY_CHALLENGING_SHOUT, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARRIOR_ABILITY_RETALIATION, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARRIOR_ABILITY_RECKLESSNESS, "", "")
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
    // Warrior keeps autonomous AI.j retreat, but should not kite away while companion-controlled.
    call AI_SetProfileCompanionRetreat(profileId, false)
    call AI_SetProfileThinkCallback(profileId, function Think)
    call AI_AddProfileProfession(profileId, AI_PROFESSION_MINING)
    call AI_AddProfileProfession(profileId, AI_PROFESSION_BLACKSMITHING)
    call RegisterAbilities(profileId)
    call AI_AddDefaultShopItems(profileId)
endfunction

private function Init takes nothing returns nothing
    set AI_Warrior_ClassId = AI_RegisterClass("Warrior")
    set AI_Warrior_ProfileId = AI_RegisterProfile(AI_Warrior_ClassId, AI_WARRIOR_UNIT_HORDE, "Horde Warrior")
    call StatsLiteUI_RegisterRageResourceClass(AI_Warrior_ClassId)
    call StatsUI_RegisterRageResourceClass(AI_Warrior_ClassId)
    call AI_SetProfileFaction(AI_Warrior_ProfileId, "Horde")
    call AI_SetProfileSpawnOwner(AI_Warrior_ProfileId, Player(1))
    call AIWarrior_ConfigureProfile(AI_Warrior_ProfileId)
    call AIWarrior_RegisterAbilityTemplatesForUnitType(AI_WARRIOR_UNIT_HORDE)
    call AI_AddRandomSpawnProfile(AI_Warrior_ProfileId)
    call RegisterBarks()
endfunction

endlibrary
