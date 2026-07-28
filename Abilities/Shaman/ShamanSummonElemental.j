/**
    ShamanSummonElemental

    Author: Valdemar
    Version:

    Description:
    Delayed elemental channel summons converted from GUI. Summoned elementals
    are controlled companions, gain Intelligence scaling, and do not consume
    normal companion party slots. Rank 5 Summon Elemental creates Greater
    variants with stronger summoner scaling and fixed elemental stat bonuses.

    Credits:
    - Old GUI "Summon Elemental" triggers

    How to install:
    Requires `Table`, `Events`, `UnitDeathEvent`, `Companions`, and
    `ShamanCommon`.

**/
library ShamanSummonElemental initializer Init requires Table, Events, UnitDeathEvent, Companions, ShamanCommon

globals
    private constant real SUMMON_DELAY = 3.00
    private constant real SUMMON_OFFSET = 120.00
    private constant real AI_PERIOD = 1.25
    private constant real AI_SEARCH_RADIUS = 750.00
    private constant real ELEMENTAL_INTELLIGENCE_LIFE_SCALE = 6.00
    private constant real ELEMENTAL_INTELLIGENCE_DAMAGE_SCALE = 0.45
    private constant real GREATER_ELEMENTAL_SUMMONER_STAT_MULTIPLIER = 1.50

    private constant integer GREATER_SUMMON_RANK = 5

    private constant integer ABILITY_AIR_LIGHTNING_SHIELD = 'ACls'
    private constant integer ABILITY_AIR_CHAIN_LIGHTNING = 'ACcl'
    private constant integer ABILITY_AIR_PURGE = 'ACpu'
    private constant integer ABILITY_WATER_CRUSHING_WAVE = 'ACcv'
    private constant integer ABILITY_WATER_FROST_NOVA = 'ACfn'
    private constant integer ABILITY_FIRE_FLAME_STRIKE = 'ACfs'
    private constant integer ABILITY_FIRE_FIREBOLT = 'ACfb'
    private constant integer ABILITY_EARTH_TAUNT = 'ANta'
    private constant integer ABILITY_EARTH_THUNDER_CLAP = 'ACtc'
    private constant integer ABILITY_EARTH_HURL_BOULDER = 'ACtb'

    private Table ElementalBySlot = 0
    private Table ElementalSlotByHandle = 0
    private Table PendingTimerBySlot = 0
    private Table PendingSlotByTimer = 0
    private Table PendingUnitTypeByTimer = 0
    private Table PendingRankByTimer = 0
    private group AiEnumGroup = null
    private timer AiTimer = null
endglobals

private function EnsureState takes nothing returns nothing
    if ElementalBySlot == 0 then
        set ElementalBySlot = Table.create()
        set ElementalSlotByHandle = Table.create()
        set PendingTimerBySlot = Table.create()
        set PendingSlotByTimer = Table.create()
        set PendingUnitTypeByTimer = Table.create()
        set PendingRankByTimer = Table.create()
    endif
    if AiEnumGroup == null then
        set AiEnumGroup = CreateGroup()
    endif
endfunction

private function GetElementalUnitType takes integer abilityId returns integer
    if abilityId == ShamanCommon_ABILITY_CHANNEL_AIR_ELEMENTAL then
        return ShamanCommon_UNIT_AIR_ELEMENTAL
    elseif abilityId == ShamanCommon_ABILITY_CHANNEL_WATER_ELEMENTAL then
        return ShamanCommon_UNIT_WATER_ELEMENTAL
    elseif abilityId == ShamanCommon_ABILITY_CHANNEL_FIRE_ELEMENTAL then
        return ShamanCommon_UNIT_FIRE_ELEMENTAL
    elseif abilityId == ShamanCommon_ABILITY_CHANNEL_EARTH_ELEMENTAL then
        return ShamanCommon_UNIT_EARTH_ELEMENTAL
    endif
    return 0
endfunction

private function ClearPendingTimer takes integer heroSlot returns nothing
    local timer pending = PendingTimerBySlot.timer[heroSlot]
    local integer timerId
    if pending != null then
        set timerId = GetHandleId(pending)
        call PendingSlotByTimer.integer.remove(timerId)
        call PendingUnitTypeByTimer.integer.remove(timerId)
        call PendingRankByTimer.integer.remove(timerId)
        call DestroyTimer(pending)
        call PendingTimerBySlot.timer.remove(heroSlot)
    endif
    set pending = null
endfunction

private function CleanupElemental takes unit elemental returns nothing
    local integer handleId
    local integer heroSlot
    if elemental == null then
        return
    endif
    call EnsureState()
    set handleId = GetHandleId(elemental)
    set heroSlot = ElementalSlotByHandle.integer[handleId]
    if heroSlot > 0 and ElementalBySlot.unit[heroSlot] == elemental then
        call ElementalBySlot.unit.remove(heroSlot)
    endif
    call ElementalSlotByHandle.integer.remove(handleId)
    call Companions_UnregisterControlled(elemental)
endfunction

private function KillActiveElemental takes integer heroSlot returns nothing
    local unit elemental
    call EnsureState()
    set elemental = ElementalBySlot.unit[heroSlot]
    if elemental != null then
        call CleanupElemental(elemental)
        call KillUnit(elemental)
    endif
    set elemental = null
endfunction

private function ApplyGreaterElementalBonuses takes unit elemental, integer unitTypeId returns nothing
    local integer customValue
    if elemental == null then
        return
    endif
    call BlzSetUnitName(elemental, "Greater " + GetUnitName(elemental))
    set customValue = GetUnitUserData(elemental)
    if customValue <= 0 then
        return
    endif
    if unitTypeId == ShamanCommon_UNIT_FIRE_ELEMENTAL or unitTypeId == ShamanCommon_UNIT_WATER_ELEMENTAL then
        set udg_Stats_SpellPowerPct[customValue] = udg_Stats_SpellPowerPct[customValue] + 25
        set udg_Stats_Crit[customValue] = udg_Stats_Crit[customValue] + 10
    elseif unitTypeId == ShamanCommon_UNIT_EARTH_ELEMENTAL then
        set udg_Stats_Block[customValue] = udg_Stats_Block[customValue] + 25
        set udg_Stats_Hit[customValue] = udg_Stats_Hit[customValue] + 10
    elseif unitTypeId == ShamanCommon_UNIT_AIR_ELEMENTAL then
        set udg_Stats_Dodge[customValue] = udg_Stats_Dodge[customValue] + 20
        set udg_Stats_Crit[customValue] = udg_Stats_Crit[customValue] + 10
        set udg_Stats_SpellPowerPct[customValue] = udg_Stats_SpellPowerPct[customValue] + 15
    endif
endfunction

private function ApplyElementalTalent takes unit hero, unit elemental, integer unitTypeId, integer summonRank returns nothing
    local integer bonus = ShamanCommon_GetSpecialBonusValue(hero, ShamanCommon_ABILITY_SUMMON_ELEMENTAL)
    local real intelligence = ShamanCommon_GetStat(hero, ShamanCommon_STAT_INTELLIGENCE)
    local real talentMultiplier = 1.00 + I2R(bonus) * 0.10
    local real summonerStatMultiplier = 1.00
    local real lifeBonus
    local real damageBonus
    local integer maxLife
    local integer damage
    if elemental == null then
        return
    endif
    if summonRank >= GREATER_SUMMON_RANK then
        set summonerStatMultiplier = GREATER_ELEMENTAL_SUMMONER_STAT_MULTIPLIER
    endif
    set maxLife = BlzGetUnitMaxHP(elemental)
    set damage = BlzGetUnitBaseDamage(elemental, 0)
    set lifeBonus = intelligence * ELEMENTAL_INTELLIGENCE_LIFE_SCALE * summonerStatMultiplier
    set damageBonus = intelligence * ELEMENTAL_INTELLIGENCE_DAMAGE_SCALE * summonerStatMultiplier
    call BlzSetUnitMaxHP(elemental, R2I(I2R(maxLife) * talentMultiplier + lifeBonus))
    call SetUnitState(elemental, UNIT_STATE_LIFE, GetUnitState(elemental, UNIT_STATE_MAX_LIFE))
    call BlzSetUnitBaseDamage(elemental, R2I(I2R(damage) * talentMultiplier + damageBonus), 0)
    if summonRank >= GREATER_SUMMON_RANK then
        call ApplyGreaterElementalBonuses(elemental, unitTypeId)
    endif
endfunction

private function IsCasting takes unit elemental returns boolean
    local integer customValue = GetUnitUserData(elemental)
    return customValue > 0 and udg_UnitIsCasting[customValue]
endfunction

private function CanUseElementalAI takes unit elemental returns boolean
    if not ShamanCommon_IsAlive(elemental) or udg_InCinematic then
        return false
    endif
    return Companions_GetMode(elemental) != COMPANION_MODE_PASSIVE and not IsCasting(elemental)
endfunction

private function IsAbilityReady takes unit caster, integer abilityId returns boolean
    local integer level
    if caster == null or abilityId == 0 then
        return false
    endif
    set level = GetUnitAbilityLevel(caster, abilityId)
    if level <= 0 then
        return false
    endif
    if BlzGetUnitAbilityCooldownRemaining(caster, abilityId) > 0.00 then
        return false
    endif
    return GetUnitState(caster, UNIT_STATE_MANA) >= I2R(BlzGetUnitAbilityManaCost(caster, abilityId, level - 1))
endfunction

private function TryTargetSpell takes unit caster, unit target, integer abilityId, string order returns boolean
    if target != null and IsAbilityReady(caster, abilityId) and IssueTargetOrder(caster, order, target) then
        return true
    endif
    return false
endfunction

private function TryPointSpell takes unit caster, real x, real y, integer abilityId, string order returns boolean
    if IsAbilityReady(caster, abilityId) and IssuePointOrder(caster, order, x, y) then
        return true
    endif
    return false
endfunction

private function TryImmediateSpell takes unit caster, integer abilityId, string order returns boolean
    if IsAbilityReady(caster, abilityId) and IssueImmediateOrder(caster, order) then
        return true
    endif
    return false
endfunction

private function IsValidAITarget takes unit source, unit target returns boolean
    return ShamanCommon_IsHostileGroundTarget(source, target, false)
endfunction

private function CountNearbyHostiles takes unit source, real radius returns integer
    local integer count = 0
    local unit target
    call EnsureState()
    call GroupClear(AiEnumGroup)
    call GroupEnumUnitsInRange(AiEnumGroup, GetUnitX(source), GetUnitY(source), radius, null)
    loop
        set target = FirstOfGroup(AiEnumGroup)
        exitwhen target == null
        call GroupRemoveUnit(AiEnumGroup, target)
        if IsValidAITarget(source, target) then
            set count = count + 1
        endif
    endloop
    set target = null
    return count
endfunction

private function FindClosestHostile takes unit source, real radius returns unit
    local unit target
    local unit best = null
    local real dx
    local real dy
    local real distanceSq
    local real bestDistanceSq = radius * radius
    call EnsureState()
    call GroupClear(AiEnumGroup)
    call GroupEnumUnitsInRange(AiEnumGroup, GetUnitX(source), GetUnitY(source), radius, null)
    loop
        set target = FirstOfGroup(AiEnumGroup)
        exitwhen target == null
        call GroupRemoveUnit(AiEnumGroup, target)
        if IsValidAITarget(source, target) then
            set dx = GetUnitX(target) - GetUnitX(source)
            set dy = GetUnitY(target) - GetUnitY(source)
            set distanceSq = dx * dx + dy * dy
            if best == null or distanceSq < bestDistanceSq then
                set best = target
                set bestDistanceSq = distanceSq
            endif
        endif
    endloop
    set target = null
    return best
endfunction

private function TryAirElementalSpell takes unit elemental, unit target, integer enemyCount returns boolean
    if enemyCount >= 2 and TryTargetSpell(elemental, elemental, ABILITY_AIR_LIGHTNING_SHIELD, "lightningshield") then
        return true
    elseif enemyCount >= 2 and TryTargetSpell(elemental, target, ABILITY_AIR_CHAIN_LIGHTNING, "chainlightning") then
        return true
    elseif TryTargetSpell(elemental, target, ABILITY_AIR_PURGE, "purge") then
        return true
    endif
    return false
endfunction

private function TryWaterElementalSpell takes unit elemental, unit target, integer enemyCount returns boolean
    if enemyCount >= 3 and TryPointSpell(elemental, GetUnitX(target), GetUnitY(target), ABILITY_WATER_CRUSHING_WAVE, "carrionswarm") then
        return true
    elseif enemyCount >= 2 and TryTargetSpell(elemental, target, ABILITY_WATER_FROST_NOVA, "frostnova") then
        return true
    endif
    return false
endfunction

private function TryFireElementalSpell takes unit elemental, unit target, integer enemyCount returns boolean
    if enemyCount >= 3 and TryPointSpell(elemental, GetUnitX(target), GetUnitY(target), ABILITY_FIRE_FLAME_STRIKE, "flamestrike") then
        return true
    elseif TryTargetSpell(elemental, target, ABILITY_FIRE_FIREBOLT, "firebolt") then
        return true
    endif
    return false
endfunction

private function TryEarthElementalSpell takes unit elemental, unit target, integer enemyCount returns boolean
    if enemyCount >= 3 and TryImmediateSpell(elemental, ABILITY_EARTH_TAUNT, "taunt") then
        return true
    elseif enemyCount >= 2 and TryImmediateSpell(elemental, ABILITY_EARTH_THUNDER_CLAP, "thunderclap") then
        return true
    elseif TryTargetSpell(elemental, target, ABILITY_EARTH_HURL_BOULDER, "thunderbolt") then
        return true
    endif
    return false
endfunction

private function TickElemental takes unit elemental returns nothing
    local integer unitTypeId
    local integer enemyCount
    local unit target
    if not CanUseElementalAI(elemental) then
        return
    endif
    set target = FindClosestHostile(elemental, AI_SEARCH_RADIUS)
    if target == null then
        set target = null
        return
    endif
    set unitTypeId = GetUnitTypeId(elemental)
    set enemyCount = CountNearbyHostiles(elemental, AI_SEARCH_RADIUS)
    if unitTypeId == ShamanCommon_UNIT_AIR_ELEMENTAL then
        call TryAirElementalSpell(elemental, target, enemyCount)
    elseif unitTypeId == ShamanCommon_UNIT_WATER_ELEMENTAL then
        call TryWaterElementalSpell(elemental, target, enemyCount)
    elseif unitTypeId == ShamanCommon_UNIT_FIRE_ELEMENTAL then
        call TryFireElementalSpell(elemental, target, enemyCount)
    elseif unitTypeId == ShamanCommon_UNIT_EARTH_ELEMENTAL then
        call TryEarthElementalSpell(elemental, target, enemyCount)
    endif
    set target = null
endfunction

private function TickElementalAI takes nothing returns nothing
    call TickElemental(ElementalBySlot.unit[ShamanCommon_HERO_SLOT_NAZGREK])
    call TickElemental(ElementalBySlot.unit[ShamanCommon_HERO_SLOT_ZULKIS])
endfunction

private function SpawnPendingElemental takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local integer heroSlot = PendingSlotByTimer.integer[timerId]
    local integer unitTypeId = PendingUnitTypeByTimer.integer[timerId]
    local integer summonRank = PendingRankByTimer.integer[timerId]
    local unit hero = ShamanCommon_GetHeroBySlot(heroSlot)
    local unit elemental
    local real x
    local real y
    call PendingSlotByTimer.integer.remove(timerId)
    call PendingUnitTypeByTimer.integer.remove(timerId)
    call PendingRankByTimer.integer.remove(timerId)
    call PendingTimerBySlot.timer.remove(heroSlot)
    call DestroyTimer(expired)
    if ShamanCommon_IsAlive(hero) and unitTypeId != 0 then
        set x = ShamanCommon_PolarX(GetUnitX(hero), SUMMON_OFFSET, GetUnitFacing(hero))
        set y = ShamanCommon_PolarY(GetUnitY(hero), SUMMON_OFFSET, GetUnitFacing(hero))
        set elemental = CreateUnit(GetOwningPlayer(hero), unitTypeId, x, y, GetUnitFacing(hero))
        call SetUnitOwner(elemental, Player(ShamanCommon_COMPANION_OWNER_PLAYER_INDEX), false)
        call ApplyElementalTalent(hero, elemental, unitTypeId, summonRank)
        set ElementalBySlot.unit[heroSlot] = elemental
        set ElementalSlotByHandle.integer[GetHandleId(elemental)] = heroSlot
        call Companions_RegisterControlled(elemental, hero, COMPANION_MODE_DEFEND)
    endif
    set elemental = null
    set hero = null
    set expired = null
endfunction

private function ScheduleSummon takes unit caster, integer unitTypeId returns nothing
    local integer heroSlot = ShamanCommon_GetHeroSlot(caster)
    local integer summonRank = ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_SUMMON_ELEMENTAL)
    local integer timerId
    local timer pending
    if heroSlot == ShamanCommon_HERO_SLOT_NONE or unitTypeId == 0 then
        return
    endif
    call EnsureState()
    call ClearPendingTimer(heroSlot)
    call KillActiveElemental(heroSlot)
    set pending = CreateTimer()
    set PendingTimerBySlot.timer[heroSlot] = pending
    set timerId = GetHandleId(pending)
    set PendingSlotByTimer.integer[timerId] = heroSlot
    set PendingUnitTypeByTimer.integer[timerId] = unitTypeId
    set PendingRankByTimer.integer[timerId] = summonRank
    call TimerStart(pending, SUMMON_DELAY, false, function SpawnPendingElemental)
    set pending = null
endfunction

private function HandleSpellChannel takes nothing returns nothing
    local integer abilityId = GetSpellAbilityId()
    local integer unitTypeId = GetElementalUnitType(abilityId)
    if unitTypeId != 0 then
        call ScheduleSummon(GetTriggerUnit(), unitTypeId)
    endif
endfunction

private function HandleDeath takes nothing returns nothing
    local unit dying = GetDyingUnit()
    if dying != null and ElementalSlotByHandle.integer[GetHandleId(dying)] > 0 then
        call CleanupElemental(dying)
    endif
    set dying = null
endfunction

private function Init takes nothing returns nothing
    call EnsureState()
    call Events_RegisterSpellChannel(function HandleSpellChannel)
    call UnitDeathEvent_Register(function HandleDeath)
    set AiTimer = CreateTimer()
    call TimerStart(AiTimer, AI_PERIOD, true, function TickElementalAI)
endfunction

endlibrary
