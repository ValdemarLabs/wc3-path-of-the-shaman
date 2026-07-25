/**
    ShamanPrimalForce

    Author: Valdemar
    Version:

    Description:
    Primal Force totem interaction effects converted from GUI. Base spell
    damage is refreshed through AbilitiesPlayerInit.

    Credits:
    - Old GUI "Primal Force" trigger

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanPrimalForce initializer Init requires Events, ShamanCommon

globals
    private constant real TOTEM_SEARCH_RADIUS = 600.00
    private constant string EFFECT_HEAL = "Abilities\\Spells\\Human\\Heal\\HealTarget.mdl"
    private constant string EFFECT_MANA = "Abilities\\Spells\\Items\\AIma\\AImaTarget.mdl"
    private constant string EFFECT_FIRE = "Abilities\\Weapons\\FireBallMissile\\FireBallMissile.mdl"
    private group EnumGroup = null
endglobals

private function ApplyEarth takes unit caster, integer rank returns nothing
    local real intelligence = ShamanCommon_GetStat(caster, ShamanCommon_STAT_INTELLIGENCE)
    local real amount = GetUnitState(caster, UNIT_STATE_MAX_LIFE) * (I2R(rank) / (100.00 + (1.00 + intelligence / 2500.00)))
    call ShamanCommon_AddLife(caster, amount)
    call DestroyEffect(AddSpecialEffectTarget(EFFECT_HEAL, caster, "chest"))
endfunction

private function ApplyWater takes unit caster, integer rank returns nothing
    local real intelligence = ShamanCommon_GetStat(caster, ShamanCommon_STAT_INTELLIGENCE)
    local real amount = GetUnitState(caster, UNIT_STATE_MAX_MANA) * (I2R(rank) / (100.00 + (1.00 + intelligence / 2500.00)))
    call ShamanCommon_AddMana(caster, amount)
    call DestroyEffect(AddSpecialEffectTarget(EFFECT_MANA, caster, "chest"))
endfunction

private function ApplyWind takes unit caster, integer rank, real x, real y returns nothing
    local unit dummy = ShamanCommon_CreateTimedDummy(GetOwningPlayer(caster), ShamanCommon_DUMMY_PRIMAL_FORCE_WIND, x, y, bj_UNIT_FACING, 3.00)
    call UnitAddAbility(dummy, ShamanCommon_ABILITY_PRIMAL_FORCE_WIND_DUMMY)
    call SetUnitAbilityLevel(dummy, ShamanCommon_ABILITY_PRIMAL_FORCE_WIND_DUMMY, rank)
    call IssueTargetOrder(dummy, "bloodlust", caster)
    set dummy = null
endfunction

private function ApplyFire takes unit caster, unit target, integer rank returns nothing
    local real percent = 30.00 + I2R(rank) * 5.00
    local real strength = ShamanCommon_GetStat(caster, ShamanCommon_STAT_STRENGTH)
    local real agility = ShamanCommon_GetStat(caster, ShamanCommon_STAT_AGILITY)
    local real intelligence = ShamanCommon_GetStat(caster, ShamanCommon_STAT_INTELLIGENCE)
    local real attackPower = I2R(BlzGetUnitBaseDamage(caster, 0)) + strength * 0.50 + agility * 0.25 + intelligence * 0.25
    local real amount
    if target == null then
        return
    endif
    set amount = attackPower * percent / 100.00
    call UnitDamageTarget(caster, target, amount, true, false, ATTACK_TYPE_MAGIC, DAMAGE_TYPE_FIRE, null)
    call DestroyEffect(AddSpecialEffectTarget(EFFECT_FIRE, target, "chest"))
endfunction

private function ApplyTotemEffect takes unit caster, unit target, unit totem, integer rank, real x, real y returns nothing
    local integer unitTypeId = GetUnitTypeId(totem)
    if not IsUnitAlly(totem, GetOwningPlayer(caster)) then
        return
    elseif ShamanCommon_IsEarthTotemUnitType(unitTypeId) then
        call ApplyEarth(caster, rank)
    elseif ShamanCommon_IsWaterTotemUnitType(unitTypeId) then
        call ApplyWater(caster, rank)
    elseif ShamanCommon_IsWindTotemUnitType(unitTypeId) then
        call ApplyWind(caster, rank, x, y)
    elseif ShamanCommon_IsFireTotemUnitType(unitTypeId) then
        call ApplyFire(caster, target, rank)
    endif
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    local unit totem
    local integer rank
    local real x
    local real y
    local real amount
    if GetSpellAbilityId() == ShamanCommon_ABILITY_PRIMAL_FORCE then
        set rank = ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_PRIMAL_FORCE)
        set x = GetUnitX(caster)
        set y = GetUnitY(caster)
        set amount = ShamanCommon_GetHybridDamageAmount(caster, ShamanCommon_ABILITY_PRIMAL_FORCE, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_INTELLIGENCE, 1.25, ShamanCommon_STAT_STRENGTH, 0.50)
        call ShamanCommon_SetRealField(caster, ShamanCommon_ABILITY_PRIMAL_FORCE, ABILITY_RLF_DAMAGE_HTB1, amount)
        call QueueUnitAnimation(caster, "stand")
        call GroupClear(EnumGroup)
        call GroupEnumUnitsInRange(EnumGroup, x, y, TOTEM_SEARCH_RADIUS, null)
        loop
            set totem = FirstOfGroup(EnumGroup)
            exitwhen totem == null
            call GroupRemoveUnit(EnumGroup, totem)
            if ShamanCommon_IsTotemUnitType(GetUnitTypeId(totem)) then
                call ApplyTotemEffect(caster, target, totem, rank, x, y)
            endif
        endloop
    endif
    set totem = null
    set target = null
    set caster = null
endfunction

private function Init takes nothing returns nothing
    set EnumGroup = CreateGroup()
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
