/**
    ShamanSpiritLink

    Author: Valdemar
    Version:

    Description:
    Hook library for Spirit Link. The imported GUI folder did not include a
    runtime script for the base effect, so object data owns the spell while
    this file provides the future talent integration point.

    Credits:
    - Old GUI Shaman ability object data

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanSpiritLink initializer Init requires Events, ShamanCommon

private function HandleSpellEffect takes nothing returns nothing
    if GetSpellAbilityId() == ShamanCommon_ABILITY_SPIRIT_LINK then
        call ShamanCommon_RefreshAbility(GetTriggerUnit(), ShamanCommon_ABILITY_SPIRIT_LINK)
    endif
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
endfunction

endlibrary
