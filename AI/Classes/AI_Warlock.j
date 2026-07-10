/**
    AI_Warlock

    Author: Valdemar
    Version:

    Description:
    Warlock AI profile registration. Detailed Warlock spell and imp behavior
    will be layered into this library after the master AI registry is verified.

    Credits:
    - Old GUI HeroWarlock triggers

    How to install:
    Requires `AI.j` and `AbilitiesLiteUI.j`.

    API:
    call AIWarlock_Register(unit whichUnit)

**/
library AIWarlock initializer Init requires AI, AbilitiesLiteUI, Table

globals
    constant integer AI_WARLOCK_UNIT_UNDEAD = 'O61K'
    constant integer AI_WARLOCK_UNIT_ORC = 'H60X'
    constant integer AI_WARLOCK_UNIT_IMP_1 = 'n61L'
    constant integer AI_WARLOCK_UNIT_IMP_2 = 'n61S'
    constant integer AI_WARLOCK_UNIT_IMP_3 = 'n61T'
    constant integer AI_WARLOCK_ABILITY_LIFE_DRAIN = 'A6EA'
    constant integer AI_WARLOCK_ABILITY_SHADOW_BOLT = 'A6EB'
    constant integer AI_WARLOCK_ABILITY_BANISH = 'A6EC'
    constant integer AI_WARLOCK_ABILITY_SUMMON_IMP = 'A6ED'
    constant integer AI_WARLOCK_ABILITY_RAIN_OF_FIRE = 'A6EE'
    constant integer AI_WARLOCK_ABILITY_LIFE_TAP = 'A6EI'
    constant integer AI_WARLOCK_ABILITY_FEAR = 'A6EG'
    constant integer AI_WARLOCK_ABILITY_CURSE_OF_AGONY = 'A6EH'
    integer AI_Warlock_ClassId = 0
    integer AI_Warlock_ProfileId = 0
    integer AI_Warlock_OrcProfileId = 0
    integer AI_Warlock_UndeadProfileId = 0

    private constant integer MAX_PLAYER_INDEX = 27
    private constant integer MAX_ACTIVE_IMPS = 128
    private constant real IMP_THINK_INTERVAL = 2.00
    private constant real IMP_FOLLOW_RANGE = 600.00
    private constant real IMP_FIREBOLT_RANGE = 600.00

    private Table WarlockImpByInstance = 0
    private Table ImpOwnerInstance = 0
    private timer ImpTimer = null
    private trigger SummonTrigger = null
    private trigger ImpDeathTrigger = null
    private integer ActiveImpCount = 0
    private unit array ActiveImps
endglobals

private function EnsureImpState takes nothing returns nothing
    if WarlockImpByInstance == 0 then
        set WarlockImpByInstance = Table.create()
        set ImpOwnerInstance = Table.create()
    endif
endfunction

private function RegisterPlayerUnitEventAll takes trigger whichTrigger, playerunitevent whichEvent returns nothing
    local integer playerIndex = 0
    loop
        call TriggerRegisterPlayerUnitEvent(whichTrigger, Player(playerIndex), whichEvent, null)
        set playerIndex = playerIndex + 1
        exitwhen playerIndex > MAX_PLAYER_INDEX
    endloop
endfunction

private function IsAliveUnit takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
endfunction

private function IsImpUnitType takes integer unitTypeId returns boolean
    return unitTypeId == AI_WARLOCK_UNIT_IMP_1 or unitTypeId == AI_WARLOCK_UNIT_IMP_2 or unitTypeId == AI_WARLOCK_UNIT_IMP_3
endfunction

private function IsWarlockProfile takes integer profileId returns boolean
    return profileId == AI_Warlock_ProfileId or profileId == AI_Warlock_OrcProfileId or profileId == AI_Warlock_UndeadProfileId
endfunction

private function RemoveImpAtIndex takes integer index returns nothing
    local unit moved
    if index <= 0 or index > ActiveImpCount then
        return
    endif
    set moved = ActiveImps[ActiveImpCount]
    set ActiveImps[index] = moved
    set ActiveImps[ActiveImpCount] = null
    set ActiveImpCount = ActiveImpCount - 1
    set moved = null
endfunction

private function AddTrackedImp takes unit imp returns nothing
    if imp == null or ActiveImpCount >= MAX_ACTIVE_IMPS then
        return
    endif
    set ActiveImpCount = ActiveImpCount + 1
    set ActiveImps[ActiveImpCount] = imp
endfunction

private function GetOwnedImp takes unit warlock returns unit
    local integer instanceId = AI_GetInstance(warlock)
    local unit imp
    call EnsureImpState()
    if instanceId <= 0 then
        return null
    endif
    set imp = WarlockImpByInstance.unit[instanceId]
    if not IsAliveUnit(imp) then
        set WarlockImpByInstance.unit[instanceId] = null
        set imp = null
    endif
    return imp
endfunction

private function TrackSummonedImp takes unit warlock, unit imp returns nothing
    local integer instanceId = AI_GetInstance(warlock)
    local unit oldImp
    call EnsureImpState()
    if instanceId <= 0 or imp == null or not IsWarlockProfile(AI_GetProfileId(warlock)) then
        return
    endif
    set oldImp = WarlockImpByInstance.unit[instanceId]
    if oldImp != null and oldImp != imp and IsAliveUnit(oldImp) then
        call KillUnit(oldImp)
    endif
    set WarlockImpByInstance.unit[instanceId] = imp
    set ImpOwnerInstance[GetHandleId(imp)] = instanceId
    call AddTrackedImp(imp)
    set oldImp = null
endfunction

private function HandleSummon takes nothing returns nothing
    local unit summoner = GetSummoningUnit()
    local unit summoned = GetSummonedUnit()
    if IsImpUnitType(GetUnitTypeId(summoned)) then
        call TrackSummonedImp(summoner, summoned)
    endif
    set summoner = null
    set summoned = null
endfunction

private function HandleImpDeath takes nothing returns nothing
    local unit dying = GetDyingUnit()
    local integer handleId = GetHandleId(dying)
    local integer ownerInstance
    local integer index = 1
    call EnsureImpState()
    set ownerInstance = ImpOwnerInstance[handleId]
    if ownerInstance > 0 and WarlockImpByInstance.unit[ownerInstance] == dying then
        set WarlockImpByInstance.unit[ownerInstance] = null
    endif
    call ImpOwnerInstance.remove(handleId)
    loop
        exitwhen index > ActiveImpCount
        if ActiveImps[index] == dying then
            call RemoveImpAtIndex(index)
            set dying = null
            return
        endif
        set index = index + 1
    endloop
    set dying = null
endfunction

private function TickImps takes nothing returns nothing
    local integer index = 1
    local unit imp
    local unit owner
    local unit target
    local integer ownerInstance
    local real dx
    local real dy
    loop
        exitwhen index > ActiveImpCount
        set imp = ActiveImps[index]
        if not IsAliveUnit(imp) then
            call RemoveImpAtIndex(index)
            set index = index - 1
        else
            set ownerInstance = ImpOwnerInstance[GetHandleId(imp)]
            set owner = AI_GetUnitByInstance(ownerInstance)
            if IsAliveUnit(owner) then
                set dx = GetUnitX(imp) - GetUnitX(owner)
                set dy = GetUnitY(imp) - GetUnitY(owner)
                if dx * dx + dy * dy > IMP_FOLLOW_RANGE * IMP_FOLLOW_RANGE or GetUnitCurrentOrder(imp) != OrderId("smart") then
                    call IssueTargetOrder(imp, "smart", owner)
                endif
                set target = AI_FindClosestEnemy(imp, IMP_FIREBOLT_RANGE)
                if target != null then
                    call IssueTargetOrder(imp, "firebolt", target)
                endif
            endif
        endif
        set index = index + 1
    endloop
    set imp = null
    set owner = null
    set target = null
endfunction

private function RegisterBarks takes integer profileId returns nothing
    call AI_RegisterBarkLine(profileId, AI_BARK_GREET, "Ah, the shaman graces me with their presence.", "HeroWarlock_Greet1")
    call AI_RegisterBarkLine(profileId, AI_BARK_GREET, "Let's see if your 'spirits' can keep up today.", "HeroWarlock_Greet2")
    call AI_RegisterBarkLine(profileId, AI_BARK_GREET, "What chaos shall we unleash?", "HeroWarlock_Greet3")
    call AI_RegisterBarkLine(profileId, AI_BARK_GREET, "The void stirs. What is your will?", "HeroWarlock_Greet4")
    call AI_RegisterBarkLine(profileId, AI_BARK_FAREWELL, "Try not to get lost communing with rocks and wind.", "HeroWarlock_Farewell1")
    call AI_RegisterBarkLine(profileId, AI_BARK_FAREWELL, "Until we meet again.", "HeroWarlock_Farewell2")
    call AI_RegisterBarkLine(profileId, AI_BARK_PASSIVE, "I will follow, but I will not bow.", "HeroWarlock_Passive1")
    call AI_RegisterBarkLine(profileId, AI_BARK_PASSIVE, "Do not mistake my silence for obedience.", "HeroWarlock_Passive2")
    call AI_RegisterBarkLine(profileId, AI_BARK_NORMAL, "Chaos awaits your word.", "HeroWarlock_Normal1")
    call AI_RegisterBarkLine(profileId, AI_BARK_NORMAL, "As you command, so it shall be.", "HeroWarlock_Normal2")
    call AI_RegisterBarkLine(profileId, AI_BARK_NORMAL, "I hunger for action.", "HeroWarlock_Normal3")
    call AI_RegisterBarkLine(profileId, AI_BARK_AGGRESSIVE, "Time to unleash the fury of the Twisting Nether!", "HeroWarlock_Aggressive1")
    call AI_RegisterBarkLine(profileId, AI_BARK_AGGRESSIVE, "The weak shall perish!", "HeroWarlock_Aggressive2")
    call AI_RegisterBarkLine(profileId, AI_BARK_AGGRESSIVE, "Let the world burn!", "HeroWarlock_Aggressive3")
    call AI_RegisterBarkLine(profileId, AI_BARK_HOLD, "Are we meditating again? How quaint.", "HeroWarlock_HoldPositions1")
    call AI_RegisterBarkLine(profileId, AI_BARK_HOLD, "I'll stay, but do not test my patience.", "HeroWarlock_HoldPositions2")
    call AI_RegisterBarkLine(profileId, AI_BARK_DROP_ITEMS, "Here, shaman. Perhaps it will help you commune better with the dirt.", "HeroWarlock_DropItems1")
    call AI_RegisterBarkLine(profileId, AI_BARK_DROP_ITEMS, "Take them before I change my mind.", "HeroWarlock_DropItems2")
    call AI_RegisterBarkLine(profileId, AI_BARK_DROP_ITEMS, "They are yours, for now.", "HeroWarlock_DropItems3")
    call AI_RegisterBarkLine(profileId, AI_BARK_IDLE, "Have you gone into a trance again, shaman?", "HeroWarlock_Idle1")
    call AI_RegisterBarkLine(profileId, AI_BARK_IDLE, "Shall we stand here until the end of days?", "HeroWarlock_Idle2")
    call AI_RegisterBarkLine(profileId, AI_BARK_MOVING, "Is this where the wind told you to go?", "HeroWarlock_Moving1")
    call AI_RegisterBarkLine(profileId, AI_BARK_MOVING, "This path reeks of death... I like it.", "HeroWarlock_Moving2")
    call AI_RegisterBarkLine(profileId, AI_BARK_MOVING, "Even the shadows grow weary of this pace.", "HeroWarlock_Moving3")
    call AI_RegisterBarkLine(profileId, AI_BARK_CASTING, "Watch and learn, shaman.", "HeroWarlock_Casting1")
    call AI_RegisterBarkLine(profileId, AI_BARK_CASTING, "This is how real power feels.", "HeroWarlock_Casting2")
    call AI_RegisterBarkLine(profileId, AI_BARK_CASTING, "Pain is the price of power!", "HeroWarlock_Casting3")
    call AI_RegisterBarkLine(profileId, AI_BARK_ATTACKING, "Feel the fury of power unchained!", "HeroWarlock_Attacking1")
    call AI_RegisterBarkLine(profileId, AI_BARK_ATTACKING, "Your end was written in the shadows.", "HeroWarlock_Attacking2")
    call AI_RegisterBarkLine(profileId, AI_BARK_ATTACKING, "You cannot escape your fate!", "HeroWarlock_Attacking3")
    call AI_RegisterBarkLine(profileId, AI_BARK_KILLING, "Their screams still linger.", "HeroWarlock_Killing1")
    call AI_RegisterBarkLine(profileId, AI_BARK_KILLING, "A fitting sacrifice.", "HeroWarlock_Killing2")
    call AI_RegisterBarkLine(profileId, AI_BARK_KILLING, "Weaklings fall before me.", "HeroWarlock_Killing3")
    call AI_RegisterBarkLine(profileId, AI_BARK_KICKED, "When you beg for my aid, I will laugh.", "HeroWarlock_Kicked1")
    call AI_RegisterBarkLine(profileId, AI_BARK_COMPANION_DIES, "They weren't strong enough...", "HeroWarlock_OtherDies1")
    call AI_RegisterBarkLine(profileId, AI_BARK_COMPANION_DIES, "They served their purpose. Barely.", "HeroWarlock_OtherDies2")
    call AI_RegisterBarkLine(profileId, AI_BARK_COMPANION_DIES, "Their weakness was their undoing.", "HeroWarlock_OtherDies3")
    call AI_RegisterBarkLine(profileId, AI_BARK_ITEM_GIVEN, "A gift from the shaman? How thoughtful.", "HeroWarlock_ItemGiven1")
    call AI_RegisterBarkLine(profileId, AI_BARK_ITEM_GIVEN, "A trinket? Useful... perhaps.", "HeroWarlock_ItemGiven2")
    call AI_RegisterBarkLine(profileId, AI_BARK_ITEM_GIVEN, "Power, no matter how small, has its uses.", "HeroWarlock_ItemGiven3")
    call AI_RegisterBarkLine(profileId, AI_BARK_ITEM_GIVEN, "I accept this offering.", "HeroWarlock_ItemGiven4")
endfunction

private function RegisterAbilities takes integer profileId returns nothing
    call AI_AddProfileStartingAbility(profileId, AI_WARLOCK_ABILITY_BANISH)
    call AI_AddProfileStartingAbility(profileId, AI_WARLOCK_ABILITY_CURSE_OF_AGONY)
    call AI_AddProfileStartingAbility(profileId, AI_WARLOCK_ABILITY_FEAR)
    call AI_AddProfileStartingAbility(profileId, AI_WARLOCK_ABILITY_LIFE_DRAIN)
    call AI_AddProfileStartingAbility(profileId, AI_WARLOCK_ABILITY_RAIN_OF_FIRE)
    call AI_AddProfileStartingAbility(profileId, AI_WARLOCK_ABILITY_SHADOW_BOLT)
    call AI_AddProfileStartingAbility(profileId, AI_WARLOCK_ABILITY_SUMMON_IMP)
    call AI_AddProfileAbility(profileId, AI_WARLOCK_ABILITY_BANISH)
    call AI_AddProfileAbility(profileId, AI_WARLOCK_ABILITY_CURSE_OF_AGONY)
    call AI_AddProfileAbility(profileId, AI_WARLOCK_ABILITY_FEAR)
    call AI_AddProfileAbility(profileId, AI_WARLOCK_ABILITY_LIFE_DRAIN)
    call AI_AddProfileAbility(profileId, AI_WARLOCK_ABILITY_RAIN_OF_FIRE)
    call AI_AddProfileAbility(profileId, AI_WARLOCK_ABILITY_SHADOW_BOLT)
    call AI_AddProfileAbility(profileId, AI_WARLOCK_ABILITY_SUMMON_IMP)
    call AI_AddProfileAbility(profileId, AI_WARLOCK_ABILITY_LIFE_TAP)
endfunction

private function RegisterAbilityTemplatesForUnitType takes integer unitTypeId returns nothing
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARLOCK_ABILITY_BANISH, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARLOCK_ABILITY_CURSE_OF_AGONY, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARLOCK_ABILITY_FEAR, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARLOCK_ABILITY_LIFE_DRAIN, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARLOCK_ABILITY_RAIN_OF_FIRE, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARLOCK_ABILITY_SHADOW_BOLT, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARLOCK_ABILITY_SUMMON_IMP, "", "")
    call AbilitiesLiteUI_RegisterAbilityForUnitTypeAuto(unitTypeId, AI_WARLOCK_ABILITY_LIFE_TAP, "", "")
endfunction

private function RegisterAbilityTemplates takes nothing returns nothing
    call RegisterAbilityTemplatesForUnitType(AI_WARLOCK_UNIT_ORC)
    call RegisterAbilityTemplatesForUnitType(AI_WARLOCK_UNIT_UNDEAD)
endfunction

private function Think takes nothing returns nothing
    local unit warlock = AI_EventUnit
    local unit target = AI_EventTarget
    local integer enemyCount
    local integer roll
    local real lifePercent
    local real manaPercent
    if warlock == null then
        set warlock = null
        return
    endif
    if AI_IsUnitCastingLocked(warlock) then
        set warlock = null
        set target = null
        return
    endif
    set enemyCount = AI_CountNearbyEnemies(warlock, 600.00)
    set roll = GetRandomInt(1, 100)
    set lifePercent = AI_GetUnitLifePercent(warlock)
    set manaPercent = AI_GetUnitManaPercent(warlock)
    if manaPercent <= 70.00 and lifePercent >= 45.00 and enemyCount <= 1 and roll <= 35 and AI_TemporaryAbilitySwap(warlock, 0, AI_WARLOCK_ABILITY_LIFE_TAP, 1, 1.20) and AI_TryCastImmediate(warlock, AI_WARLOCK_ABILITY_LIFE_TAP, "berserk", 2.00) then
        call AI_RequestBark(warlock, AI_BARK_CASTING)
    elseif target != null and lifePercent <= 35.00 and enemyCount >= 1 and AI_TryCastTarget(warlock, target, AI_WARLOCK_ABILITY_FEAR, "sleep", 2.00) then
        call AI_RequestBark(warlock, AI_BARK_CASTING)
    elseif target != null and lifePercent <= 65.00 and roll <= 55 and AI_TryCastTarget(warlock, target, AI_WARLOCK_ABILITY_LIFE_DRAIN, "drain", 5.00) then
        call AI_RequestBark(warlock, AI_BARK_CASTING)
    elseif GetOwnedImp(warlock) == null and (enemyCount <= 1 or roll <= 25) and AI_TryCastImmediate(warlock, AI_WARLOCK_ABILITY_SUMMON_IMP, "feralspirit", 3.00) then
        call AI_RequestBark(warlock, AI_BARK_CASTING)
    elseif enemyCount <= 0 or target == null then
        if GetOwnedImp(warlock) == null and AI_TryCastImmediate(warlock, AI_WARLOCK_ABILITY_SUMMON_IMP, "feralspirit", 3.00) then
            call AI_RequestBark(warlock, AI_BARK_CASTING)
        endif
    elseif roll <= 45 and AI_TryCastTarget(warlock, target, AI_WARLOCK_ABILITY_SHADOW_BOLT, "firebolt", 2.00) then
        call AI_RequestBark(warlock, AI_BARK_CASTING)
    elseif roll <= 65 and AI_TryCastTarget(warlock, target, AI_WARLOCK_ABILITY_CURSE_OF_AGONY, "parasite", 1.00) then
        call AI_RequestBark(warlock, AI_BARK_CASTING)
    elseif enemyCount > 2 and roll <= 75 and AI_TryCastTarget(warlock, target, AI_WARLOCK_ABILITY_FEAR, "sleep", 2.00) then
        call AI_RequestBark(warlock, AI_BARK_CASTING)
    elseif enemyCount > 2 and roll <= 88 and AI_TryCastPoint(warlock, GetUnitX(target), GetUnitY(target), AI_WARLOCK_ABILITY_RAIN_OF_FIRE, "rainoffire", 6.00) then
        call AI_RequestBark(warlock, AI_BARK_CASTING)
    elseif enemyCount > 2 and roll <= 96 and AI_TryCastTarget(warlock, target, AI_WARLOCK_ABILITY_BANISH, "banish", 3.00) then
        call AI_RequestBark(warlock, AI_BARK_CASTING)
    else
        call IssueTargetOrder(warlock, "attack", target)
    endif
    set warlock = null
    set target = null
endfunction

public function Register takes unit whichUnit returns integer
    local integer unitTypeId
    if whichUnit == null then
        return 0
    endif
    set unitTypeId = GetUnitTypeId(whichUnit)
    if unitTypeId == AI_WARLOCK_UNIT_ORC then
        return AI_RegisterUnit(whichUnit, AI_Warlock_OrcProfileId, 0)
    elseif unitTypeId == AI_WARLOCK_UNIT_UNDEAD then
        return AI_RegisterUnit(whichUnit, AI_Warlock_UndeadProfileId, 0)
    endif
    return 0
endfunction

private function Init takes nothing returns nothing
    call EnsureImpState()
    set AI_Warlock_ClassId = AI_RegisterClass("Warlock")
    set AI_Warlock_ProfileId = AI_RegisterProfile(AI_Warlock_ClassId, AI_WARLOCK_UNIT_ORC, "Orc Warlock")
    set AI_Warlock_OrcProfileId = AI_Warlock_ProfileId
    set AI_Warlock_UndeadProfileId = AI_RegisterProfile(AI_Warlock_ClassId, AI_WARLOCK_UNIT_UNDEAD, "Undead Warlock")
    call AI_SetProfileFaction(AI_Warlock_ProfileId, "Horde")
    call AI_SetProfileFaction(AI_Warlock_UndeadProfileId, "Undead")
    call AI_SetProfileSpawnOwner(AI_Warlock_ProfileId, Player(1))
    call AI_SetProfileSpawnOwner(AI_Warlock_UndeadProfileId, Player(1))
    call AI_SetProfileThinkCallback(AI_Warlock_ProfileId, function Think)
    call AI_SetProfileThinkCallback(AI_Warlock_UndeadProfileId, function Think)
    call RegisterAbilities(AI_Warlock_ProfileId)
    call RegisterAbilities(AI_Warlock_UndeadProfileId)
    call RegisterAbilityTemplates()
    call AI_AddDefaultShopItems(AI_Warlock_ProfileId)
    call AI_AddDefaultShopItems(AI_Warlock_UndeadProfileId)
    call AI_AddRandomSpawnProfile(AI_Warlock_ProfileId)
    call AI_AddRandomSpawnProfile(AI_Warlock_UndeadProfileId)
    call RegisterBarks(AI_Warlock_ProfileId)

    set SummonTrigger = CreateTrigger()
    call RegisterPlayerUnitEventAll(SummonTrigger, EVENT_PLAYER_UNIT_SUMMON)
    call TriggerAddAction(SummonTrigger, function HandleSummon)

    set ImpDeathTrigger = CreateTrigger()
    call RegisterPlayerUnitEventAll(ImpDeathTrigger, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(ImpDeathTrigger, function HandleImpDeath)

    set ImpTimer = CreateTimer()
    call TimerStart(ImpTimer, IMP_THINK_INTERVAL, true, function TickImps)
endfunction

endlibrary
