/**
    ShamanSpiritualHealing

    Author: Valdemar
    Version:

    Description:
    Spiritual Healing mana refund converted from GUI. When the passive is
    learned, restoration heals return mana after a short delay based on the
    caster's Intelligence and the spell mana cost.

    Credits:
    - Old GUI "Spiritual Healing Return Mana" trigger

    How to install:
    Requires `Table`, `Events`, and `ShamanCommon`.

**/
library ShamanSpiritualHealing initializer Init requires Table, Events, ShamanCommon

globals
    private constant real RETURN_DELAY = 0.05
    private constant string EFFECT_MANA = "Abilities\\Spells\\Items\\AIma\\AImaTarget.mdl"

    private Table CasterByTimer = 0
    private Table ManaCostByTimer = 0
endglobals

private function EnsureState takes nothing returns nothing
    if CasterByTimer == 0 then
        set CasterByTimer = Table.create()
        set ManaCostByTimer = Table.create()
    endif
endfunction

private function IsRestorationHeal takes integer abilityId returns boolean
    return abilityId == ShamanCommon_ABILITY_CHAIN_HEAL /*
        */ or abilityId == ShamanCommon_ABILITY_HEALING_RAIN /*
        */ or abilityId == ShamanCommon_ABILITY_HEALING_WAVE /*
        */ or abilityId == ShamanCommon_ABILITY_REJUVENATION
endfunction

private function ReturnManaTimer takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer timerId = GetHandleId(expiredTimer)
    local unit caster = CasterByTimer.unit[timerId]
    local integer manaCost = ManaCostByTimer.integer[timerId]
    local real amount

    call CasterByTimer.unit.remove(timerId)
    call ManaCostByTimer.integer.remove(timerId)
    call DestroyTimer(expiredTimer)

    if ShamanCommon_IsAlive(caster) and manaCost > 0 then
        set amount = I2R(GetHeroInt(caster, true)) * (I2R(manaCost) / 100.00)
        call ShamanCommon_AddMana(caster, amount)
        call DestroyEffect(AddSpecialEffectTarget(EFFECT_MANA, caster, "origin"))
    endif

    set caster = null
    set expiredTimer = null
endfunction

private function ScheduleManaReturn takes unit caster, integer manaCost returns nothing
    local timer returnTimer
    if caster == null or manaCost <= 0 then
        return
    endif
    call EnsureState()
    set returnTimer = CreateTimer()
    set CasterByTimer.unit[GetHandleId(returnTimer)] = caster
    set ManaCostByTimer.integer[GetHandleId(returnTimer)] = manaCost
    call TimerStart(returnTimer, RETURN_DELAY, false, function ReturnManaTimer)
    set returnTimer = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local integer rank
    local integer manaCost

    if GetUnitAbilityLevel(caster, ShamanCommon_ABILITY_SPIRITUAL_HEALING) > 0 and IsRestorationHeal(abilityId) then
        set rank = GetUnitAbilityLevel(caster, abilityId)
        if rank <= 0 then
            set rank = 1
        endif
        set manaCost = BlzGetUnitAbilityManaCost(caster, abilityId, rank - 1)
        call ScheduleManaReturn(caster, manaCost)
    endif

    set caster = null
endfunction

private function Init takes nothing returns nothing
    call EnsureState()
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
endfunction

endlibrary
