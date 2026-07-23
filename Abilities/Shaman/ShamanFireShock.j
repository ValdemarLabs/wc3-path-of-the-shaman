/**
    ShamanFireShock

    Author: Valdemar
    Version:

    Description:
    Fire Shock direct damage refresh and explosion effect converted from GUI.
    Explosion damage uses the area base values from AbilitiesPlayerInit.

    Credits:
    - Old GUI "Fire Shock" trigger

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanFireShock initializer Init requires Events, ShamanCommon

globals
    private constant real FIRE_SHOCK_AOE = 250.00
    private constant integer FIRE_SHOCK_EXPLOSION_CHANCE = 50
    private constant string EFFECT_FIRE_SHOCK = "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl"
    private constant string EFFECT_FIRE_EXPLOSION = "Abilities\\Spells\\Other\\Doom\\DoomDeath.mdl"
    private constant string EFFECT_FIRE_EXPLOSION_2 = "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl"
endglobals

private function DamageExplosionTargets takes unit caster, real x, real y, real amount returns nothing
    local group enumGroup = CreateGroup()
    local unit target
    call GroupEnumUnitsInRange(enumGroup, x, y, FIRE_SHOCK_AOE, null)
    loop
        set target = FirstOfGroup(enumGroup)
        exitwhen target == null
        call GroupRemoveUnit(enumGroup, target)
        if ShamanCommon_IsAlive(target) and not IsUnitType(target, UNIT_TYPE_STRUCTURE) and IsUnitEnemy(target, GetOwningPlayer(caster)) then
            call UnitDamageTarget(caster, target, amount, true, false, ATTACK_TYPE_MAGIC, DAMAGE_TYPE_NORMAL, null)
        endif
    endloop
    call DestroyGroup(enumGroup)
    set target = null
    set enumGroup = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    local real x
    local real y
    local real amount
    local real areaAmount
    if GetSpellAbilityId() == ShamanCommon_ABILITY_FIRE_SHOCK and target != null then
        set x = GetUnitX(target)
        set y = GetUnitY(target)
        set amount = ShamanCommon_GetDamageAmount(caster, ShamanCommon_ABILITY_FIRE_SHOCK, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_INTELLIGENCE, 1.50)
        set areaAmount = ShamanCommon_GetDamageAmount(caster, ShamanCommon_ABILITY_FIRE_SHOCK, AbilitiesPlayerInit_VALUE_AREA_BASE, ShamanCommon_STAT_INTELLIGENCE, 1.50)
        call ShamanCommon_SetRealField(caster, ShamanCommon_ABILITY_FIRE_SHOCK, ABILITY_RLF_DAMAGE_HTB1, amount)
        if GetRandomInt(1, 100) <= FIRE_SHOCK_EXPLOSION_CHANCE then
            call DamageExplosionTargets(caster, x, y, areaAmount)
            call DestroyEffect(AddSpecialEffect(EFFECT_FIRE_EXPLOSION, x, y))
            call DestroyEffect(AddSpecialEffect(EFFECT_FIRE_EXPLOSION_2, x, y))
        endif
        call DestroyEffect(AddSpecialEffect(EFFECT_FIRE_SHOCK, x, y))
    endif
    set target = null
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
endfunction

endlibrary
