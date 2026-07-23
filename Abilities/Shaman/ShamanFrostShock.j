/**
    ShamanFrostShock

    Author: Valdemar
    Version:

    Description:
    Frost Shock impact damage and frost missile burst converted from GUI.

    Credits:
    - Old GUI "Frost Shock" trigger

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanFrostShock initializer Init requires Events, ShamanCommon

globals
    private constant integer FROST_MISSILE_COUNT = 4
    private constant real FROST_DUMMY_OFFSET = 50.00
    private constant real FROST_ORDER_OFFSET = 100.00
    private constant string EFFECT_FROST_SHOCK = "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl"
endglobals

private function LaunchFrostMissiles takes unit caster, unit target, integer rank, real x, real y returns nothing
    local integer index = 1
    local real angle
    local unit dummy
    loop
        exitwhen index > FROST_MISSILE_COUNT
        set angle = GetUnitFacing(target) + (360.00 / I2R(FROST_MISSILE_COUNT)) * I2R(index)
        set dummy = ShamanCommon_CreateTimedDummy(GetOwningPlayer(caster), ShamanCommon_DUMMY_SHOCK, ShamanCommon_PolarX(x, FROST_DUMMY_OFFSET, angle), ShamanCommon_PolarY(y, FROST_DUMMY_OFFSET, angle), bj_UNIT_FACING, 1.50)
        call UnitAddAbility(dummy, ShamanCommon_ABILITY_FROST_SHOCK_BOLTS)
        call SetUnitAbilityLevel(dummy, ShamanCommon_ABILITY_FROST_SHOCK_BOLTS, rank)
        call IssuePointOrder(dummy, "carrionswarm", ShamanCommon_PolarX(x, FROST_ORDER_OFFSET, angle), ShamanCommon_PolarY(y, FROST_ORDER_OFFSET, angle))
        set index = index + 1
    endloop
    set dummy = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    local integer rank
    local real amount
    local real x
    local real y
    if GetSpellAbilityId() == ShamanCommon_ABILITY_FROST_SHOCK and target != null then
        set rank = ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_FROST_SHOCK)
        set amount = ShamanCommon_GetDamageAmount(caster, ShamanCommon_ABILITY_FROST_SHOCK, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_NONE, 0.00)
        set x = GetUnitX(target)
        set y = GetUnitY(target)
        call UnitDamageTarget(caster, target, amount, true, false, ATTACK_TYPE_MAGIC, DAMAGE_TYPE_NORMAL, null)
        call DestroyEffect(AddSpecialEffect(EFFECT_FROST_SHOCK, x, y))
        call LaunchFrostMissiles(caster, target, rank, x, y)
    endif
    set target = null
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
