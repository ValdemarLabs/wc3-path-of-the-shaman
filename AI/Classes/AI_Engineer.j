/**
    AI_Engineer

    Author: Valdemar
    Version:

    Description:
    Engineer AI profile registration. Detailed Engineer gadget, construct,
    turret, drone, and Shredder logic will be layered into this library after
    the master AI registry is verified.

    Credits:
    - Old GUI Neutral Engineer triggers

    How to install:
    Requires `AI.j` and `AbilitiesLiteUI.j`.

    API:
    call AIEngineer_Register(unit whichUnit)

**/
library AIEngineer initializer Init requires AI, AbilitiesLiteUI, VoicelinesEngineer

globals
    constant integer AI_ENGINEER_UNIT_NEUTRAL = 'N64O'
    constant integer AI_ENGINEER_UNIT_SHREDDER = 'N661'
    constant integer AI_ENGINEER_ABILITY_REPAIR = 'A00J'
    constant integer AI_ENGINEER_ABILITY_SHREDDER_SLAM = 'A00L'
    constant integer AI_ENGINEER_ABILITY_SHREDDER_CLUSTER = 'A00N'
    constant integer AI_ENGINEER_ABILITY_MECHANICAL_CONSTRUCT = 'A6FA'
    constant integer AI_ENGINEER_ABILITY_GRENADE = 'A6FV'
    constant integer AI_ENGINEER_ABILITY_SHREDDER_FORM = 'A6FX'
    constant integer AI_ENGINEER_ABILITY_SHREDDER_SHRED = 'A6FY'
    constant integer AI_ENGINEER_ABILITY_TURRET = 'A6FZ'
    constant integer AI_ENGINEER_ABILITY_DRONE = 'A6G0'
    constant integer AI_ENGINEER_ABILITY_SMOKE_BOMB = 'A6G1'
    constant integer AI_ENGINEER_ORDER_SHREDDER_SLAM = 852097
    integer AI_Engineer_ClassId = 0
    integer AI_Engineer_ProfileId = 0
    integer AI_Engineer_ShredderProfileId = 0
endglobals

private function RegisterEngineerBarks takes integer profileId returns nothing
    call AI_RegisterBarkLine(profileId, AI_BARK_GREET, VL_ENGINEER_HEROENGINEER_GREET1_TEXT, VL_ENGINEER_HEROENGINEER_GREET1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_GREET, VL_ENGINEER_HEROENGINEER_GREET2_TEXT, VL_ENGINEER_HEROENGINEER_GREET2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_GREET, VL_ENGINEER_HEROENGINEER_GREET3_TEXT, VL_ENGINEER_HEROENGINEER_GREET3_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_FAREWELL, VL_ENGINEER_HEROENGINEER_FAREWELL1_TEXT, VL_ENGINEER_HEROENGINEER_FAREWELL1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_FAREWELL, VL_ENGINEER_HEROENGINEER_FAREWELL2_TEXT, VL_ENGINEER_HEROENGINEER_FAREWELL2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_FAREWELL, VL_ENGINEER_HEROENGINEER_FAREWELL3_TEXT, VL_ENGINEER_HEROENGINEER_FAREWELL3_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_PASSIVE, VL_ENGINEER_HEROENGINEER_PASSIVE1_TEXT, VL_ENGINEER_HEROENGINEER_PASSIVE1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_PASSIVE, VL_ENGINEER_HEROENGINEER_PASSIVE2_TEXT, VL_ENGINEER_HEROENGINEER_PASSIVE2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_PASSIVE, VL_ENGINEER_HEROENGINEER_PASSIVE3_TEXT, VL_ENGINEER_HEROENGINEER_PASSIVE3_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_NORMAL, VL_ENGINEER_HEROENGINEER_NORMAL1_TEXT, VL_ENGINEER_HEROENGINEER_NORMAL1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_NORMAL, VL_ENGINEER_HEROENGINEER_NORMAL2_TEXT, VL_ENGINEER_HEROENGINEER_NORMAL2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_NORMAL, VL_ENGINEER_HEROENGINEER_NORMAL3_TEXT, VL_ENGINEER_HEROENGINEER_NORMAL3_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_AGGRESSIVE, VL_ENGINEER_HEROENGINEER_AGGRESSIVE1_TEXT, VL_ENGINEER_HEROENGINEER_AGGRESSIVE1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_AGGRESSIVE, VL_ENGINEER_HEROENGINEER_AGGRESSIVE2_TEXT, VL_ENGINEER_HEROENGINEER_AGGRESSIVE2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_HOLD, VL_ENGINEER_HEROENGINEER_HOLDPOSITIONS1_TEXT, VL_ENGINEER_HEROENGINEER_HOLDPOSITIONS1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_HOLD, VL_ENGINEER_HEROENGINEER_HOLDPOSITIONS2_TEXT, VL_ENGINEER_HEROENGINEER_HOLDPOSITIONS2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_DROP_ITEMS, VL_ENGINEER_HEROENGINEER_DROPITEMS1_TEXT, VL_ENGINEER_HEROENGINEER_DROPITEMS1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_DROP_ITEMS, VL_ENGINEER_HEROENGINEER_DROPITEMS2_TEXT, VL_ENGINEER_HEROENGINEER_DROPITEMS2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_IDLE, VL_ENGINEER_HEROENGINEER_IDLE1_TEXT, VL_ENGINEER_HEROENGINEER_IDLE1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_IDLE, VL_ENGINEER_HEROENGINEER_IDLE2_TEXT, VL_ENGINEER_HEROENGINEER_IDLE2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_MOVING, VL_ENGINEER_HEROENGINEER_MOVING1_TEXT, VL_ENGINEER_HEROENGINEER_MOVING1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_MOVING, VL_ENGINEER_HEROENGINEER_MOVING2_TEXT, VL_ENGINEER_HEROENGINEER_MOVING2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_MOVING, VL_ENGINEER_HEROENGINEER_MOVING3_TEXT, VL_ENGINEER_HEROENGINEER_MOVING3_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_CASTING, VL_ENGINEER_HEROENGINEER_CASTING1_TEXT, VL_ENGINEER_HEROENGINEER_CASTING1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_CASTING, VL_ENGINEER_HEROENGINEER_CASTING2_TEXT, VL_ENGINEER_HEROENGINEER_CASTING2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_CASTING, VL_ENGINEER_HEROENGINEER_CASTING3_TEXT, VL_ENGINEER_HEROENGINEER_CASTING3_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_ATTACKING, VL_ENGINEER_HEROENGINEER_ATTACKING1_TEXT, VL_ENGINEER_HEROENGINEER_ATTACKING1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_ATTACKING, VL_ENGINEER_HEROENGINEER_ATTACKING2_TEXT, VL_ENGINEER_HEROENGINEER_ATTACKING2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_ATTACKING, VL_ENGINEER_HEROENGINEER_ATTACKING3_TEXT, VL_ENGINEER_HEROENGINEER_ATTACKING3_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_KILLING, VL_ENGINEER_HEROENGINEER_UNITDIES1_TEXT, VL_ENGINEER_HEROENGINEER_UNITDIES1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_KILLING, VL_ENGINEER_HEROENGINEER_UNITDIES2_TEXT, VL_ENGINEER_HEROENGINEER_UNITDIES2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_KILLING, VL_ENGINEER_HEROENGINEER_UNITDIES3_TEXT, VL_ENGINEER_HEROENGINEER_UNITDIES3_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_KICKED, VL_ENGINEER_HEROENGINEER_KICKED1_TEXT, VL_ENGINEER_HEROENGINEER_KICKED1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_KICKED, VL_ENGINEER_HEROENGINEER_KICKED2_TEXT, VL_ENGINEER_HEROENGINEER_KICKED2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_COMPANION_DIES, VL_ENGINEER_HEROENGINEER_COMPANIONDIES1_TEXT, VL_ENGINEER_HEROENGINEER_COMPANIONDIES1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_COMPANION_DIES, VL_ENGINEER_HEROENGINEER_COMPANIONDIES2_TEXT, VL_ENGINEER_HEROENGINEER_COMPANIONDIES2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_ITEM_GIVEN, VL_ENGINEER_HEROENGINEER_GIVEITEM1_TEXT, VL_ENGINEER_HEROENGINEER_GIVEITEM1_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_ITEM_GIVEN, VL_ENGINEER_HEROENGINEER_GIVEITEM2_TEXT, VL_ENGINEER_HEROENGINEER_GIVEITEM2_KEY)
    call AI_RegisterBarkLine(profileId, AI_BARK_ITEM_GIVEN, VL_ENGINEER_HEROENGINEER_GIVEITEM3_TEXT, VL_ENGINEER_HEROENGINEER_GIVEITEM3_KEY)
endfunction

private function RegisterBarks takes nothing returns nothing
    call RegisterEngineerBarks(AI_Engineer_ProfileId)
    call RegisterEngineerBarks(AI_Engineer_ShredderProfileId)
endfunction

private function RegisterAbilities takes nothing returns nothing
    call AI_AddProfileStartingAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_GRENADE)
    call AI_AddProfileStartingAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_MECHANICAL_CONSTRUCT)
    call AI_AddProfileStartingAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_DRONE)
    call AI_AddProfileStartingAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_TURRET)
    call AI_AddProfileStartingAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_REPAIR)
    call AI_AddProfileStartingAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_SHREDDER_FORM)
    call AI_AddProfileAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_GRENADE)
    call AI_AddProfileAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_MECHANICAL_CONSTRUCT)
    call AI_AddProfileAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_DRONE)
    call AI_AddProfileAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_TURRET)
    call AI_AddProfileAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_SMOKE_BOMB)
    call AI_AddProfileAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_SHREDDER_FORM)
    call AI_AddProfileAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_SHREDDER_CLUSTER)
    call AI_AddProfileAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_SHREDDER_SHRED)
    call AI_AddProfileAbility(AI_Engineer_ProfileId, AI_ENGINEER_ABILITY_SHREDDER_SLAM)

    call AI_AddProfileStartingAbility(AI_Engineer_ShredderProfileId, AI_ENGINEER_ABILITY_SHREDDER_CLUSTER)
    call AI_AddProfileStartingAbility(AI_Engineer_ShredderProfileId, AI_ENGINEER_ABILITY_SHREDDER_SHRED)
    call AI_AddProfileStartingAbility(AI_Engineer_ShredderProfileId, AI_ENGINEER_ABILITY_SHREDDER_SLAM)
    call AI_AddProfileAbility(AI_Engineer_ShredderProfileId, AI_ENGINEER_ABILITY_SHREDDER_CLUSTER)
    call AI_AddProfileAbility(AI_Engineer_ShredderProfileId, AI_ENGINEER_ABILITY_SHREDDER_SHRED)
    call AI_AddProfileAbility(AI_Engineer_ShredderProfileId, AI_ENGINEER_ABILITY_SHREDDER_SLAM)
endfunction

private function RegisterAbilityTemplates takes nothing returns nothing
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ENGINEER_UNIT_NEUTRAL, AI_ENGINEER_ABILITY_GRENADE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ENGINEER_UNIT_NEUTRAL, AI_ENGINEER_ABILITY_MECHANICAL_CONSTRUCT, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ENGINEER_UNIT_NEUTRAL, AI_ENGINEER_ABILITY_DRONE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ENGINEER_UNIT_NEUTRAL, AI_ENGINEER_ABILITY_TURRET, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ENGINEER_UNIT_NEUTRAL, AI_ENGINEER_ABILITY_REPAIR, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ENGINEER_UNIT_NEUTRAL, AI_ENGINEER_ABILITY_SHREDDER_FORM, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ENGINEER_UNIT_NEUTRAL, AI_ENGINEER_ABILITY_SMOKE_BOMB, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ENGINEER_UNIT_SHREDDER, AI_ENGINEER_ABILITY_SHREDDER_CLUSTER, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ENGINEER_UNIT_SHREDDER, AI_ENGINEER_ABILITY_SHREDDER_SHRED, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(AI_ENGINEER_UNIT_SHREDDER, AI_ENGINEER_ABILITY_SHREDDER_SLAM, "", "")
endfunction

private function ThinkEngineer takes nothing returns nothing
    local unit engineer = AI_EventUnit
    local unit target = AI_EventTarget
    local integer enemyCount
    local real angle
    local real distance
    local real x
    local real y
    local integer roll
    local real lifePercent
    if engineer == null or target == null then
        set engineer = null
        set target = null
        return
    endif
    set enemyCount = AI_CountNearbyEnemies(engineer, 600.00)
    set roll = GetRandomInt(1, 100)
    set lifePercent = AI_GetUnitLifePercent(engineer)
    set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
    set distance = GetRandomReal(100.00, 400.00)
    set x = GetUnitX(engineer) + distance * Cos(angle)
    set y = GetUnitY(engineer) + distance * Sin(angle)
    if enemyCount <= 0 then
        call IssueTargetOrder(engineer, "attack", target)
    elseif (lifePercent <= 45.00 or enemyCount >= 3) and roll <= 30 and AI_TemporaryAbilitySwap(engineer, AI_ENGINEER_ABILITY_GRENADE, AI_ENGINEER_ABILITY_SMOKE_BOMB, GetUnitAbilityLevel(engineer, AI_ENGINEER_ABILITY_GRENADE), 1.00) and AI_TryCastPoint(engineer, x, y, AI_ENGINEER_ABILITY_SMOKE_BOMB, "clusterrockets", 4.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif enemyCount >= 2 and roll <= 45 and AI_TryCastImmediate(engineer, AI_ENGINEER_ABILITY_SHREDDER_FORM, "bearform", 5.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif enemyCount >= 2 and roll <= 62 and AI_TryCastPoint(engineer, GetUnitX(target), GetUnitY(target), AI_ENGINEER_ABILITY_GRENADE, "clusterrockets", 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif roll <= 74 and AI_TryCastImmediate(engineer, AI_ENGINEER_ABILITY_MECHANICAL_CONSTRUCT, "feralspirit", 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif roll <= 86 and AI_TryCastImmediate(engineer, AI_ENGINEER_ABILITY_TURRET, "summonquillbeast", 5.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif roll <= 96 and AI_TryCastImmediate(engineer, AI_ENGINEER_ABILITY_DRONE, "summonhawk", 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    else
        call IssueTargetOrder(engineer, "attack", target)
    endif
    set engineer = null
    set target = null
endfunction

private function SyncShredderAbilityLevels takes unit engineer returns nothing
    local integer shredderLevel
    if engineer == null then
        return
    endif
    set shredderLevel = GetUnitAbilityLevel(engineer, AI_ENGINEER_ABILITY_SHREDDER_FORM)
    if shredderLevel <= 0 then
        set shredderLevel = 1
    endif
    call SetUnitAbilityLevel(engineer, AI_ENGINEER_ABILITY_SHREDDER_SHRED, shredderLevel)
    call SetUnitAbilityLevel(engineer, AI_ENGINEER_ABILITY_SHREDDER_SLAM, shredderLevel)
    call SetUnitAbilityLevel(engineer, AI_ENGINEER_ABILITY_SHREDDER_CLUSTER, shredderLevel)
endfunction

private function ThinkShredder takes nothing returns nothing
    local unit engineer = AI_EventUnit
    local unit target = AI_EventTarget
    local integer enemyCount
    local integer roll
    local real lifePercent
    if engineer == null or target == null then
        set engineer = null
        set target = null
        return
    endif
    set enemyCount = AI_CountNearbyEnemies(engineer, 600.00)
    set roll = GetRandomInt(1, 100)
    set lifePercent = AI_GetUnitLifePercent(engineer)
    call SyncShredderAbilityLevels(engineer)
    if enemyCount <= 0 then
        call IssueTargetOrder(engineer, "attack", target)
    elseif enemyCount >= 2 and roll <= 35 and AI_TryCastImmediateById(engineer, AI_ENGINEER_ABILITY_SHREDDER_SLAM, AI_ENGINEER_ORDER_SHREDDER_SLAM, 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif lifePercent >= 35.00 and roll <= 58 and AI_TryCastTarget(engineer, target, 0, "absorb", 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif roll <= 76 and AI_TryCastTarget(engineer, target, AI_ENGINEER_ABILITY_SHREDDER_SHRED, "stormbolt", 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif enemyCount >= 2 and roll <= 94 and AI_TryCastPoint(engineer, GetUnitX(target), GetUnitY(target), AI_ENGINEER_ABILITY_SHREDDER_CLUSTER, "clusterrockets", 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    else
        call IssueTargetOrder(engineer, "attack", target)
    endif
    set engineer = null
    set target = null
endfunction

public function Register takes unit whichUnit returns integer
    if whichUnit == null then
        return 0
    endif
    if GetUnitTypeId(whichUnit) == AI_ENGINEER_UNIT_SHREDDER then
        return AI_RegisterUnit(whichUnit, AI_Engineer_ShredderProfileId, 0)
    endif
    return AI_RegisterUnit(whichUnit, AI_Engineer_ProfileId, 0)
endfunction

private function Init takes nothing returns nothing
    set AI_Engineer_ClassId = AI_RegisterClass("Engineer")
    set AI_Engineer_ProfileId = AI_RegisterProfile(AI_Engineer_ClassId, AI_ENGINEER_UNIT_NEUTRAL, "Neutral Engineer")
    set AI_Engineer_ShredderProfileId = AI_RegisterProfile(AI_Engineer_ClassId, AI_ENGINEER_UNIT_SHREDDER, "Engineer Shredder")
    call AI_SetProfileFaction(AI_Engineer_ProfileId, "Goblins")
    call AI_SetProfileFaction(AI_Engineer_ShredderProfileId, "Goblins")
    call AI_SetProfileSpawnOwner(AI_Engineer_ProfileId, Player(6))
    call AI_SetProfileSpawnOwner(AI_Engineer_ShredderProfileId, Player(6))
    call AI_SetProfileThinkCallback(AI_Engineer_ProfileId, function ThinkEngineer)
    call AI_SetProfileThinkCallback(AI_Engineer_ShredderProfileId, function ThinkShredder)
    call AI_AddProfileProfession(AI_Engineer_ProfileId, AI_PROFESSION_MINING)
    call AI_AddProfileProfession(AI_Engineer_ShredderProfileId, AI_PROFESSION_MINING)
    call RegisterAbilities()
    call RegisterAbilityTemplates()
    call AI_AddDefaultShopItems(AI_Engineer_ProfileId)
    call AI_AddDefaultShopItems(AI_Engineer_ShredderProfileId)
    call AI_AddRandomSpawnProfile(AI_Engineer_ProfileId)
    call RegisterBarks()
endfunction

endlibrary
