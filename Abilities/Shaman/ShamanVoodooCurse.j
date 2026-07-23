/**
    ShamanVoodooCurse

    Author: Valdemar
    Version:

    Description:
    Hook library for Voodoo Curse. The imported GUI folder did not contain a
    runtime trigger for this ability; object data currently owns the effect.

    Credits:
    - Old GUI Shaman ability object data

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanVoodooCurse initializer Init requires Events, ShamanCommon

private function HandleSpellEffect takes nothing returns nothing
    if GetSpellAbilityId() == ShamanCommon_ABILITY_VOODOO_CURSE then
        call ShamanCommon_RefreshAbility(GetTriggerUnit(), ShamanCommon_ABILITY_VOODOO_CURSE)
    endif
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
