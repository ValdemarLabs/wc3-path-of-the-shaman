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
    Requires `AI.j`.

    API:
    call AIEngineer_Register(unit whichUnit)

**/
library AIEngineer initializer Init requires AI

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
    call AI_RegisterBarkLine(profileId, AI_BARK_GREET, "What's crackin'? Hopefully not my gadgets!", "HeroEngineer_Greet1")
    call AI_RegisterBarkLine(profileId, AI_BARK_GREET, "Big ideas, small package. Let's do this!", "HeroEngineer_Greet2")
    call AI_RegisterBarkLine(profileId, AI_BARK_GREET, "Need something blown up or built?", "HeroEngineer_Greet3")
    call AI_RegisterBarkLine(profileId, AI_BARK_FAREWELL, "Don't blow yourself up while I'm gone!", "HeroEngineer_Farewell1")
    call AI_RegisterBarkLine(profileId, AI_BARK_FAREWELL, "Catch ya later! Unless you step on a mine!", "HeroEngineer_Farewell2")
    call AI_RegisterBarkLine(profileId, AI_BARK_FAREWELL, "Back to the workshop! Smell ya later!", "HeroEngineer_Farewell3")
    call AI_RegisterBarkLine(profileId, AI_BARK_PASSIVE, "Following the big boss! Gotcha!", "HeroEngineer_Passive1")
    call AI_RegisterBarkLine(profileId, AI_BARK_PASSIVE, "Fine, but don't expect me to stay quiet!", "HeroEngineer_Passive2")
    call AI_RegisterBarkLine(profileId, AI_BARK_PASSIVE, "I'm not built for passivity, but okay!", "HeroEngineer_Passive3")
    call AI_RegisterBarkLine(profileId, AI_BARK_NORMAL, "Ready to tinker and trigger!", "HeroEngineer_Normal1")
    call AI_RegisterBarkLine(profileId, AI_BARK_NORMAL, "Let's get creative... and destructive!", "HeroEngineer_Normal2")
    call AI_RegisterBarkLine(profileId, AI_BARK_NORMAL, "Gears turning, tools ready. What's next?", "HeroEngineer_Normal3")
    call AI_RegisterBarkLine(profileId, AI_BARK_AGGRESSIVE, "Time for a mechanical meltdown!", "HeroEngineer_Aggressive1")
    call AI_RegisterBarkLine(profileId, AI_BARK_AGGRESSIVE, "Let's turn this place into a scrapyard!", "HeroEngineer_Aggressive2")
    call AI_RegisterBarkLine(profileId, AI_BARK_HOLD, "Holding steady! But not for long!", "HeroEngineer_HoldPositions1")
    call AI_RegisterBarkLine(profileId, AI_BARK_HOLD, "Okay, but don't expect me to sit still for too long.", "HeroEngineer_HoldPositions2")
    call AI_RegisterBarkLine(profileId, AI_BARK_DROP_ITEMS, "Here ya go! Don't break it... unless you want to!", "HeroEngineer_DropItems1")
    call AI_RegisterBarkLine(profileId, AI_BARK_DROP_ITEMS, "Take it before I start tinkering with it!", "HeroEngineer_DropItems2")
    call AI_RegisterBarkLine(profileId, AI_BARK_IDLE, "I could be inventing something right now...", "HeroEngineer_Idle1")
    call AI_RegisterBarkLine(profileId, AI_BARK_IDLE, "You hear ticking? Eh, probably nothing.", "HeroEngineer_Idle2")
    call AI_RegisterBarkLine(profileId, AI_BARK_MOVING, "Where are we heading boss?", "HeroEngineer_Moving1")
    call AI_RegisterBarkLine(profileId, AI_BARK_MOVING, "Why haven't I invented rocket boots yet? Could come handy walking these distances...", "HeroEngineer_Moving2")
    call AI_RegisterBarkLine(profileId, AI_BARK_MOVING, "Can we stop by that rock? I think I saw sparkle of rare ore.", "HeroEngineer_Moving3")
    call AI_RegisterBarkLine(profileId, AI_BARK_CASTING, "Deploying my masterpiece!", "HeroEngineer_Casting1")
    call AI_RegisterBarkLine(profileId, AI_BARK_CASTING, "Behold! Goblin engineering at its finest!", "HeroEngineer_Casting2")
    call AI_RegisterBarkLine(profileId, AI_BARK_CASTING, "Watch this! I think it'll work!", "HeroEngineer_Casting3")
    call AI_RegisterBarkLine(profileId, AI_BARK_ATTACKING, "Say hello to my little turret!", "HeroEngineer_Attacking1")
    call AI_RegisterBarkLine(profileId, AI_BARK_ATTACKING, "Boom! Gotcha!", "HeroEngineer_Attacking2")
    call AI_RegisterBarkLine(profileId, AI_BARK_ATTACKING, "Kaboom! Just how I like it!", "HeroEngineer_Attacking3")
    call AI_RegisterBarkLine(profileId, AI_BARK_KILLING, "And THAT'S how you engineer a victory!", "HeroEngineer_UnitDies1")
    call AI_RegisterBarkLine(profileId, AI_BARK_KILLING, "Kaboom! Problem solved!", "HeroEngineer_UnitDies2")
    call AI_RegisterBarkLine(profileId, AI_BARK_KILLING, "Boom goes the bad guy!", "HeroEngineer_UnitDies3")
    call AI_RegisterBarkLine(profileId, AI_BARK_KICKED, "Guess I'll go blow something up elsewhere!", "HeroEngineer_Kicked1")
    call AI_RegisterBarkLine(profileId, AI_BARK_KICKED, "Fine, but you'll miss my brilliance!", "HeroEngineer_Kicked2")
    call AI_RegisterBarkLine(profileId, AI_BARK_COMPANION_DIES, "Tough break! Should've had better armor!", "HeroEngineer_CompanionDies1")
    call AI_RegisterBarkLine(profileId, AI_BARK_COMPANION_DIES, "Aw, now I've got more work to do!", "HeroEngineer_CompanionDies2")
    call AI_RegisterBarkLine(profileId, AI_BARK_ITEM_GIVEN, "This has potential! Or it'll blow up. Either way!", "HeroEngineer_GiveItem1")
    call AI_RegisterBarkLine(profileId, AI_BARK_ITEM_GIVEN, "Nice! I'll make it better... or louder!", "HeroEngineer_GiveItem2")
    call AI_RegisterBarkLine(profileId, AI_BARK_ITEM_GIVEN, "You're trusting me with this? Bold move!", "HeroEngineer_GiveItem3")
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

private function ThinkEngineer takes nothing returns nothing
    local unit engineer = AI_EventUnit
    local unit target = AI_EventTarget
    local integer enemyCount
    local real angle
    local real distance
    local real x
    local real y
    if engineer == null or target == null then
        set engineer = null
        set target = null
        return
    endif
    set enemyCount = AI_CountNearbyEnemies(engineer, 600.00)
    set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
    set distance = GetRandomReal(100.00, 400.00)
    set x = GetUnitX(engineer) + distance * Cos(angle)
    set y = GetUnitY(engineer) + distance * Sin(angle)
    if enemyCount <= 0 then
        call IssueTargetOrder(engineer, "attack", target)
    elseif GetRandomInt(1, 3) == 1 and AI_TryCastPoint(engineer, GetUnitX(target), GetUnitY(target), AI_ENGINEER_ABILITY_GRENADE, "clusterrockets", 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif GetRandomInt(1, 3) == 1 and AI_TryCastImmediate(engineer, AI_ENGINEER_ABILITY_MECHANICAL_CONSTRUCT, "feralspirit", 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif GetRandomInt(1, 6) == 1 and AI_TryCastImmediate(engineer, AI_ENGINEER_ABILITY_SHREDDER_FORM, "bearform", 5.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif GetRandomInt(1, 3) == 1 and AI_TryCastImmediate(engineer, AI_ENGINEER_ABILITY_TURRET, "summonquillbeast", 5.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif enemyCount >= 2 and GetRandomInt(1, 3) == 1 and AI_TemporaryAbilitySwap(engineer, AI_ENGINEER_ABILITY_GRENADE, AI_ENGINEER_ABILITY_SMOKE_BOMB, GetUnitAbilityLevel(engineer, AI_ENGINEER_ABILITY_GRENADE), 1.00) and AI_TryCastPoint(engineer, x, y, AI_ENGINEER_ABILITY_SMOKE_BOMB, "clusterrockets", 4.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif GetRandomInt(1, 3) == 1 and AI_TryCastImmediate(engineer, AI_ENGINEER_ABILITY_DRONE, "summonhawk", 2.00) then
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
    if engineer == null or target == null then
        set engineer = null
        set target = null
        return
    endif
    set enemyCount = AI_CountNearbyEnemies(engineer, 600.00)
    call SyncShredderAbilityLevels(engineer)
    if enemyCount <= 0 then
        call IssueTargetOrder(engineer, "attack", target)
    elseif GetRandomInt(1, 2) == 1 and AI_TryCastTarget(engineer, target, AI_ENGINEER_ABILITY_SHREDDER_SHRED, "stormbolt", 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif AI_TryCastTarget(engineer, target, 0, "absorb", 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif AI_TryCastImmediateById(engineer, AI_ENGINEER_ABILITY_SHREDDER_SLAM, AI_ENGINEER_ORDER_SHREDDER_SLAM, 2.00) then
        call AI_RequestBark(engineer, AI_BARK_CASTING)
    elseif GetRandomInt(1, 3) == 1 and AI_TryCastPoint(engineer, GetUnitX(target), GetUnitY(target), AI_ENGINEER_ABILITY_SHREDDER_CLUSTER, "clusterrockets", 2.00) then
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
    call AI_SetProfileSpawnOwner(AI_Engineer_ProfileId, Player(6))
    call AI_SetProfileSpawnOwner(AI_Engineer_ShredderProfileId, Player(6))
    call AI_SetProfileThinkCallback(AI_Engineer_ProfileId, function ThinkEngineer)
    call AI_SetProfileThinkCallback(AI_Engineer_ShredderProfileId, function ThinkShredder)
    call AI_AddProfileProfession(AI_Engineer_ProfileId, AI_PROFESSION_MINING)
    call AI_AddProfileProfession(AI_Engineer_ShredderProfileId, AI_PROFESSION_MINING)
    call RegisterAbilities()
    call AI_AddDefaultShopItems(AI_Engineer_ProfileId)
    call AI_AddDefaultShopItems(AI_Engineer_ShredderProfileId)
    call AI_AddRandomSpawnProfile(AI_Engineer_ProfileId)
    call RegisterBarks()
endfunction

endlibrary
