/**
    ShamanStormstrike

    Author: Valdemar
    Version:

    Description:
    Stormstrike dummy Fan of Knives damage converted from GUI. Damage is based
    on AbilitiesPlayerInit, Strength, and talent bonuses.

    Credits:
    - Old GUI "Stormstrike" trigger

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanStormstrike initializer Init requires Events, ShamanCommon

private function GetDamageAbility takes integer rank returns integer
    if rank == 1 then
        return ShamanCommon_ABILITY_STORMSTRIKE_DAMAGE_1
    elseif rank == 2 then
        return ShamanCommon_ABILITY_STORMSTRIKE_DAMAGE_2
    elseif rank == 3 then
        return ShamanCommon_ABILITY_STORMSTRIKE_DAMAGE_3
    elseif rank == 4 then
        return ShamanCommon_ABILITY_STORMSTRIKE_DAMAGE_4
    endif
    return ShamanCommon_ABILITY_STORMSTRIKE_DAMAGE_5
endfunction

private function CastBurst takes unit caster, integer rank, real amount returns nothing
    local integer damageAbility = GetDamageAbility(rank)
    local real x = ShamanCommon_PolarX(GetUnitX(caster), 50.00, GetUnitFacing(caster))
    local real y = ShamanCommon_PolarY(GetUnitY(caster), 50.00, GetUnitFacing(caster))
    local unit dummy = ShamanCommon_CreateTimedDummy(GetOwningPlayer(caster), ShamanCommon_DUMMY_STORMSTRIKE, x, y, bj_UNIT_FACING, 0.50)
    local ability dummyAbility
    call UnitAddAbility(dummy, damageAbility)
    set dummyAbility = BlzGetUnitAbility(dummy, damageAbility)
    if dummyAbility != null then
        call BlzSetAbilityRealLevelField(dummyAbility, ABILITY_RLF_DAMAGE_PER_TARGET_EFK1, 0, amount)
    endif
    call IssueImmediateOrder(dummy, "fanofknives")
    set dummyAbility = null
    set dummy = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer rank
    local real amount
    if GetSpellAbilityId() == ShamanCommon_ABILITY_STORMSTRIKE then
        set rank = ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_STORMSTRIKE)
        set amount = ShamanCommon_GetDamageAmount(caster, ShamanCommon_ABILITY_STORMSTRIKE, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_STRENGTH, 1.50)
        call ShamanCommon_PlaySound(gg_snd_Stormstrike)
        call CastBurst(caster, rank, amount)
    endif
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
