/**
    ShamanNatureShock

    Author: Valdemar
    Version:

    Description:
    Nature Shock damage and root chance converted from GUI.

    Credits:
    - Old GUI "Nature Shock" trigger

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanNatureShock initializer Init requires Events, ShamanCommon

globals
    private constant integer ROOT_CHANCE = 50
    private constant string EFFECT_NATURE_SHOCK = "Abilities\\Spells\\Undead\\ReplenishHealth\\ReplenishHealthCaster.mdl"
endglobals

private function TryRoot takes unit caster, unit target, integer rank, real x, real y returns nothing
    local unit dummy
    if GetRandomInt(1, 100) <= ROOT_CHANCE then
        set dummy = ShamanCommon_CreateTimedDummy(GetOwningPlayer(caster), ShamanCommon_DUMMY_SHOCK, x, y, bj_UNIT_FACING, 1.00)
        call UnitAddAbility(dummy, ShamanCommon_ABILITY_NATURE_SHOCK_ROOT)
        call SetUnitAbilityLevel(dummy, ShamanCommon_ABILITY_NATURE_SHOCK_ROOT, rank)
        call IssueTargetOrder(dummy, "entanglingroots", target)
    endif
    set dummy = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    local integer rank
    local real amount
    local real x
    local real y
    if GetSpellAbilityId() == ShamanCommon_ABILITY_NATURE_SHOCK and target != null then
        set rank = ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_NATURE_SHOCK)
        set amount = ShamanCommon_GetDamageAmount(caster, ShamanCommon_ABILITY_NATURE_SHOCK, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_NONE, 0.00)
        set x = GetUnitX(target)
        set y = GetUnitY(target)
        call TryRoot(caster, target, rank, x, y)
        call DestroyEffect(AddSpecialEffect(EFFECT_NATURE_SHOCK, x, y))
        call UnitDamageTarget(caster, target, amount, true, false, ATTACK_TYPE_MAGIC, DAMAGE_TYPE_NORMAL, null)
    endif
    set target = null
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
