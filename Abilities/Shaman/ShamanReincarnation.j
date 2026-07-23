/**
    ShamanReincarnation

    Author: Valdemar
    Version:

    Description:
    Hook library for Reincarnation. The imported GUI folder did not include a
    runtime trigger for this ability; object data currently owns the effect.

    Credits:
    - Old GUI Shaman ability object data

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanReincarnation initializer Init requires Events, ShamanCommon

private function HandleSpellEffect takes nothing returns nothing
    if GetSpellAbilityId() == ShamanCommon_ABILITY_REINCARNATION then
        call ShamanCommon_RefreshAbility(GetTriggerUnit(), ShamanCommon_ABILITY_REINCARNATION)
    endif
endfunction

private function Init takes nothing returns nothing
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
