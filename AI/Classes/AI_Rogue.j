/**
    AI_Rogue

    Author: Valdemar
    Version:

    Description:
    Rogue AI profile registration. Detailed Rogue ability rotation will be
    layered into this library after the master AI registry is verified.

    Credits:
    - Old GUI HeroRogue triggers

    How to install:
    Requires `AI.j` and `AbilitiesLiteUI.j`.

    API:
    call AIRogue_Register(unit whichUnit)

**/
library AIRogue initializer Init requires AI, AbilitiesLiteUI, StatsLiteUI, StatsUI, VoicelinesRogue

globals
    constant integer AI_ROGUE_UNIT_HORDE = 'O631'
    constant integer AI_ROGUE_ABILITY_EVASION = 'A6FI'
    constant integer AI_ROGUE_ABILITY_GARROTE = 'A6FF'
    constant integer AI_ROGUE_ABILITY_SHADOWSTEP = 'A6FG'
    constant integer AI_ROGUE_ABILITY_SINISTER_STRIKE = 'A6FE'
    constant integer AI_ROGUE_ABILITY_SLICE_AND_DICE = 'A6E8'
    constant integer AI_ROGUE_ABILITY_SURPRISE_ATTACK = 'A6FJ'
    constant integer AI_ROGUE_ABILITY_TOXIC_VENOM = 'A6FD'
    integer AI_Rogue_ClassId = 0
    integer AI_Rogue_ProfileId = 0
endglobals

private function RegisterBarks takes nothing returns nothing
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_GREET, VL_ROGUE_HEROROGUE_GREET1_TEXT, VL_ROGUE_HEROROGUE_GREET1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_GREET, VL_ROGUE_HEROROGUE_GREET2_TEXT, VL_ROGUE_HEROROGUE_GREET2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_GREET, VL_ROGUE_HEROROGUE_GREET3_TEXT, VL_ROGUE_HEROROGUE_GREET3_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_GREET, VL_ROGUE_HEROROGUE_GREET4_TEXT, VL_ROGUE_HEROROGUE_GREET4_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_FAREWELL, VL_ROGUE_HEROROGUE_FAREWELL1_TEXT, VL_ROGUE_HEROROGUE_FAREWELL1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_FAREWELL, VL_ROGUE_HEROROGUE_FAREWELL2_TEXT, VL_ROGUE_HEROROGUE_FAREWELL2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_FAREWELL, VL_ROGUE_HEROROGUE_FAREWELL3_TEXT, VL_ROGUE_HEROROGUE_FAREWELL3_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_FAREWELL, VL_ROGUE_HEROROGUE_FAREWELL4_TEXT, VL_ROGUE_HEROROGUE_FAREWELL4_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_PASSIVE, VL_ROGUE_HEROROGUE_PASSIVE1_TEXT, VL_ROGUE_HEROROGUE_PASSIVE1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_PASSIVE, VL_ROGUE_HEROROGUE_PASSIVE2_TEXT, VL_ROGUE_HEROROGUE_PASSIVE2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_NORMAL, VL_ROGUE_HEROROGUE_NORMAL1_TEXT, VL_ROGUE_HEROROGUE_NORMAL1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_NORMAL, VL_ROGUE_HEROROGUE_NORMAL2_TEXT, VL_ROGUE_HEROROGUE_NORMAL2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_AGGRESSIVE, VL_ROGUE_HEROROGUE_AGGRESSIVE1_TEXT, VL_ROGUE_HEROROGUE_AGGRESSIVE1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_AGGRESSIVE, VL_ROGUE_HEROROGUE_AGGRESSIVE2_TEXT, VL_ROGUE_HEROROGUE_AGGRESSIVE2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_AGGRESSIVE, VL_ROGUE_HEROROGUE_AGGRESSIVE3_TEXT, VL_ROGUE_HEROROGUE_AGGRESSIVE3_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_HOLD, VL_ROGUE_HEROROGUE_HOLDPOSITIONS1_TEXT, VL_ROGUE_HEROROGUE_HOLDPOSITIONS1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_HOLD, VL_ROGUE_HEROROGUE_HOLDPOSITIONS2_TEXT, VL_ROGUE_HEROROGUE_HOLDPOSITIONS2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_DROP_ITEMS, VL_ROGUE_HEROROGUE_DROPITEMS1_TEXT, VL_ROGUE_HEROROGUE_DROPITEMS1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_DROP_ITEMS, VL_ROGUE_HEROROGUE_DROPITEMS2_TEXT, VL_ROGUE_HEROROGUE_DROPITEMS2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_DROP_ITEMS, VL_ROGUE_HEROROGUE_DROPITEMS3_TEXT, VL_ROGUE_HEROROGUE_DROPITEMS3_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_IDLE, VL_ROGUE_HEROROGUE_IDLE1_TEXT, VL_ROGUE_HEROROGUE_IDLE1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_IDLE, VL_ROGUE_HEROROGUE_IDLE2_TEXT, VL_ROGUE_HEROROGUE_IDLE2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_MOVING, VL_ROGUE_HEROROGUE_MOVING1_TEXT, VL_ROGUE_HEROROGUE_MOVING1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_MOVING, VL_ROGUE_HEROROGUE_MOVING2_TEXT, VL_ROGUE_HEROROGUE_MOVING2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_MOVING, VL_ROGUE_HEROROGUE_MOVING3_TEXT, VL_ROGUE_HEROROGUE_MOVING3_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_CASTING, VL_ROGUE_HEROROGUE_CASTING1_TEXT, VL_ROGUE_HEROROGUE_CASTING1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_CASTING, VL_ROGUE_HEROROGUE_CASTING2_TEXT, VL_ROGUE_HEROROGUE_CASTING2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_CASTING, VL_ROGUE_HEROROGUE_CASTING3_TEXT, VL_ROGUE_HEROROGUE_CASTING3_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ATTACKING, VL_ROGUE_HEROROGUE_ATTACKING1_TEXT, VL_ROGUE_HEROROGUE_ATTACKING1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ATTACKING, VL_ROGUE_HEROROGUE_ATTACKING2_TEXT, VL_ROGUE_HEROROGUE_ATTACKING2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ATTACKING, VL_ROGUE_HEROROGUE_ATTACKING3_TEXT, VL_ROGUE_HEROROGUE_ATTACKING3_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KILLING, VL_ROGUE_HEROROGUE_KILLING1_TEXT, VL_ROGUE_HEROROGUE_KILLING1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KILLING, VL_ROGUE_HEROROGUE_KILLING2_TEXT, VL_ROGUE_HEROROGUE_KILLING2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KILLING, VL_ROGUE_HEROROGUE_KILLING3_TEXT, VL_ROGUE_HEROROGUE_KILLING3_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KICKED, VL_ROGUE_HEROROGUE_KICKED1_TEXT, VL_ROGUE_HEROROGUE_KICKED1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KICKED, VL_ROGUE_HEROROGUE_KICKED2_TEXT, VL_ROGUE_HEROROGUE_KICKED2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KICKED, VL_ROGUE_HEROROGUE_KICKED3_TEXT, VL_ROGUE_HEROROGUE_KICKED3_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_COMPANION_DIES, VL_ROGUE_HEROROGUE_UNITDIES1_TEXT, VL_ROGUE_HEROROGUE_UNITDIES1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_COMPANION_DIES, VL_ROGUE_HEROROGUE_UNITDIES2_TEXT, VL_ROGUE_HEROROGUE_UNITDIES2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_COMPANION_DIES, VL_ROGUE_HEROROGUE_UNITDIES3_TEXT, VL_ROGUE_HEROROGUE_UNITDIES3_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ITEM_GIVEN, VL_ROGUE_HEROROGUE_ITEM1_TEXT, VL_ROGUE_HEROROGUE_ITEM1_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ITEM_GIVEN, VL_ROGUE_HEROROGUE_ITEM2_TEXT, VL_ROGUE_HEROROGUE_ITEM2_KEY)
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ITEM_GIVEN, VL_ROGUE_HEROROGUE_ITEM3_TEXT, VL_ROGUE_HEROROGUE_ITEM3_KEY)
endfunction

private function RegisterAbilities takes nothing returns nothing
    call AI_AddProfileStartingAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_EVASION)
    call AI_AddProfileStartingAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_GARROTE)
    call AI_AddProfileStartingAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SINISTER_STRIKE)
    call AI_AddProfileStartingAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SLICE_AND_DICE)
    call AI_AddProfileStartingAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_TOXIC_VENOM)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_EVASION)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_GARROTE)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SHADOWSTEP)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SINISTER_STRIKE)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SLICE_AND_DICE)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SURPRISE_ATTACK)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_TOXIC_VENOM)
endfunction

private function RegisterAbilityTemplates takes nothing returns nothing
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ROGUE_UNIT_HORDE, AI_ROGUE_ABILITY_EVASION, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ROGUE_UNIT_HORDE, AI_ROGUE_ABILITY_GARROTE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ROGUE_UNIT_HORDE, AI_ROGUE_ABILITY_SHADOWSTEP, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ROGUE_UNIT_HORDE, AI_ROGUE_ABILITY_SINISTER_STRIKE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ROGUE_UNIT_HORDE, AI_ROGUE_ABILITY_SLICE_AND_DICE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ROGUE_UNIT_HORDE, AI_ROGUE_ABILITY_SURPRISE_ATTACK, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ROGUE_UNIT_HORDE, AI_ROGUE_ABILITY_TOXIC_VENOM, "", "")
endfunction

private function Think takes nothing returns nothing
    local unit rogue = AI_EventUnit
    local unit target = AI_EventTarget
    local integer enemyCount
    local integer roll
    local real lifePercent
    local real targetLife
    if rogue == null or target == null then
        set rogue = null
        set target = null
        return
    endif
    set enemyCount = AI_CountNearbyEnemies(rogue, 600.00)
    set roll = GetRandomInt(1, 100)
    set lifePercent = AI_GetUnitLifePercent(rogue)
    set targetLife = AI_GetUnitLifePercent(target)
    if enemyCount <= 0 then
        call IssueTargetOrder(rogue, "attack", target)
    elseif (lifePercent <= 45.00 or enemyCount >= 3) and roll <= 45 and AI_TryCastImmediate(rogue, AI_ROGUE_ABILITY_EVASION, "roar", 2.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif roll <= 25 and AI_TryCastTarget(rogue, target, AI_ROGUE_ABILITY_GARROTE, "parasite", 2.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif enemyCount >= 2 and roll <= 42 and AI_TemporaryAbilitySwap(rogue, AI_ROGUE_ABILITY_SINISTER_STRIKE, AI_ROGUE_ABILITY_SHADOWSTEP, GetUnitAbilityLevel(rogue, AI_ROGUE_ABILITY_SINISTER_STRIKE), 3.00) and AI_TryCastTarget(rogue, target, AI_ROGUE_ABILITY_SHADOWSTEP, "stormbolt", 4.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif targetLife <= 40.00 and AI_TryCastTarget(rogue, target, AI_ROGUE_ABILITY_SINISTER_STRIKE, "stormbolt", 2.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif roll <= 58 and AI_TryCastTarget(rogue, target, AI_ROGUE_ABILITY_SINISTER_STRIKE, "stormbolt", 2.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif roll <= 70 and AI_TryCastImmediate(rogue, AI_ROGUE_ABILITY_SLICE_AND_DICE, "roar", 5.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif enemyCount <= 2 and lifePercent >= 45.00 and roll <= 80 and AI_TemporaryAbilitySwap(rogue, AI_ROGUE_ABILITY_SINISTER_STRIKE, AI_ROGUE_ABILITY_SURPRISE_ATTACK, GetUnitAbilityLevel(rogue, AI_ROGUE_ABILITY_SINISTER_STRIKE), 5.00) and AI_TryCastImmediate(rogue, AI_ROGUE_ABILITY_SURPRISE_ATTACK, "windwalk", 6.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
        call IssueTargetOrder(rogue, "attack", target)
    elseif enemyCount >= 2 and roll <= 92 and AI_TryCastTarget(rogue, target, AI_ROGUE_ABILITY_TOXIC_VENOM, "acidbomb", 5.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    else
        call IssueTargetOrder(rogue, "attack", target)
    endif
    set rogue = null
    set target = null
endfunction

public function Register takes unit whichUnit returns integer
    return AI_RegisterUnit(whichUnit, AI_Rogue_ProfileId, 0)
endfunction

private function Init takes nothing returns nothing
    set AI_Rogue_ClassId = AI_RegisterClass("Rogue")
    set AI_Rogue_ProfileId = AI_RegisterProfile(AI_Rogue_ClassId, AI_ROGUE_UNIT_HORDE, "Horde Rogue")
    call StatsLiteUI_RegisterEnergyResourceClass(AI_Rogue_ClassId)
    call StatsUI_RegisterEnergyResourceClass(AI_Rogue_ClassId)
    call AI_SetProfileFaction(AI_Rogue_ProfileId, "Horde")
    call AI_SetProfileSpawnOwner(AI_Rogue_ProfileId, Player(1))
    call AI_SetProfileNoManaRestore(AI_Rogue_ProfileId, true)
    call AI_SetProfileThinkCallback(AI_Rogue_ProfileId, function Think)
    call AI_AddProfileProfession(AI_Rogue_ProfileId, AI_PROFESSION_SKINNING)
    call RegisterAbilities()
    call RegisterAbilityTemplates()
    call AI_AddDefaultShopItems(AI_Rogue_ProfileId)
    call AI_AddRandomSpawnProfile(AI_Rogue_ProfileId)
    call RegisterBarks()
endfunction

endlibrary
