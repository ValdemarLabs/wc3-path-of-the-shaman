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
    Requires `AI.j`.

    API:
    call AI_Restoshaman_Register(unit whichUnit)

**/
library AIRestoshaman initializer Init requires AI, Table

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

    private constant integer MAX_PLAYER_INDEX = 27
    private constant integer TOTEM_SLOT_EARTH = 1
    private constant integer TOTEM_SLOT_FIRE = 2
    private constant integer TOTEM_SLOT_WATER = 3
    private constant integer TOTEM_SLOT_WIND = 4
    private constant integer TOTEM_SLOT_EARTHBIND = 5

    private Table TotemByInstanceSlot = 0
    private Table TotemOwnerInstance = 0
    private Table TotemSlotByHandle = 0
    private trigger SummonTrigger = null
    private trigger TotemDeathTrigger = null
endglobals

private function EnsureTotemState takes nothing returns nothing
    if TotemByInstanceSlot == 0 then
        set TotemByInstanceSlot = Table.create()
        set TotemOwnerInstance = Table.create()
        set TotemSlotByHandle = Table.create()
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

private function GetTotemKey takes integer instanceId, integer slot returns integer
    return instanceId * 10 + slot
endfunction

private function GetTotemSlotForAbility takes integer abilityId returns integer
    if abilityId == AI_RESTOSHAMAN_ABILITY_TOTEM_EARTH or abilityId == AI_RESTOSHAMAN_ABILITY_TOTEM_STONESKIN then
        return TOTEM_SLOT_EARTH
    elseif abilityId == AI_RESTOSHAMAN_ABILITY_TOTEM_FIRE then
        return TOTEM_SLOT_FIRE
    elseif abilityId == AI_RESTOSHAMAN_ABILITY_TOTEM_WATER then
        return TOTEM_SLOT_WATER
    elseif abilityId == AI_RESTOSHAMAN_ABILITY_TOTEM_WIND or abilityId == AI_RESTOSHAMAN_ABILITY_TOTEM_WINDFURY then
        return TOTEM_SLOT_WIND
    elseif abilityId == AI_RESTOSHAMAN_ABILITY_TOTEM_EARTHBIND then
        return TOTEM_SLOT_EARTHBIND
    endif
    return 0
endfunction

private function GetTotemSlotForUnitType takes integer unitTypeId returns integer
    if unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_EARTH_1 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_EARTH_2 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_EARTH_3 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_STONESKIN then
        return TOTEM_SLOT_EARTH
    elseif unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_FIRE_1 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_FIRE_2 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_SKYFURY_1 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_SKYFURY_2 then
        return TOTEM_SLOT_FIRE
    elseif unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_WATER_1 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_WATER_2 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_CLEANSING_1 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_CLEANSING_2 then
        return TOTEM_SLOT_WATER
    elseif unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_WIND_1 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_WIND_2 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_WINDFURY_1 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_WINDFURY_2 then
        return TOTEM_SLOT_WIND
    elseif unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_EARTHBIND_1 or unitTypeId == AI_RESTOSHAMAN_UNIT_TOTEM_EARTHBIND_2 then
        return TOTEM_SLOT_EARTHBIND
    endif
    return 0
endfunction

private function GetLiveTotem takes integer instanceId, integer slot returns unit
    local integer key = GetTotemKey(instanceId, slot)
    local unit totem
    call EnsureTotemState()
    set totem = TotemByInstanceSlot.unit[key]
    if not IsAliveUnit(totem) then
        set TotemByInstanceSlot.unit[key] = null
        set totem = null
    endif
    return totem
endfunction

private function CanCastTotem takes unit shaman, integer abilityId returns boolean
    local integer instanceId = AI_GetInstance(shaman)
    local integer slot = GetTotemSlotForAbility(abilityId)
    if instanceId <= 0 or slot <= 0 then
        return false
    endif
    return GetLiveTotem(instanceId, slot) == null
endfunction

private function TrackTotem takes unit shaman, unit totem returns nothing
    local integer instanceId = AI_GetInstance(shaman)
    local integer slot = GetTotemSlotForUnitType(GetUnitTypeId(totem))
    local integer key
    local unit oldTotem
    call EnsureTotemState()
    if instanceId <= 0 or slot <= 0 or AI_GetProfileId(shaman) != AI_Restoshaman_ProfileId then
        return
    endif
    set key = GetTotemKey(instanceId, slot)
    set oldTotem = TotemByInstanceSlot.unit[key]
    if oldTotem != null and oldTotem != totem and IsAliveUnit(oldTotem) then
        call KillUnit(oldTotem)
    endif
    set TotemByInstanceSlot.unit[key] = totem
    set TotemOwnerInstance[GetHandleId(totem)] = instanceId
    set TotemSlotByHandle[GetHandleId(totem)] = slot
    set oldTotem = null
endfunction

private function HandleSummon takes nothing returns nothing
    local unit summoner = GetSummoningUnit()
    local unit summoned = GetSummonedUnit()
    if GetTotemSlotForUnitType(GetUnitTypeId(summoned)) > 0 then
        call TrackTotem(summoner, summoned)
    endif
    set summoner = null
    set summoned = null
endfunction

private function HandleTotemDeath takes nothing returns nothing
    local unit dying = GetDyingUnit()
    local integer handleId = GetHandleId(dying)
    local integer ownerInstance
    local integer slot
    call EnsureTotemState()
    set ownerInstance = TotemOwnerInstance[handleId]
    set slot = TotemSlotByHandle[handleId]
    if ownerInstance > 0 and slot > 0 and TotemByInstanceSlot.unit[GetTotemKey(ownerInstance, slot)] == dying then
        set TotemByInstanceSlot.unit[GetTotemKey(ownerInstance, slot)] = null
    endif
    call TotemOwnerInstance.remove(handleId)
    call TotemSlotByHandle.remove(handleId)
    set dying = null
endfunction

private function RegisterBarks takes nothing returns nothing
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_GREET, "The spirits walk with us.", "HeroRestoshaman_Greet1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_GREET, "May the winds guide us, my friend.", "HeroRestoshaman_Greet2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_GREET, "What aid do you require?", "HeroRestoshaman_Greet3")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_FAREWELL, "The spirits will watch over you.", "HeroRestoshaman_Farewell1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_FAREWELL, "I will await the call of the elements.", "HeroRestoshaman_Farewell2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_PASSIVE, "I shall remain at your side.", "HeroRestoshaman_Passive1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_PASSIVE, "I will follow you.", "HeroRestoshaman_Passive2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_NORMAL, "I will assist you in this endeavor.", "HeroRestoshaman_Normal1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_NORMAL, "Your will aligns with the elements.", "HeroRestoshaman_Normal2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_NORMAL, "Let us bring balance to the chaos.", "HeroRestoshaman_Normal3")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_AGGRESSIVE, "The storm will cleanse our enemies!", "HeroRestoshaman_Aggressive1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_AGGRESSIVE, "They will feel the wrath of the elements!", "HeroRestoshaman_Aggressive2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_HOLD, "I will remain here, as steady as a mountain.", "HeroRestoshaman_HoldPositions1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_HOLD, "I will stand firm, as the earth beneath us.", "HeroRestoshaman_HoldPositions2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_DROP_ITEMS, "Take them, they may serve you well.", "HeroRestoshaman_DropItems1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_DROP_ITEMS, "Sure, I don't need any worldly possessions.", "HeroRestoshaman_DropItems2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_IDLE, "Even the elements rest... occasionally.", "HeroRestoshaman_Idle1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_IDLE, "The calm before the storm has its purpose.", "HeroRestoshaman_Idle2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_MOVING, "The journey is as important as the destination.", "HeroRestoshaman_Moving1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_MOVING, "Keep moving; the spirits are restless.", "HeroRestoshaman_Moving2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_CASTING, "The earth lends its strength to us.", "HeroRestoshaman_Casting1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_CASTING, "I call upon the ancestral spirits!", "HeroRestoshaman_Casting2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_ATTACKING, "The earth will not yield to you!", "HeroRestoshaman_Attacking1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_ATTACKING, "Your reign ends here!", "HeroRestoshaman_Attacking2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_KILLING, "Their path has ended, as all must.", "HeroRestoshaman_UnitDies1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_KILLING, "They are one with the elements now.", "HeroRestoshaman_UnitDies2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_KICKED, "If this is your will, so be it.", "HeroRestoshaman_Kicked1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_KICKED, "I will not question the path you walk.", "HeroRestoshaman_Kicked2")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_COMPANION_DIES, "We must honor their sacrifice.", "HeroRestoshaman_CompanionDies1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_ITEM_GIVEN, "This will serve us in restoring balance.", "HeroRestoshaman_GiveItem1")
    call AI_RegisterBarkLine(AI_Restoshaman_ProfileId, AI_BARK_ITEM_GIVEN, "I will use this wisely.", "HeroRestoshaman_GiveItem2")
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

private function Think takes nothing returns nothing
    local unit shaman = AI_EventUnit
    local unit target = AI_EventTarget
    local unit ally
    local integer enemyCount
    if shaman == null then
        set shaman = null
        return
    endif
    set ally = AI_FindLowestHealthAlly(shaman, 800.00, true)
    set enemyCount = AI_CountNearbyEnemies(shaman, 600.00)
    if ally != null and AI_GetUnitLifePercent(ally) <= 50.00 and GetRandomInt(1, 2) == 1 and AI_TryCastTarget(shaman, ally, AI_RESTOSHAMAN_ABILITY_HEALING_WAVE, "holybolt", 2.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif ally != null and AI_GetUnitLifePercent(ally) <= 75.00 and enemyCount >= 2 and GetRandomInt(1, 2) == 1 and AI_TryCastTarget(shaman, ally, AI_RESTOSHAMAN_ABILITY_CHAIN_HEAL, "healingwave", 2.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif target != null and enemyCount > 2 and GetRandomInt(1, 2) == 1 and AI_TryCastTarget(shaman, target, AI_RESTOSHAMAN_ABILITY_CHAIN_LIGHTNING, "chainlightning", 2.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif target != null and enemyCount > 2 and GetRandomInt(1, 4) == 1 and AI_TryCastTarget(shaman, target, AI_RESTOSHAMAN_ABILITY_HEX, "hex", 2.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif ally != null and AI_GetUnitLifePercent(ally) <= 90.00 and GetRandomInt(1, 3) == 1 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_EARTH, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif AI_GetState(shaman) == AI_STATE_RETREAT_COMBAT and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_EARTHBIND, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif GetRandomInt(1, 3) == 1 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_FIRE, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif enemyCount > 2 and GetRandomInt(1, 3) == 1 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_STONESKIN, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif ally != null and AI_GetUnitManaPercent(ally) <= 75.00 and GetRandomInt(1, 3) == 1 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_WATER, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif enemyCount > 2 and GetRandomInt(1, 4) == 1 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_WIND, 3.00) then
        call AI_RequestBark(shaman, AI_BARK_CASTING)
    elseif GetRandomInt(1, 4) == 1 and TryTotem(shaman, AI_RESTOSHAMAN_ABILITY_TOTEM_WINDFURY, 3.00) then
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
    call EnsureTotemState()
    set AI_Restoshaman_ClassId = AI_RegisterClass("Restoshaman")
    set AI_Restoshaman_ProfileId = AI_RegisterProfile(AI_Restoshaman_ClassId, AI_RESTOSHAMAN_UNIT_HORDE, "Horde Restoshaman")
    call AI_SetProfileSpawnOwner(AI_Restoshaman_ProfileId, Player(1))
    call AI_SetProfileThinkCallback(AI_Restoshaman_ProfileId, function Think)
    call RegisterAbilities()
    call AI_AddDefaultShopItems(AI_Restoshaman_ProfileId)
    call AI_AddRandomSpawnProfile(AI_Restoshaman_ProfileId)
    call RegisterBarks()

    set SummonTrigger = CreateTrigger()
    call RegisterPlayerUnitEventAll(SummonTrigger, EVENT_PLAYER_UNIT_SUMMON)
    call TriggerAddAction(SummonTrigger, function HandleSummon)

    set TotemDeathTrigger = CreateTrigger()
    call RegisterPlayerUnitEventAll(TotemDeathTrigger, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(TotemDeathTrigger, function HandleTotemDeath)
endfunction

endlibrary
