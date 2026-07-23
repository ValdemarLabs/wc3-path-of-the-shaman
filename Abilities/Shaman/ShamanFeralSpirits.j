/**
    ShamanFeralSpirits

    Author: Valdemar
    Version:

    Description:
    Registers Feral Spirits summons as controlled companion units without
    consuming the normal companion party limit.

    Credits:
    - Old GUI "Feral Spirits" triggers

    How to install:
    Requires `Table`, `Events`, `UnitDeathEvent`, `Companions`, and
    `ShamanCommon`.

**/
library ShamanFeralSpirits initializer Init requires Table, Events, UnitDeathEvent, Companions, ShamanCommon

globals
    private Table WolfSummonerByHandle = 0
endglobals

private function EnsureState takes nothing returns nothing
    if WolfSummonerByHandle == 0 then
        set WolfSummonerByHandle = Table.create()
    endif
endfunction

private function ApplyFeralBond takes unit summoner, unit wolf returns nothing
    local integer bonus = ShamanCommon_GetSpecialBonusValue(summoner, ShamanCommon_ABILITY_FERAL_SPIRITS)
    local integer maxLife
    local integer damage
    if bonus <= 0 or wolf == null then
        return
    endif
    set maxLife = BlzGetUnitMaxHP(wolf)
    set damage = BlzGetUnitBaseDamage(wolf, 0)
    call BlzSetUnitMaxHP(wolf, R2I(I2R(maxLife) * (1.00 + I2R(bonus) * 0.10)))
    call SetUnitState(wolf, UNIT_STATE_LIFE, GetUnitState(wolf, UNIT_STATE_MAX_LIFE))
    call BlzSetUnitBaseDamage(wolf, R2I(I2R(damage) * (1.00 + I2R(bonus) * 0.10)), 0)
endfunction

private function HandleSummon takes nothing returns nothing
    local unit summoner = GetSummoningUnit()
    local unit wolf = GetSummonedUnit()
    if ShamanCommon_IsSpiritWolfUnitType(GetUnitTypeId(wolf)) and ShamanCommon_GetHeroSlot(summoner) != ShamanCommon_HERO_SLOT_NONE then
        call EnsureState()
        set WolfSummonerByHandle.unit[GetHandleId(wolf)] = summoner
        call SetUnitOwner(wolf, Player(ShamanCommon_COMPANION_OWNER_PLAYER_INDEX), false)
        call ApplyFeralBond(summoner, wolf)
        call Companions_RegisterControlled(wolf, summoner, COMPANION_MODE_DEFEND)
    endif
    set wolf = null
    set summoner = null
endfunction

private function HandleDeath takes nothing returns nothing
    local unit dying = GetDyingUnit()
    if dying != null and WolfSummonerByHandle.unit[GetHandleId(dying)] != null then
        call WolfSummonerByHandle.unit.remove(GetHandleId(dying))
        call Companions_UnregisterControlled(dying)
    endif
    set dying = null
endfunction

private function Init takes nothing returns nothing
    call EnsureState()
    call Events_RegisterUnitSummon(function HandleSummon)
    call UnitDeathEvent_Register(function HandleDeath)
endfunction

endlibrary
