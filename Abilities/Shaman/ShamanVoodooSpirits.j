/**
    ShamanVoodooSpirits

    Author: Valdemar
    Version:

    Description:
    Hook library for Voodoo Spirits. The imported GUI folder did not contain a
    runtime trigger for this ability; object data currently owns the effect.

    Credits:
    - Old GUI Shaman ability object data

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanVoodooSpirits initializer Init requires Events, ShamanCommon

private function HandleSpellEffect takes nothing returns nothing
    if GetSpellAbilityId() == ShamanCommon_ABILITY_VOODOO_SPIRITS then
        call ShamanCommon_RefreshAbility(GetTriggerUnit(), ShamanCommon_ABILITY_VOODOO_SPIRITS)
    endif
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
endfunction

endlibrary
