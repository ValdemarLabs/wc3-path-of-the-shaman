/**
    ShamanWindShear

    Author: Valdemar
    Version:

    Description:
    Wind Shear stop and silence dummy converted from GUI.

    Credits:
    - Old GUI "Wind Shear" trigger

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanWindShear initializer Init requires Events, ShamanCommon

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    local unit dummy
    local real x
    local real y
    if GetSpellAbilityId() == ShamanCommon_ABILITY_WIND_SHEAR and target != null then
        set x = GetUnitX(target)
        set y = GetUnitY(target)
        call IssueImmediateOrder(target, "stop")
        set dummy = ShamanCommon_CreateTimedDummy(GetOwningPlayer(caster), ShamanCommon_DUMMY_WIND_SHEAR, x, y, bj_UNIT_FACING, 2.00)
        call UnitAddAbility(dummy, ShamanCommon_ABILITY_WIND_SHEAR_DUMMY)
        call IssuePointOrder(dummy, "silence", x, y)
    endif
    set dummy = null
    set target = null
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
endfunction

endlibrary
