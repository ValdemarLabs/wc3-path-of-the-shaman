/**
    ShamanHex

    Author: Valdemar
    Version:

    Description:
    Hex boss and high-level target limitation converted from GUI without debug
    messages.

    Credits:
    - Old GUI "Hex Limitation" triggers

    How to install:
    Requires `Table`, `Events`, and `ShamanCommon`.

**/
library ShamanHex initializer Init requires Table, Events, ShamanCommon

globals
    private Table HexTargetByCaster = 0
endglobals

private function EnsureState takes nothing returns nothing
    if HexTargetByCaster == 0 then
        set HexTargetByCaster = Table.create()
    endif
endfunction

private function IsHexAbility takes integer abilityId returns boolean
    return abilityId == ShamanCommon_ABILITY_HEX or abilityId == ShamanCommon_ABILITY_HERO_SHAMAN_HEX
endfunction

private function HandleSpellEffect takes nothing returns nothing
    if IsHexAbility(GetSpellAbilityId()) then
        call EnsureState()
        set HexTargetByCaster.unit[GetHandleId(GetTriggerUnit())] = GetSpellTargetUnit()
    endif
endfunction

private function ShouldBreakHex takes unit caster, unit target returns boolean
    if target == null then
        return false
    elseif udg_BOSS != null and IsUnitInGroup(target, udg_BOSS) then
        return true
    endif
    return GetUnitLevel(target) >= GetUnitLevel(caster) + 5
endfunction

private function HandleSpellFinish takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target
    if IsHexAbility(GetSpellAbilityId()) then
        call EnsureState()
        set target = HexTargetByCaster.unit[GetHandleId(caster)]
        call HexTargetByCaster.unit.remove(GetHandleId(caster))
        if ShouldBreakHex(caster, target) then
            call UnitRemoveBuffs(target, false, true)
        endif
    endif
    set target = null
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call EnsureState()
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call Events_RegisterPlayerUnitEvent(function HandleSpellFinish, EVENT_PLAYER_UNIT_SPELL_FINISH)
endfunction

endlibrary
