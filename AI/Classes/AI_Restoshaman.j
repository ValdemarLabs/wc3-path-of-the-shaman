/**
    AI_Restoshaman

    Author: Valdemar
    Version:

    Description:
    Restoration Shaman AI profile registration. Detailed healing, lightning,
    and totem logic will be layered into this library after the master AI
    registry is verified.

    Credits:
    - Old GUI HeroRestoshaman triggers

    How to install:
    Requires `AI.j`, `AbilitiesLiteUI.j`, and `Abilities/Shaman/Totems.j`.

    API:
    call AIRestoshaman_Register(unit whichUnit)

**/
library AIRestoshaman initializer Init requires AI, AbilitiesLiteUI, Totems, VoicelinesRestoShaman

globals
    constant integer AI_RESTOSHAMAN_UNIT_HORDE = 'O61H'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_EARTH_1 = 'o616'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_EARTH_2 = 'o61N'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_EARTH_3 = 'o62C'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_FIRE_1 = 'o617'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_FIRE_2 = 'o61O'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_WIND_1 = 'o618'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_WIND_2 = 'o61Q'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_WATER_1 = 'o619'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_WATER_2 = 'o61P'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_EARTHBIND_1 = 'o620'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_EARTHBIND_2 = 'o62A'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_STONESKIN = 'o621'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_SKYFURY_1 = 'o622'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_SKYFURY_2 = 'o62D'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_WINDFURY_1 = 'o623'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_WINDFURY_2 = 'o62B'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_CLEANSING_1 = 'o62L'
    constant integer AI_RESTOSHAMAN_UNIT_TOTEM_CLEANSING_2 = 'o62M'
    constant integer AI_RESTOSHAMAN_ABILITY_LIGHTNING_BOLT = 'A003'
    constant integer AI_RESTOSHAMAN_ABILITY_CHAIN_LIGHTNING = 'A004'
    constant integer AI_RESTOSHAMAN_ABILITY_HEX = 'A005'
    constant integer AI_RESTOSHAMAN_ABILITY_TOTEM_WINDFURY = 'A006'
    constant integer AI_RESTOSHAMAN_ABILITY_TOTEM_WATER = 'A007'
    constant integer AI_RESTOSHAMAN_ABILITY_TOTEM_EARTH = 'A008'
    constant integer AI_RESTOSHAMAN_ABILITY_TOTEM_EARTHBIND = 'A009'
    constant integer AI_RESTOSHAMAN_ABILITY_TOTEM_FIRE = 'A00A'
    constant integer AI_RESTOSHAMAN_ABILITY_TOTEM_STONESKIN = 'A00B'
    constant integer AI_RESTOSHAMAN_ABILITY_TOTEM_WIND = 'A00C'
    constant integer AI_RESTOSHAMAN_ABILITY_HEALING_WAVE = 'A00D'
    constant integer AI_RESTOSHAMAN_ABILITY_CHAIN_HEAL = 'A00E'
    integer AI_Restoshaman_ClassId = 0
    integer AI_Restoshaman_ProfileId = 0
endglobals

private function CanCastTotem takes unit shaman, integer abilityId returns boolean
    return Totems_CanCast(shaman, abilityId)
endfunction

private function RegisterBarks takes nothing returns nothing
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_GREET, VL_RESTOSHAMAN_HERORESTOSHAMAN_GREET1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_GREET1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_GREET, VL_RESTOSHAMAN_HERORESTOSHAMAN_GREET2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_GREET2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_GREET, VL_RESTOSHAMAN_HERORESTOSHAMAN_GREET3_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_GREET3_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_FAREWELL, VL_RESTOSHAMAN_HERORESTOSHAMAN_FAREWELL1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_FAREWELL1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_FAREWELL, VL_RESTOSHAMAN_HERORESTOSHAMAN_FAREWELL2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_FAREWELL2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_PASSIVE, VL_RESTOSHAMAN_HERORESTOSHAMAN_PASSIVE1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_PASSIVE1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_PASSIVE, VL_RESTOSHAMAN_HERORESTOSHAMAN_PASSIVE2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_PASSIVE2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_NORMAL, VL_RESTOSHAMAN_HERORESTOSHAMAN_NORMAL1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_NORMAL1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_NORMAL, VL_RESTOSHAMAN_HERORESTOSHAMAN_NORMAL2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_NORMAL2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_NORMAL, VL_RESTOSHAMAN_HERORESTOSHAMAN_NORMAL3_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_NORMAL3_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_AGGRESSIVE, VL_RESTOSHAMAN_HERORESTOSHAMAN_AGGRESSIVE1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_AGGRESSIVE1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_AGGRESSIVE, VL_RESTOSHAMAN_HERORESTOSHAMAN_AGGRESSIVE2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_AGGRESSIVE2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_HOLD, VL_RESTOSHAMAN_HERORESTOSHAMAN_HOLDPOSITIONS1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_HOLDPOSITIONS1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_HOLD, VL_RESTOSHAMAN_HERORESTOSHAMAN_HOLDPOSITIONS2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_HOLDPOSITIONS2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_DROP_ITEMS, VL_RESTOSHAMAN_HERORESTOSHAMAN_DROPITEMS1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_DROPITEMS1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_DROP_ITEMS, VL_RESTOSHAMAN_HERORESTOSHAMAN_DROPITEMS2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_DROPITEMS2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_IDLE, VL_RESTOSHAMAN_HERORESTOSHAMAN_IDLE1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_IDLE1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_IDLE, VL_RESTOSHAMAN_HERORESTOSHAMAN_IDLE2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_IDLE2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_MOVING, VL_RESTOSHAMAN_HERORESTOSHAMAN_MOVING1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_MOVING1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_MOVING, VL_RESTOSHAMAN_HERORESTOSHAMAN_MOVING2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_MOVING2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_CASTING, VL_RESTOSHAMAN_HERORESTOSHAMAN_CASTING1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_CASTING1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_CASTING, VL_RESTOSHAMAN_HERORESTOSHAMAN_CASTING2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_CASTING2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_ATTACKING, VL_RESTOSHAMAN_HERORESTOSHAMAN_ATTACKING1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_ATTACKING1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_ATTACKING, VL_RESTOSHAMAN_HERORESTOSHAMAN_ATTACKING2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_ATTACKING2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_KILLING, VL_RESTOSHAMAN_HERORESTOSHAMAN_UNITDIES1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_UNITDIES1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_KILLING, VL_RESTOSHAMAN_HERORESTOSHAMAN_UNITDIES2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_UNITDIES2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_KICKED, VL_RESTOSHAMAN_HERORESTOSHAMAN_KICKED1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_KICKED1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_KICKED, VL_RESTOSHAMAN_HERORESTOSHAMAN_KICKED2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_KICKED2_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_COMPANION_DIES, VL_RESTOSHAMAN_HERORESTOSHAMAN_COMPANIONDIES1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_COMPANIONDIES1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_ITEM_GIVEN, VL_RESTOSHAMAN_HERORESTOSHAMAN_GIVEITEM1_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_GIVEITEM1_KEY)
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_ITEM_GIVEN, VL_RESTOSHAMAN_HERORESTOSHAMAN_GIVEITEM2_TEXT, VL_RESTOSHAMAN_HERORESTOSHAMAN_GIVEITEM2_KEY)
endfunction

private function RegisterAbilities takes nothing returns nothing
    call AI_AddProfileStartingAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_LIGHTNING_BOLT)
    call AI_AddProfileStartingAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_CHAIN_LIGHTNING)
    call AI_AddProfileStartingAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_HEX)
    call AI_AddProfileStartingAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_HEALING_WAVE)
    call AI_AddProfileStartingAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_CHAIN_HEAL)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_CHAIN_HEAL)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_CHAIN_LIGHTNING)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_TOTEM_EARTH)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_TOTEM_EARTHBIND)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_TOTEM_FIRE)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_TOTEM_STONESKIN)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_TOTEM_WATER)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_TOTEM_WIND)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_TOTEM_WINDFURY)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_HEALING_WAVE)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_HEX)
    call AI_AddProfileAbility(AI_Restoshaman_ProfileId, AI_RESTOSHAMAN_ABILITY_LIGHTNING_BOLT)
endfunction

private function RegisterAbilityTemplates takes nothing returns nothing
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_LIGHTNING_BOLT, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_CHAIN_LIGHTNING, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_HEX, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_TOTEM_WINDFURY, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_TOTEM_WATER, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_TOTEM_EARTH, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_TOTEM_EARTHBIND, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_TOTEM_FIRE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_TOTEM_STONESKIN, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_TOTEM_WIND, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_HEALING_WAVE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_RESTOSHAMAN_UNIT_HORDE, AI_RESTOSHAMAN_ABILITY_CHAIN_HEAL, "", "")
endfunction

private function TryTotem takes unit shaman, integer abilityId, real cooldown returns boolean
    local real angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
    local real distance = GetRandomReal(300.00, 600.00)
    local real x = GetUnitX(shaman) + distance * Cos(angle)
    local real y = GetUnitY(shaman) + distance * Sin(angle)
    if not CanCastTotem(shaman, abilityId) then
        return false
    endif
    if AI_TemporaryAbilitySwap(shaman, 0, abilityId, 1, 2.00) then
        return AI_TryCastPoint(shaman, x, y, abilityId, "healingward", cooldown)
    endif
    return false
endfunction

private function ShouldUseSupportTotems takes boolean companionControlled, real allyLife, integer enemyCount returns boolean
    return not companionControlled or allyLife <= 50.00 or enemyCount >= 3
endfunction

private function Think takes nothing returns nothing
    local unit shaman = AI_EventUnit
    local unit target = AI_EventTarget
    local unit ally
    local integer enemyCount
    local integer roll
    local real allyLife
    local real shamanLife
    local boolean companionControlled
    local boolean supportTotemsAllowed
    if shaman == null then
        set shaman = null
        return
    endif
    set ally = AI_FindLowestHealthAlly(shaman, 800.00, true)
    set enemyCount = AI_CountNearbyEnemies(shaman, 600.00)
    set roll = GetRandomInt(1, 100)
    set shamanLife = AI_GetUnitLifePercent(shaman)
    if ally != null then
        set allyLife = AI_GetUnitLifePercent(ally)
    else
        set allyLife = 100.00
    endif
    set companionControlled = AI_GetState(shaman) == AI_STATE_COMPANION_CONTROLLED
    set supportTotemsAllowed = ShouldUseSupportTotems(companionControlled, allyLife, enemyCount)
    if ally != null and (allyLife <= 35.00 or (companionControlled and allyLife <= 55.00)) and AI_TryCastTarget(shaman, ally, AI_RESTOSHAMAN_ABILITY_HEALING_WAVE, "holybolt", 2.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif ally != null and allyLife <= 70.00 and (enemyCount >= 2 or (companionControlled and enemyCount >= 1)) and roll <= 65 and AI_TryCastTarget(shaman, ally, AI_RESTOSHAMAN_ABILITY_CHAIN_HEAL, "healingwave", 2.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif shamanLife <= 45.00 and enemyCount >= 1 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_EARTHBIND, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif target != null and enemyCount > 2 and roll <= 35 and AI_TryCastTarget(shaman, target, AI_RESTOSHAMAN_ABILITY_CHAIN_LIGHTNING, "chainlightning", 2.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif target != null and enemyCount > 2 and roll <= 48 and AI_TryCastTarget(shaman, target, AI_RESTOSHAMAN_ABILITY_HEX, "hex", 2.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif ally != null and supportTotemsAllowed and allyLife <= 85.00 and roll <= 62 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_EARTH, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif AI_GetState(shaman) == AI_STATE_RETREAT_COMBAT and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_EARTHBIND, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif supportTotemsAllowed and enemyCount >= 1 and roll <= 72 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_FIRE, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif supportTotemsAllowed and enemyCount > 2 and roll <= 82 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_STONESKIN, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif ally != null and supportTotemsAllowed and AI_GetUnitManaPercent(ally) <= 55.00 and roll <= 90 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_WATER, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif supportTotemsAllowed and enemyCount > 2 and roll <= 96 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_WIND, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif supportTotemsAllowed and roll >= 97 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_WINDFURY, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif target != null and AI_TryCastTarget(shaman, target, AI_RESTOSHAMAN_ABILITY_LIGHTNING_BOLT, "chainlightning", 2.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif target != null then
        call IssueTargetOrder(shaman, "attack", target)
    endif
    set shaman = null
    set target = null
    set ally = null
endfunction

public function Register takes unit whichUnit returns integer
    return AI_RegisterUnit(whichUnit, AI_Restoshaman_ProfileId, 0)
endfunction

private function Init takes nothing returns nothing
    set AI_Restoshaman_ClassId = AI_RegisterClass("Restoshaman")
    set AI_Restoshaman_ProfileId = AI_RegisterProfile(AI_Restoshaman_ClassId, AI_RESTOSHAMAN_UNIT_HORDE, "Horde Restoshaman")
    call AI_SetProfileFaction(AI_Restoshaman_ProfileId, "Horde")
    call AI_SetProfileSpawnOwner(AI_Restoshaman_ProfileId, Player(1))
    call AI_SetProfileThinkCallback(AI_Restoshaman_ProfileId, function Think)
    call AI_AddProfileProfession(AI_Restoshaman_ProfileId, AI_PROFESSION_HERBALISM)
    call RegisterAbilities()
    call RegisterAbilityTemplates()
    call AI_AddDefaultShopItems(AI_Restoshaman_ProfileId)
    call AI_AddRandomSpawnProfile(AI_Restoshaman_ProfileId)
    call RegisterBarks()
endfunction

endlibrary
