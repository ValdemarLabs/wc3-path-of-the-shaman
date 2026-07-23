/**
    ShamanHealingRain

    Author: Valdemar
    Version:

    Description:
    Healing Rain Etq1 amount refresh converted from GUI. Uses
    AbilitiesPlayerInit, Intelligence scaling, and restoration heal talents.

    Credits:
    - Old GUI "Healing Rain" trigger

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanHealingRain initializer Init requires Events, ShamanCommon

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local real amount
    if GetSpellAbilityId() == ShamanCommon_ABILITY_HEALING_RAIN then
        set amount = ShamanCommon_GetHealingAmount(caster, ShamanCommon_ABILITY_HEALING_RAIN, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_INTELLIGENCE, 1.25)
        call ShamanCommon_SetRealField(caster, ShamanCommon_ABILITY_HEALING_RAIN, ABILITY_RLF_LIFE_HEALED, amount)
    endif
    set caster = null
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
endfunction

endlibrary
