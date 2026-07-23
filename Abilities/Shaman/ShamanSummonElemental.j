/**
    ShamanSummonElemental

    Author: Valdemar
    Version:

    Description:
    Delayed elemental channel summons converted from GUI. Summoned elementals
    are controlled companions but do not consume normal companion party slots.

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
    private Table ElementalBySlot = 0
    private Table ElementalSlotByHandle = 0
    private Table PendingTimerBySlot = 0
    private Table PendingSlotByTimer = 0
    private Table PendingUnitTypeByTimer = 0
endglobals

private function EnsureState takes nothing returns nothing
    if ElementalBySlot == 0 then
        set ElementalBySlot = Table.create()
        set ElementalSlotByHandle = Table.create()
        set PendingTimerBySlot = Table.create()
        set PendingSlotByTimer = Table.create()
        set PendingUnitTypeByTimer = Table.create()
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

private function ApplyElementalTalent takes unit hero, unit elemental returns nothing
    local integer bonus = ShamanCommon_GetSpecialBonusValue(hero, ShamanCommon_ABILITY_SUMMON_ELEMENTAL)
    local integer maxLife
    local integer damage
    if bonus <= 0 or elemental == null then
        return
    endif
    set maxLife = BlzGetUnitMaxHP(elemental)
    set damage = BlzGetUnitBaseDamage(elemental, 0)
    call BlzSetUnitMaxHP(elemental, R2I(I2R(maxLife) * (1.00 + I2R(bonus) * 0.10)))
    call SetUnitState(elemental, UNIT_STATE_LIFE, GetUnitState(elemental, UNIT_STATE_MAX_LIFE))
    call BlzSetUnitBaseDamage(elemental, R2I(I2R(damage) * (1.00 + I2R(bonus) * 0.10)), 0)
endfunction

private function SpawnPendingElemental takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local integer heroSlot = PendingSlotByTimer.integer[timerId]
    local integer unitTypeId = PendingUnitTypeByTimer.integer[timerId]
    local unit hero = ShamanCommon_GetHeroBySlot(heroSlot)
    local unit elemental
    local real x
    local real y
    call PendingSlotByTimer.integer.remove(timerId)
    call PendingUnitTypeByTimer.integer.remove(timerId)
    call PendingTimerBySlot.timer.remove(heroSlot)
    call DestroyTimer(expired)
    if ShamanCommon_IsAlive(hero) and unitTypeId != 0 then
        set x = ShamanCommon_PolarX(GetUnitX(hero), SUMMON_OFFSET, GetUnitFacing(hero))
        set y = ShamanCommon_PolarY(GetUnitY(hero), SUMMON_OFFSET, GetUnitFacing(hero))
        set elemental = CreateUnit(GetOwningPlayer(hero), unitTypeId, x, y, GetUnitFacing(hero))
        call SetUnitOwner(elemental, Player(ShamanCommon_COMPANION_OWNER_PLAYER_INDEX), false)
        call ApplyElementalTalent(hero, elemental)
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
    local timer pending
    if heroSlot == ShamanCommon_HERO_SLOT_NONE or unitTypeId == 0 then
        return
    endif
    call EnsureState()
    call ClearPendingTimer(heroSlot)
    call KillActiveElemental(heroSlot)
    set pending = CreateTimer()
    set PendingTimerBySlot.timer[heroSlot] = pending
    set PendingSlotByTimer.integer[GetHandleId(pending)] = heroSlot
    set PendingUnitTypeByTimer.integer[GetHandleId(pending)] = unitTypeId
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
endfunction

endlibrary
